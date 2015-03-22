using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.CSymbolResolve : shotodolplug.Module {
	public TypeSymbol? current_type_symbol {
		get {
			var sym = current_symbol;
			while (sym != null) {
				if (sym is TypeSymbol) {
					return (TypeSymbol) sym;
				}
				sym = sym.parent_symbol;
			}
			return null;
		}
	}
	public Class? current_class {
		get { return current_type_symbol as Class; }
	}

	public string self_instance = "self_data";
	public CSymbolResolve() {
		base("C Symbol Resolver", "0.0");
	}

	public override int init() {
		PluginManager.register("c/symbol", new AnyInterfaceExtension(this, this));
	}

	public override int deinit() {
	}

	public string get_ccode_aroop_name(CodeNode node) {
		// TODO fill me
	}

	public string get_ccode_name(CodeNode node) {
		// TODO fill me
	}

	public string get_ccode_copy_function(CodeNode node) {
		// TODO fill me
	}

	public string get_ccode_dup_function(CodeNode node) {
		// TODO fill me
	}

	public string get_ccode_ref_function(CodeNode node) {
		// TODO fill me
	}

	public string get_ccode_free_function(CodeNode node) {
		// TODO fill me
	}

	public string get_ccode_lower_case_prefix(CodeNode node) {
		// TODO fill me
	}

	public string get_ccode_real_name(CodeNode node) {
		// TODO fill me
	}

	public string get_ccode_vfunc_name(CodeNode node) {
		// TODO fill me
	}
}

