using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.CastExpressionModule : shotodolplug.Module {
	SourceEmitterModule emitter;
	CSymbolResolve resolve;
	public CastExpressionModule() {
		base("CastExpression", "0.0");
	}

	public override int init() {
		PluginManager.register("visit/cast_expression", new HookExtension(visit_cast_expression, this));
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

	Value?visit_cast_expression (Value?given) {
		CastExpression?expr = (CastExpression?)given;
		if (expr.is_silent_cast) {
			if (expr.inner.value_type is ObjectType) {
				var silent_cast = new CCodeFunctionCall (new CCodeIdentifier ("aroop_object_silent_cast"));
				silent_cast.add_argument (resolve.get_type_id_expression (expr.type_reference));
				silent_cast.add_argument (resolve.get_type_id_expression (expr.inner.value_type));
				silent_cast.add_argument (resolve.get_cvalue (expr.inner));
				resolve.set_cvalue (expr, silent_cast);
			} else {
				expr.error = true;
				Report.error (expr.source_reference, "Operation not supported for this type");
			}
			return null;
		}
		
		if (expr.type_reference.data_type != null && expr.type_reference.data_type.get_full_name () == "Aroop.Value") {
			var needs_cast = new CCodeFunctionCall (new CCodeIdentifier ("aroop_object_unimplemented_cast"));
			needs_cast.add_argument (resolve.get_type_id_expression (expr.type_reference));
			needs_cast.add_argument (resolve.get_type_id_expression (expr.inner.value_type));
			needs_cast.add_argument (resolve.get_cvalue (expr.inner));
			resolve.set_cvalue (expr, needs_cast);
			return null;
		} else if (expr.inner.value_type.data_type != null && expr.inner.value_type.data_type.get_full_name () == "Aroop.Value") {
			var needs_cast = new CCodeFunctionCall (new CCodeIdentifier ("aroop_object_unimplemented_cast"));
			needs_cast.add_argument (resolve.get_type_id_expression (expr.type_reference));
			needs_cast.add_argument (resolve.get_type_id_expression (expr.inner.value_type));
			needs_cast.add_argument (resolve.get_cvalue (expr.inner));
			resolve.set_cvalue (expr, needs_cast);
			return null;
		}

		if (expr.inner.value_type is ArrayType && expr.type_reference is PointerType) {
			var array_type = (ArrayType) expr.inner.value_type;
			if (!array_type.fixed_length) {
				resolve.set_cvalue (expr, new CCodeMemberAccess (resolve.get_cvalue (expr.inner), "data"));
				return null;
			}
		}

		AroopCodeGeneratorAdapter.generate_type_declaration (expr.type_reference, emitter.cfile);

		if (expr.inner.value_type is GenericType && !(expr.type_reference is GenericType)) {
			// generic types use an extra pointer, dereference that pointer
			var generic_to_nogeneric = new CCodeFunctionCall (new CCodeIdentifier ("aroop_generic_to_nongeneric_cast"));
			generic_to_nogeneric.add_argument (resolve.get_type_id_expression (expr.type_reference, false, true));
			generic_to_nogeneric.add_argument (resolve.get_type_id_expression (expr.inner.value_type));
			generic_to_nogeneric.add_argument (resolve.get_cvalue (expr.inner));
			resolve.set_cvalue (expr, generic_to_nogeneric);
			//resolve.set_cvalue (expr, new CCodeUnaryExpression (CCodeUnaryOperator.POINTER_INDIRECTION, new CCodeCastExpression (get_cvalue (expr.inner), get_ccode_aroop_name (expr.type_reference) + "*")));
		} else {
			resolve.set_cvalue (expr, new CCodeCastExpression (resolve.get_cvalue (expr.inner), resolve.get_ccode_aroop_name (expr.type_reference)));
		}
		if (expr.type_reference is DelegateType) {
			resolve.set_cvalue(expr, generate_method_to_delegate_cast_expression_as_comma_2(resolve.get_cvalue(expr.inner), expr.inner.value_type, expr.type_reference, expr.inner));
		}
		return null;
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
		if (expression_type is DelegateType) {
			return null;
		}
		CCodeExpression delegate_expr = generate_method_to_delegate_cast_expression(source_cexpr, expression_type, target_type, expr);
		var assign_temp_var = emitter.get_temp_variable (target_type);
		AroopCodeGeneratorAdapter.generate_temp_variable(assign_temp_var);
		//emit_temp_var (assign_temp_var);
		ccomma.append_expression(new CCodeAssignment(resolve.get_variable_cexpression (assign_temp_var.name), delegate_expr));
		ccomma.append_expression(resolve.get_variable_cexpression(assign_temp_var.name));
		return resolve.get_variable_cexpression(assign_temp_var.name);
	}

	CCodeExpression generate_method_to_delegate_cast_expression(CCodeExpression source_cexpr, DataType? expression_type, DataType? target_type, Expression? expr) {
		if (expression_type is DelegateType) {
			return source_cexpr;
		}
		if (source_cexpr is CCodeCastExpression) {
			CCodeCastExpression cast_expr = (CCodeCastExpression)source_cexpr;
			if(cast_expr.type_name == resolve.get_ccode_aroop_name(target_type) && cast_expr.inner is CCodeInitializerList) {
				return source_cexpr;
			}
		}
		var clist = new CCodeInitializerList ();
		if (expression_type is NullType) {
			clist.append (source_cexpr);
		} else {
			clist.append (AroopCodeGeneratorAdapter.generate_delegate_closure_argument(expr));
		}
		clist.append (source_cexpr);
		return new CCodeCastExpression(clist, resolve.get_ccode_aroop_name(target_type));
	}
}
