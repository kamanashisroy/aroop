using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.ExpressionModule : shotodolplug.Module {
	SourceEmitterModule emitter;
	CSymbolResolve resolve;
	public ExpressionModule() {
		base("Expression", "0.0");
	}

	public override int init() {
		PluginManager.register("visit/expression", new HookExtension(visit_expression, this));
		PluginManager.register("visit/end_full_expression", new HookExtension(visit_end_full_expression, this));
		PluginManager.register("generate/expression/transformation", new HookExtension(transform_expression_helper, this));
		PluginManager.register("generate/instance/cast", new HookExtension(generate_instance_cast_helper, this));
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

	Value? visit_expression (Value?given) {
		Expression?expr = (Expression?)given;
		print_debug("Emitting expression %s\n".printf(expr.to_string()));
		print_debug(" --> %s\n".printf((resolve.get_cvalue(expr) == null)?"null":"not null"));
		if (resolve.get_cvalue (expr) != null && !expr.lvalue) {
			// memory management, implicit casts, and boxing/unboxing
			resolve.set_cvalue (expr, transform_expression (resolve.get_cvalue (expr), expr.value_type, expr.target_type, expr));
		}
		print_debug("Done expression %s\n".printf(expr.to_string()));
		return null;
	}


	Value? visit_end_full_expression (Value?given) {
		Expression?expr = (Expression?)given;
		/* expr is a full expression, i.e. an initializer, the
		 * expression in an expression statement, the controlling
		 * expression in if, while, for, or foreach statements
		 *
		 * we unref temporary variables at the end of a full
		 * expression
		 */
		print_debug("end_full_expression %s\n".printf(expr.to_string()));

		if (((Vala.List<LocalVariable>) emitter.emit_context.temp_ref_vars).size == 0) {
			/* nothing to do without temporary variables */
			print_debug("end_full_expression %s nothing to do ..\n".printf(expr.to_string()));
			return null;
		}

		var expr_type = expr.value_type;
		if (expr.target_type != null) {
			expr_type = expr.target_type;
		}

		print_debug("end_full_expression creating temporary variable %s\n".printf(expr.to_string()));
		var full_expr_var = emitter.get_temp_variable (expr_type, true, expr);
		AroopCodeGeneratorAdapter.generate_temp_variable(full_expr_var);

		var expr_list = new CCodeCommaExpression ();
		print_debug("visit_end_full_expression doing assignment for %s ========================= \n".printf(expr.to_string()));
		expr_list.append_expression (new CCodeAssignment (resolve.get_variable_cexpression (full_expr_var.name), resolve.get_cvalue (expr)));

		foreach (LocalVariable local in emitter.emit_context.temp_ref_vars) {
			var ma = new MemberAccess.simple (local.name);
			ma.symbol_reference = local;
			expr_list.append_expression (resolve.get_unref_expression (resolve.get_variable_cexpression (local.name), local.variable_type, ma));
		}

		expr_list.append_expression (resolve.get_variable_cexpression (full_expr_var.name));

		resolve.set_cvalue (expr, expr_list);

		emitter.emit_context.temp_ref_vars.clear ();
		return null;
	}

	Value? transform_expression_helper (Value?given_args) {
		var args = (HashTable<string,Value?>)given_args;
		return transform_expression(
			(CCodeExpression?)args["source_cexpr"]
			,(DataType?)args["expression_type"]
			,(DataType?)args["target_type"]
			,(Expression?)args["expr"]
		);
	}

	CCodeExpression transform_expression (CCodeExpression source_cexpr, DataType? expression_type, DataType? target_type, Expression? expr = null) {

		// check for optimization
		if(source_cexpr is CCodeAssignment)
			print_debug("Transforming expression %s may be we can do optimization ********\n".printf(expr.to_string()));

		if(expr != null && expr is Vala.Assignment) {
			Vala.Assignment aexpr = (Vala.Assignment)expr;
			print_debug("Investigating assignment left:%s, right:%s\n".printf(aexpr.left.to_string(), aexpr.right.to_string()));
		}


		var cexpr = source_cexpr;
		if (expression_type == null) {
			return cexpr;
		}

		print_debug("Transforming expression %s for target %s\n".printf(expr.to_string(), (target_type == null)?"(null)":target_type.to_string()));

		if (expression_type.value_owned
		    && (target_type == null || !target_type.value_owned)) {
			// value leaked, destroy it
			var pointer_type = target_type as PointerType;
			if (pointer_type != null && !(pointer_type.base_type is VoidType)) {
				// manual memory management for non-void pointers
				// treat void* special to not leak memory with void* method parameters
			} else if (resolve.requires_destroy (expression_type)) {
#if true
				var decl = emitter.get_temp_variable (expression_type, true, expression_type);
				AroopCodeGeneratorAdapter.generate_temp_variable(decl);
				emitter.emit_context.temp_ref_vars.insert (0, decl);
				print_debug("adding temp variable %s for expression %s\n".printf(decl.to_string(), expr.to_string()));
				print_debug("transform_expression doing assignment for %s ========================= \n".printf(expr.to_string()));
				cexpr = new CCodeAssignment (resolve.get_variable_cexpression (decl.name), cexpr);
#else
				// use macro instead of temporary variable
				var assign_n_unref = new CCodeFunctionCall(new CCodeIdentifier ("aroop_assign_requires_destroy_TODO"));
				assign_n_unref.add_argument(cexpr); // TODO add the unref method there.
				cexpr = assign_n_unref;
#endif
			}
		}

		if (target_type == null) {
			// value will be destroyed, no need for implicit casts
			return cexpr;
		}

		cexpr = get_implicit_cast_expression (cexpr, expression_type, target_type, expr);

		if (target_type.value_owned && !expression_type.value_owned) {
			// need to copy value
			if (resolve.requires_copy (target_type) && !(expression_type is NullType)) {
				CodeNode node = expr;
				if (node == null) {
					node = expression_type;
				}
				cexpr = resolve.get_ref_cexpression (target_type, cexpr, expr, node);
			}
		}
		print_debug("End of transformation of %s for target %s\n".printf(expr.to_string(), target_type.to_string()));

		return cexpr;
	}
	CCodeExpression get_implicit_cast_expression (CCodeExpression source_cexpr, DataType? expression_type, DataType? target_type, Expression? expr = null) {
		var cexpr = source_cexpr;

		if (expression_type.data_type != null && expression_type.data_type == target_type.data_type) {
			// same type, no cast required
			print_debug("no cast required for target %s for expression %s\n".printf(expr.to_string(), target_type.to_string()));
			return cexpr;
		}

		if (expression_type is NullType) {
			if (target_type is ArrayType) {
				var array = new CCodeFunctionCall (new CCodeIdentifier ("aroop_array"));
				array.add_argument (new CCodeConstant ("NULL"));
				array.add_argument (new CCodeConstant ("0"));
				return array;
			}

			if (target_type is DelegateType) {
				return AroopCodeGeneratorAdapter.generate_method_to_delegate_cast_expression(source_cexpr, expression_type, target_type, expr);
			}
			// null literal, no cast required when not converting to generic type pointer
			return cexpr;
		}

		if (expression_type is ArrayType && target_type is PointerType) {
			var array_type = (ArrayType) expression_type;
			if (!array_type.inline_allocated) {
				//return new CCodeMemberAccess (cexpr, "data");
				return cexpr;
			}
		}

		if (expression_type is ArrayType && target_type is ArrayType) {
			var source_array_type = (ArrayType) expression_type;
			var target_array_type = (ArrayType) target_type;
			if (source_array_type.inline_allocated && !target_array_type.inline_allocated) {
				var array = new CCodeFunctionCall (new CCodeIdentifier ("aroop_array"));
				array.add_argument (cexpr);

				var csizeof = new CCodeFunctionCall (new CCodeIdentifier ("sizeof"));
				csizeof.add_argument (cexpr);
				var csizeofelement = new CCodeFunctionCall (new CCodeIdentifier ("sizeof"));
				csizeofelement.add_argument (new CCodeElementAccess (cexpr, new CCodeConstant ("0")));
				array.add_argument (new CCodeBinaryExpression (CCodeBinaryOperator.DIV, csizeof, csizeofelement));

				return array;
			}
		}

		AroopCodeGeneratorAdapter.generate_type_declaration (target_type, emitter.cfile);

		if (target_type is DelegateType && expression_type is MethodType) {
			return AroopCodeGeneratorAdapter.generate_method_to_delegate_cast_expression(source_cexpr, expression_type, target_type, expr);
		}

		Class? cl = null;
		Interface? iface = null;
		if(target_type.data_type is Class)
			cl = target_type.data_type as Class;
		if(target_type.data_type is Interface)
			iface = target_type.data_type as Interface;
		if (emitter.context.checking && (iface != null || (cl != null && !cl.is_compact))) {
			// checked cast for strict subtypes of GTypeInstance
			return generate_instance_cast (cexpr, target_type.data_type);
		} else if (target_type.data_type != null && resolve.get_ccode_aroop_name (expression_type) != resolve.get_ccode_aroop_name (target_type)) {
			Struct?st = null;
			if(target_type.data_type is Struct)
				st = target_type.data_type as Struct;
			if (target_type.data_type.is_reference_type () || (st != null && st.is_simple_type ())) {
				// don't cast non-simple structs
				return new CCodeCastExpression (cexpr, resolve.get_ccode_aroop_name (target_type));
			} else {
				return cexpr;
			}
		} else {
			return cexpr;
		}
	}

	Value? generate_instance_cast_helper (Value?given_args) {
		var args = (HashTable<string,Value?>)given_args;
		return generate_instance_cast (
			(CCodeExpression?)args["expr"]
			,(TypeSymbol?)args["type"]
		);
	}
	CCodeExpression generate_instance_cast (CCodeExpression expr, TypeSymbol type) {
		return new CCodeCastExpression (expr, resolve.get_ccode_aroop_name (type) + "*");
	}
}

