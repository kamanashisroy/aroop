using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.ControlFlowModule : shotodolplug.Module {
	SourceEmitterModule emitter;
	CSymbolResolve resolve;
	public ControlFlowModule() {
		base("ControlFlow", "0.0");
	}

	public override int init() {
		PluginManager.register("visit/if_statement", new HookExtension(visit_if_statement, this));
		PluginManager.register("visit/switch_statement", new HookExtension(visit_switch_statement, this));
		PluginManager.register("visit/switch_label", new HookExtension(visit_switch_label, this));
		PluginManager.register("visit/loop", new HookExtension(visit_loop, this));
		PluginManager.register("visit/break_statement", new HookExtension(visit_break_statement, this));
		PluginManager.register("visit/continue_statement", new HookExtension(visit_continue_statement, this));
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

	Value? visit_if_statement (Value?given_args) {
		IfStatement stmt = (IfStatement?)given_args;
		emitter.ccode.open_if (resolve.get_cvalue (stmt.condition));

		stmt.true_statement.emit (emitter.visitor);

		if (stmt.false_statement != null) {
			emitter.ccode.add_else ();
			stmt.false_statement.emit (emitter.visitor);
		}

		emitter.ccode.close ();
		return null;
	}

	Value? visit_switch_statement (Value?given_args) {
		SwitchStatement stmt = (SwitchStatement?)given_args;
		emitter.ccode.open_switch (resolve.get_cvalue (stmt.expression));

		foreach (SwitchSection section in stmt.get_sections ()) {
			if (section.has_default_label ()) {
				emitter.ccode.add_default ();
			}
			section.emit (emitter.visitor);
		}

		emitter.ccode.close ();
		return null;
	}

	Value? visit_switch_label (Value?given_args) {
		SwitchLabel label = (SwitchLabel?)given_args;
		if (label.expression != null) {
			label.expression.emit (emitter.visitor);
			emitter.visitor.visit_end_full_expression (label.expression);
			emitter.ccode.add_case (resolve.get_cvalue (label.expression));
		}
		return null;
	}

	Value? visit_loop (Value?given_args) {
		Loop stmt = (Loop?)given_args;
		emitter.ccode.open_while (new CCodeConstant ("true"));
		stmt.body.emit (emitter.visitor);
		emitter.ccode.close ();
		return null;
	}

	Value? visit_break_statement (Value?given_args) {
		BreakStatement?stmt = (BreakStatement?)given_args;
		AroopCodeGeneratorAdapter.append_local_free (emitter.current_symbol, true);
		emitter.ccode.add_break ();
		return null;
	}

	Value? visit_continue_statement (Value?given_args) {
		ContinueStatement stmt = (ContinueStatement?)given_args;
		AroopCodeGeneratorAdapter.append_local_free (emitter.current_symbol, true);
		emitter.ccode.add_continue ();
		return null;
	}
}

