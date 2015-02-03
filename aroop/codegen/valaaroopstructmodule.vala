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
using Vala;

public abstract class aroop.AroopStructModule : AroopBaseModule {  
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
		var func_macro = new CCodeMacroReplacement("%s(x,xindex,y,yindex)".printf(get_ccode_free_function(st)), "({%s(x,xindex,y,yindex);})".printf(get_ccode_copy_function(st)));
		decl_space.add_type_declaration (func_macro);
	}

	public void generate_element_destruction_code(Field f, CCodeBlock stmt) {
		if (f.binding != MemberBinding.INSTANCE)  {
			return;
		}
		var array_type = f.variable_type as ArrayType;
		if (array_type != null && array_type.fixed_length) {
			// TODO cleanup array
			int i = 0;
			//for (int i = 0; i < array_type.length; i++) {
				var fld = new CCodeMemberAccess.pointer(new CCodeIdentifier(self_instance), get_ccode_name(f));
				var element = new CCodeElementAccess (fld, new CCodeConstant (i.to_string ()));
				if (requires_destroy (array_type.element_type))  {
					stmt.add_statement(new CCodeExpressionStatement(get_unref_expression(element, array_type.element_type)));
				}
			//}
			return;
		}
		if (requires_destroy (f.variable_type))  {
			stmt.add_statement(new CCodeExpressionStatement(get_unref_expression(new CCodeMemberAccess.pointer(new CCodeIdentifier(self_instance), get_ccode_name(f)), f.variable_type)));
		}
	}

	public void generate_struct_copy_function (Struct st) {
		string copy_function_name = "%scopy".printf (get_ccode_lower_case_prefix (st));
		var function = new CCodeFunction (copy_function_name, "int");
		if(st.is_internal_symbol()) {
			function.modifiers = CCodeModifiers.STATIC;
		}
		function.add_parameter (new CCodeParameter (self_instance, get_ccode_aroop_name(st)+"*"));
		function.add_parameter (new CCodeParameter ("nouse1", "int"));
		function.add_parameter (new CCodeParameter ("dest", "void*"));
		function.add_parameter (new CCodeParameter ("nouse2", "int"));
		push_function (function); // XXX I do not know what push does 
		if(st.is_internal_symbol()) {
			cfile.add_function_declaration (function);
		} else {
			header_file.add_function_declaration (function);
		}
		
		pop_function (); // XXX I do not know what pop does 
		var vblock = new CCodeBlock ();

		var cleanupblock = new CCodeBlock();
		foreach (Field f in st.get_fields ()) {
			generate_element_destruction_code(f, cleanupblock);
		}

		var destroy_if_null = new CCodeIfStatement(
			new CCodeBinaryExpression(CCodeBinaryOperator.EQUALITY, new CCodeIdentifier("dest"), new CCodeConstant("0"))
			, cleanupblock
		);
		vblock.add_statement(destroy_if_null);
		vblock.add_statement(new CCodeReturnStatement(new CCodeConstant("0")));


		function.block = vblock;
		cfile.add_function(function);
	}

	public override void visit_struct (Struct st) {
		push_context (new EmitContext (st));

		generate_struct_copy_function(st);
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
		return (instanceType == current_type_symbol && (cid.name) == self_instance);
	}
	
	public CCodeExpression get_field_cvalue_for_struct(Field f, CCodeExpression cexpr) {
		if(is_current_instance_struct((TypeSymbol) f.parent_symbol, cexpr)) {
			return new CCodeMemberAccess.pointer (cexpr, get_ccode_name (f));
		}
		unowned CCodeUnaryExpression?cuop = null;
		if((cexpr is CCodeUnaryExpression) 
			&& (cuop = (CCodeUnaryExpression)cexpr) != null
			&& cuop.operator == CCodeUnaryOperator.POINTER_INDIRECTION) {
			return new CCodeMemberAccess.pointer (cuop.inner, get_ccode_name (f));
		}
		return new CCodeMemberAccess (cexpr, get_ccode_name (f));
	}

	
	public CCodeExpression generate_instance_cargument_for_struct(MemberAccess ma, Method m, CCodeExpression instance) { 
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
			if(is_current_instance_struct((TypeSymbol)m.parent_symbol, instance)) {
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
			returnparam = new CCodeParameter (self_instance, get_ccode_aroop_name (this_type)+"*");
			//returnparam = new CCodeUnaryExpression((CCodeUnaryOperator.POINTER_INDIRECTION, get_variable_cexpression (param.name)));
		}
		return returnparam;
	}

	public override CCodeExpression? generate_cargument_for_struct (Vala.Parameter param, Expression arg, CCodeExpression? cexpr) {
		if (!((arg.formal_target_type is StructValueType) || (arg.formal_target_type is PointerType))) {
			return cexpr;
		}

		if(arg.formal_target_type is PointerType) {
			if(arg.target_type is PointerType) {
				if (param.direction == Vala.ParameterDirection.IN) {
					CCodeUnaryExpression?unary = null;
					if ((unary = cexpr as CCodeUnaryExpression) != null) {
						if(unary.operator == CCodeUnaryOperator.ADDRESS_OF 
							&& unary.inner is CCodeIdentifier 
							&& ((CCodeIdentifier)unary.inner).name == self_instance) {// &this => this
							//print("working with1 : %s\n", param.name);
							return unary.inner;
						} else { 
							return cexpr;
						}
					} else if (cexpr is CCodeIdentifier || cexpr is CCodeMemberAccess) {
						return cexpr;
					} else {
						var ccomma = new CCodeCommaExpression ();
						ccomma.append_expression (cexpr);
						return ccomma;
					}
				}
			}
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
	
	public override CCodeExpression? handle_struct_argument (Vala.Parameter param, Expression arg, CCodeExpression? cexpr) {
		assert_not_reached ();
		return null;
	}
}

