using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.SourceModule : shotodolplug.Module {

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
	public bool current_method_inner_error;




	public CCodeFile header_file;
	public CCodeFile cfile;
	public SourceModule() {
		base("Source", "0.0");
		
	}

	public override int init() {
		//PluginManager.register("visit/compiler", new HookExtension(visit_struct, this));
		PluginManager.register("source", new HookExtension((shotodolplug.Hook)getInstance, this));
		PluginManager.register("source/emit", new HookExtension((shotodolplug.Hook)emitHook, this));
		return 0;
	}

	public override int deinit() {
		return 0;
	}

	public SourceModule getInstance(Object param) {
		return this;
	}

	public void emitHook (CodeContext context) {
		this.context = context;

		root_symbol = context.root;

		bool_type = new BooleanType ((Struct) root_symbol.scope.lookup ("bool"));
		char_type = new IntegerType ((Struct) root_symbol.scope.lookup ("char"));
		int_type = new IntegerType ((Struct) root_symbol.scope.lookup ("int"));
		uint_type = new IntegerType ((Struct) root_symbol.scope.lookup ("uint"));
		string_type = new ObjectType ((Class) root_symbol.scope.lookup ("string"));

		var aroop_ns = (Namespace) root_symbol.scope.lookup ("aroop");
		//object_class = (Class) aroop_ns.scope.lookup ("Object");
		object_class = (Class) aroop_ns.scope.lookup ("Replicable");
		type_class = (Class) aroop_ns.scope.lookup ("Type");
		value_class = (Class) aroop_ns.scope.lookup ("Value");
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
				file.accept (this);
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
	public void generate_type_declaration (DataType type, CCodeFile decl_space) {
		// TODO fill me
		/*if (type is ObjectType) {
			var object_type = (ObjectType) type;
			if (object_type.type_symbol is Class) {
				generate_class_declaration ((Class) object_type.type_symbol, decl_space);
			} else if (object_type.type_symbol is Interface) {
				generate_interface_declaration ((Interface) object_type.type_symbol, decl_space);
			}
		} else if (type is DelegateType) {
			var deleg_type = (DelegateType) type;
			var d = deleg_type.delegate_symbol;
			generate_delegate_declaration (d, decl_space);
		} else if (type.data_type is Enum) {
			var en = (Enum) type.data_type;
			generate_enum_declaration (en, decl_space);
		} else if (type is ValueType) {
			var value_type = (ValueType) type;
			generate_struct_declaration ((Struct) value_type.type_symbol, decl_space);
		} else if (type is ArrayType) {
			var array_type = (ArrayType) type;
			generate_struct_declaration (array_struct, decl_space);
			assert(array_type.element_type != null);
			generate_type_declaration (array_type.element_type, decl_space);
		} else if (type is PointerType) {
			var pointer_type = (PointerType) type;
			assert(pointer_type.base_type != null);
			generate_type_declaration (pointer_type.base_type, decl_space);
		}

		foreach (DataType type_arg in type.get_type_arguments ()) {
			if(type_arg != null)generate_type_declaration (type_arg, decl_space);
		}*/
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




	public string generate_block_var_name(Block b) {
		int block_id = get_block_id (b);
		return "_data%d_".printf (block_id);
	}
	public string generate_block_name(Block b) {
		int block_id = get_block_id (b);
		return "Block%dData".printf (block_id);
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
