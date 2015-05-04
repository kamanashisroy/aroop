using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.MethodCallModule : shotodolplug.Module {
	SourceEmitterModule emitter;
	CSymbolResolve resolve;
	public MethodCallModule() {
		base("MethodCall", "0.0");
	}

	public override int init() {
		PluginManager.register("visit/method_call", new HookExtension(visit_method_call, this));
		PluginManager.register("rehash", new HookExtension(rehashHook, this));
		return 0;
	}

	public override int deinit() {
		return 0;
	}

	Value?rehashHook(Value?arg) {
		emitter = (SourceEmitterModule?)PluginManager.swarmValue("source/emitter", null);
		resolve = (CSymbolResolve?)PluginManager.swarmValue("resolve/c/symbol",null);
		return null;
	}

	Value? visit_method_call (Value?given_args) {
		MethodCall?expr = (MethodCall?)given_args;
		// the bare function call
		var ccall = new CCodeFunctionCall (resolve.get_cvalue (expr.call));

		Method m = null;
		Vala.List<Vala.Parameter> params;

		var ma = expr.call as MemberAccess;

		var itype = expr.call.value_type;
		params = itype.get_parameters ();

		if (itype is MethodType) {
			assert (ma != null);
			m = ((MethodType) itype).method_symbol;
		} else if (itype is ObjectType) {
			// constructor
			assert(((ObjectType) itype).type_symbol is Class);
			var cl = (Class) ((ObjectType) itype).type_symbol;
			m = cl.default_construction_method;
			AroopCodeGeneratorAdapter.generate_method_declaration (m, emitter.cfile);
			ccall = new CCodeFunctionCall (new CCodeIdentifier (resolve.get_ccode_real_name (m)));
		} else if (itype is DelegateType) {
			ccall = (CCodeFunctionCall?)PluginManager.swarmValue("generate/delegate/method/call", expr);//generate_delegate_method_call_ccode(expr);
			if(ccall == null)
				print("Please report this bug, ccall should not be null\n");
		}

		if (m is CreationMethod) {
			var cl = m.parent_symbol;

			if (cl == emitter.current_class) {
				ccall.add_argument (new CCodeIdentifier (resolve.self_instance));
			} else {
				ccall.add_argument (new CCodeCastExpression (new CCodeIdentifier (resolve.self_instance), resolve.get_ccode_aroop_name (cl) + "*"));
			}
		} else if (m != null) {
			if (m.binding == MemberBinding.INSTANCE) {
				var instance = resolve.get_cvalue (ma.inner);
				var st = m.parent_symbol as Struct;
				if (st != null && !st.is_simple_type ()) {
					instance = AroopCodeGeneratorAdapter.generate_instance_cargument_for_struct(ma, m, instance);
				}
				
				ccall.add_argument (instance);
			}

			if (m.binding != MemberBinding.INSTANCE && m.parent_symbol is ObjectTypeSymbol) {
				// support static methods in generic types
				var type_symbol = (ObjectTypeSymbol) m.parent_symbol;
				if (type_symbol.get_type_parameters ().size > 0 && ma.inner is MemberAccess) {
					var type_ma = (MemberAccess) ma.inner;
					AroopCodeGeneratorAdapter.add_generic_type_arguments (ccall, type_ma.get_type_arguments (), expr);
				}
			}
			if (m.get_type_parameters ().size > 0) {
				AroopCodeGeneratorAdapter.add_generic_type_arguments (ccall, ma.get_type_arguments (), expr);
			}
		}

		// the complete call expression, might include casts, comma expressions, and/or assignments
		CCodeExpression ccall_expr = ccall;

		bool ellipsis = false;

		int i = 1;
		Iterator<Vala.Parameter> params_it = params.iterator ();
		foreach (Expression arg in expr.get_argument_list ()) {
			CCodeExpression cexpr = resolve.get_cvalue (arg);

			if (params_it.next ()) {
				var param = params_it.get ();
				ellipsis = param.params_array || param.ellipsis;
				if (!ellipsis) {
					cexpr = AroopCodeGeneratorAdapter.generate_cargument_for_struct (param, arg, cexpr);

					// unref old value for non-null non-weak ref/out arguments
					// disabled for arrays for now as that requires special handling
					// (ret_tmp = call (&tmp), var1 = (assign_tmp = dup (tmp), free (var1), assign_tmp), ret_tmp)
					if (param.direction != Vala.ParameterDirection.IN && resolve.requires_destroy (arg.value_type)
					    && (param.direction == Vala.ParameterDirection.OUT || !param.variable_type.value_owned)
					    && !(param.variable_type is ArrayType)) {
						var unary = (UnaryExpression) arg;

						var ccomma = new CCodeCommaExpression ();

						var temp_var = emitter.get_temp_variable (param.variable_type, param.variable_type.value_owned);
						//temp_var.is_imaginary = true;
						AroopCodeGeneratorAdapter.generate_temp_variable(temp_var);
						cexpr = new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, resolve.get_variable_cexpression (temp_var.name));

						if (param.direction == Vala.ParameterDirection.REF) {
							var crefcomma = new CCodeCommaExpression ();
							crefcomma.append_expression (new CCodeAssignment (resolve.get_variable_cexpression (temp_var.name), resolve.get_cvalue (unary.inner)));
							crefcomma.append_expression (cexpr);
							cexpr = crefcomma;
						}

						// call function
						LocalVariable ret_temp_var = null;
						if (itype.get_return_type () is VoidType) {
							ccomma.append_expression (ccall_expr);
						} else {
							ret_temp_var = emitter.get_temp_variable (itype.get_return_type ());
							//ret_temp_var.is_imaginary = true;
							AroopCodeGeneratorAdapter.generate_temp_variable(ret_temp_var);
							ccomma.append_expression (new CCodeAssignment (resolve.get_variable_cexpression (ret_temp_var.name), ccall_expr));
						}

						var cassign_comma = new CCodeCommaExpression ();

						var assign_temp_var = emitter.get_temp_variable (unary.inner.value_type, unary.inner.value_type.value_owned);
						//assign_temp_var.is_imaginary = true;
						AroopCodeGeneratorAdapter.generate_temp_variable(assign_temp_var);

						cassign_comma.append_expression (new CCodeAssignment (resolve.get_variable_cexpression (assign_temp_var.name), AroopCodeGeneratorAdapter.generate_expression_transformation (resolve.get_variable_cexpression (temp_var.name), param.variable_type, unary.inner.value_type, arg)));

						// unref old value
						cassign_comma.append_expression (resolve.get_unref_expression (resolve.get_cvalue (unary.inner), arg.value_type, arg));

						cassign_comma.append_expression (resolve.get_variable_cexpression (assign_temp_var.name));

						// assign new value
						ccomma.append_expression (new CCodeAssignment (resolve.get_cvalue (unary.inner), cassign_comma));

						// return value
						if (!(itype.get_return_type () is VoidType)) {
							ccomma.append_expression (resolve.get_variable_cexpression (ret_temp_var.name));
						}

						ccall_expr = ccomma;
					}

					if (CodegenPlugBaseModule.get_ccode_type (param) != null) {
						if(param.variable_type is DelegateType) {
#if false
							var deleg_comma = new CCodeCommaExpression();
							var deleg_temp_var = generate_method_to_delegate_cast_expression_as_comma(cexpr, arg.value_type, param.variable_type, arg, deleg_comma);
							if(deleg_temp_var == null) { 
								cexpr = generate_method_to_delegate_cast_expression(cexpr, arg.value_type, param.variable_type, arg);
							} else {
								deleg_comma.append_expression(ccall_expr);
								ccall_expr = deleg_comma;
								cexpr = deleg_temp_var;
							}
#endif
						} else {
							cexpr = new CCodeCastExpression (cexpr, CodegenPlugBaseModule.get_ccode_type (param));
						}
					}
				} else if(/*arg.value_type is MethodType &&*/ param.variable_type is DelegateType) {					
#if false
					CCodeExpression?dleg_expr = generate_delegate_closure_argument(arg);
					cexpr = generate_method_to_delegate_cast_expression(cexpr, arg.value_type, param.variable_type, arg);
#else
#if false
							var deleg_comma = new CCodeCommaExpression();
							var deleg_temp_var = generate_method_to_delegate_cast_expression_as_comma(cexpr, arg.value_type, param.variable_type, arg, deleg_comma);
							if(deleg_temp_var == null) { 
								cexpr = generate_method_to_delegate_cast_expression(cexpr, arg.value_type, param.variable_type, arg);
							} else {
								deleg_comma.append_expression(ccall_expr);
								ccall_expr = deleg_comma;
								cexpr = deleg_temp_var;
							}
#endif
#endif
				}
			}

			ccall.add_argument (cexpr);
			i++;
		}
		if (params_it.next ()) {
			var param = params_it.get ();

			/* if there are more parameters than arguments,
			 * the additional parameter is an ellipsis parameter
			 * otherwise there is a bug in the semantic analyzer
			 */
			assert (param.params_array || param.ellipsis);
			ellipsis = true;
		}

		if (itype.get_return_type () is GenericType) {
			var ccomma = new CCodeCommaExpression ();

			var temp_var = emitter.get_temp_variable (expr.value_type);
			//temp_var.is_imaginary = true;
			AroopCodeGeneratorAdapter.generate_temp_variable(temp_var);
			//if (expr.value_type is GenericType) {
				//ccall.add_argument (resolve.get_variable_cexpression (temp_var.name));
			//} else {
				ccall.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, resolve.get_variable_cexpression (temp_var.name)));
			//}

			// call function
			ccomma.append_expression (ccall_expr);

			ccomma.append_expression (resolve.get_variable_cexpression (temp_var.name));

			ccall_expr = ccomma;
		}

		if (expr.tree_can_fail) {
			// method can fail
			emitter.current_method_inner_error = true;
			// add &inner_error before the ellipsis arguments
			ccall.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, resolve.get_variable_cexpression ("_inner_error_")));
		}

		if (expr.parent_node is ExpressionStatement) {
			emitter.ccode.add_expression (ccall_expr);
		} else {
			var temp_var = emitter.get_temp_variable (expr.value_type);
			var temp_ref = resolve.get_variable_cexpression (temp_var.name);

			AroopCodeGeneratorAdapter.generate_temp_variable(temp_var);

			emitter.ccode.add_assignment (temp_ref, ccall_expr);
			resolve.set_cvalue (expr, temp_ref);
		}
		return null;
	}


}


