/* valaaroopassignmentmodule.vala
 *
 * Copyright (C) 2006-2011  Jürg Billeter
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
/**
 * The link between an assignment and generated code.
 */
public class aroop.AroopAssignmentModule : AroopMemberAccessModule {
	CCodeExpression? emit_simple_assignment (Assignment assignment) {
		CCodeExpression rhs = get_cvalue (assignment.right);
		CCodeExpression lhs = (CCodeExpression) get_ccodenode (assignment.left);

#if false
		var dtvar = assignment.left.value_type as DelegateType;
		if(dtvar != null) {
			var closure_exp = new CCodeFunctionCall(new CCodeIdentifier("aroop_assign_closure_of_delegate"));
			closure_exp.add_argument(lhs);
			closure_exp.add_argument(rhs);
			ccode.add_expression(closure_exp);
		}
#endif
		bool unref_old = requires_destroy (assignment.left.value_type);

		if (unref_old) {
#if false
			if (!is_pure_ccode_expression (lhs)) {
				/* Assign lhs to temp var to avoid repeating side effect */
				var lhs_value_type = assignment.left.value_type.copy ();
				string lhs_temp_name = "_tmp%d_".printf (next_temp_var_id++);
				var lhs_temp = new LocalVariable (lhs_value_type, "*" + lhs_temp_name);
				emit_temp_var (lhs_temp);
				ccode.add_assignment (get_variable_cexpression (lhs_temp_name), new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, lhs));
				lhs = new CCodeParenthesizedExpression (new CCodeUnaryExpression (CCodeUnaryOperator.POINTER_INDIRECTION, get_variable_cexpression (lhs_temp_name)));
			}

			var temp_decl = get_temp_variable (assignment.left.value_type);
			emit_temp_var (temp_decl);
			ccode.add_assignment (get_variable_cexpression (temp_decl.name), rhs);
			/* unref old value */
			ccode.add_expression (get_unref_expression (lhs, assignment.left.value_type, assignment.left));

			rhs = get_variable_cexpression (temp_decl.name);
#else
			/* unref old value */
			ccode.add_expression (get_unref_expression (lhs, assignment.left.value_type, assignment.left));
#endif
		}
	
		var cop = CCodeAssignmentOperator.SIMPLE;
		if (assignment.operator == AssignmentOperator.BITWISE_OR) {
			cop = CCodeAssignmentOperator.BITWISE_OR;
		} else if (assignment.operator == AssignmentOperator.BITWISE_AND) {
			cop = CCodeAssignmentOperator.BITWISE_AND;
		} else if (assignment.operator == AssignmentOperator.BITWISE_XOR) {
			cop = CCodeAssignmentOperator.BITWISE_XOR;
		} else if (assignment.operator == AssignmentOperator.ADD) {
			cop = CCodeAssignmentOperator.ADD;
		} else if (assignment.operator == AssignmentOperator.SUB) {
			cop = CCodeAssignmentOperator.SUB;
		} else if (assignment.operator == AssignmentOperator.MUL) {
			cop = CCodeAssignmentOperator.MUL;
		} else if (assignment.operator == AssignmentOperator.DIV) {
			cop = CCodeAssignmentOperator.DIV;
		} else if (assignment.operator == AssignmentOperator.PERCENT) {
			cop = CCodeAssignmentOperator.PERCENT;
		} else if (assignment.operator == AssignmentOperator.SHIFT_LEFT) {
			cop = CCodeAssignmentOperator.SHIFT_LEFT;
		} else if (assignment.operator == AssignmentOperator.SHIFT_RIGHT) {
			cop = CCodeAssignmentOperator.SHIFT_RIGHT;
		}

		CCodeExpression codenode = new CCodeAssignment (lhs, rhs, cop);

		ccode.add_expression (codenode);

		if (assignment.parent_node is ExpressionStatement) {
			return null;
		} else {
			return lhs;
		}
	}

	CCodeExpression? emit_fixed_length_array_assignment (Assignment assignment, ArrayType array_type) {
		CCodeExpression rhs = get_cvalue (assignment.right);
		CCodeExpression lhs = (CCodeExpression) get_ccodenode (assignment.left);

		// it is necessary to use memcpy for fixed-length (stack-allocated) arrays
		// simple assignments do not work in C
		var sizeof_call = new CCodeFunctionCall (new CCodeIdentifier ("sizeof"));
		sizeof_call.add_argument (new CCodeIdentifier (get_ccode_name (array_type.element_type)));
		var size = new CCodeBinaryExpression (CCodeBinaryOperator.MUL, /*new CCodeConstant ("%d".printf (array_type.length))*/get_cvalue(array_type.length), sizeof_call);
		var ccopy = new CCodeFunctionCall (new CCodeIdentifier ("memcpy"));
		ccopy.add_argument (lhs);
		ccopy.add_argument (rhs);
		ccopy.add_argument (size);

		ccode.add_expression (ccopy);

		if (assignment.parent_node is ExpressionStatement) {
			return null;
		} else {
			return lhs;
		}
	}

	public override void visit_assignment (Assignment assignment) {
		if (assignment.left.error || assignment.right.error) {
			assignment.error = true;
			return;
		}

		if (assignment.left.symbol_reference is Property) {
			var ma = assignment.left as MemberAccess;
			var prop = (Property) assignment.left.symbol_reference;

			store_property (prop, ma.inner, assignment.right.target_value);

			set_cvalue (assignment, get_ccodenode (assignment.right));
		} else {
			var array_type = assignment.left.value_type as ArrayType;
			if (array_type != null && array_type.fixed_length) {
				set_cvalue (assignment, emit_fixed_length_array_assignment (assignment, array_type));
			} else {
				set_cvalue (assignment, emit_simple_assignment (assignment));
			}
		}
	}

	public virtual void store_variable (Variable variable, TargetValue lvalue, TargetValue value, bool initializer) {
		if (!initializer && requires_destroy (variable.variable_type)) {
			/* unref old value */
			ccode.add_expression (destroy_value (lvalue));
		}

		ccode.add_assignment (get_cvalue_ (lvalue), get_cvalue_ (value));
#if false
		var dtvar = lvalue.value_type as DelegateType;
		if(dtvar != null) {
			var closure_exp = new CCodeFunctionCall(new CCodeIdentifier("aroop_assign_closure_of_delegate"));
			closure_exp.add_argument(get_cvalue_ (lvalue));
			//if(value.value_type is MethodType) {
				//closure_exp.add_argument(new CCodeConstant("NULL"));
			//} else {
				closure_exp.add_argument(get_cvalue_ (value));
			//}
			ccode.add_expression(closure_exp);
		}
#endif
	}

	public override void store_local (LocalVariable local, TargetValue value, bool initializer) {
		store_variable (local, get_local_cvalue (local), value, initializer);
	}

	public override void store_parameter (Vala.Parameter param, TargetValue value, bool capturing_parameter = false) {
		store_variable (param, get_parameter_cvalue (param), value, false);
	}

	public override void store_field (Field field, TargetValue? instance, TargetValue value) {
		store_variable (field, get_field_cvalue (field, instance), value, false);
	}
#if false
	public virtual void store_delegate (Variable variable, TargetValue? pinstance, Expression exp, bool initializer) {
		if(variable is LocalVariable) {
			store_local((LocalVariable)variable, exp.target_value, initializer);
		} else if(variable is Field) {
			store_field((Field)variable, pinstance, exp.target_value);
		} else {
			assert("I do not know this!" == null);
			//store_variable(variable, lvalue, value, initializer);
		}
	}
#endif
}
