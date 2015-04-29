using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.BaseAccessModule : shotodolplug.Module {
	SourceEmitterModule?emitter = null;
	CSymbolResolve?resolve = null;
	public BaseAccessModule() {
		base("BaseAccess", "0.0");
	}

	public override int init() {
		PluginManager.register("visit/base_access", new HookExtension(visit_base_access, this));
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


	Value? visit_base_access (Value?given) {
		BaseAccess?expr = (BaseAccess?)given;
		if(expr.value_type != null)
			AroopCodeGeneratorAdapter.generate_type_declaration (expr.value_type, emitter.cfile);
		//set_cvalue (expr, new CCodeCastExpression (new CCodeIdentifier (self_instance), get_ccode_aroop_name (expr.value_type)));
		var aroop_base_access = new CCodeFunctionCall (new CCodeIdentifier ("aroop_base_access"));
		aroop_base_access.add_argument (new CCodeConstant(resolve.get_ccode_aroop_name (expr.value_type)));
		aroop_base_access.add_argument (new CCodeIdentifier (resolve.self_instance));
		resolve.set_cvalue (expr, aroop_base_access);
		return null;
	}
}
