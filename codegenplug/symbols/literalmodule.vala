
using Vala;
using shotodolplug;
using codegenplug;


/**
 * The link between a method and generated code.
 */
public class codegenplug.LiteralModule : shotodolplug.Module {
	SourceEmitterModule?emitter = null;
	CSymbolResolve?resolve = null;
	public LiteralModule() {
		base("Literal", "0.0");
	}

	public override int init() {
		PluginManager.register("visit/integer_literal", new HookExtension(visit_integer_literal, this));
		PluginManager.register("visit/null_literal", new HookExtension(visit_null_literal, this));
		PluginManager.register("visit/boolean_literal", new HookExtension(visit_boolean_literal, this));
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

	Value? visit_integer_literal (Value? givenValue) {
		IntegerLiteral?expr = (IntegerLiteral?)givenValue;
		resolve.set_cvalue (expr, new CCodeConstant (expr.value));
		return null;
	}

	Value?visit_null_literal (Value?given) {
		NullLiteral?expr = (NullLiteral?)given;
		resolve.set_cvalue (expr, new CCodeConstant ("NULL"));
		return null;
	}

#if false
	public override void visit_list_literal (ListLiteral expr) {
		CCodeExpression ptr;
		int length = expr.get_expressions ().size;

		if (length == 0) {
			ptr = new CCodeConstant ("NULL");
		} else {
			var array_type = new ArrayType (expr.element_type, 1, expr.source_reference);
			array_type.inline_allocated = true;
			array_type.fixed_length = true;
			array_type.length = length;

			var temp_var = get_temp_variable (array_type, true, expr);
			var name_cnode = get_variable_cexpression (temp_var.name);

			emit_temp_var (temp_var);

			int i = 0;
			foreach (Expression e in expr.get_expressions ()) {
				print_debug("visit_list_literal creating assignment for %s ++++++++++++++++++\n".printf(expr.to_string()));
				ccode.add_assignment (new CCodeElementAccess (name_cnode, new CCodeConstant (i.to_string ())), resolve.get_cvalue (e));
				i++;
			}

			ptr = name_cnode;
		}

		var array_type = new ArrayType (expr.element_type, 1, expr.source_reference);

		var temp_var = get_temp_variable (array_type, true, expr);
		var name_cnode = get_variable_cexpression (temp_var.name);

		emit_temp_var (temp_var);

		var array_init = new CCodeFunctionCall (new CCodeIdentifier ("aroop_array_init"));
		array_init.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, name_cnode));
		array_init.add_argument (ptr);
		array_init.add_argument (new CCodeConstant (length.to_string ()));
		ccode.add_expression (array_init);

		var list_creation = new CCodeFunctionCall (new CCodeIdentifier ("aroop_list_new"));
		list_creation.add_argument (get_type_id_expression (expr.element_type));
		list_creation.add_argument (name_cnode);

		resolve.set_cvalue (expr, list_creation);
	}

	public override void visit_set_literal (SetLiteral expr) {
		var ce = new CCodeCommaExpression ();
		int length = expr.get_expressions ().size;

		if (length == 0) {
			ce.append_expression (new CCodeConstant ("NULL"));
		} else {
			var array_type = new ArrayType (expr.element_type, 1, expr.source_reference);
			array_type.inline_allocated = true;
			array_type.fixed_length = true;
			array_type.length = length;

			var temp_var = get_temp_variable (array_type, true, expr);
			var name_cnode = get_variable_cexpression (temp_var.name);

			emit_temp_var (temp_var);

			int i = 0;
			foreach (Expression e in expr.get_expressions ()) {
				ce.append_expression (new CCodeAssignment (new CCodeElementAccess (name_cnode, new CCodeConstant (i.to_string ())), resolve.get_cvalue (e)));
				i++;
			}

			ce.append_expression (name_cnode);
		}

		var set_creation = new CCodeFunctionCall (new CCodeIdentifier ("aroop_set_new"));
		set_creation.add_argument (get_type_id_expression (expr.element_type));
		set_creation.add_argument (new CCodeConstant (length.to_string ()));
		set_creation.add_argument (ce);

		resolve.set_cvalue (expr, set_creation);
	}

	public override void visit_map_literal (MapLiteral expr) {
		var key_ce = new CCodeCommaExpression ();
		var value_ce = new CCodeCommaExpression ();
		int length = expr.get_keys ().size;

		if (length == 0) {
			key_ce.append_expression (new CCodeConstant ("NULL"));
			value_ce.append_expression (new CCodeConstant ("NULL"));
		} else {
			var key_array_type = new ArrayType (expr.map_key_type, 1, expr.source_reference);
			key_array_type.inline_allocated = true;
			key_array_type.fixed_length = true;
			key_array_type.length = length;

			var key_temp_var = get_temp_variable (key_array_type, true, expr);
			var key_name_cnode = get_variable_cexpression (key_temp_var.name);

			emit_temp_var (key_temp_var);

			var value_array_type = new ArrayType (expr.map_value_type, 1, expr.source_reference);
			value_array_type.inline_allocated = true;
			value_array_type.fixed_length = true;
			value_array_type.length = length;

			var value_temp_var = get_temp_variable (value_array_type, true, expr);
			var value_name_cnode = get_variable_cexpression (value_temp_var.name);

			emit_temp_var (value_temp_var);

			for (int i = 0; i < length; i++) {
				key_ce.append_expression (new CCodeAssignment (new CCodeElementAccess (key_name_cnode, new CCodeConstant (i.to_string ())), resolve.get_cvalue (expr.get_keys ().get (i))));
				value_ce.append_expression (new CCodeAssignment (new CCodeElementAccess (value_name_cnode, new CCodeConstant (i.to_string ())), resolve.get_cvalue (expr.get_values ().get (i))));
			}

			key_ce.append_expression (key_name_cnode);
			value_ce.append_expression (value_name_cnode);
		}

		var map_creation = new CCodeFunctionCall (new CCodeIdentifier ("aroop_map_new"));
		map_creation.add_argument (get_type_id_expression (expr.map_key_type));
		map_creation.add_argument (get_type_id_expression (expr.map_value_type));
		map_creation.add_argument (new CCodeConstant (length.to_string ()));
		map_creation.add_argument (key_ce);
		map_creation.add_argument (value_ce);

		resolve.set_cvalue (expr, map_creation);
	}
#endif

	Value?visit_boolean_literal (Value?given) {
		BooleanLiteral?expr = (BooleanLiteral?)given;
		resolve.set_cvalue (expr, new CCodeConstant (expr.value ? "true" : "false"));
		return null;
	}
}

