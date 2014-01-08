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
	protected override void generate_delegate_declaration (Delegate d, CCodeFile decl_space) {
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
		
		function.add_parameter (new CCodeParameter ("_closure_data", "void*"));
		
		foreach (Parameter param in d.get_parameters ()) {
			generate_type_declaration (param.variable_type, decl_space);

			function.add_parameter (new CCodeParameter (param.name, get_ccode_name (param.variable_type)));
		}
		return function;
	}
	
	protected override CCodeExpression? generate_delegate_closure_argument(Expression arg) {
		CCodeExpression?dleg_expr = null;
		do {
			var cast_expr = arg as CastExpression;
			if(cast_expr != null) {
				return generate_delegate_closure_argument(cast_expr.inner);
			}
			var ma22 = arg as MemberAccess;
			if(ma22 != null) {
				Method? m22 = null;
				m22 = ((MethodType) arg.value_type).method_symbol;
				if (m22 != null && m22.binding == MemberBinding.INSTANCE) {
					var instance22 = get_cvalue (ma22.inner);
					var st22 = m22.parent_symbol as Struct;
					if (st22 != null && !st22.is_simple_type ()) {
						instance22 = generate_instance_cargument_for_struct(ma22, m22, instance22);
					}
					dleg_expr = instance22;
				}
			} else if(current_closure_block != null) {
				Block b = current_closure_block;
				dleg_expr = new CCodeUnaryExpression (
					CCodeUnaryOperator.ADDRESS_OF, 
					new CCodeIdentifier(generate_block_var_name(b))
				);
			} else if(current_method != null && current_method.binding == MemberBinding.INSTANCE) {
				dleg_expr = new CCodeIdentifier(self_instance); // will it cause security exception ?
			} else {
				dleg_expr = new CCodeIdentifier("NULL");
			}
			if(dleg_expr == null) {
				Parameter? pm = (Parameter)arg;
				if(pm != null)
					dleg_expr = new CCodeIdentifier(pm.to_string() + "_closure_data");
				else
					dleg_expr = new CCodeIdentifier("NULL");
			}
		} while(false);
		return dleg_expr;
	}

	public override void visit_delegate (Delegate d) {
		d.accept_children (this);

		generate_delegate_declaration (d, cfile);

		if (!d.is_internal_symbol ()) {
			generate_delegate_declaration (d, header_file);
		}
	}
	
}
