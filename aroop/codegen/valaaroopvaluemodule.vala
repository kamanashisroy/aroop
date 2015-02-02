/* valaaroopvaluemodule.vala
 *
 * Copyright (C) 2009-2011  Jürg Billeter
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Jürg Billeter <j@bitron.ch>
 */

using Vala;

public class aroop.AroopValueModule : AroopObjectModule {
	public override void visit_creation_method (CreationMethod m) {
		if (current_type_symbol is Class &&
		    (current_class.base_class == null ||
		     current_class.base_class.get_full_name () != "Aroop.Value")) {
			base.visit_creation_method (m);
			return;
		}

		visit_method (m);
	}

	public override void generate_struct_declaration (Struct st, CCodeFile decl_space) {
		base.generate_struct_declaration (st, decl_space);

		if (add_symbol_declaration (decl_space, st, get_ccode_copy_function (st))) {
			return;
		}

		generate_class_declaration (type_class, decl_space);

#if false
		var func_macro = new CCodeMacroReplacement("%s(dst,dst_index,src,src_index)".printf(get_ccode_copy_function(st)), "({aroop_struct_cpy_or_destroy(dst,src,%s);})".printf(CCodeBaseModule.get_ccode_destroy_function(st)));
		decl_space.add_type_declaration (func_macro);
#endif

	}

	public override void visit_struct (Struct st) {
		base.visit_struct (st);
	}

#if false
	public override void visit_assignment (Assignment assignment) {
		base.visit_assignment (assignment);
		return;
	}
#endif

	public override void store_variable (Variable variable, TargetValue lvalue, TargetValue value, bool initializer) {
		var generic_type = (lvalue.value_type as GenericType);
		if (generic_type == null) {
			base.store_variable (variable, lvalue, value, initializer);
			return;
		}

		var ccall = new CCodeFunctionCall (new CCodeIdentifier ("aroop_type_value_copy"));
		if (generic_type.type_parameter.parent_symbol is TypeSymbol) {
			// generic type
			ccall.add_argument (new CCodeMemberAccess.pointer (new CCodeIdentifier (self_instance), get_generic_class_variable_cname()));
		} else {
			// generic method
			ccall.add_argument (new CCodeIdentifier ("%s_type".printf (generic_type.type_parameter.name.down ())));
		}
		ccall.add_argument (get_cvalue_ (lvalue));
		ccall.add_argument (new CCodeConstant ("0"));
		ccall.add_argument (get_cvalue_ (value));
		ccall.add_argument (new CCodeConstant ("0"));

		ccode.add_expression (ccall);
	}

	public override void visit_binary_expression (BinaryExpression expr) {
		var generic_type = expr.left.value_type as GenericType;
		if (generic_type == null) {
			base.visit_binary_expression (expr);
			return;
		}

		CCodeExpression cleft;
		CCodeExpression left_index = new CCodeConstant ("0");
		CCodeExpression cright;
		CCodeExpression right_index = new CCodeConstant ("0");

		var left_ea = expr.left as ElementAccess;
		var right_ea = expr.right as ElementAccess;

		if (left_ea != null) {
			cleft = new CCodeMemberAccess ((CCodeExpression) get_ccodenode (left_ea.container), "data");
			left_index = (CCodeExpression) get_ccodenode (left_ea.get_indices ().get (0));
		} else {
			cleft = (CCodeExpression) get_ccodenode (expr.left);
		}

		if (right_ea != null) {
			cright = new CCodeMemberAccess ((CCodeExpression) get_ccodenode (right_ea.container), "data");
			right_index = (CCodeExpression) get_ccodenode (right_ea.get_indices ().get (0));
		} else {
			cright = (CCodeExpression) get_ccodenode (expr.right);
		}

		var ccall = new CCodeFunctionCall (new CCodeIdentifier ("aroop_type_value_equals"));
		ccall.add_argument (get_type_id_expression (generic_type));
		ccall.add_argument (cleft);
		ccall.add_argument (left_index);
		ccall.add_argument (cright);
		ccall.add_argument (right_index);

		if (expr.operator == BinaryOperator.EQUALITY) {
			set_cvalue (expr, ccall);
		} else {
			set_cvalue (expr, new CCodeUnaryExpression (CCodeUnaryOperator.LOGICAL_NEGATION, ccall));
		}
	}

	public override void visit_method_call (MethodCall expr) {
		var ma = expr.call as MemberAccess;
		if (ma == null || ma.inner == null || !(ma.inner.value_type is GenericType)) {
			base.visit_method_call (expr);
			return;
		}

		// handle method calls on generic types

		expr.accept_children (this);

		if (ma.member_name == "hash") {
			var val = ma.inner;
			CCodeExpression cval;
			CCodeExpression val_index = new CCodeConstant ("0");

			var val_ea = val as ElementAccess;
			if (val_ea != null) {
				val = val_ea.container;

				cval = new CCodeMemberAccess ((CCodeExpression) get_ccodenode (val), "data");
				val_index = (CCodeExpression) get_ccodenode (val_ea.get_indices ().get (0));
			} else {
				cval = (CCodeExpression) get_ccodenode (val);
			}

			var ccall = new CCodeFunctionCall (new CCodeIdentifier ("aroop_type_value_hash"));
			ccall.add_argument (get_type_id_expression (ma.inner.value_type));
			ccall.add_argument (cval);
			ccall.add_argument (val_index);

			set_cvalue (expr, ccall);
		}
	}

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
				ccode.add_assignment (new CCodeElementAccess (name_cnode, new CCodeConstant (i.to_string ())), get_cvalue (e));
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

		set_cvalue (expr, list_creation);
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
				ce.append_expression (new CCodeAssignment (new CCodeElementAccess (name_cnode, new CCodeConstant (i.to_string ())), get_cvalue (e)));
				i++;
			}

			ce.append_expression (name_cnode);
		}

		var set_creation = new CCodeFunctionCall (new CCodeIdentifier ("aroop_set_new"));
		set_creation.add_argument (get_type_id_expression (expr.element_type));
		set_creation.add_argument (new CCodeConstant (length.to_string ()));
		set_creation.add_argument (ce);

		set_cvalue (expr, set_creation);
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
				key_ce.append_expression (new CCodeAssignment (new CCodeElementAccess (key_name_cnode, new CCodeConstant (i.to_string ())), get_cvalue (expr.get_keys ().get (i))));
				value_ce.append_expression (new CCodeAssignment (new CCodeElementAccess (value_name_cnode, new CCodeConstant (i.to_string ())), get_cvalue (expr.get_values ().get (i))));
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

		set_cvalue (expr, map_creation);
	}

	public override void visit_tuple (Tuple tuple) {
		var type_array_type = new ArrayType (new PointerType (new VoidType ()), 1, tuple.source_reference);
		type_array_type.inline_allocated = true;
		type_array_type.fixed_length = true;
		type_array_type.length = tuple.get_expressions ().size;

		var type_temp_var = get_temp_variable (type_array_type, true, tuple);
		var type_name_cnode = get_variable_cexpression (type_temp_var.name);
		emit_temp_var (type_temp_var);

		var array_type = new ArrayType (new PointerType (new VoidType ()), 1, tuple.source_reference);
		array_type.inline_allocated = true;
		array_type.fixed_length = true;
		array_type.length = tuple.get_expressions ().size;

		var temp_var = get_temp_variable (array_type, true, tuple);
		var name_cnode = get_variable_cexpression (temp_var.name);
		emit_temp_var (temp_var);

		var type_ce = new CCodeCommaExpression ();
		var ce = new CCodeCommaExpression ();

		int i = 0;
		foreach (Expression e in tuple.get_expressions ()) {
			var element_type = tuple.value_type.get_type_arguments ().get (i);

			type_ce.append_expression (new CCodeAssignment (new CCodeElementAccess (type_name_cnode, new CCodeConstant (i.to_string ())), get_type_id_expression (element_type)));

			var cexpr = get_cvalue (e);

			var unary = cexpr as CCodeUnaryExpression;
			if (unary != null && unary.operator == CCodeUnaryOperator.POINTER_INDIRECTION) {
				// *expr => expr
				cexpr = unary.inner;
			} else if (cexpr is CCodeIdentifier || cexpr is CCodeMemberAccess) {
				cexpr = new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, cexpr);
			} else {
				// if cexpr is e.g. a function call, we can't take the address of the expression
				// tmp = expr, &tmp

				var element_temp_var = get_temp_variable (element_type);
				emit_temp_var (element_temp_var);
				ce.append_expression (new CCodeAssignment (get_variable_cexpression (element_temp_var.name), cexpr));
				cexpr = new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, new CCodeIdentifier (element_temp_var.name));
			}

			ce.append_expression (new CCodeAssignment (new CCodeElementAccess (name_cnode, new CCodeConstant (i.to_string ())), cexpr));

			i++;
		}

		type_ce.append_expression (type_name_cnode);
		ce.append_expression (name_cnode);

		var tuple_creation = new CCodeFunctionCall (new CCodeIdentifier ("aroop_tuple_new"));
		tuple_creation.add_argument (new CCodeConstant (tuple.get_expressions ().size.to_string ()));
		tuple_creation.add_argument (type_ce);
		tuple_creation.add_argument (ce);

		set_cvalue (tuple, tuple_creation);
	}
}
