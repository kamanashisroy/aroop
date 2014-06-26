/* valaaroopmethodcallmodule.vala
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
 */

public class Vala.AroopMethodCallModule : AroopAssignmentModule {

	protected virtual CCodeExpression? generate_delegate_closure_argument(Expression arg) {
		return null;
	}
	protected virtual CCodeFunctionCall? generate_delegate_method_call_ccode (MethodCall expr) {
		return null;
	}

	public override void visit_method_call (MethodCall expr) {
		// the bare function call
		var ccall = new CCodeFunctionCall (get_cvalue (expr.call));

		Method m = null;
		List<Parameter> params;

		var ma = expr.call as MemberAccess;

		var itype = expr.call.value_type;
		params = itype.get_parameters ();

		if (itype is MethodType) {
			assert (ma != null);
			m = ((MethodType) itype).method_symbol;
		} else if (itype is ObjectType) {
			// constructor
			var cl = (Class) ((ObjectType) itype).type_symbol;
			m = cl.default_construction_method;
			generate_method_declaration (m, cfile);
			ccall = new CCodeFunctionCall (new CCodeIdentifier (get_ccode_real_name (m)));
		} else if (itype is DelegateType) {
#if false
			bool is_param = false;
			foreach (Parameter param in current_method.get_parameters ()) {
				//print("symbol:%s:parent:%s\n".printf(expr.call.to_string(), param.name.to_string()));
				if(param.name == expr.call.to_string()) {
					is_param = true;
					break;
				}
			}
			if(is_param) {
				// TODO avoid to_string() 
				ccall.add_argument (new CCodeIdentifier(expr.call.to_string() + "_closure_data"));
			} else if (ma != null) {
				var closure_instance = get_cvalue (ma.inner);
				if(closure_instance != null) {
					var ccode_member_access = (CCodeMemberAccess)get_cvalue (expr.call);
					var closure_expr = new CCodeMemberAccess.pointer(closure_instance, ccode_member_access.member_name + "_closure_data");
					ccall.add_argument(closure_expr);
				} else {
					ccall.add_argument (new CCodeIdentifier(expr.call.to_string() + "_closure_data"));
					//ccall.add_argument (new CCodeConstant("NULL"));
				}
			} else {
				ccall.add_argument (new CCodeConstant("NULL"));
			}
#else
			ccall = generate_delegate_method_call_ccode(expr);
#endif
		}

		if (m is CreationMethod) {
			var cl = (Class) m.parent_symbol;

			if (cl == current_class) {
				ccall.add_argument (new CCodeIdentifier (self_instance));
			} else {
				ccall.add_argument (new CCodeCastExpression (new CCodeIdentifier (self_instance), get_ccode_aroop_name (cl) + "*"));
			}
		} else if (m != null) {
			if (m.binding == MemberBinding.INSTANCE) {
				var instance = get_cvalue (ma.inner);
				var st = m.parent_symbol as Struct;
				if (st != null && !st.is_simple_type ()) {
					instance = generate_instance_cargument_for_struct(ma, m, instance);
				}
				
				ccall.add_argument (instance);
			}

			if (m.binding != MemberBinding.INSTANCE && m.parent_symbol is ObjectTypeSymbol) {
				// support static methods in generic types
				var type_symbol = (ObjectTypeSymbol) m.parent_symbol;
				if (type_symbol.get_type_parameters ().size > 0 && ma.inner is MemberAccess) {
					var type_ma = (MemberAccess) ma.inner;
					add_generic_type_arguments (ccall, type_ma.get_type_arguments (), expr);
				}
			}
			if (m.get_type_parameters ().size > 0) {
				add_generic_type_arguments (ccall, ma.get_type_arguments (), expr);
			}
		}

		// the complete call expression, might include casts, comma expressions, and/or assignments
		CCodeExpression ccall_expr = ccall;

		bool ellipsis = false;

		int i = 1;
		Iterator<Parameter> params_it = params.iterator ();
		foreach (Expression arg in expr.get_argument_list ()) {
			CCodeExpression cexpr = get_cvalue (arg);

			if (params_it.next ()) {
				var param = params_it.get ();
				ellipsis = param.params_array || param.ellipsis;
				if (!ellipsis) {
					cexpr = generate_cargument_for_struct (param, arg, cexpr);

					// unref old value for non-null non-weak ref/out arguments
					// disabled for arrays for now as that requires special handling
					// (ret_tmp = call (&tmp), var1 = (assign_tmp = dup (tmp), free (var1), assign_tmp), ret_tmp)
					if (param.direction != ParameterDirection.IN && requires_destroy (arg.value_type)
					    && (param.direction == ParameterDirection.OUT || !param.variable_type.value_owned)
					    && !(param.variable_type is ArrayType)) {
						var unary = (UnaryExpression) arg;

						var ccomma = new CCodeCommaExpression ();

						var temp_var = get_temp_variable (param.variable_type, param.variable_type.value_owned);
						temp_var.is_imaginary = true;
						emit_temp_var (temp_var);
						cexpr = new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, get_variable_cexpression (temp_var.name));

						if (param.direction == ParameterDirection.REF) {
							var crefcomma = new CCodeCommaExpression ();
							crefcomma.append_expression (new CCodeAssignment (get_variable_cexpression (temp_var.name), get_cvalue (unary.inner)));
							crefcomma.append_expression (cexpr);
							cexpr = crefcomma;
						}

						// call function
						LocalVariable ret_temp_var = null;
						if (itype.get_return_type () is VoidType) {
							ccomma.append_expression (ccall_expr);
						} else {
							ret_temp_var = get_temp_variable (itype.get_return_type ());
							ret_temp_var.is_imaginary = true;
							emit_temp_var (ret_temp_var);
							ccomma.append_expression (new CCodeAssignment (get_variable_cexpression (ret_temp_var.name), ccall_expr));
						}

						var cassign_comma = new CCodeCommaExpression ();

						var assign_temp_var = get_temp_variable (unary.inner.value_type, unary.inner.value_type.value_owned);
						assign_temp_var.is_imaginary = true;
						emit_temp_var (assign_temp_var);

						cassign_comma.append_expression (new CCodeAssignment (get_variable_cexpression (assign_temp_var.name), transform_expression (get_variable_cexpression (temp_var.name), param.variable_type, unary.inner.value_type, arg)));

						// unref old value
						cassign_comma.append_expression (get_unref_expression (get_cvalue (unary.inner), arg.value_type, arg));

						cassign_comma.append_expression (get_variable_cexpression (assign_temp_var.name));

						// assign new value
						ccomma.append_expression (new CCodeAssignment (get_cvalue (unary.inner), cassign_comma));

						// return value
						if (!(itype.get_return_type () is VoidType)) {
							ccomma.append_expression (get_variable_cexpression (ret_temp_var.name));
						}

						ccall_expr = ccomma;
					}

					if (CCodeBaseModule.get_ccode_type (param) != null) {
						if(param.variable_type is DelegateType) {
#if false
							var deleg_comma = new CCodeCommaExpression();
							var deleg_temp_var = generate_method_to_delegate_cast_expression_as_comma(cexpr, arg.value_type, param.variable_type, arg, deleg_comma);
							if(deleg_temp_var == null) { 
								cexpr = generate_method_to_delegate_cast_expression(cexpr, arg.value_type, param.variable_type, arg);
							} else {
								deleg_comma.append_expression(ccall_expr);
								ccall_expr = deleg_comma;
								cexpr = deleg_temp_var;
							}
#endif
						} else {
							cexpr = new CCodeCastExpression (cexpr, CCodeBaseModule.get_ccode_type (param));
						}
					}
				} else if(/*arg.value_type is MethodType &&*/ param.variable_type is DelegateType) {					
#if false
					CCodeExpression?dleg_expr = generate_delegate_closure_argument(arg);
					cexpr = generate_method_to_delegate_cast_expression(cexpr, arg.value_type, param.variable_type, arg);
#else
#if false
							var deleg_comma = new CCodeCommaExpression();
							var deleg_temp_var = generate_method_to_delegate_cast_expression_as_comma(cexpr, arg.value_type, param.variable_type, arg, deleg_comma);
							if(deleg_temp_var == null) { 
								cexpr = generate_method_to_delegate_cast_expression(cexpr, arg.value_type, param.variable_type, arg);
							} else {
								deleg_comma.append_expression(ccall_expr);
								ccall_expr = deleg_comma;
								cexpr = deleg_temp_var;
							}
#endif
#endif
				}
			}

			ccall.add_argument (cexpr);
			i++;
		}
		if (params_it.next ()) {
			var param = params_it.get ();

			/* if there are more parameters than arguments,
			 * the additional parameter is an ellipsis parameter
			 * otherwise there is a bug in the semantic analyzer
			 */
			assert (param.params_array || param.ellipsis);
			ellipsis = true;
		}

		if (itype.get_return_type () is GenericType) {
			var ccomma = new CCodeCommaExpression ();

			var temp_var = get_temp_variable (expr.value_type);
			temp_var.is_imaginary = true;
			emit_temp_var (temp_var);
			//if (expr.value_type is GenericType) {
				//ccall.add_argument (get_variable_cexpression (temp_var.name));
			//} else {
				ccall.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, get_variable_cexpression (temp_var.name)));
			//}

			// call function
			ccomma.append_expression (ccall_expr);

			ccomma.append_expression (get_variable_cexpression (temp_var.name));

			ccall_expr = ccomma;
		}

		if (expr.tree_can_fail) {
			// method can fail
			current_method_inner_error = true;
			// add &inner_error before the ellipsis arguments
			ccall.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, get_variable_cexpression ("_inner_error_")));
		}

		if (expr.parent_node is ExpressionStatement) {
			ccode.add_expression (ccall_expr);
		} else {
			var temp_var = get_temp_variable (expr.value_type);
			var temp_ref = get_variable_cexpression (temp_var.name);

			emit_temp_var (temp_var);

			ccode.add_assignment (temp_ref, ccall_expr);
			set_cvalue (expr, temp_ref);
		}
	}
}

