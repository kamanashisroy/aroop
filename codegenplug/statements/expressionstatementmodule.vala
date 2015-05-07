using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.ExpressionStatementModule : shotodolplug.Module {
	SourceEmitterModule emitter;
	CSymbolResolve resolve;
	public ExpressionStatementModule() {
		base("ExpressionStatement", "0.0");
	}

	public override int init() {
		PluginManager.register("visit/expression_statement", new HookExtension(visit_expression_statement, this));
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

	Value? visit_expression_statement (Value?given) {
		ExpressionStatement?stmt = (ExpressionStatement?)given;
		if (stmt.expression.error) {
			stmt.error = true;
			return null;
		}

		print_debug("expression_statement generating code for %s\n".printf(stmt.to_string()));
		if (resolve.get_cvalue (stmt.expression) != null) {
			emitter.ccode.add_expression (resolve.get_cvalue (stmt.expression));
		}
		/* free temporary objects and handle errors */

		foreach (LocalVariable local in emitter.emit_context.temp_ref_vars) {
			var ma = new MemberAccess.simple (local.name);
			ma.symbol_reference = local;
			ma.value_type = local.variable_type.copy ();
			emitter.ccode.add_expression (resolve.get_unref_expression (resolve.get_variable_cexpression (local.name), local.variable_type, ma));
		}

		if (stmt.tree_can_fail && stmt.expression.tree_can_fail) {
			// simple case, no node breakdown necessary
			AroopCodeGeneratorAdapter.add_simple_check (stmt.expression);
		}

		emitter.emit_context.temp_ref_vars.clear ();
		return null;
	}
}

