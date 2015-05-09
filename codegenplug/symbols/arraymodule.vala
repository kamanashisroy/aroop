using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.ArrayModule : shotodolplug.Module {
	CSymbolResolve resolve;
	SourceEmitterModule emitter;
	public ArrayModule() {
		base("Array", "0.0");
	}

	public override int init() {
		PluginManager.register("visit/array_creation_expression", new HookExtension(visit_array_creation_expression, this));
		PluginManager.register("visit/slice_expression", new HookExtension(visit_slice_expression, this));
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

	Value?visit_array_creation_expression (Value?given) {
		ArrayCreationExpression?expr = (ArrayCreationExpression?)given;
		print_debug("Creating array here ------------********* for %s \n".printf(expr.to_string()));
		var array_type = expr.target_type as ArrayType;
		if (array_type != null && array_type.fixed_length) {
			// no heap allocation for fixed-length arrays

#if false
			var temp_var = get_temp_variable (array_type, true, expr);
			var name_cnode = new CCodeIdentifier (temp_var.name);
			int i = 0;

			emit_temp_var (temp_var);

			append_initializer_list (name_cnode, expr.initializer_list, ref i);

			resolve.set_cvalue (expr, name_cnode);
#else
			var array_new = new CCodeFunctionCall (new CCodeIdentifier ("aroop_fixedlen_array_create"));
			array_new.add_argument (new CCodeIdentifier(resolve.get_ccode_name (array_type.element_type)));
			int i = 0;
			foreach (Expression e in expr.initializer_list.get_initializers ()) {
				array_new.add_argument (resolve.get_cvalue (e));
				i++;
			}
			resolve.set_cvalue (expr, array_new);
#endif

			return null;
		}

		AroopCodeGeneratorAdapter.generate_method_declaration ((Method) emitter.array_struct.scope.lookup ("create"), emitter.cfile);

		var array_new = new CCodeFunctionCall (new CCodeIdentifier ("aroop_array_create"));
		array_new.add_argument (resolve.get_type_id_expression (expr.element_type));

		// length of new array
		array_new.add_argument (resolve.get_cvalue (expr.get_sizes ().get (0)));

		var temp_var = emitter.get_temp_variable (expr.value_type, true, expr);
		var name_cnode = resolve.get_variable_cexpression (temp_var.name);

		AroopCodeGeneratorAdapter.generate_temp_variable(temp_var);

		emitter.ccode.add_assignment (name_cnode, array_new);

		resolve.set_cvalue (expr, name_cnode);
		return null;
	}

	Value?visit_slice_expression (Value?given) {
		SliceExpression?expr = (SliceExpression?)given;
		var ccontainer = resolve.get_cvalue (expr.container);
		var cstart = resolve.get_cvalue (expr.start);
		var cstop = resolve.get_cvalue (expr.stop);

		var array_type = (ArrayType) expr.container.value_type;

		var array = new CCodeFunctionCall (new CCodeIdentifier ("aroop_array"));
		array.add_argument (new CCodeBinaryExpression (CCodeBinaryOperator.PLUS, new CCodeCastExpression (new CCodeMemberAccess (ccontainer, "data"), resolve.get_ccode_name (array_type.element_type) + "*"), cstart));
		array.add_argument (new CCodeBinaryExpression (CCodeBinaryOperator.MINUS, cstop, cstart));

		resolve.set_cvalue (expr, array);
		return null;
	}
}

