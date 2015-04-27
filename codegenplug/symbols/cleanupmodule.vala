using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.CleanUpModule : shotodolplug.Module {
	SourceEmitterModule emitter;
	CSymbolResolve resolve;
	public CleanUpModule() {
		base("CleanUp", "0.0");
	}

	public override int init() {
		PluginManager.register("append/cleanup/local", new HookExtension(append_local_free_helper, this));
		PluginManager.register("append/cleanup/parameter", new HookExtension(append_param_free_helper, this));
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

	Value? append_local_free_helper (Value?given_args) {
		var args = (HashTable<string,Value?>)given_args;
		append_local_free(
			(Symbol)args["sym"]
			,(((string?)args["stop_at_loop"]) == "1")
			,(CodeNode?)args["stop_at"]
		);
		return null;
	}

	void append_local_free (Symbol sym, bool stop_at_loop = false, CodeNode? stop_at = null) {
		var b = (Block) sym;

		var local_vars = b.get_local_variables ();
		// free in reverse order
		for (int i = local_vars.size - 1; i >= 0; i--) {
			var local = local_vars[i];
			if (local.active /*&& !local.floating*/ && !local.captured && resolve.requires_destroy (local.variable_type)) {
				var ma = new MemberAccess.simple (local.name);
				ma.symbol_reference = local;
				emitter.ccode.add_expression (resolve.get_unref_expression (resolve.get_variable_cexpression (local.name), local.variable_type, ma));
			}
		}

		if (b.captured) {
			AroopCodeGeneratorAdapter.generate_block_finalization(b, emitter.ccode);
		}

		if (stop_at_loop) {
			if (b.parent_node is Loop ||
			    b.parent_node is ForeachStatement ||
			    b.parent_node is SwitchStatement) {
				return;
			}
		}

		if (b.parent_node == stop_at) {
			return;
		}

		if (sym.parent_symbol is Block) {
			append_local_free (sym.parent_symbol, stop_at_loop, stop_at);
		} else if (sym.parent_symbol is Method) {
			append_param_free ((Method) sym.parent_symbol);
		}
	}

	Value? append_param_free_helper (Value?given_args) {
		append_local_free((Method?)given_args);
		return null;
	}


	void append_param_free (Method m) {
		foreach (Vala.Parameter param in m.get_parameters ()) {
			if (resolve.requires_destroy (param.variable_type) && param.direction == ParameterDirection.IN) {
				var ma = new MemberAccess.simple (param.name);
				ma.symbol_reference = param;
				emitter.ccode.add_expression (resolve.get_unref_expression (resolve.get_variable_cexpression (param.name), param.variable_type, ma));
			}
		}
	}
}
