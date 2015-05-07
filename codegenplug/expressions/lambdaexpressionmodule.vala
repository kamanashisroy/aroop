using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.LambdaExpressionModule : shotodolplug.Module {
	SourceEmitterModule emitter;
	CSymbolResolve resolve;
	public LambdaExpressionModule() {
		base("LambdaExpression", "0.0");
	}

	public override int init() {
		PluginManager.register("visit/lambda_expression", new HookExtension(visit_lambda_expression, this));
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

	Value?visit_lambda_expression (Value?given) {
		LambdaExpression?expr = (LambdaExpression?)given;
		expr.accept_children (emitter.visitor);
		resolve.set_cvalue (expr, new CCodeIdentifier (resolve.get_ccode_name (expr.method)));
		return null;
	}
}
