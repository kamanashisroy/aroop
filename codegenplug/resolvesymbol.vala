using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.CSymbolResolve : shotodolplug.Module {
	SymbolResolve csres;
	public CSymbolResolve() {
		base("Object", "0.0");
	}

	public override int init() {
		PluginManager.register("visit/class", new HookExtension(visit_class, this));
	}

	public override int deinit() {
	}

}

