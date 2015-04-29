using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.PostfixExpressionModule : shotodolplug.Module {
	SourceEmitterModule emitter;
	CSymbolResolve resolve;
	public PostfixExpressionModule() {
		base("PostfixExpression", "0.0");
	}

	public override int init() {
		PluginManager.register("visit/postfix_expression", new HookExtension(visit_postfix_expression, this));
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

	Value?visit_postfix_expression (Value?given) {
		PostfixExpression?expr = (PostfixExpression?)given;
		MemberAccess ma = find_property_access (expr.inner);
		if (ma != null) {
			// property postfix expression
			var prop = (Property) ma.symbol_reference;

			// assign current value to temp variable
			var temp_decl = emitter.get_temp_variable (prop.property_type, true, expr);
			AroopCodeGeneratorAdapter.generate_temp_variable (temp_decl);
			emitter.ccode.add_assignment (resolve.get_variable_cexpression (temp_decl.name), resolve.get_cvalue (expr.inner));

			// increment/decrement property
			var op = expr.increment ? CCodeBinaryOperator.PLUS : CCodeBinaryOperator.MINUS;
			var cexpr = new CCodeBinaryExpression (op, resolve.get_variable_cexpression (temp_decl.name), new CCodeConstant ("1"));
			AroopCodeGeneratorAdapter.store_property (prop, ma.inner, new AroopValue (expr.value_type, cexpr));

			// return previous value
			resolve.set_cvalue (expr, new CCodeIdentifier (temp_decl.name));
			return null;
		}

		var op = expr.increment ? CCodeUnaryOperator.POSTFIX_INCREMENT : CCodeUnaryOperator.POSTFIX_DECREMENT;

		resolve.set_cvalue (expr, new CCodeUnaryExpression (op, resolve.get_cvalue (expr.inner)));
		return null;
	}
	MemberAccess? find_property_access (Expression expr) {
		if (!(expr is MemberAccess)) {
			return null;
		}

		var ma = (MemberAccess) expr;
		if (ma.symbol_reference is Property) {
			return ma;
		}

		return null;
	}

}
