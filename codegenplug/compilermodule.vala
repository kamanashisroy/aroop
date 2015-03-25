using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.CompilerModule : shotodolplug.Module {

	
	public EmitContext emit_context = new EmitContext ();
	public Symbol current_symbol { get { return emit_context.current_symbol; } }
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

	public void push_context (EmitContext emit_context) {
		/*
		if (this.emit_context != null) {
			emit_context_stack.add (this.emit_context);
		}

		this.emit_context = emit_context;*/
	}

	public void pop_context () {
		/*if (emit_context_stack.size > 0) {
			this.emit_context = emit_context_stack[emit_context_stack.size - 1];
			emit_context_stack.remove_at (emit_context_stack.size - 1);
		} else {
			this.emit_context = null;
		}*/
	}

	public void push_function (CCodeFunction func) {
		/*emit_context.ccode_stack.add (ccode);
		emit_context.ccode = func;*/
	}

	public void pop_function () {
		/*emit_context.ccode = emit_context.ccode_stack[emit_context.ccode_stack.size - 1];
		emit_context.ccode_stack.remove_at (emit_context.ccode_stack.size - 1);*/
	}

	public bool add_symbol_declaration (CCodeFile decl_space, Symbol sym, string name) {
#if false
		if (decl_space.add_declaration (name)) {
			return true;
		}
		/*print("%s(%s) Something may happen(%s)\n"
			, name
			, sym.external_package?"External":"Internal"
			, decl_space.is_header?"Headerfile":"C file");*/
		if (sym.external_package || (!decl_space.is_header && CodeContext.get ().use_header && !sym.is_internal_symbol ())) {
			// add appropriate include file
			foreach (string header_filename in CCodeBaseModule.get_ccode_header_filenames (sym).split (",")) {
				/*print("%s is being added for symbol %s in %s\n"
					, header_filename
					, name
					, decl_space.is_header?"Headerfile":"C file");*/
				//decl_space.add_include (header_filename, !sym.external_package);
				decl_space.add_include (header_filename, !sym.external_package ||
				                                         (sym.external_package &&
				                                          sym.from_commandline));
			}
			// declaration complete
			return true;
		} else {
			// require declaration
			return false;
		}
#else
		return false;
#endif
	}
}
public class codegenplug.EmitContext {
	public Symbol? current_symbol;
	public ArrayList<Symbol> symbol_stack = new ArrayList<Symbol> ();
	public TryStatement current_try;
	public CatchClause current_catch;
	public CCodeFunction ccode;
	public ArrayList<CCodeFunction> ccode_stack = new ArrayList<CCodeFunction> ();
	public ArrayList<LocalVariable> temp_ref_vars = new ArrayList<LocalVariable> ();
	public int next_temp_var_id;
	public Map<string,string> variable_name_map = new HashMap<string,string> (str_hash, str_equal);
	public bool current_method_inner_error;
	
	public EmitContext (Symbol? symbol = null) {
		current_symbol = symbol;
	}

	public void push_symbol (Symbol symbol) {
		symbol_stack.add (current_symbol);
		current_symbol = symbol;
	}

	public void pop_symbol () {
		current_symbol = symbol_stack[symbol_stack.size - 1];
		symbol_stack.remove_at (symbol_stack.size - 1);
	}
}
