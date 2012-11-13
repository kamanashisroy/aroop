/* valaaroopdelegatemodule.vala
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

using GLib;

/**
 * The link between a delegate and generated code.
 */
public class Vala.AroopDelegateModule : AroopValueModule {
	public override void generate_delegate_declaration (Delegate d, CCodeFile decl_space) {
		if (add_symbol_declaration (decl_space, d, get_ccode_aroop_name (d))) {
			return;
		}
		var return_type = "int ";
		if (d.return_type is GenericType) {
			return_type = "void *";
		} else {
			return_type = get_ccode_name (d.return_type);
		}
		decl_space.add_type_declaration (
		  new CCodeTypeDefinition (
		    return_type
		    , generate_invoke_function (d, decl_space)));
	}

	CCodeFunctionDeclarator generate_invoke_function (Delegate d, CCodeFile decl_space) {
		var function = new CCodeFunctionDeclarator (get_ccode_aroop_name (d));

		foreach (Parameter param in d.get_parameters ()) {
			generate_type_declaration (param.variable_type, decl_space);

			function.add_parameter (new CCodeParameter (param.name, get_ccode_name (param.variable_type)));
		}

#if false
		function.block = new CCodeBlock ();

		var get_target = new CCodeFunctionCall (new CCodeIdentifier ("aroop_delegate_get_target"));
		get_target.add_argument (new CCodeIdentifier ("this"));

		var cdecl = new CCodeDeclaration ("AroopObject*");
		cdecl.add_declarator (new CCodeVariableDeclarator ("target", get_target));
		function.block.add_statement (cdecl);

		var priv = new CCodeFunctionCall (new CCodeIdentifier ("%s_GET_PRIVATE".printf (get_ccode_upper_case_name (d))));
		priv.add_argument (new CCodeIdentifier ("this"));

		string instance_param_list = "(AroopObject *";
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
#endif
		return function;
	}

	public override void visit_delegate (Delegate d) {
		d.accept_children (this);

		generate_delegate_declaration (d, cfile);

		if (!d.is_internal_symbol ()) {
			generate_delegate_declaration (d, header_file);
		}
	}
}
