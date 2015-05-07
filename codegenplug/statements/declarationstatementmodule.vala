using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.DeclarationStatementModule : shotodolplug.Module {
	SourceEmitterModule emitter;
	CSymbolResolve resolve;
	public DeclarationStatementModule() {
		base("DeclarationStatement", "0.0");
	}

	public override int init() {
		PluginManager.register("visit/declaration_statement", new HookExtension(visit_declaration_statement, this));
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

	Value? visit_declaration_statement (Value?given) {
		DeclarationStatement?stmt = (DeclarationStatement?)given;
		var local = stmt.declaration as LocalVariable;
		if (local == null) {
			local = new LocalVariable(new PointerType(new VoidType()), "_AROOP_NO_DECLARATION_VARIABLE_");
		}
		emitter.push_declaration_variable(local);
		print_debug("Emitting declaration statement %s\n".printf(stmt.to_string()));
		stmt.declaration.accept (emitter.visitor);
		print_debug("Done declaration statement %s\n".printf(stmt.to_string()));
		emitter.pop_declaration_variable();
		return null;
	}
}

