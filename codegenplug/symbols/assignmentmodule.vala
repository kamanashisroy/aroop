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

		bool unref_old = resolve.requires_destroy (assignment.left.value_type);

		if (unref_old) {
			/* unref old value */
			emitter.ccode.add_expression (resolve.get_unref_expression (lhs, assignment.left.value_type, assignment.left));
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

}
