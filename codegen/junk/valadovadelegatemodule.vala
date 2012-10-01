/* valadovadelegatemodule.vala
 *
 * Copyright (C) 2006-2010  Jürg Billeter
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
 *	Raffaele Sandrini <raffaele@sandrini.ch>
 */

/**
 * The link between a delegate and generated code.
 */
public class Vala.DovaDelegateModule : DovaValueModule {
	public override void generate_delegate_declaration (Delegate d, CCodeFile decl_space) {
		if (add_symbol_declaration (decl_space, d, get_ccode_name (d))) {
			return;
		}

		decl_space.add_type_declaration (new CCodeTypeDefinition ("struct _%s".printf (get_ccode_name (d)), new CCodeVariableDeclarator (get_ccode_name (d))));

		generate_class_declaration (type_class, decl_space);
		generate_method_declaration ((Method) object_class.scope.lookup ("ref"), decl_space);
		generate_method_declaration ((Method) object_class.scope.lookup ("unref"), decl_space);

		var type_fun = new CCodeFunction ("%s_type_get".printf (get_ccode_lower_case_name (d)), "DovaType *");
		if (d.is_internal_symbol ()) {
			type_fun.modifiers = CCodeModifiers.STATIC;
		}
		decl_space.add_function_declaration (type_fun);

		var type_init_fun = new CCodeFunction ("%s_type_init".printf (get_ccode_lower_case_name (d)));
		if (d.is_internal_symbol ()) {
			type_init_fun.modifiers = CCodeModifiers.STATIC;
		}
		type_init_fun.add_parameter (new CCodeParameter ("type", "DovaType *"));
		decl_space.add_function_declaration (type_init_fun);

		generate_type_declaration (d.return_type, decl_space);

		var function = generate_new_function (d, decl_space);
		function.block = null;
		decl_space.add_function_declaration (function);

		function = generate_invoke_function (d, decl_space);
		function.block = null;
		decl_space.add_function_declaration (function);
	}

	CCodeFunction generate_new_function (Delegate d, CCodeFile decl_space) {
		var function = new CCodeFunction ("%s_new".printf (get_ccode_lower_case_name (d)), "%s*".printf (get_ccode_name (d)));
		if (d.is_internal_symbol ()) {
			function.modifiers |= CCodeModifiers.STATIC;
		}

		function.add_parameter (new CCodeParameter ("target", "DovaObject *"));
		function.add_parameter (new CCodeParameter ("(*method) (void)", "void"));

		function.block = new CCodeBlock ();

		var alloc_call = new CCodeFunctionCall (new CCodeIdentifier ("dova_object_alloc"));
		alloc_call.add_argument (new CCodeFunctionCall (new CCodeIdentifier ("%s_type_get".printf (get_ccode_lower_case_name (d)))));

		var cdecl = new CCodeDeclaration ("%s*".printf (get_ccode_name (d)));
		cdecl.add_declarator (new CCodeVariableDeclarator ("this", alloc_call));
		function.block.add_statement (cdecl);

		var init_call = new CCodeFunctionCall (new CCodeIdentifier ("dova_delegate_init"));
		init_call.add_argument (new CCodeIdentifier ("this"));
		init_call.add_argument (new CCodeIdentifier ("target"));
		function.block.add_statement (new CCodeExpressionStatement (init_call));

		var priv = new CCodeFunctionCall (new CCodeIdentifier ("%s_GET_PRIVATE".printf (get_ccode_upper_case_name (d))));
		priv.add_argument (new CCodeIdentifier ("this"));
		var assignment = new CCodeAssignment (new CCodeMemberAccess.pointer (priv, "method"), new CCodeIdentifier ("method"));
		function.block.add_statement (new CCodeExpressionStatement (assignment));

		function.block.add_statement (new CCodeReturnStatement (new CCodeIdentifier ("this")));

		return function;
	}

	CCodeFunction generate_invoke_function (Delegate d, CCodeFile decl_space) {
		var function = new CCodeFunction ("%s_invoke".printf (get_ccode_lower_case_name (d)));

		if (d.is_internal_symbol ()) {
			function.modifiers |= CCodeModifiers.STATIC;
		}

		function.add_parameter (new CCodeParameter ("this", "%s*".printf (get_ccode_name (d))));

		string param_list = "";

		foreach (Parameter param in d.get_parameters ()) {
			generate_type_declaration (param.variable_type, decl_space);

			function.add_parameter (new CCodeParameter (param.name, get_ccode_name (param.variable_type)));

			if (param_list != "") {
				param_list += ", ";
			}
			param_list += get_ccode_name (param.variable_type);
		}

		if (d.return_type is GenericType) {
			function.add_parameter (new CCodeParameter ("result", "void *"));

			if (param_list != "") {
				param_list += ", ";
			}
			param_list += "void *";
		} else {
			function.return_type = get_ccode_name (d.return_type);
		}

		function.block = new CCodeBlock ();

		var get_target = new CCodeFunctionCall (new CCodeIdentifier ("dova_delegate_get_target"));
		get_target.add_argument (new CCodeIdentifier ("this"));

		var cdecl = new CCodeDeclaration ("DovaObject*");
		cdecl.add_declarator (new CCodeVariableDeclarator ("target", get_target));
		function.block.add_statement (cdecl);

		var priv = new CCodeFunctionCall (new CCodeIdentifier ("%s_GET_PRIVATE".printf (get_ccode_upper_case_name (d))));
		priv.add_argument (new CCodeIdentifier ("this"));

		string instance_param_list = "(DovaObject *";
		if (param_list != "") {
			instance_param_list += ",";
			instance_param_list += param_list;
		}
		instance_param_list += ")";

		var instance_block = new CCodeBlock ();
		var instance_call = new CCodeFunctionCall (new CCodeCastExpression (new CCodeMemberAccess.pointer (priv, "method"), "%s (*) %s".printf (function.return_type, instance_param_list)));

		instance_call.add_argument (new CCodeIdentifier ("target"));

		string static_param_list = "(";
		if (param_list != "") {
			static_param_list += param_list;
		} else {
			static_param_list += "void";
		}
		static_param_list += ")";

		var static_block = new CCodeBlock ();
		var static_call = new CCodeFunctionCall (new CCodeCastExpression (new CCodeMemberAccess.pointer (priv, "method"), "%s (*) %s".printf (function.return_type, static_param_list)));

		foreach (Parameter param in d.get_parameters ()) {
			instance_call.add_argument (new CCodeIdentifier (param.name));
			static_call.add_argument (new CCodeIdentifier (param.name));
		}

		if (d.return_type is VoidType) {
			instance_block.add_statement (new CCodeExpressionStatement (instance_call));
			static_block.add_statement (new CCodeExpressionStatement (static_call));
		} else if (d.return_type is GenericType) {
			instance_call.add_argument (new CCodeIdentifier ("result"));
			static_call.add_argument (new CCodeIdentifier ("result"));
			instance_block.add_statement (new CCodeExpressionStatement (instance_call));
			static_block.add_statement (new CCodeExpressionStatement (static_call));
		} else {
			instance_block.add_statement (new CCodeReturnStatement (instance_call));
			static_block.add_statement (new CCodeReturnStatement (static_call));
		}

		function.block.add_statement (new CCodeIfStatement (new CCodeIdentifier ("target"), instance_block, static_block));

		return function;
	}

	public override void visit_delegate (Delegate d) {
		d.accept_children (this);

		generate_delegate_declaration (d, cfile);

		if (!d.is_internal_symbol ()) {
			generate_delegate_declaration (d, header_file);
		}

		generate_type_get_function (d, delegate_class);

		var instance_priv_struct = new CCodeStruct ("_%sPrivate".printf (get_ccode_name (d)));

		instance_priv_struct.add_field ("void", "(*method) (void)");

		cfile.add_type_declaration (new CCodeTypeDefinition ("struct %s".printf (instance_priv_struct.name), new CCodeVariableDeclarator ("%sPrivate".printf (get_ccode_name (d)))));
		cfile.add_type_definition (instance_priv_struct);

		string macro = "((%sPrivate *) (((char *) o) + _%s_object_offset))".printf (get_ccode_name (d), get_ccode_lower_case_name (d));
		cfile.add_type_member_declaration (new CCodeMacroReplacement ("%s_GET_PRIVATE(o)".printf (get_ccode_upper_case_name (d, null)), macro));

		var cdecl = new CCodeDeclaration ("intptr_t");
		cdecl.add_declarator (new CCodeVariableDeclarator ("_%s_object_offset".printf (get_ccode_lower_case_name (d)), new CCodeConstant ("0")));
		cdecl.modifiers = CCodeModifiers.STATIC;
		cfile.add_type_member_declaration (cdecl);

		cdecl = new CCodeDeclaration ("intptr_t");
		cdecl.add_declarator (new CCodeVariableDeclarator ("_%s_type_offset".printf (get_ccode_lower_case_name (d)), new CCodeConstant ("0")));
		cdecl.modifiers = CCodeModifiers.STATIC;
		cfile.add_type_member_declaration (cdecl);

		cfile.add_function (generate_new_function (d, cfile));
		cfile.add_function (generate_invoke_function (d, cfile));
	}
}
