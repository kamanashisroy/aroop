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
		PluginManager.register("visit/expression_statement", new HookExtension(visit_expression_statement, this));
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
		if (resolve.get_cvalue (expr) != null && !expr.lvalue) {
			// memory management, implicit casts, and boxing/unboxing
			resolve.set_cvalue (expr, transform_expression (resolve.get_cvalue (expr), expr.value_type, expr.target_type, expr));
		}
		return null;
	}

	Value? visit_expression_statement (Value?given) {
		ExpressionStatement?stmt = (ExpressionStatement?)given;
		if (stmt.expression.error) {
			stmt.error = true;
			return null;
		}

		if (resolve.get_cvalue (stmt.expression) != null) {
			emitter.ccode.add_expression (resolve.get_cvalue (stmt.expression));
		}
		/* free temporary objects and handle errors */

		foreach (LocalVariable local in emitter.emit_context.temp_ref_vars) {
			var ma = new MemberAccess.simple (local.name);
			ma.symbol_reference = local;
			ma.value_type = local.variable_type.copy ();
			emitter.ccode.add_expression (resolve.get_unref_expression (resolve.get_variable_cexpression (local.name), local.variable_type, ma));
		}

		if (stmt.tree_can_fail && stmt.expression.tree_can_fail) {
			// simple case, no node breakdown necessary
#if false
			// TODO Enable This Check
			add_simple_check (stmt.expression);
#endif
		}

		emitter.emit_context.temp_ref_vars.clear ();
		return null;
	}

	CCodeExpression transform_expression (CCodeExpression source_cexpr, DataType? expression_type, DataType? target_type, Expression? expr = null) {
		var cexpr = source_cexpr;
		if (expression_type == null) {
			return cexpr;
		}


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
				PluginManager.swarmValue ("generate/temp", decl);
				emitter.emit_context.temp_ref_vars.insert (0, decl);
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

		return cexpr;
	}
	public CCodeExpression get_implicit_cast_expression (CCodeExpression source_cexpr, DataType? expression_type, DataType? target_type, Expression? expr = null) {
		var cexpr = source_cexpr;

		if (expression_type.data_type != null && expression_type.data_type == target_type.data_type) {
			// same type, no cast required
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
				return generate_method_to_delegate_cast_expression_as_comma_2(source_cexpr, expression_type, target_type, expr);
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
			return generate_method_to_delegate_cast_expression_as_comma_2(source_cexpr, expression_type, target_type, expr);
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
	CCodeExpression? generate_method_to_delegate_cast_expression_as_comma_2(CCodeExpression source_cexpr, DataType? expression_type, DataType? target_type, Expression? expr) {
		var deleg_comma = new CCodeCommaExpression();
		var deleg_temp_var = generate_method_to_delegate_cast_expression_as_comma(source_cexpr, expression_type, target_type, expr, deleg_comma);
		if(deleg_temp_var == null) { 
			return generate_method_to_delegate_cast_expression(source_cexpr, expression_type, target_type, expr);
		}
		return deleg_comma;
	}

	CCodeExpression? generate_method_to_delegate_cast_expression_as_comma(CCodeExpression source_cexpr, DataType? expression_type, DataType? target_type, Expression? expr, CCodeCommaExpression ccomma) {
		return null;
	}
	CCodeExpression generate_method_to_delegate_cast_expression(CCodeExpression source_cexpr, DataType? expression_type, DataType? target_type, Expression? expr) {
		return source_cexpr;
	}
	CCodeExpression generate_instance_cast (CCodeExpression expr, TypeSymbol type) {
		return new CCodeCastExpression (expr, resolve.get_ccode_aroop_name (type) + "*");
	}
}

