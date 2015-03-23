using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.CompilerModule : shotodolplug.Module {
	public class EmitContext {
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


}

