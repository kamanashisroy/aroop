using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.CompilerModule : shotodolplug.Module {
	public CCodeFile header_file;
	public CCodeFile cfile;
	public CompilerModule() {
		base("Compiler", "0.0");
	}

	public override int init() {
		//PluginManager.register("visit/compiler", new HookExtension(visit_struct, this));
	}

	public override int deinit() {
	}
}

