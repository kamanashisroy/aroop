using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.StringModule : shotodolplug.Module {
	SourceEmitterModule emitter;
	CSymbolResolve resolve;
	public StringModule() {
		base("String", "0.0");
	}

	public override int init() {
		PluginManager.register("visit/string_literal", new HookExtension(visit_string_literal, this));
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
	Value? visit_string_literal(Value?given_args) {
		StringLiteral?expr = (StringLiteral?)given_args;
	//public override void visit_string_literal (StringLiteral expr) {
		// FIXME handle escaped characters in scanner/parser and escape them here again for C
#if no_string_t
		var cliteral = new CCodeConstant ("\"\\0\" " + expr.value);

		var cbinary = new CCodeBinaryExpression (CCodeBinaryOperator.PLUS, cliteral, new CCodeConstant ("1"));
		set_cvalue (expr, new CCodeCastExpression (cbinary, "string_t"));
#else
		resolve.set_cvalue (expr, new CCodeConstant(expr.value));
#endif
		return null;
	}
}


