/* valaaroopstructmodule.vala
 *
 * Copyright (C) 2006-2009  Jürg Billeter
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

using GLib;

public abstract class Vala.AroopStructModule : AroopBaseModule {  
	public override void generate_struct_declaration (Struct st, CCodeFile decl_space) {
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
			generate_struct_declaration (st, header_file);
			return;
		}
		var proto = new CCodeStructPrototype (get_ccode_name (st));
		if(st.is_internal_symbol() && decl_space.is_header) {
			// declare prototype	
			decl_space.add_type_definition (proto);
			proto.generate_type_declaration(decl_space);
			return;
		}
		if (add_symbol_declaration (decl_space, st, get_ccode_name (st))) {
			return;
		}

		if (st.base_struct != null) {
			generate_struct_declaration (st.base_struct, decl_space);
			return;
		}

		var instance_struct = proto.definition;

		foreach (Field f in st.get_fields ()) {
			generate_element_declaration(f, instance_struct, decl_space);
		}
		proto.generate_type_declaration(decl_space);
		decl_space.add_type_definition (instance_struct);
	}

	public override void visit_struct (Struct st) {
		push_context (new EmitContext (st));


		if (st.is_internal_symbol ()) {
			generate_struct_declaration (st, cfile);
		} else {
			generate_struct_declaration (st, header_file);
		}

		st.accept_children (this);

		pop_context ();
	}
	
	public bool is_current_instance_struct(TypeSymbol instanceType, CCodeExpression cexpr) {
		CCodeIdentifier?cid = null;
		if(!(cexpr is CCodeIdentifier) || (cid = (CCodeIdentifier)cexpr) == null || cid.name == null) {
			return false;
		}
		//print("[%s]member access identifier:%s\n", instanceType.name, cid.name);
		return (instanceType == current_type_symbol && (cid.name) == "this");
	}
	
	public CCodeExpression get_field_cvalue_for_struct(Field f, CCodeExpression cexpr) {
		if(is_current_instance_struct((TypeSymbol) f.parent_symbol, cexpr)) {
			return new CCodeMemberAccess.pointer (cexpr, get_ccode_name (f));
		}
		unowned CCodeUnaryExpression?cuop = null;
		if((cexpr is CCodeUnaryExpression) 
			&& (cuop = (CCodeUnaryExpression)cexpr) == null
			&& cuop.operator == CCodeUnaryOperator.POINTER_INDIRECTION) {
			return new CCodeMemberAccess.pointer (cuop.inner, get_ccode_name (f));
		}
		return new CCodeMemberAccess (cexpr, get_ccode_name (f));
	}

	
	public CCodeExpression generate_instance_cargument_for_struct(MethodCall expr, Method m, CCodeExpression instance) { // TODO this function should be in struct module
		var ma = expr.call as MemberAccess;
		var returnval = instance;
		// we need to pass struct instance by reference
		var unary = instance as CCodeUnaryExpression;
		
		if (unary != null) {
			if(unary.operator == CCodeUnaryOperator.POINTER_INDIRECTION) {
				// *expr => expr
				//print("[%s]*expr => expr\n", m.name);
				
				returnval = unary.inner;
			}
		} else if (instance is CCodeIdentifier) {
			if((Struct)m.parent_symbol == current_type_symbol) {
				//print("[%s]'this' struct instance argument:%s\n", m.name, ((CCodeIdentifier)instance).name);
				return returnval;
			} else {
				//print("[%s]struct instance argument(it is not 'this' so it requires '&' operator):%s\n", m.name, ((CCodeIdentifier)instance).name);
				return new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, instance);
			}
		} else if(instance is CCodeMemberAccess) {
			//print("[%s]memberaccess:%s\n", m.name, expr.target_value.value_type.to_string());
			return new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, instance);
			//returnval = instance;
		} else {
			// if instance is e.g. a function call, we can't take the address of the expression
			// (tmp = expr, &tmp)
			var ccomma = new CCodeCommaExpression ();

			var temp_var = get_temp_variable (ma.inner.target_type);
			emit_temp_var (temp_var);
			ccomma.append_expression (new CCodeAssignment (get_variable_cexpression (temp_var.name), instance));
			ccomma.append_expression (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, get_variable_cexpression (temp_var.name)));

			returnval = ccomma;
		}
		return returnval;
	}
	
	public CCodeParameter?generate_instance_cparameter_for_struct(Method m, CCodeParameter?param, DataType this_type) {
		var returnparam = param;
		var st = (Struct) m.parent_symbol;
		if (st.is_boolean_type () || st.is_integer_type () || st.is_floating_type ()) {
			// use return value
		} else {
			returnparam = new CCodeParameter ("this", get_ccode_aroop_name (this_type)+"*");
			//returnparam = new CCodeUnaryExpression((CCodeUnaryOperator.POINTER_INDIRECTION, get_variable_cexpression (param.name)));
		}
		return returnparam;
	}

	public override CCodeExpression? generate_cargument_for_struct (Parameter param, Expression arg, CCodeExpression? cexpr) {
		if (!((arg.formal_target_type is StructValueType) || (arg.formal_target_type is PointerType))) {
			return cexpr;
		}

		if(arg.formal_target_type is PointerType) {
			if(arg.target_type is PointerType) {
				if (param.direction == ParameterDirection.IN) {
					var unary = cexpr as CCodeUnaryExpression;
					if (unary != null) {
						if(unary.operator == CCodeUnaryOperator.POINTER_INDIRECTION) {// *expr => expr
							//print("working with1 : %s\n", param.name);
							return unary.inner;
						} else { 
							return cexpr;
						}
					} else if (cexpr is CCodeIdentifier || cexpr is CCodeMemberAccess) {
						//print("working with2 : %s\n", param.name);
						return new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, cexpr);
					} else {
#if true
						var ccomma = new CCodeCommaExpression ();
						ccomma.append_expression (cexpr);
						return ccomma;
#else
						print("working with3 : %s\n", param.name);
						// if cexpr is e.g. a function call, we can't take the address of the expression
						// (tmp = expr, &tmp)
						var ccomma = new CCodeCommaExpression ();

						var temp_var = get_temp_variable (arg.target_type);
						emit_temp_var (temp_var);
						ccomma.append_expression (new CCodeAssignment (get_variable_cexpression (temp_var.name), cexpr));
						ccomma.append_expression (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, new CCodeIdentifier (temp_var.name)));

						return ccomma;
#endif
					}
				}
			}
			//print("formal target is pointer : %s\n", param.name);
			return cexpr;
		}
#if false			
		if(arg.formal_target_type is StructValueType) {
			if (cexpr is CCodeIdentifier || cexpr is CCodeMemberAccess) {
				print("function argument struct passed by value : %s\n", param.name);
				return new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, cexpr);
			}
		}
#endif
		return cexpr;
	}
	
	public override CCodeExpression? handle_struct_argument (Parameter param, Expression arg, CCodeExpression? cexpr) {
		assert_not_reached ();
		return null;
	}
}

