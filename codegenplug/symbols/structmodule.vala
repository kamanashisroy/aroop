using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.StructModule : shotodolplug.Module {
	SourceEmitterModule compiler;
	CSymbolResolve resolve;
	CodeGenerator cgen;
	AroopCodeGeneratorAdapter cgenAdapter;
	public StructModule() {
		base("Struct", "0.0");
	}

	public override int init() {
		PluginManager.register("visit/struct", new HookExtension((shotodolplug.Hook)visit_struct, this));
		return 0;
	}

	public override int deinit() {
		return 0;
	}

	void generate_declaration (Struct st, CCodeFile decl_space) {
		if (st.is_boolean_type ()) {
			// typedef for boolean types
			return;
		} else if (st.is_integer_type ()) {
			// typedef for integral types
			return;
		} else if (st.is_decimal_floating_type ()) {
			// typedef for decimal floating types
			return;
		} else if (st.is_floating_type ()) {
			// typedef for generic floating types
			return;
		}
		if(st.external_package) {
			return;
		}
		if(!st.is_internal_symbol() && !decl_space.is_header) {
			generate_declaration (st, compiler.header_file);
			return;
		}
		var proto = new CCodeStructPrototype (resolve.get_ccode_name (st));
#if true
		if(st.is_internal_symbol() && decl_space.is_header) {
			// declare prototype	
			decl_space.add_type_definition (proto);
			proto.generate_type_declaration(decl_space);
			return;
		}
#endif
		if (compiler.add_symbol_declaration (decl_space, st, resolve.get_ccode_name (st))) {
			return;
		}

		if (st.base_struct != null) {
			generate_declaration (st.base_struct, decl_space);
			//return;
		}

		var instance_struct = proto.definition;

		foreach (Field f in st.get_fields ()) {
			cgenAdapter.generate_element_declaration(f, instance_struct, decl_space);
		}
		proto.generate_type_declaration(decl_space);
		decl_space.add_type_definition (instance_struct);
		var func_macro = new CCodeMacroReplacement("%s(x,xindex,y,yindex)".printf(resolve.get_ccode_free_function(st)), "({%s(x,xindex,y,yindex);})".printf(resolve.get_ccode_copy_function(st)));
		decl_space.add_type_declaration (func_macro);
	}

	void generate_struct_copy_function (Struct st) {
		string copy_function_name = "%scopy".printf (resolve.get_ccode_lower_case_prefix (st));
		var function = new CCodeFunction (copy_function_name, "int");
		if(st.is_internal_symbol()) {
			function.modifiers = CCodeModifiers.STATIC;
		}
		function.add_parameter (new CCodeParameter (resolve.self_instance, resolve.get_ccode_aroop_name(st)+"*"));
		function.add_parameter (new CCodeParameter ("nouse1", "int"));
		function.add_parameter (new CCodeParameter ("dest", "void*"));
		function.add_parameter (new CCodeParameter ("nouse2", "int"));
		compiler.push_function (function); // XXX I do not know what push does 
		if(st.is_internal_symbol()) {
			compiler.cfile.add_function_declaration (function);
		} else {
			compiler.header_file.add_function_declaration (function);
		}
		
		compiler.pop_function (); // XXX I do not know what pop does 
		var vblock = new CCodeBlock ();

		var cleanupblock = new CCodeBlock();
		foreach (Field f in st.get_fields ()) {
			cgenAdapter.generate_element_destruction_code(f, cleanupblock);
		}

		var destroy_if_null = new CCodeIfStatement(
			new CCodeBinaryExpression(CCodeBinaryOperator.EQUALITY, new CCodeIdentifier("dest"), new CCodeConstant("0"))
			, cleanupblock
		);
		vblock.add_statement(destroy_if_null);
		vblock.add_statement(new CCodeReturnStatement(new CCodeConstant("0")));


		function.block = vblock;
		compiler.cfile.add_function(function);
	}

	Object? visit_struct (Struct st) {
		compiler.push_context (new EmitContext (st));

		generate_struct_copy_function(st);
		if (st.is_internal_symbol ()) {
			generate_declaration (st, compiler.cfile);
		} else {
			generate_declaration (st, compiler.header_file);
		}

		st.accept_children (cgen);

		compiler.pop_context ();
		return null;
	}
	
	CCodeParameter?generate_instance_cparameter_for_struct(Method m, CCodeParameter?param, DataType this_type) {
		var returnparam = param;
		var st = (Struct) m.parent_symbol;
		if (st.is_boolean_type () || st.is_integer_type () || st.is_floating_type ()) {
			// use return value
		} else {
			returnparam = new CCodeParameter (resolve.self_instance, resolve.get_ccode_aroop_name (this_type)+"*");
			//returnparam = new CCodeUnaryExpression((CCodeUnaryOperator.POINTER_INDIRECTION, get_variable_cexpression (param.name)));
		}
		return returnparam;
	}
}

