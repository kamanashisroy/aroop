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
	public override void generate_class_declaration (Class cl, CCodeFile decl_space) {
		if (add_symbol_declaration (decl_space, cl, get_ccode_lower_case_name (cl))) {
			return;
		}

		decl_space.add_type_declaration(new CCodeTypeDefinition ("struct _%s,".printf (get_ccode_aroop_name (cl)), new CCodeVariableDeclarator (get_ccode_aroop_name (cl))));

		generate_vtable(cl, decl_space);

		var class_struct = new CCodeStruct ("_%s".printf (get_ccode_aroop_name (cl)));
		if (cl.base_class != null) {
			class_struct.add_field ("%s".printf(get_ccode_aroop_name (cl.base_class)), "super_data");
		}
		foreach (Field f in cl.get_fields ()) {
			if (f.binding == MemberBinding.INSTANCE)  {
				generate_type_declaration (f.variable_type, decl_space);

				string field_ctype = get_ccode_aroop_name (f.variable_type);
				if (f.is_volatile) {
					field_ctype = "volatile " + field_ctype;
				}

				class_struct.add_field (field_ctype, get_ccode_name (f) + get_ccode_declarator_suffix (f.variable_type));
			}
		}
		// TODO do something when there is no vtable ..
		class_struct.add_field ("struct aroop_vtable_%s*".printf(get_ccode_aroop_name (cl)), "vtable");
		decl_space.add_type_definition (class_struct);
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

	CCodeFunction create_set_value_equals_function (bool decl_only = false) {
		var result = new CCodeFunction ("aroop_type_set_value_equals");
		result.add_parameter (new CCodeParameter ("type", "AroopType *"));
		result.add_parameter (new CCodeParameter ("(*function) (void *value, intptr_t value_index, void *other, intptr_t other_index)", "bool"));
		if (decl_only) {
			return result;
		}

		result.block = new CCodeBlock ();

		var priv_call = new CCodeFunctionCall (new CCodeIdentifier ("DOVA_TYPE_GET_PRIVATE"));
		priv_call.add_argument (new CCodeIdentifier ("type"));

		result.block.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeMemberAccess.pointer (priv_call, "value_equals"), new CCodeIdentifier ("function"))));
		return result;
	}

	public void declare_set_value_equals_function (CCodeFile decl_space) {
		if (add_symbol_declaration (decl_space, type_class, "aroop_type_set_value_equals")) {
			return;
		}
		decl_space.add_function_declaration (create_set_value_equals_function (true));
	}

	CCodeFunction create_set_value_hash_function (bool decl_only = false) {
		var result = new CCodeFunction ("aroop_type_set_value_hash");
		result.add_parameter (new CCodeParameter ("type", "AroopType *"));
		result.add_parameter (new CCodeParameter ("(*function) (void *value, intptr_t value_index)", "uintptr_t"));
		if (decl_only) {
			return result;
		}

		result.block = new CCodeBlock ();

		var priv_call = new CCodeFunctionCall (new CCodeIdentifier ("DOVA_TYPE_GET_PRIVATE"));
		priv_call.add_argument (new CCodeIdentifier ("type"));

		result.block.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeMemberAccess.pointer (priv_call, "value_hash"), new CCodeIdentifier ("function"))));
		return result;
	}

#if 0
	public void declare_set_value_hash_function (CCodeFile decl_space) {
		if (add_symbol_declaration (decl_space, type_class, "aroop_type_set_value_hash")) {
			return;
		}
		decl_space.add_function_declaration (create_set_value_hash_function (true));
	}
#endif

	CCodeFunction create_set_value_to_any_function (bool decl_only = false) {
		var result = new CCodeFunction ("aroop_type_set_value_to_any");
		result.add_parameter (new CCodeParameter ("type", "AroopType *"));
		result.add_parameter (new CCodeParameter ("(*function) (void *value, intptr_t value_index)", "AroopObject *"));
		if (decl_only) {
			return result;
		}

		result.block = new CCodeBlock ();

		var priv_call = new CCodeFunctionCall (new CCodeIdentifier ("DOVA_TYPE_GET_PRIVATE"));
		priv_call.add_argument (new CCodeIdentifier ("type"));

		result.block.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeMemberAccess.pointer (priv_call, "value_to_any"), new CCodeIdentifier ("function"))));
		return result;
	}

	CCodeFunction create_set_value_from_any_function (bool decl_only = false) {
		var result = new CCodeFunction ("aroop_type_set_value_from_any");
		result.add_parameter (new CCodeParameter ("type", "AroopType *"));
		result.add_parameter (new CCodeParameter ("(*function) (AroopObject *any, void *value, intptr_t value_index)", "void"));
		if (decl_only) {
			return result;
		}

		result.block = new CCodeBlock ();

		var priv_call = new CCodeFunctionCall (new CCodeIdentifier ("DOVA_TYPE_GET_PRIVATE"));
		priv_call.add_argument (new CCodeIdentifier ("type"));

		result.block.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeMemberAccess.pointer (priv_call, "value_from_any"), new CCodeIdentifier ("function"))));
		return result;
	}

	private void generate_vtable(Class cl, CCodeFile decl_space) {
		var vtable_struct = new CCodeStruct ("aroop_vtable_%s".printf (get_ccode_aroop_name (cl)));
		foreach (Method m in cl.get_methods ()) {
			generate_virtual_method_declaration (m, decl_space, vtable_struct);
		}
		decl_space.add_type_definition (vtable_struct);
	}

	private void add_class_system_init_prepare(Class cl, Class of_class) {
		var vdecl = new CCodeDeclaration ("struct aroop_vtable_%s".printf (get_ccode_aroop_name(of_class)));
		vdecl.add_declarator (new CCodeVariableDeclarator ("vtable_%sovrd_%s".printf(get_ccode_lower_case_prefix(cl), get_ccode_aroop_name(of_class))));
		cfile.add_type_member_declaration(vdecl);
	}

	private void add_class_system_init_function(Class cl) {
		// create the vtable instances
		add_class_system_init_prepare(cl, cl);
		foreach (DataType base_type in cl.get_base_types ()) {
			var object_type = (ObjectType) base_type;
			if (object_type.type_symbol is Class) {
				add_class_system_init_prepare(cl, ((Class)object_type.type_symbol));
			}
		}

		var ifunc = new CCodeFunction ("%stype_system_init".printf (get_ccode_lower_case_prefix (cl)), "int");
		push_function (ifunc); // XXX I do not know what push does 

		cfile.add_function_declaration (ifunc);

		pop_function (); // XXX I do not know what pop does 

		// Now add definition
		var iblock = new CCodeBlock ();

		// bool done = false;
		var cdone = new CCodeDeclaration ("bool");
		cdone.add_declarator (new CCodeVariableDeclarator ("done", new CCodeConstant ("false")));
		cdone.modifiers = CCodeModifiers.STATIC;
		iblock.add_statement (cdone);

		var finish = new CCodeReturnStatement(new CCodeConstant ("0"));
		// check if we are already initiated ..
		iblock.add_statement (new CCodeIfStatement(new CCodeIdentifier ("done"), finish));
		// copy vtable from base class
		var some_parent_type = (ObjectType)null;
		foreach (DataType base_type in cl.get_base_types ()) {
			var object_type = (ObjectType) base_type;
			if (object_type.type_symbol is Class) {
				if(some_parent_type == null) {
					some_parent_type = object_type;
					// ask for initiation of super class ..
					iblock.add_statement(new CCodeExpressionStatement (new CCodeFunctionCall (new CCodeIdentifier ("%stype_system_init".printf (get_ccode_lower_case_prefix ((Class)object_type.type_symbol))))));
				}
				iblock.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeIdentifier ("vtable_%sovrd_%s".printf(get_ccode_lower_case_prefix(cl), get_ccode_aroop_name((Class) object_type.type_symbol))), new CCodeIdentifier ("vtable_%sovrd_%s".printf( get_ccode_lower_case_prefix((Class) some_parent_type.type_symbol), get_ccode_aroop_name((Class) object_type.type_symbol) ) ))));
			}
		}

		// prepare our vtable
		foreach (Method m in cl.get_methods ()) {
			if (m.is_virtual || m.overrides) {
				iblock.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeIdentifier ("vtable_%sovrd_%s.%s".printf(get_ccode_lower_case_prefix(cl), get_ccode_aroop_name((Class) m.base_method.parent_symbol), get_ccode_vfunc_name (m))), new CCodeIdentifier ( get_ccode_real_name (m) ))));
			}
		}

		iblock.add_statement(new CCodeExpressionStatement(new CCodeAssignment (new CCodeIdentifier ("done"), new CCodeConstant ("true"))));
		iblock.add_statement (finish);
		ifunc.block = iblock;
		cfile.add_function (ifunc);
	}

	private void add_pray_function (Class cl) {
		var function = new CCodeFunction ("%spray".printf (get_ccode_lower_case_prefix (cl)), "void");
		function.modifiers = CCodeModifiers.STATIC;

		function.add_parameter (new CCodeParameter ("data", "God*"));
		function.add_parameter (new CCodeParameter ("callback", "int"));
		function.add_parameter (new CCodeParameter ("cb_data", "void*"));
		function.add_parameter (new CCodeParameter ("va_list", "ap"));
		function.add_parameter (new CCodeParameter ("size", "int"));

		push_function (function); // XXX I do not know what push does 

		cfile.add_function_declaration (function);

		pop_function (); // XXX I do not know what pop does 

		// Now add definition
		var vblock = new CCodeBlock ();

		var stat = new CCodeDeclaration ("%s *".printf (get_ccode_aroop_name(cl)));
		stat.add_declarator (new CCodeVariableDeclarator ("this"));
		vblock.add_statement (stat);

		var assign_stat = new CCodeIdentifier ("data");
		vblock.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeIdentifier ("this"), new CCodeCastExpression (assign_stat, "%s *".printf (get_ccode_aroop_name(cl))))));

		var switch_stat = new CCodeSwitchStatement (new CCodeIdentifier ("callback"));
		switch_stat.add_statement (new CCodeCaseStatement(new CCodeIdentifier ("OPPN_ACTION_INITIALIZE")));
		switch_stat.add_statement(new CCodeExpressionStatement (new CCodeFunctionCall (new CCodeIdentifier ("%stype_system_init".printf (get_ccode_lower_case_prefix (cl))))));

		// assign vtables
		foreach (DataType base_type in cl.get_base_types ()) {
			var object_type = (ObjectType) base_type;
			if (object_type.type_symbol is Class) {
				switch_stat.add_statement (new CCodeExpressionStatement (new CCodeAssignment(new CCodeIdentifier ("(%s)this->vtable".printf(get_ccode_aroop_name(((Class)object_type.type_symbol)))), new CCodeIdentifier ("&vtable_%sovrd_%s".printf(get_ccode_lower_case_prefix(cl), get_ccode_aroop_name(((Class)object_type.type_symbol)))))));
			}
		}
		switch_stat.add_statement (new CCodeExpressionStatement (new CCodeAssignment(new CCodeIdentifier ("this->vtable"), new CCodeIdentifier ("&vtable_%sovrd_%s".printf(get_ccode_lower_case_prefix(cl), get_ccode_aroop_name(cl))))));


		switch_stat.add_statement (new CCodeBreakStatement());
		switch_stat.add_statement (new CCodeCaseStatement(new CCodeIdentifier ("OPPN_ACTION_FINALIZE")));
		switch_stat.add_statement (new CCodeBreakStatement());
		vblock.add_statement (switch_stat);

		vblock.add_statement (new CCodeReturnStatement(new CCodeConstant ("0")));

		function.block = vblock;

		cfile.add_function (function);

	}


	void add_finalize_function (Class cl) {
		var function = new CCodeFunction ("%sfinalize".printf (get_ccode_lower_case_prefix (cl)), "void");
		function.modifiers = CCodeModifiers.STATIC;

		function.add_parameter (new CCodeParameter ("this", get_ccode_aroop_name (cl) + "*"));

		push_function (function);

		cfile.add_function_declaration (function);

		if (cl.destructor != null) {
			cl.destructor.body.emit (this);
		}

		foreach (var f in cl.get_fields ()) {
			if (f.binding == MemberBinding.INSTANCE)  {
				CCodeExpression lhs = null;
				if (f.is_internal_symbol ()) {
					var priv_call = new CCodeFunctionCall (new CCodeIdentifier ("%s_GET_PRIVATE".printf (get_ccode_upper_case_name (cl, null))));
					priv_call.add_argument (new CCodeIdentifier ("this"));
					lhs = new CCodeMemberAccess.pointer (priv_call, get_ccode_name (f));
				} else {
					lhs = new CCodeMemberAccess.pointer (new CCodeIdentifier ("this"), get_ccode_name (f));
				}

				if (requires_destroy (f.variable_type)) {
					var this_access = new MemberAccess.simple ("this");
					this_access.value_type = get_data_type_for_symbol ((TypeSymbol) f.parent_symbol);

					var field_st = f.parent_symbol as Struct;
					if (field_st != null && !field_st.is_simple_type ()) {
						set_cvalue (this_access, new CCodeIdentifier ("(*this)"));
					} else {
						set_cvalue (this_access, new CCodeIdentifier ("this"));
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
				ccall.add_argument (new CCodeIdentifier ("this"));
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
		generate_class_declaration (cl, cfile);

		if (!cl.is_internal_symbol ()) {
			generate_class_declaration (cl, header_file);
		}

		cl.accept_children (this);

#if 0
		var type_init_block = generate_type_get_function (cl, cl.base_class);

		foreach (DataType base_type in cl.get_base_types ()) {
			var object_type = (ObjectType) base_type;
			if (object_type.type_symbol is Interface) {
				generate_interface_declaration ((Interface) object_type.type_symbol, cfile);

				var type_init_call = new CCodeFunctionCall (new CCodeIdentifier ("%s_type_init".printf (get_ccode_arolower_case_name (object_type.type_symbol))));
				type_init_call.add_argument (new CCodeIdentifier ("type"));
				foreach (var type_arg in base_type.get_type_arguments ()) {
					type_init_call.add_argument (get_type_id_expression (type_arg, true));
				}
				type_init_block.add_statement (new CCodeExpressionStatement (type_init_call));
			}
		}

		// finalizer
		if (cl.base_class != null && !cl.is_fundamental () && (cl.get_fields ().size > 0 || cl.destructor != null)) {
			add_finalize_function (cl);

			generate_method_declaration ((Method) object_class.scope.lookup ("finalize"), cfile);

			var override_call = new CCodeFunctionCall (new CCodeIdentifier ("aroop_object_override_finalize"));
			override_call.add_argument (new CCodeIdentifier ("type"));
			override_call.add_argument (new CCodeIdentifier ("%sfinalize".printf (get_ccode_lower_case_prefix (cl))));
			type_init_block.add_statement (new CCodeExpressionStatement (override_call));
		}
#if 0
		foreach (Method m in cl.get_methods ()) {
			if (m.is_virtual || m.overrides) {
				var override_call = new CCodeFunctionCall (new CCodeIdentifier ("%soverride_%s".printf (get_ccode_lower_case_prefix (m.base_method.parent_symbol), m.name)));
				override_call.add_argument (new CCodeIdentifier ("type"));
				override_call.add_argument (new CCodeIdentifier (get_ccode_real_name (m)));
				type_init_block.add_statement (new CCodeExpressionStatement (override_call));
			} else if (m.base_interface_method != null) {
				var override_call = new CCodeFunctionCall (new CCodeIdentifier ("%soverride_%s".printf (get_ccode_lower_case_prefix (m.base_interface_method.parent_symbol), m.name)));
				override_call.add_argument (new CCodeIdentifier ("type"));
				override_call.add_argument (new CCodeIdentifier (get_ccode_real_name (m)));
				type_init_block.add_statement (new CCodeExpressionStatement (override_call));
			}
		}
#endif
		foreach (Property prop in cl.get_properties ()) {
			if (prop.is_virtual || prop.overrides) {
				if (prop.get_accessor != null) {
					var override_call = new CCodeFunctionCall (new CCodeIdentifier ("%soverride_get_%s".printf (get_ccode_lower_case_prefix (prop.base_property.parent_symbol), prop.name)));
					override_call.add_argument (new CCodeIdentifier ("type"));
					override_call.add_argument (new CCodeIdentifier (get_ccode_name (prop.get_accessor)));
					type_init_block.add_statement (new CCodeExpressionStatement (override_call));
				}
				if (prop.set_accessor != null) {
					var override_call = new CCodeFunctionCall (new CCodeIdentifier ("%soverride_set_%s".printf (get_ccode_lower_case_prefix (prop.base_property.parent_symbol), prop.name)));
					override_call.add_argument (new CCodeIdentifier ("type"));
					override_call.add_argument (new CCodeIdentifier (get_ccode_name (prop.set_accessor)));
					type_init_block.add_statement (new CCodeExpressionStatement (override_call));
				}
			}
		}

		if (cl == type_class) {
			var priv_call = new CCodeFunctionCall (new CCodeIdentifier ("DOVA_TYPE_GET_PRIVATE"));
			priv_call.add_argument (new CCodeIdentifier ("type"));

			var value_copy_function = new CCodeFunction ("aroop_type_value_copy");
			value_copy_function.add_parameter (new CCodeParameter ("type", "AroopType *"));
			value_copy_function.add_parameter (new CCodeParameter ("dest", "void *"));
			value_copy_function.add_parameter (new CCodeParameter ("dest_index", "intptr_t"));
			value_copy_function.add_parameter (new CCodeParameter ("src", "void *"));
			value_copy_function.add_parameter (new CCodeParameter ("src_index", "intptr_t"));

			value_copy_function.block = new CCodeBlock ();

			var ccall = new CCodeFunctionCall (new CCodeMemberAccess.pointer (priv_call, "value_copy"));
			ccall.add_argument (new CCodeIdentifier ("dest"));
			ccall.add_argument (new CCodeIdentifier ("dest_index"));
			ccall.add_argument (new CCodeIdentifier ("src"));
			ccall.add_argument (new CCodeIdentifier ("src_index"));
			value_copy_function.block.add_statement (new CCodeExpressionStatement (ccall));

			cfile.add_function (value_copy_function);

			declare_set_value_copy_function (cfile);
			declare_set_value_copy_function (header_file);
			cfile.add_function (create_set_value_copy_function ());

			var value_equals_function = new CCodeFunction ("aroop_type_value_equals", "bool");
			value_equals_function.add_parameter (new CCodeParameter ("type", "AroopType *"));
			value_equals_function.add_parameter (new CCodeParameter ("value", "void *"));
			value_equals_function.add_parameter (new CCodeParameter ("value_index", "intptr_t"));
			value_equals_function.add_parameter (new CCodeParameter ("other", "void *"));
			value_equals_function.add_parameter (new CCodeParameter ("other_index", "intptr_t"));

			value_equals_function.block = new CCodeBlock ();

			ccall = new CCodeFunctionCall (new CCodeMemberAccess.pointer (priv_call, "value_equals"));
			ccall.add_argument (new CCodeIdentifier ("value"));
			ccall.add_argument (new CCodeIdentifier ("value_index"));
			ccall.add_argument (new CCodeIdentifier ("other"));
			ccall.add_argument (new CCodeIdentifier ("other_index"));
			value_equals_function.block.add_statement (new CCodeReturnStatement (ccall));

			cfile.add_function (value_equals_function);

			declare_set_value_equals_function (cfile);
			declare_set_value_equals_function (header_file);
			cfile.add_function (create_set_value_equals_function ());

			var value_hash_function = new CCodeFunction ("aroop_type_value_hash", "uintptr_t");
			value_hash_function.add_parameter (new CCodeParameter ("type", "AroopType *"));
			value_hash_function.add_parameter (new CCodeParameter ("value", "void *"));
			value_hash_function.add_parameter (new CCodeParameter ("value_index", "intptr_t"));

			value_hash_function.block = new CCodeBlock ();

			ccall = new CCodeFunctionCall (new CCodeMemberAccess.pointer (priv_call, "value_hash"));
			ccall.add_argument (new CCodeIdentifier ("value"));
			ccall.add_argument (new CCodeIdentifier ("value_index"));
			value_hash_function.block.add_statement (new CCodeReturnStatement (ccall));

			cfile.add_function (value_hash_function);

			declare_set_value_hash_function (cfile);
			declare_set_value_hash_function (header_file);
			cfile.add_function (create_set_value_hash_function ());

			var value_to_any_function = new CCodeFunction ("aroop_type_value_to_any", "AroopObject *");
			value_to_any_function.add_parameter (new CCodeParameter ("type", "AroopType *"));
			value_to_any_function.add_parameter (new CCodeParameter ("value", "void *"));
			value_to_any_function.add_parameter (new CCodeParameter ("value_index", "intptr_t"));

			value_to_any_function.block = new CCodeBlock ();

			ccall = new CCodeFunctionCall (new CCodeMemberAccess.pointer (priv_call, "value_to_any"));
			ccall.add_argument (new CCodeIdentifier ("value"));
			ccall.add_argument (new CCodeIdentifier ("value_index"));
			value_to_any_function.block.add_statement (new CCodeReturnStatement (ccall));

			cfile.add_function (value_to_any_function);

			declare_set_value_to_any_function (cfile);
			declare_set_value_to_any_function (header_file);
			cfile.add_function (create_set_value_to_any_function ());

			var value_from_any_function = new CCodeFunction ("aroop_type_value_from_any", "void");
			value_from_any_function.add_parameter (new CCodeParameter ("type", "AroopType *"));
			value_from_any_function.add_parameter (new CCodeParameter ("any_", "any *"));
			value_from_any_function.add_parameter (new CCodeParameter ("value", "void *"));
			value_from_any_function.add_parameter (new CCodeParameter ("value_index", "intptr_t"));

			value_from_any_function.block = new CCodeBlock ();

			ccall = new CCodeFunctionCall (new CCodeMemberAccess.pointer (priv_call, "value_from_any"));
			ccall.add_argument (new CCodeIdentifier ("any_"));
			ccall.add_argument (new CCodeIdentifier ("value"));
			ccall.add_argument (new CCodeIdentifier ("value_index"));
			value_from_any_function.block.add_statement (new CCodeReturnStatement (ccall));

			cfile.add_function (value_from_any_function);

			declare_set_value_from_any_function (cfile);
			declare_set_value_from_any_function (header_file);
			cfile.add_function (create_set_value_from_any_function ());
		}
#endif

		pop_context ();
	}

	public override void visit_interface (Interface iface) {
		push_context (new EmitContext (iface));

		generate_interface_declaration (iface, cfile);

		var type_priv_struct = new CCodeStruct ("_%sTypePrivate".printf (get_ccode_aroop_name (iface)));

		foreach (var type_param in iface.get_type_parameters ()) {
			var type_param_decl = new CCodeDeclaration ("AroopType *");
			type_param_decl.add_declarator (new CCodeVariableDeclarator ("%s_type".printf (type_param.name.down ())));
			type_priv_struct.add_declaration (type_param_decl);
		}

		foreach (Method m in iface.get_methods ()) {
			generate_virtual_method_declaration (m, cfile, type_priv_struct);
		}

		if (!type_priv_struct.is_empty) {
			cfile.add_type_declaration (new CCodeTypeDefinition ("struct %s".printf (type_priv_struct.name), new CCodeVariableDeclarator ("%sTypePrivate".printf (get_ccode_aroop_name (iface)))));
			cfile.add_type_definition (type_priv_struct);
		}

		var cdecl = new CCodeDeclaration ("AroopType *");
		cdecl.add_declarator (new CCodeVariableDeclarator ("%s_type".printf (get_ccode_aroop_name (iface)), new CCodeConstant ("NULL")));
		cdecl.modifiers = CCodeModifiers.STATIC;
		cfile.add_type_member_declaration (cdecl);

		var type_fun = new CCodeFunction ("%s_type_get".printf (get_ccode_aroop_name (iface)), "AroopType *");
		if (iface.is_internal_symbol ()) {
			type_fun.modifiers = CCodeModifiers.STATIC;
		}
		foreach (var type_param in iface.get_type_parameters ()) {
			type_fun.add_parameter (new CCodeParameter ("%s_type".printf (type_param.name.down ()), "AroopType *"));
		}
		type_fun.block = new CCodeBlock ();

		var type_init_block = new CCodeBlock ();

		var calloc_call = new CCodeFunctionCall (new CCodeIdentifier ("calloc"));
		calloc_call.add_argument (new CCodeConstant ("1"));

		if (!type_priv_struct.is_empty) {
			calloc_call.add_argument (new CCodeConstant ("aroop_type_get_type_size (aroop_type_type_get ()) + sizeof (%sTypePrivate)".printf (get_ccode_aroop_name (iface))));
		} else {
			calloc_call.add_argument (new CCodeConstant ("aroop_type_get_type_size (aroop_type_type_get ())"));
		}

		type_init_block.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeIdentifier ("%s_type".printf (get_ccode_aroop_name (iface))), calloc_call)));

		// call any_type_init to set value_copy and similar functions
		var any_type_init_call = new CCodeFunctionCall (new CCodeIdentifier ("any_type_init"));
		any_type_init_call.add_argument (new CCodeIdentifier ("%s_type".printf (get_ccode_aroop_name (iface))));
		type_init_block.add_statement (new CCodeExpressionStatement (any_type_init_call));

		var type_init_call = new CCodeFunctionCall (new CCodeIdentifier ("%s_type_init".printf (get_ccode_aroop_name (iface))));
		type_init_call.add_argument (new CCodeIdentifier ("%s_type".printf (get_ccode_aroop_name (iface))));
		foreach (var type_param in iface.get_type_parameters ()) {
			type_init_call.add_argument (new CCodeIdentifier ("%s_type".printf (type_param.name.down ())));
		}
		type_init_block.add_statement (new CCodeExpressionStatement (type_init_call));

		type_fun.block.add_statement (new CCodeIfStatement (new CCodeUnaryExpression (CCodeUnaryOperator.LOGICAL_NEGATION, new CCodeIdentifier ("%s_type".printf (get_ccode_aroop_name (iface)))), type_init_block));

		type_fun.block.add_statement (new CCodeReturnStatement (new CCodeIdentifier ("%s_type".printf (get_ccode_aroop_name (iface)))));

		cfile.add_function (type_fun);

		var type_init_fun = new CCodeFunction ("%s_type_init".printf (get_ccode_aroop_name (iface)));
		if (iface.is_internal_symbol ()) {
			type_init_fun.modifiers = CCodeModifiers.STATIC;
		}
		type_init_fun.add_parameter (new CCodeParameter ("type", "AroopType *"));
		foreach (var type_param in iface.get_type_parameters ()) {
			type_init_fun.add_parameter (new CCodeParameter ("%s_type".printf (type_param.name.down ()), "AroopType *"));
		}
		type_init_fun.block = new CCodeBlock ();

		foreach (DataType base_type in iface.get_prerequisites ()) {
			var object_type = (ObjectType) base_type;
			if (object_type.type_symbol is Interface) {
				type_init_call = new CCodeFunctionCall (new CCodeIdentifier ("%s_type_init".printf (get_ccode_aroop_name (object_type.type_symbol))));
				type_init_call.add_argument (new CCodeIdentifier ("type"));
				type_init_fun.block.add_statement (new CCodeExpressionStatement (type_init_call));
			}
		}

		var vtable_alloc = new CCodeFunctionCall (new CCodeIdentifier ("calloc"));
		vtable_alloc.add_argument (new CCodeConstant ("1"));
		vtable_alloc.add_argument (new CCodeConstant ("sizeof (%sTypePrivate)".printf (get_ccode_aroop_name (iface))));

		var type_get_call = new CCodeFunctionCall (new CCodeIdentifier ("%s_type_get".printf (get_ccode_aroop_name (iface))));
		foreach (var type_param in iface.get_type_parameters ()) {
			type_get_call.add_argument (new CCodeIdentifier ("%s_type".printf (type_param.name.down ())));
		}

		if (!type_priv_struct.is_empty) {
			var add_interface_call = new CCodeFunctionCall (new CCodeIdentifier ("aroop_type_add_interface"));
			add_interface_call.add_argument (new CCodeIdentifier ("type"));
			add_interface_call.add_argument (type_get_call);
			add_interface_call.add_argument (vtable_alloc);
			type_init_fun.block.add_statement (new CCodeExpressionStatement (add_interface_call));
		}

		cfile.add_function (type_init_fun);

		iface.accept_children (this);

		pop_context ();
	}

#if 0
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
			var cselfparam = new CCodeParameter ("this", get_ccode_aroop_name (this_type));

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
			override_func.add_parameter (new CCodeParameter ("type", "AroopType *"));
			override_func.add_parameter (new CCodeParameter ("(*function) %s".printf (param_list), acc.readable ? get_ccode_aroop_name (acc.value_type) : "void"));

			decl_space.add_function_declaration (override_func);
		}
	}
#endif

	public override void visit_property_accessor (PropertyAccessor acc) {
#if 0
		push_context (new EmitContext (acc));

		var prop = (Property) acc.prop;

		// do not declare overriding properties and interface implementations
		if (prop.is_abstract || prop.is_virtual
		    || (prop.base_property == null && prop.base_interface_property == null)) {
			generate_property_accessor_declaration (acc, cfile);

			if (!prop.is_internal_symbol ()
			    && (acc.access == SymbolAccessibility.PUBLIC
				|| acc.access == SymbolAccessibility.PROTECTED)) {
				generate_property_accessor_declaration (acc, header_file);
			}
		}

		DataType this_type;
		if (prop.parent_symbol is Struct) {
			var st = (Struct) prop.parent_symbol;
			this_type = SemanticAnalyzer.get_data_type_for_symbol (st);
		} else {
			var t = (ObjectTypeSymbol) prop.parent_symbol;
			this_type = new ObjectType (t);
		}
		var cselfparam = new CCodeParameter ("this", get_ccode_aroop_name (this_type));
		var cvalueparam = new CCodeParameter ("value", get_ccode_aroop_name (acc.value_type));

		string cname = get_ccode_name (acc);

		if (prop.is_abstract || prop.is_virtual) {
			CCodeFunction function;
			if (acc.readable) {
				function = new CCodeFunction (get_ccode_name (acc), get_ccode_aroop_name (current_return_type));
			} else {
				function = new CCodeFunction (get_ccode_name (acc), "void");
			}
			function.add_parameter (cselfparam);
			if (acc.writable) {
				function.add_parameter (cvalueparam);
			}

			if (prop.is_internal_symbol () || !(acc.readable || acc.writable) || acc.is_internal_symbol ()) {
				// accessor function should be private if the property is an internal symbol
				function.modifiers |= CCodeModifiers.STATIC;
			}

			push_function (function);

			var vcast = get_type_private_from_type ((ObjectTypeSymbol) prop.parent_symbol, get_type_from_instance (new CCodeIdentifier ("this")));

			if (acc.readable) {
				var vcall = new CCodeFunctionCall (new CCodeMemberAccess.pointer (vcast, "get_%s".printf (prop.name)));
				vcall.add_argument (new CCodeIdentifier ("this"));
				ccode.add_return (vcall);
			} else {
				var vcall = new CCodeFunctionCall (new CCodeMemberAccess.pointer (vcast, "set_%s".printf (prop.name)));
				vcall.add_argument (new CCodeIdentifier ("this"));
				vcall.add_argument (new CCodeIdentifier ("value"));
				ccode.add_expression (vcall);
			}

			pop_function ();

			cfile.add_function (function);


			string param_list = "(%s *this".printf (get_ccode_aroop_name (prop.parent_symbol));
			if (!acc.readable) {
				param_list += ", ";
				param_list += get_ccode_aroop_name (acc.value_type);
			}
			param_list += ")";

			var override_func = new CCodeFunction ("%soverride_%s_%s".printf (get_ccode_lower_case_prefix (prop.parent_symbol), acc.readable ? "get" : "set", prop.name));
			override_func.add_parameter (new CCodeParameter ("type", "AroopType *"));
			override_func.add_parameter (new CCodeParameter ("(*function) %s".printf (param_list), acc.readable ? get_ccode_aroop_name (acc.value_type) : "void"));

			push_function (override_func);

			vcast = get_type_private_from_type ((ObjectTypeSymbol) prop.parent_symbol, new CCodeIdentifier ("type"));

			ccode.add_assignment (new CCodeMemberAccess.pointer (vcast, "%s_%s".printf (acc.readable ? "get" : "set", prop.name)), new CCodeIdentifier ("function"));

			pop_function ();

			cfile.add_function (override_func);
		}

		if (!prop.is_abstract) {
			CCodeFunction function;
			if (acc.writable) {
				function = new CCodeFunction (cname, "void");
			} else {
				function = new CCodeFunction (cname, get_ccode_aroop_name (acc.value_type));
			}

			if (prop.binding == MemberBinding.INSTANCE) {
				function.add_parameter (cselfparam);
			}
			if (acc.writable) {
				function.add_parameter (cvalueparam);
			}

			if (prop.is_internal_symbol () || !(acc.readable || acc.writable) || acc.is_internal_symbol ()) {
				// accessor function should be private if the property is an internal symbol
				function.modifiers |= CCodeModifiers.STATIC;
			}

			push_function (function);

			acc.body.emit (this);

			if (acc.readable) {
				var cdecl = new CCodeDeclaration (get_ccode_aroop_name (acc.value_type));
				cdecl.add_declarator (new CCodeVariableDeclarator.zero ("result", default_value_for_type (acc.value_type, true)));
				function.block.prepend_statement (cdecl);

				function.block.add_statement (new CCodeReturnStatement (new CCodeIdentifier ("result")));
			}

			cfile.add_function (function);
		}

		pop_context ();
#endif
	}

	public override void generate_interface_declaration (Interface iface, CCodeFile decl_space) {
		if (add_symbol_declaration (decl_space, iface, get_ccode_aroop_name (iface))) {
			return;
		}

		// typedef to AroopObject instead of dummy struct to avoid warnings/casts
		generate_class_declaration (object_class, decl_space);
		decl_space.add_type_declaration (new CCodeTypeDefinition ("AroopObject", new CCodeVariableDeclarator (get_ccode_aroop_name (iface))));

		generate_class_declaration (type_class, decl_space);

		var type_fun = new CCodeFunction ("%s_type_get".printf (get_ccode_aroop_name (iface)), "AroopType *");
		if (iface.is_internal_symbol ()) {
			type_fun.modifiers = CCodeModifiers.STATIC;
		}
		foreach (var type_param in iface.get_type_parameters ()) {
			type_fun.add_parameter (new CCodeParameter ("%s_type".printf (type_param.name.down ()), "AroopType *"));
		}
		decl_space.add_function_declaration (type_fun);

		var type_init_fun = new CCodeFunction ("%s_type_init".printf (get_ccode_aroop_name (iface)));
		if (iface.is_internal_symbol ()) {
			type_init_fun.modifiers = CCodeModifiers.STATIC;
		}
		type_init_fun.add_parameter (new CCodeParameter ("type", "AroopType *"));
		foreach (var type_param in iface.get_type_parameters ()) {
			type_init_fun.add_parameter (new CCodeParameter ("%s_type".printf (type_param.name.down ()), "AroopType *"));
		}
		decl_space.add_function_declaration (type_init_fun);
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
			var func_macro = new CCodeMacroReplacement("%s(x, ...)".printf(get_ccode_name(m)), "((%s*)x)->%s(x, __VA_ARGS__)".printf(get_ccode_aroop_name((Class) m.parent_symbol), m.name));
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

	CCodeExpression get_type_from_instance (CCodeExpression instance_expression) {
		return new CCodeMemberAccess.pointer (new CCodeCastExpression (instance_expression, "AroopObject *"), "type");
	}

	public override void visit_method (Method m) {
		push_context (new EmitContext (m));

		foreach (Parameter param in m.get_parameters ()) {
			param.accept (this);
		}

		foreach (Expression precondition in m.get_preconditions ()) {
			precondition.emit (this);
		}

		foreach (Expression postcondition in m.get_postconditions ()) {
			postcondition.emit (this);
		}

		generate_method_declaration (m, cfile);

		if (!m.is_internal_symbol ()) {
			generate_method_declaration (m, header_file);
		}

		var function = new CCodeFunction (get_ccode_real_name (m));

		generate_cparameters (m, cfile, function);

		// generate *_real_* functions for virtual methods
		if (!m.is_abstract) {
			if (m.base_method != null || m.base_interface_method != null) {
				// declare *_real_* function
				function.modifiers |= CCodeModifiers.STATIC;
				cfile.add_function_declaration (function);
			} else if (m.is_internal_symbol ()) {
				function.modifiers |= CCodeModifiers.STATIC;
			}

			if (m.body != null) {
				push_function (function);

				if (context.module_init_method == m) {
					add_module_init ();
				}

				if (m.closure) {
					// add variables for parent closure blocks
					// as closures only have one parameter for the innermost closure block
					var closure_block = current_closure_block;
					int block_id = get_block_id (closure_block);
					while (true) {
						var parent_closure_block = next_closure_block (closure_block.parent_symbol);
						if (parent_closure_block == null) {
							break;
						}
						int parent_block_id = get_block_id (parent_closure_block);

						var parent_data = new CCodeMemberAccess.pointer (new CCodeIdentifier ("_data%d_".printf (block_id)), "_data%d_".printf (parent_block_id));
						var cdecl = new CCodeDeclaration ("Block%dData*".printf (parent_block_id));
						cdecl.add_declarator (new CCodeVariableDeclarator ("_data%d_".printf (parent_block_id), parent_data));

						ccode.add_statement (cdecl);

						closure_block = parent_closure_block;
						block_id = parent_block_id;
					}

					// add self variable for closures
					// as closures have block data parameter
					if (m.binding == MemberBinding.INSTANCE) {
						var cself = new CCodeMemberAccess.pointer (new CCodeIdentifier ("_data%d_".printf (block_id)), "this");
						var cdecl = new CCodeDeclaration ("%s *".printf (get_ccode_aroop_name (current_class)));
						cdecl.add_declarator (new CCodeVariableDeclarator ("this", cself));

						ccode.add_statement (cdecl);
					}
				}
				foreach (Parameter param in m.get_parameters ()) {
					if (param.ellipsis) {
						break;
					}

					var t = param.variable_type.data_type;
					if (t != null && t.is_reference_type ()) {
						if (param.direction == ParameterDirection.OUT) {
							// ensure that the passed reference for output parameter is cleared
							var a = new CCodeAssignment (new CCodeUnaryExpression (CCodeUnaryOperator.POINTER_INDIRECTION, get_variable_cexpression (param.name)), new CCodeConstant ("NULL"));
							var cblock = new CCodeBlock ();
							cblock.add_statement (new CCodeExpressionStatement (a));

							var condition = new CCodeBinaryExpression (CCodeBinaryOperator.INEQUALITY, new CCodeIdentifier (param.name), new CCodeConstant ("NULL"));
							var if_statement = new CCodeIfStatement (condition, cblock);
							ccode.add_statement (if_statement);
						}
					}
				}

				m.body.emit (this);

				if (!(m.return_type is VoidType) && !(m.return_type is GenericType)) {
					var cdecl = new CCodeDeclaration (get_ccode_aroop_name (m.return_type));
					cdecl.add_declarator (new CCodeVariableDeclarator.zero ("result", default_value_for_type (m.return_type, true)));
					ccode.add_statement (cdecl);

					ccode.add_statement (new CCodeReturnStatement (new CCodeIdentifier ("result")));
				}

				var st = m.parent_symbol as Struct;
				if (m is CreationMethod && st != null && (st.is_boolean_type () || st.is_integer_type () || st.is_floating_type ())) {
					var cdecl = new CCodeDeclaration (get_ccode_aroop_name (st));
					cdecl.add_declarator (new CCodeVariableDeclarator ("this", new CCodeConstant ("0")));
					ccode.add_statement (cdecl);

					ccode.add_statement (new CCodeReturnStatement (new CCodeIdentifier ("this")));
				}

				cfile.add_function (function);
			}
		}
#if 0
		if (m.is_abstract || m.is_virtual) {
			generate_class_declaration ((Class) object_class, cfile);

			var vfunc = new CCodeFunction (get_ccode_name (m), (m.return_type is GenericType) ? "void" : get_ccode_aroop_name (m.return_type));
			vfunc.block = new CCodeBlock ();

			vfunc.add_parameter (new CCodeParameter ("this", "%s *".printf (get_ccode_aroop_name (m.parent_symbol))));
			foreach (TypeParameter type_param in m.get_type_parameters ()) {
				vfunc.add_parameter (new CCodeParameter ("%s_type".printf (type_param.name.down ()), "AroopType*"));
			}
			foreach (Parameter param in m.get_parameters ()) {
				string ctypename = get_ccode_aroop_name (param.variable_type);
				if (param.direction != ParameterDirection.IN) {
					ctypename += "*";
				}
				vfunc.add_parameter (new CCodeParameter (param.name, ctypename));
			}
			if (m.return_type is GenericType) {
				vfunc.add_parameter (new CCodeParameter ("result", "void *"));
			}

			if (m.get_full_name () == "any.equals") {
				// make this null-safe
				var null_block = new CCodeBlock ();
				null_block.add_statement (new CCodeReturnStatement (new CCodeUnaryExpression (CCodeUnaryOperator.LOGICAL_NEGATION, new CCodeIdentifier ("other"))));
				vfunc.block.add_statement (new CCodeIfStatement (new CCodeUnaryExpression (CCodeUnaryOperator.LOGICAL_NEGATION, new CCodeIdentifier ("this")), null_block));
			} else if (m.get_full_name () == "any.hash") {
				// make this null-safe
				var null_block = new CCodeBlock ();
				null_block.add_statement (new CCodeReturnStatement (new CCodeConstant ("0")));
				vfunc.block.add_statement (new CCodeIfStatement (new CCodeUnaryExpression (CCodeUnaryOperator.LOGICAL_NEGATION, new CCodeIdentifier ("this")), null_block));
			} else if (m.get_full_name () == "any.to_string") {
				// make this null-safe
				var null_string = new CCodeFunctionCall (new CCodeIdentifier ("string_create_from_cstring"));
				null_string.add_argument (new CCodeConstant ("\"(null)\""));
				var null_block = new CCodeBlock ();
				null_block.add_statement (new CCodeReturnStatement (null_string));
				vfunc.block.add_statement (new CCodeIfStatement (new CCodeExpression (CCodeUnaryOperator.LOGICAL_NEGATION, new CCodeIdentifier ("this")), null_block));
			}

			var vcast = get_type_private_from_type ((ObjectTypeSymbol) m.parent_symbol, get_type_from_instance (new CCodeIdentifier ("this")));

			var vcall = new CCodeFunctionCall (new CCodeMemberAccess.pointer (vcast, get_ccode_vfunc_name (m)));
			vcall.add_argument (new CCodeIdentifier ("this"));
			foreach (TypeParameter type_param in m.get_type_parameters ()) {
				vcall.add_argument (new CCodeIdentifier ("%s_type".printf (type_param.name.down ())));
			}
			foreach (Parameter param in m.get_parameters ()) {
				vcall.add_argument (new CCodeIdentifier (param.name));
			}
			if (m.return_type is GenericType) {
				vcall.add_argument (new CCodeIdentifier ("result"));
			}

			if (m.return_type is VoidType || m.return_type is GenericType) {
				vfunc.block.add_statement (new CCodeExpressionStatement (vcall));
			} else {
				vfunc.block.add_statement (new CCodeReturnStatement (vcall));
			}

			cfile.add_function (vfunc);


			vfunc = new CCodeFunction ("%sbase_%s".printf (get_ccode_lower_case_prefix (m.parent_symbol), m.name), (m.return_type is GenericType) ? "void" : get_ccode_aroop_name (m.return_type));
			vfunc.block = new CCodeBlock ();

			vfunc.add_parameter (new CCodeParameter ("base_type", "AroopType *"));
			vfunc.add_parameter (new CCodeParameter ("this", "%s *".printf (get_ccode_aroop_name (m.parent_symbol))));
			foreach (TypeParameter type_param in m.get_type_parameters ()) {
				vfunc.add_parameter (new CCodeParameter ("%s_type".printf (type_param.name.down ()), "AroopType*"));
			}
			foreach (Parameter param in m.get_parameters ()) {
				string ctypename = get_ccode_aroop_name (param.variable_type);
				if (param.direction != ParameterDirection.IN) {
					ctypename += "*";
				}
				vfunc.add_parameter (new CCodeParameter (param.name, ctypename));
			}
			if (m.return_type is GenericType) {
				vfunc.add_parameter (new CCodeParameter ("result", "void *"));
			}

			var base_type = new CCodeIdentifier ("base_type");

			vcast = get_type_private_from_type ((ObjectTypeSymbol) m.parent_symbol, base_type);

			vcall = new CCodeFunctionCall (new CCodeMemberAccess.pointer (vcast, get_ccode_vfunc_name (m)));
			vcall.add_argument (new CCodeIdentifier ("this"));
			foreach (TypeParameter type_param in m.get_type_parameters ()) {
				vcall.add_argument (new CCodeIdentifier ("%s_type".printf (type_param.name.down ())));
			}
			foreach (Parameter param in m.get_parameters ()) {
				vcall.add_argument (new CCodeIdentifier (param.name));
			}
			if (m.return_type is GenericType) {
				vcall.add_argument (new CCodeIdentifier ("result"));
			}

			if (m.return_type is VoidType || m.return_type is GenericType) {
				vfunc.block.add_statement (new CCodeExpressionStatement (vcall));
			} else {
				vfunc.block.add_statement (new CCodeReturnStatement (vcall));
			}

			cfile.add_function (vfunc);


			string param_list = "(%s *this".printf (get_ccode_aroop_name (m.parent_symbol));
			foreach (var param in m.get_parameters ()) {
				param_list += ", ";
				param_list += get_ccode_aroop_name (param.variable_type);
			}
			if (m.return_type is GenericType) {
				param_list += ", void *";
			}
			param_list += ")";

			var override_func = new CCodeFunction ("%soverride_%s".printf (get_ccode_lower_case_prefix (m.parent_symbol), m.name));
			override_func.add_parameter (new CCodeParameter ("type", "AroopType *"));
			override_func.add_parameter (new CCodeParameter ("(*function) %s".printf (param_list), (m.return_type is GenericType) ? "void" : get_ccode_aroop_name (m.return_type)));
			override_func.block = new CCodeBlock ();

			vcast = get_type_private_from_type ((ObjectTypeSymbol) m.parent_symbol, new CCodeIdentifier ("type"));

			override_func.block.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeMemberAccess.pointer (vcast, m.name), new CCodeIdentifier ("function"))));

			cfile.add_function (override_func);
		}
#endif
		pop_context ();

		if (m.entry_point) {
			generate_type_declaration (new StructValueType (array_struct), cfile);

			// m is possible entry point, add appropriate startup code
			var cmain = new CCodeFunction ("main", "int");
			cmain.line = function.line;
			cmain.add_parameter (new CCodeParameter ("argc", "int"));
			cmain.add_parameter (new CCodeParameter ("argv", "char **"));

			push_function (cmain);

			var aroop_init_call = new CCodeFunctionCall (new CCodeIdentifier ("aroop_init"));
			aroop_init_call.add_argument (new CCodeIdentifier ("argc"));
			aroop_init_call.add_argument (new CCodeIdentifier ("argv"));
			ccode.add_statement (new CCodeExpressionStatement (aroop_init_call));

			add_module_init ();

			var cdecl = new CCodeDeclaration ("int");
			cdecl.add_declarator (new CCodeVariableDeclarator ("result", new CCodeConstant ("0")));
			ccode.add_statement (cdecl);

			var main_call = new CCodeFunctionCall (new CCodeIdentifier (function.name));

			if (m.get_parameters ().size == 1) {
				// create Aroop array from C array
				// should be replaced by Aroop list
				var array_creation = new CCodeFunctionCall (new CCodeIdentifier ("aroop_array_create"));
				array_creation.add_argument (new CCodeFunctionCall (new CCodeIdentifier ("string_type_get")));
				array_creation.add_argument (new CCodeIdentifier ("argc"));

				cdecl = new CCodeDeclaration ("AroopArray");
				cdecl.add_declarator (new CCodeVariableDeclarator ("args", array_creation));
				ccode.add_statement (cdecl);

				var array_data = new CCodeMemberAccess (new CCodeIdentifier ("args"), "data");

				cdecl = new CCodeDeclaration ("string_t*");
				cdecl.add_declarator (new CCodeVariableDeclarator ("args_data", array_data));
				ccode.add_statement (cdecl);

				cdecl = new CCodeDeclaration ("int");
				cdecl.add_declarator (new CCodeVariableDeclarator ("argi"));
				ccode.add_statement (cdecl);

				var string_creation = new CCodeFunctionCall (new CCodeIdentifier ("string_create_from_cstring"));
				string_creation.add_argument (new CCodeElementAccess (new CCodeIdentifier ("argv"), new CCodeIdentifier ("argi")));

				var loop_block = new CCodeBlock ();
				loop_block.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeElementAccess (new CCodeIdentifier ("args_data"), new CCodeIdentifier ("argi")), string_creation)));

				var for_stmt = new CCodeForStatement (new CCodeBinaryExpression (CCodeBinaryOperator.LESS_THAN, new CCodeIdentifier ("argi"), new CCodeIdentifier ("argc")), loop_block);
				for_stmt.add_initializer (new CCodeAssignment (new CCodeIdentifier ("argi"), new CCodeConstant ("0")));
				for_stmt.add_iterator (new CCodeUnaryExpression (CCodeUnaryOperator.POSTFIX_INCREMENT, new CCodeIdentifier ("argi")));
				ccode.add_statement (for_stmt);

				main_call.add_argument (new CCodeIdentifier ("args"));
			}

			if (m.return_type is VoidType) {
				// method returns void, always use 0 as exit code
				var main_stmt = new CCodeExpressionStatement (main_call);
				main_stmt.line = cmain.line;
				ccode.add_statement (main_stmt);
			} else {
				var main_stmt = new CCodeExpressionStatement (new CCodeAssignment (new CCodeIdentifier ("result"), main_call));
				main_stmt.line = cmain.line;
				ccode.add_statement (main_stmt);
			}

			var ret_stmt = new CCodeReturnStatement (new CCodeIdentifier ("result"));
			ret_stmt.line = cmain.line;
			ccode.add_statement (ret_stmt);

			pop_function ();

			cfile.add_function (cmain);
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
			cdecl.add_declarator (new CCodeVariableDeclarator ("this"));
			vblock.add_statement (cdecl);

			var alloc_call = new CCodeFunctionCall (new CCodeIdentifier ("aroop_object_alloc"));
			alloc_call.add_argument (new CCodeIdentifier ("sizeof(struct _%s)".printf (get_ccode_aroop_name(current_class))));
			alloc_call.add_argument (new CCodeIdentifier("%spray".printf (get_ccode_lower_case_prefix (current_class))));
			vblock.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeIdentifier ("this"), new CCodeCastExpression (alloc_call, "%s *".printf (get_ccode_aroop_name (current_type_symbol))))));

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
				priv_call.add_argument (new CCodeIdentifier ("this"));

				vblock.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeMemberAccess.pointer (priv_call, f.name), calloc_call)));
			}

			var vcall = new CCodeFunctionCall (new CCodeIdentifier (get_ccode_real_name (m)));
			vcall.add_argument (new CCodeIdentifier ("this"));
			vblock.add_statement (new CCodeExpressionStatement (vcall));

			generate_cparameters (m, cfile, vfunc, null, vcall);
			CCodeStatement cstmt = new CCodeReturnStatement (new CCodeIdentifier ("this"));
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
			int block_id = get_block_id (closure_block);
			instance_param = new CCodeParameter ("_data%d_".printf (block_id), "Block%dData*".printf (block_id));
		} else if (m.parent_symbol is Class && m is CreationMethod) {
			if (vcall == null) {
				instance_param = new CCodeParameter ("this", get_ccode_aroop_name (((Class) m.parent_symbol)) + "*");
			}
		} else if (m.binding == MemberBinding.INSTANCE || (m.parent_symbol is Struct && m is CreationMethod)) {
			TypeSymbol parent_type = find_parent_type (m);
			var this_type = get_data_type_for_symbol (parent_type);

			generate_type_declaration (this_type, decl_space);

			if (m.base_interface_method != null && !m.is_abstract && !m.is_virtual) {
				var base_type = new ObjectType ((Interface) m.base_interface_method.parent_symbol);
				instance_param = new CCodeParameter ("this", get_ccode_aroop_name (base_type));
			} else if (m.overrides) {
				var base_type = new ObjectType ((Class) m.base_method.parent_symbol);
				generate_type_declaration (base_type, decl_space);
				instance_param = new CCodeParameter ("this", get_ccode_aroop_name (base_type));
			} else {
				if (m.parent_symbol is Struct && m is CreationMethod) {
					var st = (Struct) m.parent_symbol;
					if (st.is_boolean_type () || st.is_integer_type () || st.is_floating_type ()) {
						// use return value
					} else {
						instance_param = new CCodeParameter ("*this", get_ccode_aroop_name (this_type));
					}
				} else {
					instance_param = new CCodeParameter ("this", get_ccode_aroop_name (this_type));
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
					var cparam = new CCodeParameter ("%s_type".printf (type_param.name.down ()), "AroopType*");
					if (vcall != null) {
						func.add_parameter (cparam);
					}
				}
			}
		} else {
			foreach (TypeParameter type_param in m.get_type_parameters ()) {
				var cparam = new CCodeParameter ("%s_type".printf (type_param.name.down ()), "AroopType*");
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
				func.add_parameter (new CCodeParameter ("result", "void *"));
				if (vdeclarator != null) {
					vdeclarator.add_parameter (new CCodeParameter ("result", "void *"));
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
				var ccontainer = new CCodeMemberAccess (get_cvalue (expr.container), "data");

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

	void add_module_init () {
		foreach (var field in static_fields) {
			field.initializer.emit (this);

			var lhs = new CCodeIdentifier (get_ccode_name (field));
			var rhs = get_cvalue (field.initializer);

			ccode.add_assignment (lhs, rhs);
		}
	}
}
