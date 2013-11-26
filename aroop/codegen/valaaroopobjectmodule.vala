/* valaaroopobjectmodule.vala
 *
 * Copyright (C) 2009-2011  Jürg Billeter
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Jürg Billeter <j@bitron.ch>
 */

public class Vala.AroopObjectModule : AroopArrayModule {
	private string get_ccode_vtable_struct(Class cl) {
		return "struct aroop_vtable_%s".printf(CCodeBaseModule.get_ccode_lower_case_suffix(cl));
	}
	
	private string get_ccode_vtable_var(Class cl, Class of_class) {
		return "vtable_%sovrd_%s".printf(get_ccode_lower_case_prefix(cl)
			, CCodeBaseModule.get_ccode_lower_case_suffix(of_class));
	}
	
	public override void generate_class_declaration (Class cl, CCodeFile decl_space) {
		//print("%s is being declared\n", get_ccode_lower_case_name(cl));
		//if(cl.base_class != null && cl.base_class.external_package && !decl_space.is_header) {
			//print("Following ..\n");
			//add_symbol_declaration(decl_space, cl.base_class, get_ccode_lower_case_name(cl.base_class));
		//}
		if(cl.external_package) {
			//print("External ..\n");
			add_symbol_declaration(decl_space, cl, get_ccode_lower_case_name(cl));
			return;
		}
		if(!cl.is_internal_symbol() && !decl_space.is_header) {
			generate_class_declaration (cl, header_file);
			return;
		}
		var proto = new CCodeStructPrototype (get_ccode_aroop_name (cl));
		if(cl.is_internal_symbol() && decl_space.is_header) {
			// declare prototype
			decl_space.add_type_definition (proto);
			proto.generate_type_declaration(decl_space);
			return;
		}
		if (add_symbol_declaration (decl_space, cl, get_ccode_lower_case_name (cl))) {
			return;
		}

		if (cl.base_class != null) {
			if (cl.base_class.is_internal_symbol ()) {
				generate_class_declaration (cl.base_class, cfile);
			} else {
				generate_class_declaration (cl.base_class, header_file);
			}
		}
		generate_getter_setter_declaration(cl, decl_space);
		generate_generic_builder_macro(cl, decl_space);

		proto.generate_type_declaration(decl_space);
		//decl_space.add_type_declaration(new CCodeTypeDefinition (get_ccode_aroop_definition(cl), new CCodeVariableDeclarator (get_ccode_aroop_name (cl))));

		if(cl.has_vtables) {
			generate_vtable(cl, decl_space);
		}
		
		var class_struct = proto.definition;
		if (cl.base_class != null) {
			class_struct.add_field (get_ccode_aroop_definition(cl.base_class), "super_data");
		}
		foreach (Field f in cl.get_fields ()) {
			generate_element_declaration(f, class_struct, decl_space);
		}
		int tparams = 0;
		foreach (var type_parameter in cl.get_type_parameters ()) {
			class_struct.add_field (get_aroop_type_cname(), get_generic_class_variable_cname(tparams));
			tparams++;
		}
		if(cl.has_vtables) {
			class_struct.add_field ("%s*".printf(get_ccode_vtable_struct (cl)), "vtable");
		}
		decl_space.add_type_definition (class_struct);
	}

	public void generate_getter_setter_declaration(Class cl, CCodeFile decl_space) {
		foreach (Property prop in cl.get_properties ()) {
            if (prop.is_abstract && prop.is_virtual) {
            	// say we do not support that
				Report.error (prop.source_reference, "virtual or abstract property is not supported");
            }
            generate_type_declaration (prop.property_type, decl_space);
			var prop_name = get_ccode_name (prop.field) + get_ccode_declarator_suffix (prop.field.variable_type);
			var prop_accessor = "";
			var get_params = "";
			var set_params = "y";
			if(prop.binding == MemberBinding.INSTANCE) {
				prop_accessor = "((%s*)x)->".printf(get_ccode_aroop_name(cl));
				get_params = "x";
				set_params = "x,y";
			}
			if (prop.get_accessor != null) {
				var macro_function = "%sget_%s(%s)".printf (CCodeBaseModule.get_ccode_lower_case_prefix (cl)
				                                            , prop.name, get_params);
				var macro_body = "({%s%s;})".printf(prop_accessor, prop_name);
				
				var func_macro = new CCodeMacroReplacement(macro_function, macro_body);
				decl_space.add_type_declaration (func_macro);
            }
            if (prop.set_accessor != null) {
				// TODO define it in local file if it is not public 
				var macro_function = "%sset_%s(%s)".printf (CCodeBaseModule.get_ccode_lower_case_prefix (cl)
				                                            , prop.name, set_params);
				var macro_body = "({%s%s = y;})".printf(prop_accessor, prop_name);
				var func_macro = new CCodeMacroReplacement(macro_function, macro_body);
				decl_space.add_type_declaration (func_macro);
            }
        }

	}

	void generate_virtual_method_declaration (Method m, CCodeFile decl_space, CCodeStruct type_struct) {
		if (!m.is_abstract && !m.is_virtual) {
			return;
		}

		// add vfunc field to the type struct
		var vdeclarator = new CCodeFunctionDeclarator (get_ccode_vfunc_name (m));

		generate_cparameters (m, decl_space, new CCodeFunction ("fake"), vdeclarator);

		var vdecl = new CCodeDeclaration (get_ccode_aroop_name (m.return_type));
		vdecl.add_declarator (vdeclarator);
		type_struct.add_declaration (vdecl);
	}

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

	private void generate_vtable(Class cl, CCodeFile decl_space) {
		var vtable_struct = new CCodeStruct ("aroop_vtable_%s".printf(CCodeBaseModule.get_ccode_lower_case_suffix(cl)));
		foreach (Method m in cl.get_methods ()) {
			generate_virtual_method_declaration (m, decl_space, vtable_struct);
		}
		decl_space.add_type_definition (vtable_struct);
	}

	private void add_vtable_ovrd_variables_external(Class cl, Class of_class) {
		if(of_class.external_package && of_class.has_vtables) {
			var vbdecl = new CCodeDeclaration (get_ccode_vtable_struct(of_class));
			vbdecl.add_declarator (new CCodeVariableDeclarator (get_ccode_vtable_var(
				cl, of_class)));
			vbdecl.modifiers |= CCodeModifiers.EXTERN;
			cfile.add_type_member_declaration(vbdecl);
			if(of_class.base_class != null) {
				add_vtable_ovrd_variables_external(cl, of_class.base_class);
			}
		}
	}

	private void add_vtable_ovrd_variables(Class cl, Class of_class) {
		if (of_class.base_class != null) {
			add_vtable_ovrd_variables(cl, of_class.base_class);
		}
		if(!of_class.has_vtables) {
			return;
		}
		var vdecl = new CCodeDeclaration (get_ccode_vtable_struct(of_class));
		vdecl.add_declarator (new CCodeVariableDeclarator (get_ccode_vtable_var(cl, of_class)));
		cfile.add_type_member_declaration(vdecl);
		add_vtable_ovrd_variables_external(of_class, of_class);
	}
	
	private void cpy_vtable_of_base_class(Class cl, Class of_class, CCodeBlock block) {
		if(of_class.base_class != null) {
			cpy_vtable_of_base_class(cl, of_class.base_class, block);			
		}
		if(!of_class.has_vtables) {
			return;
		}
		block.add_statement (
			new CCodeExpressionStatement (
				new CCodeAssignment (
					new CCodeIdentifier (get_ccode_vtable_var(cl, of_class))
					, new CCodeIdentifier (get_ccode_vtable_var(cl.base_class, of_class))
				)
			)
		);
	}

	private void add_class_system_init_function(Class cl) {
		// create the vtable instances
		add_vtable_ovrd_variables(cl, cl);

		var ifunc = new CCodeFunction ("%stype_system_init".printf (get_ccode_lower_case_prefix (cl)), "int");
		push_function (ifunc); // XXX I do not know what push does 

		if(cl.is_internal_symbol()) {
			cfile.add_function_declaration (ifunc);
		} else {
			header_file.add_function_declaration (ifunc);
		}
		pop_function (); // XXX I do not know what pop does 

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
						"%stype_system_init".printf (get_ccode_lower_case_prefix (cl.base_class))
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
								get_ccode_vtable_var(cl, (Class) m.base_method.parent_symbol)
								, get_ccode_vfunc_name (m)))
							, new CCodeIdentifier ( get_ccode_real_name (m) ))));
			}
		}

		iblock.add_statement(new CCodeExpressionStatement(new CCodeAssignment (new CCodeIdentifier ("done"), new CCodeConstant ("true"))));
		iblock.add_statement (finish);
		ifunc.block = iblock;
		cfile.add_function (ifunc);
	}

	private void set_vtables(Class cl, Class of_class, CCodeBlock block) {
		if(of_class.base_class != null) {
			set_vtables(cl, of_class.base_class, block);			
		}
		if(!of_class.has_vtables) {
			return;
		}
		block.add_statement (new CCodeExpressionStatement (
			new CCodeAssignment(
				new CCodeIdentifier (
					"((%s*)%s)->vtable".printf(
						get_ccode_aroop_name(of_class), self_instance)),
				new CCodeIdentifier ("&%s".printf(get_ccode_vtable_var(cl, of_class))))));
	}

	private void generate_generic_builder_macro(Class cl, CCodeFile decl_space) {
		var params = cl.get_type_parameters();
		return_if_fail(params != null);
		int gtype_count = params.size;
		return_if_fail(gtype_count == 0);
		var macro_function = "%sbuild_generics(x".printf (CCodeBaseModule.get_ccode_lower_case_prefix (cl));
		int i = 0;
		var macro_body = "({";
		for (i=0; i<gtype_count; i++) {
			macro_function = "%s,g_type_%d".printf(macro_function, i);
			macro_body = "%s(x)->%s=g_type_%d;".printf(macro_body, get_generic_class_variable_cname(i), i);
			i++;
		}
		macro_function = "%s)".printf(macro_function);
		macro_body = "%s})".printf(macro_body);
		var func_macro = new CCodeMacroReplacement(macro_function, macro_body);
		decl_space.add_type_declaration (func_macro);
	}
	
	private void add_pray_function (Class cl) {
		var function = new CCodeFunction ("%spray".printf (get_ccode_lower_case_prefix (cl)), "int");
		if(cl.is_internal_symbol()) {
			function.modifiers = CCodeModifiers.STATIC;
		}

		function.add_parameter (new CCodeParameter ("data", "void*"));
		function.add_parameter (new CCodeParameter ("callback", "int"));
		function.add_parameter (new CCodeParameter ("cb_data", "void*"));
		function.add_parameter (new CCodeParameter ("ap", "va_list"));
		function.add_parameter (new CCodeParameter ("size", "int"));

		push_function (function); // XXX I do not know what push does 

		cfile.add_function_declaration (function);

		pop_function (); // XXX I do not know what pop does 

		// Now add definition
		var vblock = new CCodeBlock ();

		var stat = new CCodeDeclaration ("%s *".printf (get_ccode_aroop_name(cl)));
		stat.add_declarator (new CCodeVariableDeclarator (self_instance));
		vblock.add_statement (stat);

		var obj_arg_var = new CCodeIdentifier ("data");
		var obj_cb_data_var = new CCodeIdentifier ("cb_data");
		vblock.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeIdentifier (self_instance), new CCodeCastExpression (obj_arg_var, "%s *".printf (get_ccode_aroop_name(cl))))));

		var switch_stat = new CCodeSwitchStatement (new CCodeIdentifier ("callback"));
		switch_stat.add_statement (new CCodeCaseStatement(new CCodeIdentifier ("OPPN_ACTION_INITIALIZE")));
		switch_stat.add_statement(new CCodeExpressionStatement (new CCodeFunctionCall (new CCodeIdentifier ("%stype_system_init".printf (get_ccode_lower_case_prefix (cl))))));

		// assign vtables
		set_vtables(cl, cl, switch_stat as CCodeBlock);

		switch_stat.add_statement (new CCodeBreakStatement());
		switch_stat.add_statement (new CCodeCaseStatement(new CCodeIdentifier ("OPPN_ACTION_FINALIZE")));
		// TODO may be we should call destructor function here *****~~~~~****!~~~!!!!!!|||(:>)
		switch_stat.add_statement (new CCodeBreakStatement());
		
		switch_stat.add_statement (new CCodeCaseStatement(new CCodeIdentifier ("OPPN_ACTION_GET_SIZE")));
		var sizeof_stat = new CCodeFunctionCall (new CCodeIdentifier("sizeof"));
		sizeof_stat.add_argument(new CCodeIdentifier(get_ccode_aroop_name (cl)));
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
						new CCodeMemberAccess.pointer (new CCodeIdentifier (self_instance), get_generic_class_variable_cname(i))
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

		vblock.add_statement (switch_stat);
		vblock.add_statement (new CCodeReturnStatement(new CCodeConstant ("0")));

		function.block = vblock;

		cfile.add_function (function);

	}

	void add_finalize_function (Class cl) {
		var function = new CCodeFunction ("%sfinalize".printf (get_ccode_lower_case_prefix (cl)), "void");
		function.modifiers = CCodeModifiers.STATIC;

		function.add_parameter (new CCodeParameter (self_instance, get_ccode_aroop_name (cl) + "*"));

		push_function (function);

		cfile.add_function_declaration (function);

		if (cl.destructor != null) {
			cl.destructor.body.emit (this);
		}

		foreach (var f in cl.get_fields ()) {
			if (f.binding == MemberBinding.INSTANCE)  {
				CCodeExpression lhs = new CCodeMemberAccess.pointer (new CCodeIdentifier (self_instance), get_ccode_name (f));

				if (requires_destroy (f.variable_type)) {
					var this_access = new MemberAccess.simple (self_instance);
					this_access.value_type = get_data_type_for_symbol ((TypeSymbol) f.parent_symbol);

					var field_st = f.parent_symbol as Struct;
					if (field_st != null && !field_st.is_simple_type ()) {
						set_cvalue (this_access, new CCodeIdentifier ("(*this)"));
					} else {
						set_cvalue (this_access, new CCodeIdentifier (self_instance));
					}

					var ma = new MemberAccess (this_access, f.name);
					ma.symbol_reference = f;
					ccode.add_expression (get_unref_expression (lhs, f.variable_type, ma));
				}
			}
		}

		// chain up to finalize function of the base class
		foreach (DataType base_type in cl.get_base_types ()) {
			var object_type = (ObjectType) base_type;
			if (object_type.type_symbol is Class) {
				var ccall = new CCodeFunctionCall (new CCodeIdentifier ("aroop_object_base_finalize"));
				var type_get_call = new CCodeFunctionCall (new CCodeIdentifier ("%s_type_get".printf (get_ccode_aroop_name (object_type.type_symbol))));
				foreach (var type_arg in base_type.get_type_arguments ()) {
					type_get_call.add_argument (get_type_id_expression (type_arg, false));
				}
				ccall.add_argument (type_get_call);
				ccall.add_argument (new CCodeIdentifier (self_instance));
				ccode.add_statement (new CCodeExpressionStatement (ccall));
			}
		}

		pop_function ();

		cfile.add_function (function);
	}

	public override void visit_class (Class cl) {
		push_context (new EmitContext (cl));

		add_pray_function (cl);
		add_class_system_init_function(cl);

		if (cl.is_internal_symbol ()) {
			generate_class_declaration (cl, cfile);
		} else {
			generate_class_declaration (cl, header_file);
		}

		cl.accept_children (this);
		pop_context ();
	}

	public override void visit_interface (Interface iface) {
		push_context (new EmitContext (iface));

		generate_interface_declaration (iface, cfile);

		iface.accept_children (this);

		pop_context ();
	}

#if false
	public override void generate_property_accessor_declaration (PropertyAccessor acc, CCodeFile decl_space) {
		if (add_symbol_declaration (decl_space, acc.prop, get_ccode_name (acc))) {
			return;
		}

		var prop = (Property) acc.prop;

		generate_type_declaration (acc.value_type, decl_space);

		CCodeFunction function;

		if (acc.readable) {
			function = new CCodeFunction (get_ccode_name (acc), get_ccode_aroop_name (acc.value_type));
		} else {
			function = new CCodeFunction (get_ccode_name (acc), "void");
		}

		if (prop.binding == MemberBinding.INSTANCE) {
			DataType this_type;
			if (prop.parent_symbol is Struct) {
				var st = (Struct) prop.parent_symbol;
				this_type = SemanticAnalyzer.get_data_type_for_symbol (st);
			} else {
				var t = (ObjectTypeSymbol) prop.parent_symbol;
				this_type = new ObjectType (t);
			}

			generate_type_declaration (this_type, decl_space);
			var cselfparam = new CCodeParameter (self_instance, get_ccode_aroop_name (this_type));

			function.add_parameter (cselfparam);
		}

		if (acc.writable) {
			var cvalueparam = new CCodeParameter ("value", get_ccode_aroop_name (acc.value_type));
			function.add_parameter (cvalueparam);
		}

		if (prop.is_internal_symbol () || acc.is_internal_symbol ()) {
			function.modifiers |= CCodeModifiers.STATIC;
		}
		decl_space.add_function_declaration (function);

		if (prop.is_abstract || prop.is_virtual) {
			string param_list = "(%s *this".printf (get_ccode_aroop_name (prop.parent_symbol));
			if (!acc.readable) {
				param_list += ", ";
				param_list += get_ccode_aroop_name (acc.value_type);
			}
			param_list += ")";

			var override_func = new CCodeFunction ("%soverride_%s_%s".printf (get_ccode_lower_case_prefix (prop.parent_symbol), acc.readable ? "get" : "set", prop.name));
			override_func.add_parameter (new CCodeParameter ("type", get_aroop_type_cname()));
			override_func.add_parameter (new CCodeParameter ("(*function) %s".printf (param_list), acc.readable ? get_ccode_aroop_name (acc.value_type) : "void"));

			decl_space.add_function_declaration (override_func);
		}
	}
#endif

	public override void visit_property_accessor (PropertyAccessor acc) {
	}

	public override void generate_interface_declaration (Interface iface, CCodeFile decl_space) {
		if (add_symbol_declaration (decl_space, iface, get_ccode_lower_case_name (iface))) {
			return;
		}
		decl_space.add_type_declaration(new CCodeTypeDefinition ("void*", new CCodeVariableDeclarator (get_ccode_aroop_name (iface))));

#if false
		var vtable_struct = new CCodeStruct ("aroop_iface_vtable_%s".printf (get_ccode_aroop_name (iface)));
		foreach (Method m in iface.get_methods ()) {
			generate_virtual_method_declaration (m, decl_space, vtable_struct);
		}
		// typedef to AroopObject instead of dummy struct to avoid warnings/casts
		generate_class_declaration (object_class, decl_space);
#endif
	}


	public override bool method_has_wrapper (Method method) {
		return (method.get_attribute ("NoWrapper") == null);
	}

	public override string? get_custom_creturn_type (Method m) {
		var attr = m.get_attribute ("CCode");
		if (attr != null) {
			string type = attr.get_string ("type");
			if (type != null) {
				return type;
			}
		}
		return null;
	}

	public override void generate_method_declaration (Method m, CCodeFile decl_space) {
		if (add_symbol_declaration (decl_space, m, get_ccode_name (m))) {
			return;
		}

		if (m.is_abstract || m.is_virtual) {
			// TODO remove the __VA_ARGS__ for single argument function
			int count = m.get_parameters().size;
			var macro_function = "%s(x".printf(get_ccode_name(m));
			var macro_body = "((%s*)x)->vtable->%s(x".printf(get_ccode_aroop_name((Class) m.parent_symbol), m.name);
			if(count != 0) {
				macro_function += ", ...";
				macro_body += ", __VA_ARGS__";
			}
			var func_macro = new CCodeMacroReplacement(macro_function + ")", macro_body + ")");
			decl_space.add_type_declaration (func_macro);
		} else {
			var function = new CCodeFunction (get_ccode_name (m));

			if (m.is_internal_symbol ()) {
				function.modifiers |= CCodeModifiers.STATIC;
				if (m.is_inline) {
					function.modifiers |= CCodeModifiers.INLINE;
				}
			}

			generate_cparameters (m, decl_space, function, null, new CCodeFunctionCall (new CCodeIdentifier ("fake")));

			decl_space.add_function_declaration (function);
		}
		if (m is CreationMethod && m.parent_symbol is Class) {
			generate_class_declaration ((Class) m.parent_symbol, decl_space);

			// _init function
			var function = new CCodeFunction (get_ccode_real_name (m));

			if (m.is_internal_symbol ()) {
				function.modifiers |= CCodeModifiers.STATIC;
			}

			generate_cparameters (m, decl_space, function);

			decl_space.add_function_declaration (function);
		}
	}

	public override void visit_creation_method (CreationMethod m) {
		bool visible = !m.is_internal_symbol ();

		visit_method (m);

		DataType creturn_type;
		if (current_type_symbol is Class) {
			creturn_type = new ObjectType (current_class);
		} else {
			creturn_type = new VoidType ();
		}

		// do not generate _new functions for creation methods of abstract classes
		if (current_type_symbol is Class && !current_class.is_abstract) {
			var vfunc = new CCodeFunction (get_ccode_name (m));

			var vblock = new CCodeBlock ();

			var cdecl = new CCodeDeclaration ("%s *".printf (get_ccode_aroop_name (current_type_symbol)));
			cdecl.add_declarator (new CCodeVariableDeclarator (self_instance));
			vblock.add_statement (cdecl);

			var alloc_call = new CCodeFunctionCall (new CCodeIdentifier ("aroop_object_alloc"));
			alloc_call.add_argument (new CCodeIdentifier ("sizeof(struct _%s)".printf (get_ccode_aroop_name(current_class))));
			alloc_call.add_argument (new CCodeIdentifier("%spray".printf (get_ccode_lower_case_prefix (current_class))));
			vblock.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeIdentifier (self_instance), new CCodeCastExpression (alloc_call, "%s *".printf (get_ccode_aroop_name (current_type_symbol))))));

#if false
			// allocate memory for fields of generic types
			// this is only a temporary measure until this can be allocated inline at the end of the instance
			// this also won't work for subclasses of classes that have fields of generic types
			foreach (var f in current_class.get_fields ()) {
				if (f.binding != MemberBinding.INSTANCE || !(f.variable_type is GenericType)) {
					continue;
				}

				var generic_type = (GenericType) f.variable_type;
				var type_get_value_size = new CCodeFunctionCall (new CCodeIdentifier ("aroop_type_get_value_size"));
				type_get_value_size.add_argument (new CCodeIdentifier ("%s_type".printf (generic_type.type_parameter.name.down ())));

				var calloc_call = new CCodeFunctionCall (new CCodeIdentifier ("calloc"));
				calloc_call.add_argument (new CCodeConstant ("1"));
				calloc_call.add_argument (type_get_value_size);
				var priv_call = new CCodeFunctionCall (new CCodeIdentifier ("%s_GET_PRIVATE".printf (get_ccode_upper_case_name (current_class, null))));
				priv_call.add_argument (new CCodeIdentifier (self_instance));

				vblock.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeMemberAccess.pointer (priv_call, f.name), calloc_call)));
			}
#else
			int i = 0;
			foreach (var generic_type in  current_class.get_type_parameters ()) {
			//foreach (var f in current_class.get_fields ()) {
				//if (f.binding != MemberBinding.INSTANCE || !(f.variable_type is GenericType)) {
					//continue;
				//}
				
				//var generic_type = (GenericType) f.variable_type;
				vblock.add_statement (
					new CCodeExpressionStatement (
						new CCodeAssignment (
							new CCodeMemberAccess.pointer (new CCodeIdentifier (self_instance), get_generic_class_variable_cname(i))
							, new CCodeConstant("g_type")
						)
					)
				);
				i++;
			}
#endif

			var vcall = new CCodeFunctionCall (new CCodeIdentifier (get_ccode_real_name (m)));
			vcall.add_argument (new CCodeIdentifier (self_instance));
			if(m.tree_can_fail) {
				vcall.add_argument (new CCodeIdentifier ("_err"));
			}
			vblock.add_statement (new CCodeExpressionStatement (vcall));

			generate_cparameters (m, cfile, vfunc, null, vcall);
			CCodeStatement cstmt = new CCodeReturnStatement (new CCodeIdentifier (self_instance));
			cstmt.line = vfunc.line;
			vblock.add_statement (cstmt);

			if (!visible) {
				vfunc.modifiers |= CCodeModifiers.STATIC;
			}

			cfile.add_function_declaration (vfunc);

			vfunc.block = vblock;

			cfile.add_function (vfunc);
		}
	}

	private TypeSymbol? find_parent_type (Symbol sym) {
		while (sym != null) {
			if (sym is TypeSymbol) {
				return (TypeSymbol) sym;
			}
			sym = sym.parent_symbol;
		}
		return null;
	}

	public override void generate_cparameters (Method m, CCodeFile decl_space, CCodeFunction func, CCodeFunctionDeclarator? vdeclarator = null, CCodeFunctionCall? vcall = null) {
		CCodeParameter instance_param = null;
		if (m.closure) {
			var closure_block = current_closure_block;
			instance_param = new CCodeParameter (
				generate_block_var_name (closure_block)
				, generate_block_name (closure_block) + "*");
		} else if (m.parent_symbol is Class && m is CreationMethod) {
			if (vcall == null) {
				instance_param = new CCodeParameter (self_instance, get_ccode_aroop_name (((Class) m.parent_symbol)) + "*");
			}
		} else if (m.binding == MemberBinding.INSTANCE) {
			TypeSymbol parent_type = find_parent_type (m);
			var this_type = get_data_type_for_symbol (parent_type);

			generate_type_declaration (this_type, decl_space);

			if (m.base_interface_method != null && !m.is_abstract && !m.is_virtual) {
				var base_type = new ObjectType ((Interface) m.base_interface_method.parent_symbol);
				instance_param = new CCodeParameter ("base_instance", get_ccode_aroop_name (base_type));
			} else if (m.overrides) {
				var base_type = new ObjectType ((Class) m.base_method.parent_symbol);
				generate_type_declaration (base_type, decl_space);
				instance_param = new CCodeParameter ("base_instance", get_ccode_aroop_name (base_type));
			} else {
				if (m.parent_symbol is Struct) {
					instance_param = generate_instance_cparameter_for_struct(m, instance_param, this_type);
				} else {
					instance_param = new CCodeParameter (self_instance, get_ccode_aroop_name (this_type));
				}
			}
		}
		if (instance_param != null) {
			func.add_parameter (instance_param);
			if (vdeclarator != null) {
				vdeclarator.add_parameter (instance_param);
			}
		}

		if (m is CreationMethod) {
			generate_class_declaration ((Class) type_class, decl_space);

			if (m.parent_symbol is Class) {
				var cl = (Class) m.parent_symbol;
				foreach (TypeParameter type_param in cl.get_type_parameters ()) {
					var cparam = new CCodeParameter ("%s_type".printf (type_param.name.down ()), get_aroop_type_cname());
					if (vcall != null) {
						func.add_parameter (cparam);
					}
				}
			}
		} else {
			foreach (TypeParameter type_param in m.get_type_parameters ()) {
				var cparam = new CCodeParameter ("%s_type".printf (type_param.name.down ()), get_aroop_type_cname());
				func.add_parameter (cparam);
				if (vdeclarator != null) {
					vdeclarator.add_parameter (cparam);
				}
				if (vcall != null) {
					vcall.add_argument (new CCodeIdentifier ("%s_type".printf (type_param.name.down ())));
				}
			}
		}

		foreach (Parameter param in m.get_parameters ()) {
			CCodeParameter cparam;
			if (!param.ellipsis) {
				string ctypename = get_ccode_aroop_name (param.variable_type);

				generate_type_declaration (param.variable_type, decl_space);

				if (param.direction != ParameterDirection.IN && !(param.variable_type is GenericType)) {
					ctypename += "*";
				}

				cparam = new CCodeParameter (get_variable_cname (param.name), ctypename);
			} else {
				cparam = new CCodeParameter.with_ellipsis ();
			}

			func.add_parameter (cparam);
			if (vdeclarator != null) {
				vdeclarator.add_parameter (cparam);
			}
			if (param.variable_type is DelegateType) {
				CCodeParameter xparam = new CCodeParameter (get_variable_cname (param.name)+"_closure_data", "void*");
				func.add_parameter (xparam);
				if (vdeclarator != null) {
					vdeclarator.add_parameter (xparam);
				}
			}
			
			
			if (vcall != null) {
				if (param.name != null) {
					vcall.add_argument (get_variable_cexpression (param.name));
				}
			}
		}

		if (m.parent_symbol is Class && m is CreationMethod && vcall != null) {
			func.return_type = get_ccode_aroop_name (((Class) m.parent_symbol)) + "*";
		} else {
			if (m.return_type is GenericType) {
				func.add_parameter (new CCodeParameter ("result", "void **"));
				if (vdeclarator != null) {
					vdeclarator.add_parameter (new CCodeParameter ("result", "void **"));
				}
			} else {
				var st = m.parent_symbol as Struct;
				if (m is CreationMethod && st != null && (st.is_boolean_type () || st.is_integer_type () || st.is_floating_type ())) {
					func.return_type = get_ccode_aroop_name (st);
				} else {
					func.return_type = get_ccode_aroop_name (m.return_type);
				}
			}

			generate_type_declaration (m.return_type, decl_space);
		}
		
		if(m.tree_can_fail) {
			var cparam = new CCodeParameter ("_err", "aroop_wrong**");
			current_method_inner_error = true;

			func.add_parameter (cparam);
			if (vdeclarator != null) {
				vdeclarator.add_parameter (cparam);
			}
		}
	}

	public override void visit_element_access (ElementAccess expr) {
		var array_type = expr.container.value_type as ArrayType;
		if (array_type != null) {
			// access to element in an array

			expr.accept_children (this);

			List<Expression> indices = expr.get_indices ();
			var cindex = get_cvalue (indices[0]);

			if (array_type.inline_allocated) {
				if (array_type.element_type is GenericType) {
					// generic array
					// calculate offset in bytes based on value size
					var value_size = new CCodeFunctionCall (new CCodeIdentifier ("aroop_type_get_value_size"));
					value_size.add_argument (get_type_id_expression (array_type.element_type));
					set_cvalue (expr, new CCodeBinaryExpression (CCodeBinaryOperator.PLUS, new CCodeCastExpression (get_cvalue (expr.container), "char*"), new CCodeBinaryExpression (CCodeBinaryOperator.MUL, value_size, cindex)));
				} else {
					set_cvalue (expr, new CCodeElementAccess (get_cvalue (expr.container), cindex));
				}
			} else {
				var ccontainer = get_cvalue (expr.container);

				if (array_type.element_type is GenericType) {
					// generic array
					// calculate offset in bytes based on value size
					var value_size = new CCodeFunctionCall (new CCodeIdentifier ("aroop_type_get_value_size"));
					value_size.add_argument (get_type_id_expression (array_type.element_type));
					set_cvalue (expr, new CCodeBinaryExpression (CCodeBinaryOperator.PLUS, new CCodeCastExpression (ccontainer, "char*"), new CCodeBinaryExpression (CCodeBinaryOperator.MUL, value_size, cindex)));
				} else {
					set_cvalue (expr, new CCodeElementAccess (new CCodeCastExpression (ccontainer, "%s*".printf (get_ccode_aroop_name (array_type.element_type))), cindex));
				}
			}

		} else {
			base.visit_element_access (expr);
		}
	}
}
