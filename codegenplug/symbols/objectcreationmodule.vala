using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.ObjectCreationModule : shotodolplug.Module {
	SourceEmitterModule?emitter = null;
	CSymbolResolve?resolve = null;
	public ObjectCreationModule() {
		base("ObjectCreation", "0.0");
	}

	public override int init() {
		PluginManager.register("visit/object_creation_expression", new HookExtension(visit_object_creation_expression_helper, this));
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

	Value?visit_object_creation_expression_helper(Value?arg) {
		visit_object_creation_expression((ObjectCreationExpression?)arg);
		return null;
	}

	void visit_object_creation_expression (ObjectCreationExpression expr) {
		CCodeExpression instance = null;
		CCodeExpression creation_expr = null;

		Struct?st = null;
		if(expr.type_reference.data_type is Struct)
			st = expr.type_reference.data_type as Struct;

		bool struct_by_ref = false;
		if (st != null && !st.is_boolean_type () && !st.is_integer_type () && !st.is_floating_type ()) {
			struct_by_ref = true;
		}
		bool usingtemp_so_requires_assignment = true;

		if (struct_by_ref || expr.get_object_initializer ().size > 0) {
			/**
			 * The following code may pop target variable ..
			 */ 
#if false
			// value-type initialization or object creation expression with object initializer
			var temp_decl = emitter.get_temp_variable (expr.type_reference, false, expr);
			AroopCodeGeneratorAdapter.generate_temp_variable (temp_decl);
			print_debug("visit_object_creation_expression is creating temporary variable %s for %s\n".printf(temp_decl.to_string(), expr.to_string()));

			// TODO omit the following line of code
			var memclean = new CCodeFunctionCall(new CCodeIdentifier("aroop_memclean_raw2"));
			var temp_ref = resolve.get_variable_cexpression (temp_decl.name);
			memclean.add_argument(new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, temp_ref));
			emitter.ccode.add_expression (memclean); // XXX doing costly memory cleanup
			instance = resolve.get_variable_cexpression (resolve.get_variable_cname (temp_decl.name));
#else
			usingtemp_so_requires_assignment = false;
			instance = resolve.get_variable_cexpression(emitter.get_declaration_variable().name);
#endif
		}

		if (expr.symbol_reference == null) {
			// no creation method
			if (expr.type_reference.data_type is Struct) {
				var creation_call = new CCodeFunctionCall (new CCodeIdentifier ("memset"));
				creation_call.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, instance));
				creation_call.add_argument (new CCodeConstant ("0"));
				creation_call.add_argument (new CCodeIdentifier ("sizeof (%s)".printf (resolve.get_ccode_aroop_name (expr.type_reference))));

				creation_expr = creation_call;
			}
		} else if (expr.symbol_reference is Method) {
			// use creation method
			var m = (Method) expr.symbol_reference;
			var params = m.get_parameters ();
			CCodeFunctionCall creation_call;

			AroopCodeGeneratorAdapter.generate_method_declaration (m, emitter.cfile);

			Class?cl = null;
			if(expr.type_reference.data_type is Class)
				cl = expr.type_reference.data_type as Class;

			if (!CodegenPlugBaseModule.get_ccode_has_new_function (m)) {
				// use construct function directly
				creation_call = new CCodeFunctionCall (new CCodeIdentifier (resolve.get_ccode_real_name (m)));
				creation_call.add_argument (new CCodeIdentifier (CodegenPlugBaseModule.get_ccode_type_id (cl)));
			} else {
				creation_call = new CCodeFunctionCall (new CCodeIdentifier (resolve.get_ccode_name (m)));
			}

			if (struct_by_ref && !(resolve.get_ccode_instance_pos (m) < 0)) {
				creation_call.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, instance));
			}

			AroopCodeGeneratorAdapter.generate_type_declaration (expr.type_reference, emitter.cfile);

			if ((st != null) || (cl != null && !cl.is_compact)) {
				AroopCodeGeneratorAdapter.add_generic_type_arguments (creation_call, expr.type_reference.get_type_arguments (), expr);
			}

			bool ellipsis = false;

			int i = 1;
			Iterator<Vala.Parameter> params_it = params.iterator ();
			foreach (Expression arg in expr.get_argument_list ()) {
				CCodeExpression cexpr = resolve.get_cvalue (arg);
				Vala.Parameter param = null;
				if (params_it.next ()) {
					param = params_it.get ();
					ellipsis = param.ellipsis;
					if (!ellipsis) {
						cexpr = AroopCodeGeneratorAdapter.generate_cargument_for_struct (param, arg, cexpr);
					}
				}

				creation_call.add_argument (cexpr);

				i++;
			}
			while (params_it.next ()) {
				var param = params_it.get ();

				if (param.ellipsis) {
					ellipsis = true;
					break;
				}

				if (param.initializer == null) {
					Report.error (expr.source_reference, "no default expression for argument %d".printf (i));
					return;
				}

				/* evaluate default expression here as the code
				 * generator might not have visited the formal
				 * parameter yet */
				param.initializer.emit (emitter.visitor);

				creation_call.add_argument (resolve.get_cvalue (param.initializer));
				i++;
			}

			if (struct_by_ref && resolve.get_ccode_instance_pos (m) < 0) {
				// instance parameter is at the end in a struct creation method
				creation_call.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, instance));
			}
			
			if (expr.tree_can_fail) {
				// method can fail
				emitter.current_method_inner_error = true;
				creation_call.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, resolve.get_variable_cexpression ("_inner_error_")));
				
			}

			if (ellipsis) {
				/* ensure variable argument list ends with NULL
				 * except when using printf-style arguments */
				if (!m.printf_format && !m.scanf_format && resolve.get_ccode_sentinel (m) != "") {
					creation_call.add_argument (new CCodeConstant (resolve.get_ccode_sentinel (m)));
				}
			}

			creation_expr = creation_call;

			// cast the return value of the creation method back to the intended type if
			// it requested a special C return type
			if (resolve.get_custom_creturn_type (m) != null) {
				creation_expr = new CCodeCastExpression (creation_expr, resolve.get_ccode_aroop_name (expr.type_reference));
			}
		} else if (expr.symbol_reference is ErrorCode) {
			var ecode = (ErrorCode) expr.symbol_reference;
			var edomain = (ErrorDomain) ecode.parent_symbol;
			CCodeFunctionCall creation_call;

			AroopCodeGeneratorAdapter.generate_error_domain_declaration (edomain, emitter.cfile);

			if (expr.get_argument_list ().size == 1) {
				// must not be a format argument
				creation_call = new CCodeFunctionCall (new CCodeIdentifier ("aroop_error_new_literal"));
			} else {
				creation_call = new CCodeFunctionCall (new CCodeIdentifier ("aroop_error_new"));
			}
			creation_call.add_argument (new CCodeIdentifier (resolve.get_error_module_lower_case_name (edomain)));
			creation_call.add_argument (new CCodeIdentifier (resolve.get_error_module_lower_case_name (ecode)));
			foreach (Expression arg in expr.get_argument_list ()) {
				creation_call.add_argument (resolve.get_cvalue (arg));
			}
			creation_expr = creation_call;
		} else {
			assert (false);
		}

		if (instance != null) {
			if (expr.type_reference.data_type is Struct) {
				emitter.ccode.add_expression (creation_expr);
			} else {
				emitter.ccode.add_assignment (instance, creation_expr);
			}

			foreach (MemberInitializer init in expr.get_object_initializer ()) {
				if (init.symbol_reference is Field) {
					var f = (Field) init.symbol_reference;
					var instance_target_type = resolve.get_data_type_for_symbol ((TypeSymbol) f.parent_symbol);
					var typed_inst = AroopCodeGeneratorAdapter.generate_expression_transformation(instance, expr.type_reference, instance_target_type);
					CCodeExpression lhs;
					if (expr.type_reference.data_type is Struct) {
						lhs = new CCodeMemberAccess (typed_inst, resolve.get_ccode_name (f));
					} else {
						lhs = new CCodeMemberAccess.pointer (typed_inst, resolve.get_ccode_name (f));
					}
					emitter.ccode.add_assignment (lhs, resolve.get_cvalue (init.initializer));
				} else if (init.symbol_reference is Property) {
					var inst_ma = new MemberAccess.simple ("new");
					inst_ma.value_type = expr.type_reference;
					resolve.set_cvalue (inst_ma, instance);
					AroopCodeGeneratorAdapter.store_property ((Property) init.symbol_reference, inst_ma, init.initializer.target_value);
				}
			}

			creation_expr = instance;
		}

		if (creation_expr != null) {
#if false
			var temp_var = emitter.get_temp_variable (expr.value_type);
			var temp_ref = resolve.get_variable_cexpression (temp_var.name);

			AroopCodeGeneratorAdapter.generate_temp_variable (temp_var);
			print_debug("visit_object_creation_expression 2 is creating temporary variable %s for %s\n".printf(temp_var.to_string(), expr.to_string()));

			emitter.ccode.add_assignment (temp_ref, creation_expr);
			resolve.set_cvalue (expr, temp_ref);
#else
			if(usingtemp_so_requires_assignment)
				emitter.ccode.add_assignment (resolve.get_variable_cexpression(emitter.get_declaration_variable().name), creation_expr);
			resolve.set_cvalue (expr, creation_expr);
#endif
		}
	}
}
