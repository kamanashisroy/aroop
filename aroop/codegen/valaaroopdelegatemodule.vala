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
using Vala;

/**
 * The link between a delegate and generated code.
 */
public class aroop.AroopDelegateModule : AroopValueModule {
	protected override void generate_delegate_declaration (Delegate d, CCodeFile decl_space) {
		if (add_symbol_declaration (decl_space, d, get_ccode_aroop_name (d))) {
			return;
		}
		var proto = new CCodeStructPrototype (get_ccode_aroop_name (d));
		if(d.is_internal_symbol() && decl_space.is_header) {
			// declare prototype	
			decl_space.add_type_definition (proto);
			proto.generate_type_declaration(decl_space);
			return;
		}
		var return_type = "int ";
		if (d.return_type is GenericType) {
			return_type = "void *";
		} else {
			return_type = get_ccode_name (d.return_type);
		}
		var cb_type = new CCodeTypeDefinition (
		    return_type
		    , generate_invoke_function (d, decl_space));
		decl_space.add_type_definition (cb_type);
		var instance_struct = proto.definition;
		instance_struct.add_field ("void*", "aroop_closure_data", null);
		instance_struct.add_field (get_ccode_aroop_name (d)+"_aroop_delegate_cb", "aroop_cb", null);
		proto.generate_type_declaration(decl_space);
		decl_space.add_type_definition (instance_struct);
	}

	CCodeFunctionDeclarator generate_invoke_function (Delegate d, CCodeFile decl_space) {
		var function = new CCodeFunctionDeclarator (get_ccode_aroop_name (d)+"_aroop_delegate_cb");
		
		function.add_parameter (new CCodeParameter ("_closure_data", "void*"));
		
		foreach (Parameter param in d.get_parameters ()) {
			generate_type_declaration (param.variable_type, decl_space);

			function.add_parameter (new CCodeParameter (param.name, get_ccode_name (param.variable_type)));
		}
		return function;
	}

#if false
	public override void generate_element_declaration(Field f, CCodeStruct container, CCodeFile decl_space) {
		if (f.binding != MemberBinding.INSTANCE)  {
			return;
		}
		base.generate_element_declaration(f,container,decl_space);
		if(f.variable_type is DelegateType) {
			string field_ctype_cdata =  "void*";
			if (f.is_volatile) {
				field_ctype_cdata = "volatile " + field_ctype_cdata;
			}
			container.add_field (field_ctype_cdata, "%s_closure_data".printf(get_ccode_name (f)
				+ get_ccode_declarator_suffix (f.variable_type)), null, generate_declarator_suffix_cexpr(f.variable_type));
		}
	}
#endif
	
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
	
#if false
	public override void visit_local_variable (LocalVariable local) {
		if(local.variable_type is DelegateType) {
			//LocalVariable closure_var = new LocalVariable(new PointerType(new VoidType()), "%s_closure_data".printf(local.name), local.initializer, local.source_reference);
			LocalVariable closure_var = new LocalVariable(new PointerType(new VoidType()), "%s_closure_data".printf(local.name), null, null);
			/*if (local.is_volatile) {
				closure_var.is_volatile = true;
			}*/
			base.visit_local_variable(closure_var);
		}
		base.visit_local_variable(local);
	}
#endif

#if false
	public override void store_delegate (Variable variable, TargetValue?pinstance, Expression exp, bool initializer) {
		var deleg_arg = generate_delegate_closure_argument(exp);
		var closure_exp = new CCodeFunctionCall(new CCodeIdentifier("aroop_assign_closure_as_it_is_of_delegate"));
		if(variable is LocalVariable) {
			closure_exp.add_argument(get_cvalue_(get_local_cvalue ((LocalVariable)variable)));
		} else if(variable is Field) {
			closure_exp.add_argument(get_cvalue_(get_field_cvalue ((Field)variable,pinstance)));
		} else {
			assert("I do not know this!" == null);
		}
#if false
		if(value.value_type is MethodType) {
			closure_exp.add_argument(new CCodeConstant("NULL"));
		} else {
			closure_exp.add_argument(get_cvalue_ (value));
		}
#endif
		closure_exp.add_argument(deleg_arg);
		ccode.add_expression(closure_exp);
		base.store_delegate(variable, pinstance, exp, initializer);
	}
#endif

	public override CCodeExpression? generate_method_to_delegate_cast_expression_as_comma(CCodeExpression source_cexpr, DataType? expression_type, DataType? target_type, Expression? expr, CCodeCommaExpression ccomma) {
		if (expression_type is DelegateType) {
			return null;
		}
		CCodeExpression delegate_expr = generate_method_to_delegate_cast_expression(source_cexpr, expression_type, target_type, expr);
		var assign_temp_var = get_temp_variable (target_type);
		emit_temp_var (assign_temp_var);
		ccomma.append_expression(new CCodeAssignment(get_variable_cexpression (assign_temp_var.name), delegate_expr));
		ccomma.append_expression(get_variable_cexpression(assign_temp_var.name));
		return get_variable_cexpression(assign_temp_var.name);
	}

	public override CCodeExpression generate_method_to_delegate_cast_expression(CCodeExpression source_cexpr, DataType? expression_type, DataType? target_type, Expression? expr) {
		if (expression_type is DelegateType) {
			return source_cexpr;
		}
		if (source_cexpr is CCodeCastExpression) {
			CCodeCastExpression cast_expr = (CCodeCastExpression)source_cexpr;
			if(cast_expr.type_name == get_ccode_aroop_name(target_type) && cast_expr.inner is CCodeInitializerList) {
				return source_cexpr;
			}
		}
		var clist = new CCodeInitializerList ();
		if (expression_type is NullType) {
			clist.append (source_cexpr);
		} else {
			clist.append (generate_delegate_closure_argument(expr));
		}
		clist.append (source_cexpr);
		return new CCodeCastExpression(clist, get_ccode_aroop_name(target_type));
	}
	protected override CCodeFunctionCall? generate_delegate_method_call_ccode (MethodCall expr) {
		var ccall = new CCodeFunctionCall (new CCodeMemberAccess(get_cvalue(expr.call),"aroop_cb"));
		ccall.add_argument (new CCodeMemberAccess(get_cvalue(expr.call),"aroop_closure_data"));
		return ccall;
	}

	public CCodeExpression get_delegate_cb(Expression expr) {
		if(expr.value_type is DelegateType) {
			return new CCodeMemberAccess(get_cvalue(expr), "aroop_cb");
		}
		return get_cvalue(expr);
	}

	public CCodeExpression get_delegate_cb_closure(Expression expr) {
		if(expr.value_type is DelegateType) {
			return new CCodeMemberAccess(get_cvalue(expr), "aroop_closure_data");
		}
		return generate_delegate_closure_argument(expr);
	}

	public override void visit_binary_expression (BinaryExpression expr) {
		if((!(expr.left.value_type is DelegateType) && !(expr.right.value_type is DelegateType)) || (expr.operator != BinaryOperator.EQUALITY && expr.operator != BinaryOperator.INEQUALITY) ) {
			base.visit_binary_expression(expr);
			return;
		}
		
		var cbleft = get_delegate_cb(expr.left);
		var cbright = get_delegate_cb(expr.right);
		var cbbinary = new CCodeBinaryExpression(expr.operator == BinaryOperator.EQUALITY?CCodeBinaryOperator.EQUALITY:CCodeBinaryOperator.INEQUALITY, cbright, cbleft);
		if(expr.left.value_type is NullType || expr.right.value_type is NullType) {
			set_cvalue(expr, cbbinary);
			return;
		}
		var closure_left = get_delegate_cb_closure(expr.left);
		var closure_right = get_delegate_cb_closure(expr.right);
		var closure_binary = new CCodeBinaryExpression(expr.operator == BinaryOperator.EQUALITY?CCodeBinaryOperator.EQUALITY:CCodeBinaryOperator.INEQUALITY, closure_right, closure_left);
		set_cvalue(expr, new CCodeBinaryExpression(CCodeBinaryOperator.AND, cbbinary, closure_binary));
	}

	public override CCodeExpression? generate_delegate_init_expr() {
			var clist = new CCodeInitializerList ();
			clist.append (new CCodeConstant ("0"));
			clist.append (new CCodeConstant ("0"));
			return clist;
	}
}
