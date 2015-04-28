using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.ObjectModule : shotodolplug.Module {
	SourceEmitterModule?emitter = null;
	CSymbolResolve?resolve = null;
	Class type_class;
	public ObjectModule() {
		base("Object", "0.0");
		//type_class = (Class) aroop_ns.scope.lookup ("Type");
	}

	public override int init() {
		PluginManager.register("visit/class", new HookExtension(visit_class, this));
		PluginManager.register("visit/interface", new HookExtension(visit_interface, this));
		PluginManager.register("visit/creation_method", new HookExtension(visit_creation_method, this));
		PluginManager.register("generate/class/declaration", new HookExtension(generate_class_declaration_helper, this));
		PluginManager.register("generate/interface/declaration", new HookExtension(generate_interface_declaration_helper, this));
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

	string get_ccode_vtable_struct(Class cl) {
		return "struct aroop_vtable_%s".printf(resolve.get_ccode_lower_case_suffix(cl));
	}
	
	Value? generate_class_declaration_helper(Value?given_args) {
		var args = (HashTable<string,Value?>)given_args;
		generate_class_declaration((Class?)args["class"], (CCodeFile?)args["decl_space"]);
		return null;
	}

	void generate_class_declaration (Class cl, CCodeFile decl_space) {
		assert(cl != null);
		var proto = new CCodeStructPrototype (resolve.get_ccode_aroop_name (cl));
		if (emitter.add_symbol_declaration (decl_space, cl, resolve.get_ccode_lower_case_name (cl))) {
			return;
		}

		if (cl.base_class != null) {
			if (cl.base_class.is_internal_symbol ()) {
				generate_class_declaration (cl.base_class, emitter.cfile);
			} else {
				generate_class_declaration (cl.base_class, emitter.header_file);
			}
		}
		generate_getter_setter_declaration(cl, decl_space);
		generate_generic_builder_macro(cl, decl_space);

		proto.generate_type_declaration(decl_space);
		//decl_space.add_type_declaration(new CCodeTypeDefinition (resolve.get_ccode_aroop_definition(cl), new CCodeVariableDeclarator (resolve.get_ccode_aroop_name (cl))));
		bool has_vtables = resolve.hasVtables(cl);

		if(has_vtables) {
			generate_vtable(cl, decl_space);
		}
		
		var class_struct = proto.definition;
		if (cl.base_class != null) {
			class_struct.add_field (resolve.get_ccode_aroop_definition(cl.base_class), "super_data");
		}
		foreach (Field f in cl.get_fields ()) {
			AroopCodeGeneratorAdapter.generate_element_declaration(f, class_struct, decl_space, cl.is_internal_symbol());
		}
		int tparams = 0;
		foreach (var type_parameter in cl.get_type_parameters ()) {
			class_struct.add_field (resolve.get_aroop_type_cname(), resolve.get_generic_class_variable_cname(tparams));
			tparams++;
		}
		if(has_vtables) {
			class_struct.add_field ("%s*".printf(get_ccode_vtable_struct (cl)), "vtable");
		}
		decl_space.add_type_definition (class_struct);
	}

	void generate_getter_setter_declaration(Class cl, CCodeFile decl_space) {
		foreach (Property prop in cl.get_properties ()) {
			if (prop.is_abstract && prop.is_virtual) {
				// say we do not support that
				Report.error (prop.source_reference, "virtual or abstract property is not supported");
			}
			AroopCodeGeneratorAdapter.generate_type_declaration (prop.property_type, decl_space);
			var prop_name = resolve.get_ccode_name (prop.field);
#if false
			// TODO add array accessor
			 + get_ccode_declarator_suffix (prop.field.variable_type).to_string();
#endif
			var prop_accessor = "";
			var get_params = "";
			var set_params = "y";
			if(prop.binding == MemberBinding.INSTANCE) {
				prop_accessor = "((%s*)x)->".printf(resolve.get_ccode_aroop_name(cl));
				get_params = "x";
				set_params = "x,y";
			}
			if (prop.get_accessor != null) {
#if USE_MACRO_GETTER_SETTER
				CCodeFunction gfunc = new CCodeFunction (
					"%sget_%s".printf (
						resolve.get_ccode_lower_case_prefix (cl)
						, prop.name
					)
					, resolve.get_ccode_aroop_name(prop.property_type)
				);
				if(prop.binding == MemberBinding.INSTANCE) {
					gfunc.add_parameter (new CCodeParameter (resolve.self_instance, resolve.get_ccode_aroop_name (cl) + "*"));
				}
				emitter.push_function (gfunc);
				if(prop.is_internal_symbol()) {
					emitter.cfile.add_function_declaration (gfunc);
				} else {
					emitter.header_file.add_function_declaration (gfunc);
				}
				emitter.visitor.visit_property_accessor2(prop.get_accessor);
				emitter.pop_function ();
				emitter.cfile.add_function(gfunc);
#else
				var macro_function = "%sget_%s(%s)".printf (resolve.get_ccode_lower_case_prefix (cl)
				                                            , prop.name, get_params);
				var macro_body = "({%s%s;})".printf(prop_accessor, prop_name);
				
				var func_macro = new CCodeMacroReplacement(macro_function, macro_body);
				decl_space.add_type_declaration (func_macro);
#endif
			}
			if (prop.set_accessor != null) {
				// TODO define it in local file if it is not public 
				var macro_function = "%sset_%s(%s)".printf (resolve.get_ccode_lower_case_prefix (cl)
																										, prop.name, set_params);
				var macro_body = "({%s%s = y;})".printf(prop_accessor, prop_name);
				var func_macro = new CCodeMacroReplacement(macro_function, macro_body);
				decl_space.add_type_declaration (func_macro);
			}
		}
	}

	Object?generate_virtual_method_declaration (Method m, CCodeFile decl_space, CCodeStruct type_struct) {
		if (!m.is_abstract && !m.is_virtual) {
			return null;
		}

		// add vfunc field to the type struct
		var vdeclarator = new CCodeFunctionDeclarator (resolve.get_ccode_vfunc_name (m));

		AroopCodeGeneratorAdapter.generate_cparameters (m, decl_space, new CCodeFunction ("fake"), vdeclarator);

		var vdecl = new CCodeDeclaration (resolve.get_ccode_aroop_name (m.return_type));
		vdecl.add_declarator (vdeclarator);
		type_struct.add_declaration (vdecl);
		return null;
	}

#if false
	bool has_instance_struct (Class cl) {
		foreach (Field f in cl.get_fields ()) {
			if (f.binding == MemberBinding.INSTANCE)  {
				return true;
			}
		}
		return false;
	}

	bool has_type_struct (Class cl) {
		if (cl.get_type_parameters ().size > 0) {
			return true;
		}
		foreach (Method m in cl.get_methods ()) {
			if (m.is_abstract || m.is_virtual) {
				return true;
			}
		}
		foreach (Property prop in cl.get_properties ()) {
			if (prop.is_abstract || prop.is_virtual) {
				return true;
			}
		}
		return false;
	}
#endif
	
#if false
	string get_base_vtable_name() {
		return "_base_vtable";
	}
#endif

	void generate_vtable(Class cl, CCodeFile decl_space) {
		var vtable_struct = new CCodeStruct ("aroop_vtable_%s".printf(resolve.get_ccode_lower_case_suffix(cl)));
		foreach (Method m in cl.get_methods ()) {
			generate_virtual_method_declaration (m, decl_space, vtable_struct);
		}
#if false
		//if(cl.base_class != null && cl.base_class.has_vtables) {
			var basevtable = new CCodeDeclaration ("%s*".printf(get_ccode_vtable_struct (cl)));
			basevtable.add_declarator (new CCodeVariableDeclarator (get_base_vtable_name()));
			vtable_struct.add_declaration (basevtable);
		//}
#endif
		decl_space.add_type_definition (vtable_struct);
	}

	void add_vtable_ovrd_variables_external(Class cl, Class of_class) {
		if(of_class.external_package && resolve.hasVtables(of_class)) {
			var vbdecl = new CCodeDeclaration (get_ccode_vtable_struct(of_class));
			vbdecl.add_declarator (new CCodeVariableDeclarator (resolve.get_ccode_vtable_var(
				cl, of_class)));
			vbdecl.modifiers |= CCodeModifiers.EXTERN;
			emitter.cfile.add_type_member_declaration(vbdecl);
		}
		if(of_class.base_class != null) {
			add_vtable_ovrd_variables_external(cl, of_class.base_class);
		}
	}

	void add_vtable_ovrd_variables(Class cl, Class of_class) {
		if (of_class.base_class != null) {
			add_vtable_ovrd_variables(cl, of_class.base_class);
		}
		add_vtable_ovrd_variables_external(of_class, of_class);
		if(!resolve.hasVtables(of_class)) {
			return;
		}
		var vdecl = new CCodeDeclaration (get_ccode_vtable_struct(of_class));
		vdecl.add_declarator (new CCodeVariableDeclarator (resolve.get_ccode_vtable_var(cl, of_class)));
		emitter.cfile.add_type_member_declaration(vdecl);
	}
	
	void cpy_vtable_of_base_class(Class cl, Class of_class, CCodeBlock block) {
		if(of_class.base_class != null) {
			cpy_vtable_of_base_class(cl, of_class.base_class, block);			
		}
		if(!resolve.hasVtables(of_class)) {
			return;
		}
		block.add_statement (
			new CCodeExpressionStatement (
				new CCodeAssignment (
					new CCodeIdentifier (resolve.get_ccode_vtable_var(cl, of_class))
					, new CCodeIdentifier (resolve.get_ccode_vtable_var(cl.base_class, of_class))
				)
			)
		);
#if false
		//if(of_class.base_class != null) {
			block.add_statement (
				new CCodeExpressionStatement (
					new CCodeAssignment (
						new CCodeIdentifier (
							"%s.%s".printf(
							resolve.get_ccode_vtable_var(cl, of_class)
							, get_base_vtable_name()))
						, new CCodeIdentifier ( "&%s".printf(resolve.get_ccode_vtable_var(cl.base_class, of_class)) ))));
		//}
#endif
	}

	void add_class_system_init_function(Class cl) {
		// create the vtable instances
		add_vtable_ovrd_variables(cl, cl);

		var ifunc = new CCodeFunction ("%stype_system_init".printf (resolve.get_ccode_lower_case_prefix (cl)), "int");
		emitter.push_function (ifunc); // XXX I do not know what push does 

		if(cl.is_internal_symbol()) {
			emitter.cfile.add_function_declaration (ifunc);
		} else {
			emitter.header_file.add_function_declaration (ifunc);
		}
		emitter.pop_function (); // XXX I do not know what pop does 

		// Now add definition
		var iblock = new CCodeBlock ();

		// bool done = false;
		var cdone = new CCodeDeclaration ("aroop_bool");
		cdone.add_declarator (new CCodeVariableDeclarator ("done", new CCodeConstant ("false")));
		cdone.modifiers = CCodeModifiers.STATIC;
		iblock.add_statement (cdone);

		var finish = new CCodeReturnStatement(new CCodeConstant ("0"));
		// check if we are already initiated ..
		iblock.add_statement (new CCodeIfStatement(new CCodeIdentifier ("done"), finish));
		
		if(cl.base_class != null) {
			// initiate base class
			iblock.add_statement(
			new CCodeExpressionStatement (
				new CCodeFunctionCall (
					new CCodeIdentifier (
						"%stype_system_init".printf (resolve.get_ccode_lower_case_prefix (cl.base_class))
						)
					)
				)
			);	
			
			// copy vtable from all the base classes recursively
			cpy_vtable_of_base_class(cl, cl.base_class, iblock);
		}

		// prepare our vtable
		foreach (Method m in cl.get_methods ()) {
			if (m.is_virtual || m.overrides) {
				iblock.add_statement (
					new CCodeExpressionStatement (
						new CCodeAssignment (
							new CCodeIdentifier (
								"%s.%s".printf(
								resolve.get_ccode_vtable_var(cl, (Class) m.base_method.parent_symbol)
								, resolve.get_ccode_vfunc_name (m)))
							, new CCodeIdentifier ( resolve.get_ccode_real_name (m) ))));
			}
		}

		iblock.add_statement(new CCodeExpressionStatement(new CCodeAssignment (new CCodeIdentifier ("done"), new CCodeConstant ("true"))));
		iblock.add_statement (finish);
		ifunc.block = iblock;
		emitter.cfile.add_function (ifunc);
	}

	void set_vtables(Class cl, Class of_class, CCodeBlock block) {
		if(of_class.base_class != null) {
			set_vtables(cl, of_class.base_class, block);			
		}
		if(!resolve.hasVtables(of_class)) {
			return;
		}
		block.add_statement (new CCodeExpressionStatement (
			new CCodeAssignment(
				new CCodeIdentifier (
					"((%s*)%s)->vtable".printf(
						resolve.get_ccode_aroop_name(of_class), resolve.self_instance)),
				new CCodeIdentifier ("&%s".printf(resolve.get_ccode_vtable_var(cl, of_class))))));
	}

	void generate_generic_builder_macro(Class cl, CCodeFile decl_space) {
		var params = cl.get_type_parameters();
		return_if_fail(params != null);
		int gtype_count = params.size;
		return_if_fail(gtype_count == 0);
		var macro_function = "%sbuild_generics(x".printf (resolve.get_ccode_lower_case_prefix (cl));
		int i = 0;
		var macro_body = "({";
		for (i=0; i<gtype_count; i++) {
			macro_function = "%s,g_type_%d".printf(macro_function, i);
			macro_body = "%s(x)->%s=g_type_%d;".printf(macro_body, resolve.get_generic_class_variable_cname(i), i);
			i++;
		}
		macro_function = "%s)".printf(macro_function);
		macro_body = "%s})".printf(macro_body);
		var func_macro = new CCodeMacroReplacement(macro_function, macro_body);
		decl_space.add_type_declaration (func_macro);
	}
	
	string get_pray_function(Class cl) {
		return "%s_pray".printf (resolve.get_ccode_aroop_name (cl));
	}

	void add_pray_function (Class cl) {
		string pray_function_name = get_pray_function(cl);
		var function = new CCodeFunction (pray_function_name, "int");
		if(cl.is_internal_symbol()) {
			function.modifiers = CCodeModifiers.STATIC;
		}

		function.add_parameter (new CCodeParameter ("data", "void*"));
		function.add_parameter (new CCodeParameter ("callback", "int"));
		function.add_parameter (new CCodeParameter ("cb_data", "void*"));
		function.add_parameter (new CCodeParameter ("ap", "va_list"));
		function.add_parameter (new CCodeParameter ("size", "int"));

		emitter.push_function (function); // XXX I do not know what push does 

		if(cl.is_internal_symbol()) {
			emitter.cfile.add_function_declaration (function);
		} else {
			emitter.header_file.add_function_declaration (function);
		}
		
		emitter.pop_function (); // XXX I do not know what pop does 

		// Now add definition
		var vblock = new CCodeBlock ();

		var stat = new CCodeDeclaration ("%s *".printf (resolve.get_ccode_aroop_name(cl)));
		stat.add_declarator (new CCodeVariableDeclarator (resolve.self_instance));
		vblock.add_statement (stat);

		var obj_arg_var = new CCodeIdentifier ("data");
		var obj_cb_data_var = new CCodeIdentifier ("cb_data");
		vblock.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeIdentifier (resolve.self_instance), new CCodeCastExpression (obj_arg_var, "%s *".printf (resolve.get_ccode_aroop_name(cl))))));

		var switch_stat = new CCodeSwitchStatement (new CCodeIdentifier ("callback"));
		switch_stat.add_statement (new CCodeCaseStatement(new CCodeIdentifier ("OPPN_ACTION_INITIALIZE")));
		switch_stat.add_statement(new CCodeExpressionStatement (new CCodeFunctionCall (new CCodeIdentifier ("%stype_system_init".printf (resolve.get_ccode_lower_case_prefix (cl))))));

		// assign vtables
		set_vtables(cl, cl, switch_stat as CCodeBlock);

		switch_stat.add_statement (new CCodeBreakStatement());
		switch_stat.add_statement (new CCodeCaseStatement(new CCodeIdentifier ("OPPN_ACTION_FINALIZE")));
		var destruction_function = new CCodeFunctionCall (new CCodeIdentifier("%sdestruction".printf (resolve.get_ccode_lower_case_prefix (cl))));
		destruction_function.add_argument(obj_arg_var);
		switch_stat.add_statement(new CCodeExpressionStatement(destruction_function));
		switch_stat.add_statement (new CCodeBreakStatement());
		
		switch_stat.add_statement (new CCodeCaseStatement(new CCodeIdentifier ("OPPN_ACTION_GET_SIZE")));
		var sizeof_stat = new CCodeFunctionCall (new CCodeIdentifier("sizeof"));
		sizeof_stat.add_argument(new CCodeIdentifier(resolve.get_ccode_aroop_name (cl)));
		switch_stat.add_statement (new CCodeReturnStatement(sizeof_stat));
		
		switch_stat.add_statement (new CCodeCaseStatement(new CCodeIdentifier ("OPPN_ACTION_IS_EQUAL")));
		var is_equal_stat = new CCodeBinaryExpression (
			CCodeBinaryOperator.EQUALITY
			, obj_arg_var
			, obj_cb_data_var);
		switch_stat.add_statement (new CCodeReturnStatement(is_equal_stat));

		switch_stat.add_statement (new CCodeCaseStatement(new CCodeIdentifier ("OPPN_ACTION_SET_GENERIC_TYPES")));
		int i = 0;
		foreach (var generic_type in  cl.get_type_parameters ()) {
		//foreach (var f in cl.get_fields ()) {
			//if (f.binding != MemberBinding.INSTANCE || !(f.variable_type is GenericType)) {
				//continue;
			//}
			
			//var generic_type = (GenericType) f.variable_type;
			CCodeExpression? typearg = null;
			if(i == 0) {
				typearg = new CCodeConstant("cb_data");
			} else {
				if(i == 1) {
					var variadic_start = new CCodeFunctionCall(new CCodeConstant("va_start"));
					variadic_start.add_argument(new CCodeConstant("ap"));
					variadic_start.add_argument(new CCodeConstant("cb_data"));
					switch_stat.add_statement (variadic_start);
				}
				var varg = new CCodeFunctionCall(new CCodeConstant("va_arg"));
				varg.add_argument(new CCodeConstant("ap"));
				varg.add_argument(new CCodeConstant("void*"));
				typearg = varg;
			}


			switch_stat.add_statement (
				new CCodeExpressionStatement (
					new CCodeAssignment (
						new CCodeMemberAccess.pointer (new CCodeIdentifier (resolve.self_instance), resolve.get_generic_class_variable_cname(i))
						, typearg
					)
				)
			);
			i++;
		}
		switch_stat.add_statement (new CCodeBreakStatement());

		switch_stat.add_statement (new CCodeCaseStatement(new CCodeIdentifier ("OPPN_ACTION_REF")));
		var ref_case = new CCodeFunctionCall (new CCodeIdentifier("OPPREF"));
		ref_case.add_argument(obj_arg_var);
		switch_stat.add_statement (new CCodeExpressionStatement (ref_case));
		switch_stat.add_statement (new CCodeBreakStatement());

		switch_stat.add_statement (new CCodeCaseStatement(new CCodeIdentifier ("OPPN_ACTION_UNREF")));
		var unref_case = new CCodeFunctionCall (new CCodeIdentifier("OPPUNREF2"));
		unref_case.add_argument(obj_arg_var);
		switch_stat.add_statement (new CCodeExpressionStatement (unref_case));
		switch_stat.add_statement (new CCodeBreakStatement());

		switch_stat.add_statement (new CCodeCaseStatement(new CCodeIdentifier ("OPPN_ACTION_GET_SOURCE_MODULE")));
		var module_name_case = new CCodeFunctionCall (new CCodeIdentifier("aroop_txt_embeded_rebuild_and_set_static_string"));
		module_name_case.add_argument(new CCodeCastExpression(obj_cb_data_var, "aroop_txt_t*"));
		module_name_case.add_argument(new CCodeConstant("AROOP_MODULE_NAME"));
		switch_stat.add_statement (new CCodeExpressionStatement (module_name_case));
		switch_stat.add_statement (new CCodeBreakStatement());

		switch_stat.add_statement (new CCodeCaseStatement(new CCodeIdentifier ("OPPN_ACTION_GET_CLASS_NAME")));
		var class_name_case = new CCodeFunctionCall (new CCodeIdentifier("aroop_txt_embeded_rebuild_and_set_static_string"));
		class_name_case.add_argument(new CCodeCastExpression(obj_cb_data_var, "aroop_txt_t*"));
		class_name_case.add_argument(new CCodeConstant("\"%s\"".printf(resolve.get_ccode_aroop_name(cl))));
		switch_stat.add_statement (new CCodeExpressionStatement (class_name_case));
		switch_stat.add_statement (new CCodeBreakStatement());

		switch_stat.add_statement (new CCodeCaseStatement(new CCodeIdentifier ("OPPN_ACTION_IS_TYPE_OF")));
		var is_equal_this_class = new CCodeBinaryExpression (
			CCodeBinaryOperator.EQUALITY
			, new CCodeIdentifier(pray_function_name)
			, obj_cb_data_var);
		CCodeExpression else_not_this_class = new CCodeConstant("0");
		if(cl.base_class != null) {
			string base_pray_function_name = get_pray_function(cl.base_class);
			var super_pray_call = new CCodeFunctionCall (new CCodeIdentifier(base_pray_function_name));
			super_pray_call.add_argument(obj_arg_var);
			super_pray_call.add_argument(new CCodeIdentifier ("callback"));
			super_pray_call.add_argument(obj_cb_data_var);
			super_pray_call.add_argument(new CCodeIdentifier ("ap"));
			super_pray_call.add_argument(new CCodeIdentifier ("size"));
			else_not_this_class = super_pray_call;
		}
		var is_type_of_this_class = new CCodeIfStatement(is_equal_this_class, new CCodeReturnStatement(new CCodeConstant("1")), new CCodeReturnStatement(else_not_this_class));
		switch_stat.add_statement (is_type_of_this_class);
		switch_stat.add_statement (new CCodeBreakStatement());

		vblock.add_statement (switch_stat);
		vblock.add_statement (new CCodeReturnStatement(new CCodeConstant ("0")));

		function.block = vblock;

		emitter.cfile.add_function (function);

	}

	void add_destruction_function (Class cl) {
		var function = new CCodeFunction ("%sdestruction".printf (resolve.get_ccode_lower_case_prefix (cl)), "void");
		if(cl.is_internal_symbol()) {
			function.modifiers = CCodeModifiers.STATIC;
		}

		function.add_parameter (new CCodeParameter (resolve.self_instance, resolve.get_ccode_aroop_name (cl) + "*"));

		emitter.push_function (function);


		if(cl.is_internal_symbol()) {
			emitter.cfile.add_function_declaration (function);
		} else {
			emitter.header_file.add_function_declaration (function);
		}

		if (cl.destructor != null) {
			cl.destructor.body.emit (emitter.visitor);
		}

		foreach (Field f in cl.get_fields ()) {
			AroopCodeGeneratorAdapter.generate_element_destruction_code(f, emitter.ccode.block);
		}
#if false
		foreach (var f in cl.get_fields ()) {
			if (f.binding == MemberBinding.INSTANCE)  {
				CCodeExpression lhs = new CCodeMemberAccess.pointer (new CCodeIdentifier (resolve.self_instance), resolve.get_ccode_name (f));

				if (resolve.requires_destroy (f.variable_type)) {
					var this_access = new MemberAccess.simple (resolve.self_instance);
					this_access.value_type = resolve.get_data_type_for_symbol ((TypeSymbol) f.parent_symbol);

					Struct?field_st = null;
					if(f.parent_symbol is Struct)
						field_st = f.parent_symbol as Struct;
					if (field_st != null && !field_st.is_simple_type ()) {
						resolve.set_cvalue (this_access, new CCodeIdentifier ("(*this)"));
					} else {
						resolve.set_cvalue (this_access, new CCodeIdentifier (resolve.self_instance));
					}

					var ma = new MemberAccess (this_access, f.name);
					ma.symbol_reference = f;
					emitter.ccode.add_expression (resolve.get_unref_expression (lhs, f.variable_type, ma));
				}
			}
		}

		if(cl.base_class != null) {
			string base_pray_function_name = get_pray_function(cl.base_class);
			var super_pray_call = new CCodeFunctionCall (new CCodeIdentifier(base_pray_function_name));
			super_pray_call.add_argument(obj_arg_var);
			super_pray_call.add_argument(new CCodeIdentifier ("callback"));
			super_pray_call.add_argument(obj_cb_data_var);
			super_pray_call.add_argument(new CCodeIdentifier ("ap"));
			super_pray_call.add_argument(new CCodeIdentifier ("size"));
			switch_stat.add_statement(new CCodeExpressionStatement(super_pray_call));
		}
#endif
		// chain up to destroy function of the base class
		foreach (DataType base_type in cl.get_base_types ()) {
			var object_type = (ObjectType) base_type;
			if (object_type.type_symbol is Class) {
#if false
				var ccall = new CCodeFunctionCall (new CCodeIdentifier ("aroop_object_base_destroy"));
				var type_get_call = new CCodeFunctionCall (new CCodeIdentifier ("%s_type_get".printf (resolve.get_ccode_aroop_name (object_type.type_symbol))));
				foreach (var type_arg in base_type.get_type_arguments ()) {
					type_get_call.add_argument (resolve.get_type_id_expression (type_arg, false));
				}
				ccall.add_argument (type_get_call);
				ccall.add_argument (new CCodeIdentifier (resolve.self_instance));
				emitter.ccode.add_statement (new CCodeExpressionStatement (ccall));
#endif
				var ccall = new CCodeFunctionCall (new CCodeIdentifier("%sdestruction".printf (resolve.get_ccode_lower_case_prefix (cl.base_class))));
				ccall.add_argument (new CCodeIdentifier (resolve.self_instance));
				emitter.ccode.add_statement (new CCodeExpressionStatement (ccall));
			}
		}

		emitter.pop_function ();

		emitter.cfile.add_function (function);
	}

	bool cleanup_is_already_declared;
	Value?visit_class (Value?args) {
		Class cl = (Class)args;
		cleanup_is_already_declared = false;
		emitter.push_context (new EmitContext (cl));

		add_destruction_function (cl);
		add_pray_function (cl);
		add_class_system_init_function(cl);

		if (cl.is_internal_symbol ()) {
			generate_class_declaration (cl, emitter.cfile);
		} else {
			generate_class_declaration (cl, emitter.header_file);
		}

		cl.accept_children (emitter.visitor);
		emitter.pop_context ();
		return null;
	}

	Value? visit_interface (Value?args) {
		Interface iface = (Interface)args;
		emitter.push_context (new EmitContext (iface));

		generate_interface_declaration (iface, emitter.cfile);

		iface.accept_children (emitter.visitor);

		emitter.pop_context ();
		return null;
	}


#if USE_MACRO_GETTER_SETTER
	void visit_property_accessor2 (PropertyAccessor acc) {
		//emitter.push_context (new EmitContext (acc));
		if (acc.result_var != null) {
			acc.result_var.accept (emitter.visitor);
		}
		if(acc.body != null) {
			emitter.ccode.add_declaration (resolve.get_ccode_name (acc.value_type), new CCodeVariableDeclarator ("result"));
			acc.body.emit (emitter.visitor);
		}
	}
#endif

	Value? generate_interface_declaration_helper (Value?given_args) {
		var args = (HashTable<string,Value?>)given_args;
		generate_interface_declaration((Interface?)args["interface"], (CCodeFile?)args["decl_space"]);
		return null;
	}

	void generate_interface_declaration (Interface iface, CCodeFile decl_space) {
		if (emitter.add_symbol_declaration (decl_space, iface, resolve.get_ccode_lower_case_name (iface))) {
			return;
		}
		decl_space.add_type_declaration(new CCodeTypeDefinition ("void*", new CCodeVariableDeclarator (resolve.get_ccode_aroop_name (iface))));

#if false
		var vtable_struct = new CCodeStruct ("aroop_iface_vtable_%s".printf (resolve.get_ccode_aroop_name (iface)));
		foreach (Method m in iface.get_methods ()) {
			generate_virtual_method_declaration (m, decl_space, vtable_struct);
		}
		// typedef to AroopObject instead of dummy struct to avoid warnings/casts
		generate_class_declaration (object_class, decl_space);
#endif
	}


	void generate_method_declaration (Method m, CCodeFile decl_space) {
		if (emitter.add_symbol_declaration (decl_space, m, resolve.get_ccode_name (m))) {
			return;
		}

		if (m.is_abstract || m.is_virtual) {
			// TODO remove the __VA_ARGS__ for single argument function
			int count = m.get_parameters().size; // get the number of parameters
			if (m.return_type is GenericType) {
				count++;
			}
			var macro_function = "%s(x".printf(resolve.get_ccode_name(m));
			var macro_body = "((%s*)x)->vtable->%s(x".printf(resolve.get_ccode_aroop_name((Class) m.parent_symbol), m.name);
			if(count != 0 || m.get_error_types().size != 0) {
				macro_function += ", ...";
				macro_body += ", __VA_ARGS__";
			}
			var func_macro = new CCodeMacroReplacement(macro_function + ")", macro_body + ")");
			decl_space.add_type_declaration (func_macro);
			// for base
#if false
			macro_function = "%s(x".printf(get_ccode_base_name(m));
			macro_body = "((%s*)x)->vtable->_base_vtable->%s(x".printf(resolve.get_ccode_aroop_name((Class) m.parent_symbol), m.name);
			if(count != 0 || m.get_error_types().size != 0) {
				macro_function += ", ...";
				macro_body += ", __VA_ARGS__";
			}
			func_macro = new CCodeMacroReplacement(macro_function + ")", macro_body + ")");
			decl_space.add_type_declaration (func_macro);
#endif
		} else {
			var function = new CCodeFunction (resolve.get_ccode_name (m));

			if (m.is_internal_symbol ()) {
				function.modifiers |= CCodeModifiers.STATIC;
				if (m.is_inline) {
					function.modifiers |= CCodeModifiers.INLINE;
				}
			}

			AroopCodeGeneratorAdapter.generate_cparameters (m, decl_space, function, null, new CCodeFunctionCall (new CCodeIdentifier ("fake")));

			decl_space.add_function_declaration (function);
		}
		if (m is CreationMethod && m.parent_symbol != null && m.parent_symbol is Class) {
			generate_class_declaration ((Class) m.parent_symbol, decl_space);

			// _init function
			var function = new CCodeFunction (resolve.get_ccode_real_name (m));

			if (m.is_internal_symbol ()) {
				function.modifiers |= CCodeModifiers.STATIC;
			}

			AroopCodeGeneratorAdapter.generate_cparameters (m, decl_space, function);

			decl_space.add_function_declaration (function);
		}
	}

	void cleanup_object_while_creation(Class cls, CCodeBlock vblock) {
		foreach (var f in cls.get_fields ()) {
			if (f.binding == MemberBinding.INSTANCE)  {
				CCodeExpression fieldexp = new CCodeMemberAccess.pointer (new CCodeIdentifier (resolve.self_instance), resolve.get_ccode_name (f));
				if (resolve.requires_destroy (f.variable_type)) {
					var bless_function = "aroop_cleanup_in_countructor_function";
					if (f.variable_type.data_type is Struct) {
						bless_function = "aroop_cleanup_in_countructor_function_for_struct";
					}
					if (f.variable_type is ArrayType) {
						bless_function = "aroop_cleanup_in_countructor_function_for_array_costly";
					}
					var cleanupfields = new CCodeFunctionCall (new CCodeIdentifier (bless_function));
					cleanupfields.add_argument (fieldexp);
					vblock.add_statement (new CCodeExpressionStatement (cleanupfields));
				}
			}
		}
		Class?upper = cls.base_class;
		if(upper != null && upper != cls) {
			var vcall = new CCodeFunctionCall (new CCodeIdentifier ("%s_prepare_internal".printf(resolve.get_ccode_aroop_name (upper))));
			vcall.add_argument (new CCodeIdentifier (resolve.self_instance));
			vblock.add_statement (new CCodeExpressionStatement (vcall));
		}
	}

	Value? visit_creation_method (Value? args) {
		CreationMethod m = (CreationMethod)args;
		bool visible = !m.is_internal_symbol ();

		emitter.visitor.visit_method (m);

		DataType creturn_type;
		if (emitter.current_type_symbol is Class) {
			creturn_type = new ObjectType (emitter.current_class);
		} else {
			creturn_type = new VoidType ();
		}

		if(emitter.current_type_symbol is Class) {
			if(!cleanup_is_already_declared) {
				var vfunc_cleanup_constructor = new CCodeFunction ("%s_prepare_internal".printf(resolve.get_ccode_name (emitter.current_class)));
				vfunc_cleanup_constructor.add_parameter(new CCodeParameter (resolve.self_instance, "%s *".printf(resolve.get_ccode_aroop_name (emitter.current_class))));
				var vblock_cleanup_constructor = new CCodeBlock ();
				cleanup_object_while_creation(emitter.current_class, vblock_cleanup_constructor);
				if(!emitter.current_class.is_internal_symbol()) {
					emitter.header_file.add_function_declaration (vfunc_cleanup_constructor);
				} else {
					vfunc_cleanup_constructor.modifiers |= CCodeModifiers.STATIC;
					emitter.cfile.add_function_declaration (vfunc_cleanup_constructor);
				}
				vfunc_cleanup_constructor.block = vblock_cleanup_constructor;
				emitter.cfile.add_function (vfunc_cleanup_constructor);
				cleanup_is_already_declared = true;
			}
		}

		// do not generate _new functions for creation methods of abstract classes
		if (emitter.current_type_symbol is Class && !emitter.current_class.is_abstract) {
			var vfunc = new CCodeFunction (resolve.get_ccode_name (m));

			var vblock = new CCodeBlock ();

			var cdecl = new CCodeDeclaration ("%s *".printf (resolve.get_ccode_aroop_name (emitter.current_type_symbol)));
			cdecl.add_declarator (new CCodeVariableDeclarator (resolve.self_instance));
			vblock.add_statement (cdecl);


			var alloc_call = new CCodeFunctionCall (new CCodeIdentifier ("aroop_object_alloc"));
			alloc_call.add_argument (new CCodeIdentifier ("sizeof(struct _%s)".printf (resolve.get_ccode_aroop_name(emitter.current_class))));
			alloc_call.add_argument (new CCodeIdentifier(get_pray_function(emitter.current_class)));
			vblock.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeIdentifier (resolve.self_instance), new CCodeCastExpression (alloc_call, "%s *".printf (resolve.get_ccode_aroop_name (emitter.current_type_symbol))))));

#if false
			// allocate memory for fields of generic types
			// this is only a temporary measure until this can be allocated inline at the end of the instance
			// this also won't work for subclasses of classes that have fields of generic types
			foreach (var f in emitter.current_class.get_fields ()) {
				if (f.binding != MemberBinding.INSTANCE || !(f.variable_type is GenericType)) {
					continue;
				}

				var generic_type = (GenericType) f.variable_type;
				var type_get_value_size = new CCodeFunctionCall (new CCodeIdentifier ("aroop_type_get_value_size"));
				type_get_value_size.add_argument (new CCodeIdentifier ("%s_type".printf (generic_type.type_parameter.name.down ())));

				var calloc_call = new CCodeFunctionCall (new CCodeIdentifier ("calloc"));
				calloc_call.add_argument (new CCodeConstant ("1"));
				calloc_call.add_argument (type_get_value_size);
				var priv_call = new CCodeFunctionCall (new CCodeIdentifier ("%s_GET_PRIVATE".printf (resolve.get_ccode_upper_case_name (emitter.current_class, null))));
				priv_call.add_argument (new CCodeIdentifier (resolve.self_instance));

				vblock.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeMemberAccess.pointer (priv_call, f.name), calloc_call)));
			}
#else
			int i = 0;
			foreach (var generic_type in  emitter.current_class.get_type_parameters ()) {
			//foreach (var f in emitter.current_class.get_fields ()) {
				//if (f.binding != MemberBinding.INSTANCE || !(f.variable_type is GenericType)) {
					//continue;
				//}
				
				//var generic_type = (GenericType) f.variable_type;
				vblock.add_statement (
					new CCodeExpressionStatement (
						new CCodeAssignment (
							new CCodeMemberAccess.pointer (new CCodeIdentifier (resolve.self_instance), resolve.get_generic_class_variable_cname(i))
							, new CCodeConstant("g_type")
						)
					)
				);
				i++;
			}
#endif


			var vcleanupcall = new CCodeFunctionCall (new CCodeIdentifier ("%s_prepare_internal".printf(resolve.get_ccode_aroop_name (emitter.current_class))));
			vcleanupcall.add_argument (new CCodeIdentifier (resolve.self_instance));
			vblock.add_statement (new CCodeExpressionStatement (vcleanupcall));

			var vcall = new CCodeFunctionCall (new CCodeIdentifier (resolve.get_ccode_real_name (m)));
			vcall.add_argument (new CCodeIdentifier (resolve.self_instance));
			vblock.add_statement (new CCodeExpressionStatement (vcall));
			AroopCodeGeneratorAdapter.generate_cparameters (m, emitter.cfile, vfunc, null, vcall);
			if(m.tree_can_fail) {
				vcall.add_argument (new CCodeIdentifier ("aroop_internal_err"));
			}
			CCodeStatement cstmt = new CCodeReturnStatement (new CCodeIdentifier (resolve.self_instance));
			cstmt.line = vfunc.line;
			vblock.add_statement (cstmt);

			if (!visible) {
				vfunc.modifiers |= CCodeModifiers.STATIC;
			}

			emitter.cfile.add_function_declaration (vfunc);

			vfunc.block = vblock;

			emitter.cfile.add_function (vfunc);

		}
		return null;
	}

	TypeSymbol? find_parent_type (Symbol sym) {
		while (sym != null) {
			if (sym is TypeSymbol) {
				return (TypeSymbol) sym;
			}
			sym = sym.parent_symbol;
		}
		return null;
	}

	void visit_element_access (ElementAccess expr) {
		var array_type = expr.container.value_type as ArrayType;
		if (array_type != null) {
			// access to element in an array

			expr.accept_children (emitter.visitor);

			Vala.List<Expression> indices = expr.get_indices ();
			var cindex = resolve.get_cvalue (indices[0]);

			if (array_type.inline_allocated) {
				if (array_type.element_type is GenericType) {
					// generic array
					// calculate offset in bytes based on value size
					var value_size = new CCodeFunctionCall (new CCodeIdentifier ("aroop_type_get_value_size"));
					value_size.add_argument (resolve.get_type_id_expression (array_type.element_type));
					resolve.set_cvalue (expr, new CCodeBinaryExpression (CCodeBinaryOperator.PLUS, new CCodeCastExpression (resolve.get_cvalue (expr.container), "char*"), new CCodeBinaryExpression (CCodeBinaryOperator.MUL, value_size, cindex)));
				} else {
					resolve.set_cvalue (expr, new CCodeElementAccess (resolve.get_cvalue (expr.container), cindex));
				}
			} else {
				var ccontainer = resolve.get_cvalue (expr.container);

				if (array_type.element_type is GenericType) {
					// generic array
					// calculate offset in bytes based on value size
					var value_size = new CCodeFunctionCall (new CCodeIdentifier ("aroop_type_get_value_size"));
					value_size.add_argument (resolve.get_type_id_expression (array_type.element_type));
					resolve.set_cvalue (expr, new CCodeBinaryExpression (CCodeBinaryOperator.PLUS, new CCodeCastExpression (ccontainer, "char*"), new CCodeBinaryExpression (CCodeBinaryOperator.MUL, value_size, cindex)));
				} else {
					resolve.set_cvalue (expr, new CCodeElementAccess (new CCodeCastExpression (ccontainer, "%s*".printf (resolve.get_ccode_aroop_name (array_type.element_type))), cindex));
				}
			}

		} else {
			//TODO fix me emitter.visitor.visit_element_access (expr);
		}
	}

}
