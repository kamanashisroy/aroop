using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.SourceEmitterModule : shotodolplug.Module {

	public EmitContext emit_context = new EmitContext ();
	public CCodeFunction ccode { get { return emit_context.ccode; } }
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
	public DataType? current_return_type {
		get {
			var m = current_method;
			if (m != null) {
				return m.return_type;
			}

			var acc = (PropertyAccessor)PluginManager.swarmValue("current/property_accessor", null);
			if (acc != null) {
				if (acc.readable) {
					return acc.value_type;
				} else {
					return void_type;
				}
			}

			return null;
		}
	}
	public Method? current_method {
		get {
			var sym = current_symbol;
			while (sym is Block) {
				sym = sym.parent_symbol;
			}
			return sym as Method;
		}
	}


	public Class? current_class {
		get { return current_type_symbol as Class; }
	}

	public Block? current_closure_block {
		get {
			return next_closure_block (current_symbol);
		}
	}
	public PropertyAccessor? current_property_accessor {
		get {
			var sym = current_symbol;
			while (sym is Block) {
				sym = sym.parent_symbol;
			}
			return sym as PropertyAccessor;
		}
	}


	public bool current_method_inner_error;
	public int next_temp_var_id;
	int next_block_id = 0;
	Map<Block,int> block_map = new HashMap<Block,int> ();

	public unowned Block? next_closure_block (Symbol sym) {
		unowned Block block = null;
		while (true) {
			block = sym as Block;
			if (!(sym is Block || sym is Method)) {
				// no closure block
				break;
			}
			if (block != null && block.captured) {
				// closure block found
				break;
			}
			sym = sym.parent_symbol;
		}
		return block;
	}

	public int get_block_id (Block b) {
		int result = block_map[b];
		if (result == 0) {
			result = ++next_block_id;
			block_map[b] = result;
		}
		return result;
	}


	public CCodeFile header_file;
	public CCodeFile cfile;
	public SourceEmitterModule() {
		base("Source", "0.0");
		
	}

	public override int init() {
		PluginManager.register("source/emitter", new HookExtension(getInstance, this));
		PluginManager.register("source/emit", new HookExtension(emitHook, this));
		PluginManager.register("set/csource_filename", new HookExtension(set_csource_filename, this));
		return 0;
	}

	public override int deinit() {
		return 0;
	}

	Value? getInstance(Value?param) {
		return this;
	}
	string? csource_filename;
	Value? set_csource_filename(Value?param) {
		csource_filename = (string?)param;
		return null;
	}

	Symbol root_symbol;
	DataType void_type = new VoidType ();
	DataType bool_type;
	DataType char_type;
	DataType int_type;
	DataType uint_type;
	DataType string_type;
	//public Class object_class;
	public Interface object_class;
	//public Class type_class;
	public Struct type_class;
	Struct value_class;
	Class string_class;
	public Struct array_struct;
	Class delegate_class;
	Class error_class;
	public CodeContext context { get; set; }
	public CodeGenerator?visitor = null;


	Set<Symbol> generated_external_symbols;

	Value?emitHook (Value?inmsg) {
		var args = (HashTable<string,Value?>)inmsg;
		this.context = (CodeContext)args["context"];
		PluginManager.swarmValue("set/context", context);
		visitor = (CodeGenerator)args["visitor"];

		root_symbol = context.root;

		bool_type = new BooleanType ((Struct) root_symbol.scope.lookup ("bool"));
		char_type = new IntegerType ((Struct) root_symbol.scope.lookup ("char"));
		int_type = new IntegerType ((Struct) root_symbol.scope.lookup ("int"));
		uint_type = new IntegerType ((Struct) root_symbol.scope.lookup ("uint"));
		string_type = new ObjectType ((Class) root_symbol.scope.lookup ("string"));

		var aroop_ns = (Namespace) root_symbol.scope.lookup ("aroop");
		//object_class = (Class) aroop_ns.scope.lookup ("Object");
		object_class = (Interface) aroop_ns.scope.lookup ("Replicable");
		//type_class = (Class) aroop_ns.scope.lookup ("Type");
		type_class = (Struct) aroop_ns.scope.lookup ("Type");
		value_class = (Struct) aroop_ns.scope.lookup ("Value");
		string_class = (Class) root_symbol.scope.lookup ("string");
		array_struct = (Struct) aroop_ns.scope.lookup ("Array");
		delegate_class = (Class) aroop_ns.scope.lookup ("Delegate");
		error_class = (Class) aroop_ns.scope.lookup ("AroopError");

		header_file = new CCodeFile ();
		header_file.is_header = true;

		cfile = new CCodeFile ();

		if (context.nostdpkg) {
			header_file.add_include ("aroop/aroop_core.h");
			header_file.add_include ("aroop/core/xtring.h");
			header_file.add_include ("aroop/aroop_factory.h");
			cfile.add_include ("aroop/aroop_core.h");
			cfile.add_include ("aroop/core/xtring.h");
		} else {
			header_file.add_include ("aroop/aroop_core.h");
			header_file.add_include ("aroop/core/xtring.h");
			header_file.add_include ("aroop/aroop_factory.h");
			cfile.add_include ("aroop/aroop_core.h");
			cfile.add_include ("aroop/core/xtring.h");
		}

		generated_external_symbols = new HashSet<Symbol> ();


		/* we're only interested in non-pkg source files */
		var source_files = context.get_source_files ();
		foreach (SourceFile file in source_files) {
			if (file.file_type == SourceFileType.SOURCE) {
				file.accept (visitor);
			}
		}

		if (csource_filename != null) {
			if (!cfile.store (csource_filename, null, context.version_header, context.debug)) {
				Report.error (null, "unable to open `%s' for writing".printf (csource_filename));
			}
		}

		cfile = null;

		// generate C header file for public API
		if (context.header_filename != null) {
			if (!header_file.store (context.header_filename, null, context.version_header, false)) {
				Report.error (null, "unable to open `%s' for writing".printf (context.header_filename));
			}
		}
		return null;
	}



	Vala.List<EmitContext> emit_context_stack = new ArrayList<EmitContext> ();
	public void push_context (EmitContext emit_context) {
		if (this.emit_context != null) {
			emit_context_stack.add (this.emit_context);
		}

		this.emit_context = emit_context;
	}

	public void pop_context () {
		if (emit_context_stack.size > 0) {
			this.emit_context = emit_context_stack[emit_context_stack.size - 1];
			emit_context_stack.remove_at (emit_context_stack.size - 1);
		} else {
			this.emit_context = null;
		}
	}

	public void push_function (CCodeFunction func) {
		emit_context.ccode_stack.add (ccode);
		emit_context.ccode = func;
	}

	public void pop_function () {
		emit_context.ccode = emit_context.ccode_stack[emit_context.ccode_stack.size - 1];
		emit_context.ccode_stack.remove_at (emit_context.ccode_stack.size - 1);
	}

	public bool add_symbol_declaration (CCodeFile decl_space, Symbol sym, string name) {
#if true
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

	public bool add_generated_external_symbol (Symbol external_symbol) {
		return generated_external_symbols.add (external_symbol);
	}
	public LocalVariable get_temp_variable (DataType type, bool value_owned = true, CodeNode? node_reference = null) {
		var var_type = type.copy ();
		var_type.value_owned = value_owned;
		var local = new LocalVariable (var_type, "_tmp%d_".printf (next_temp_var_id));

		if (node_reference != null) {
			local.source_reference = node_reference.source_reference;
		}

		next_temp_var_id++;
		return local;
	}

	public TypeSymbol? find_parent_type (Symbol sym) {
		while (sym != null) {
			if (sym is TypeSymbol) {
				return (TypeSymbol) sym;
			}
			sym = sym.parent_symbol;
		}
		return null;
	}

	public ArrayList<LocalVariable> current_declaration_variable_stack = new ArrayList<LocalVariable> ();
	public void push_declaration_variable (LocalVariable local) {
		current_declaration_variable_stack.add (local);
	}

	public void pop_declaration_variable () {
		current_declaration_variable_stack.remove_at (current_declaration_variable_stack.size - 1);
	}

	public LocalVariable get_declaration_variable () {
		return current_declaration_variable_stack.get(current_declaration_variable_stack.size - 1);
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
