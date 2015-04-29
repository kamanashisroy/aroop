using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.AssignmentModule : shotodolplug.Module {
	SourceEmitterModule emitter;
	CSymbolResolve resolve;
	public AssignmentModule() {
		base("Assignment", "0.0");
	}

	public override int init() {
		PluginManager.register("visit/assignment", new HookExtension(visit_assignment, this));
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

	CCodeExpression? emit_simple_assignment (Assignment assignment) {
		CCodeExpression rhs = resolve.get_cvalue (assignment.right);
		CCodeExpression lhs = (CCodeExpression) resolve.get_ccodenode (assignment.left);

#if false
		var dtvar = assignment.left.value_type as DelegateType;
		if(dtvar != null) {
			var closure_exp = new CCodeFunctionCall(new CCodeIdentifier("aroop_assign_closure_of_delegate"));
			closure_exp.add_argument(lhs);
			closure_exp.add_argument(rhs);
			emitter.ccode.add_expression(closure_exp);
		}
#endif
		bool unref_old = resolve.requires_destroy (assignment.left.value_type);

		if (unref_old) {
#if false
			if (!is_pure_ccode_expression (lhs)) {
				/* Assign lhs to temp var to avoid repeating side effect */
				var lhs_value_type = assignment.left.value_type.copy ();
				string lhs_temp_name = "_tmp%d_".printf (next_temp_var_id++);
				var lhs_temp = new LocalVariable (lhs_value_type, "*" + lhs_temp_name);
				AroopCodeGeneratorAdapter.generate_temp_variable (lhs_temp);
				emitter.ccode.add_assignment (get_variable_cexpression (lhs_temp_name), new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, lhs));
				lhs = new CCodeParenthesizedExpression (new CCodeUnaryExpression (CCodeUnaryOperator.POINTER_INDIRECTION, resolve.get_variable_cexpression (lhs_temp_name)));
			}

			var temp_decl = emitter..get_temp_variable (assignment.left.value_type);
			AroopCodeGeneratorAdapter.generate_temp_variable (temp_decl);
			emitter.ccode.add_assignment (get_variable_cexpression (temp_decl.name), rhs);
			/* unref old value */
			emitter.ccode.add_expression (get_unref_expression (lhs, assignment.left.value_type, assignment.left));

			rhs = resolve.get_variable_cexpression (temp_decl.name);
#else
			/* unref old value */
			emitter.ccode.add_expression (resolve.get_unref_expression (lhs, assignment.left.value_type, assignment.left));
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

		emitter.ccode.add_expression (codenode);

		if (assignment.parent_node is ExpressionStatement) {
			return null;
		} else {
			return lhs;
		}
	}

	CCodeExpression? emit_fixed_length_array_assignment (Assignment assignment, ArrayType array_type) {
		CCodeExpression rhs = resolve.get_cvalue (assignment.right);
		CCodeExpression lhs = (CCodeExpression) resolve.get_ccodenode (assignment.left);

		// it is necessary to use memcpy for fixed-length (stack-allocated) arrays
		// simple assignments do not work in C
		var sizeof_call = new CCodeFunctionCall (new CCodeIdentifier ("sizeof"));
		sizeof_call.add_argument (new CCodeIdentifier (resolve.get_ccode_name (array_type.element_type)));
		var size = new CCodeBinaryExpression (CCodeBinaryOperator.MUL, /*new CCodeConstant ("%d".printf (array_type.length))*/resolve.get_cvalue(array_type.length), sizeof_call);
		var ccopy = new CCodeFunctionCall (new CCodeIdentifier ("memcpy"));
		ccopy.add_argument (lhs);
		ccopy.add_argument (rhs);
		ccopy.add_argument (size);

		emitter.ccode.add_expression (ccopy);

		if (assignment.parent_node is ExpressionStatement) {
			return null;
		} else {
			return lhs;
		}
	}

	Value? visit_assignment (Value?given) {
		Assignment?assignment = (Assignment?)given;
		if (assignment.left.error || assignment.right.error) {
			assignment.error = true;
			return null;
		}

		if (assignment.left.symbol_reference is Property) {
			var ma = assignment.left as MemberAccess;
			var prop = (Property) assignment.left.symbol_reference;

			AroopCodeGeneratorAdapter.store_property (prop, ma.inner, assignment.right.target_value);

			resolve.set_cvalue (assignment, resolve.get_ccodenode (assignment.right));
		} else {
			var array_type = assignment.left.value_type as ArrayType;
			if (array_type != null && array_type.fixed_length) {
				resolve.set_cvalue (assignment, emit_fixed_length_array_assignment (assignment, array_type));
			} else {
				resolve.set_cvalue (assignment, emit_simple_assignment (assignment));
			}
		}
		return null;
	}

#if false
	void store_variable (Variable variable, TargetValue lvalue, TargetValue value, bool initializer) {
		if (!initializer && requires_destroy (variable.variable_type)) {
			/* unref old value */
			ccode.add_expression (destroy_value (lvalue));
		}

		ccode.add_assignment (resolve.get_cvalue_ (lvalue), resolve.get_cvalue_ (value));
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

	void store_delegate (Variable variable, TargetValue? pinstance, Expression exp, bool initializer) {
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
