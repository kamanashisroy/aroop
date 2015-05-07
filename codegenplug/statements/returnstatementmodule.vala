using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.ReturnStatementModule : shotodolplug.Module {
	SourceEmitterModule emitter;
	CSymbolResolve resolve;
	public ReturnStatementModule() {
		base("ReturnStatementModule", "0.0");
	}

	public override int init() {
		PluginManager.register("visit/return_statement", new HookExtension(visit_return_statement, this));
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

	Value? visit_return_statement (Value?given) {
		ReturnStatement stmt = (ReturnStatement?)given;
		// free local variables
		CCodeExpression holder = new CCodeIdentifier ("result");

		var rexpr = stmt.return_expression;
		if(rexpr != null) {
			if(emitter.current_return_type is GenericType) {
				holder = new CCodeUnaryExpression (CCodeUnaryOperator.POINTER_INDIRECTION, new CCodeIdentifier ("result"));
			}
			print_debug("visit_return_statement creating assignment for %s ++++++++++++++++++\n".printf(stmt.to_string()));
			emitter.ccode.add_assignment (holder, resolve.get_cvalue(rexpr));
		}
		AroopCodeGeneratorAdapter.append_local_free (emitter.current_symbol);
		emitter.ccode.add_return ((emitter.current_return_type is VoidType || emitter.current_return_type is GenericType) ? null : holder);
		return null;
	}

}

