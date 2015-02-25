/* valaaroopmemberaccessmodule.vala
 *
 * Copyright (C) 2006-2011  Jürg Billeter
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

public abstract class aroop.AroopMemberAccessModule : AroopControlFlowModule {
	protected string get_ccode_vtable_var(Class cl, Class of_class) {
		return "vtable_%sovrd_%s".printf(get_ccode_lower_case_prefix(cl)
			, CCodeBaseModule.get_ccode_lower_case_suffix(of_class));
	}

#if false
	string get_vtable_var(Class cl, Class of_class) {
		print("%s grephere %s\n", get_ccode_aroop_name(cl), get_ccode_aroop_name(of_class));
		if(of_class == null) {
			return "unknown";
		}
		if(of_class.base_class != null) {
			return get_vtable_var(cl, of_class.base_class);
		}
		if(hasVtables(of_class)) {
			return get_ccode_vtable_var(cl, of_class);
		}
		return "unknown";
	}
#endif

	string get_vtable_var_for_method(Class cl, Class of_class, Method m) {
		print("%s grephere %s\n", get_ccode_aroop_name(cl), get_ccode_aroop_name(of_class));
		if(of_class == null) {
			return "unknown";
		}
		if(of_class.base_class != null) {
			if(hasVtables(of_class.base_class) && of_class.base_class.get_methods().contains(m) ) {
				return get_vtable_var_for_method(cl, of_class.base_class, m);
			}
			return get_ccode_vtable_var(cl, of_class);
		}
		if(hasVtables(of_class)) {
			return get_ccode_vtable_var(cl, of_class);
		}
		return "unknown";
	}

	public override void visit_member_access (MemberAccess expr) {
		CCodeExpression pub_inst = null;
		DataType base_type = null;

		if (expr.inner != null) {
			pub_inst = get_cvalue (expr.inner);

			if (expr.inner.value_type != null) {
				base_type = expr.inner.value_type;
			}
		}

		if (expr.symbol_reference is Method) {
			var m = (Method) expr.symbol_reference;

			if (!(m is DynamicMethod)) {
				generate_method_declaration (m, cfile);

				if (!m.external && m.external_package) {
					// internal VAPI methods
					// only add them once per source file
					if (add_generated_external_symbol (m)) {
						visit_method (m);
					}
				}
			}

			if (expr.inner is BaseAccess) {
				if (m.base_method != null/* && !m.base_method.is_abstract*/) {

					//generate_type_declaration (m.base_method.parent_symbol, cfile);
					Class?mb_class = null;
					Class?b_class = null;
					if(m.base_method.parent_symbol is Class)
						mb_class = (Class) m.base_method.parent_symbol;
					if(current_class.base_class is Class)
						b_class = (Class) current_class.base_class;
					assert(b_class != null);
					if(b_class.base_class != null) {
						//b_class = b_class.base_class;
					}
					var aroop_base_method_call = new CCodeFunctionCall (new CCodeIdentifier ("aroop_base_method_call"));
					aroop_base_method_call.add_argument (new CCodeConstant(get_vtable_var_for_method (b_class, mb_class, m)));
					//aroop_base_method_call.add_argument (new CCodeConstant(m.base_method.name));
					aroop_base_method_call.add_argument (new CCodeConstant(get_ccode_vfunc_name(m)));
					set_cvalue (expr, aroop_base_method_call);
					//set_cvalue (expr, new CCodeIdentifier (get_ccode_base_name (m.base_method)));
					return;
				} else if (m.base_interface_method != null) {
					var base_iface = (Interface) m.base_interface_method.parent_symbol;

					set_cvalue (expr, new CCodeIdentifier ("%s_base_%s".printf (get_ccode_lower_case_name (base_iface, null), m.name)));
					return;
				}
			}

			if (m.base_method != null) {
				if (!method_has_wrapper (m.base_method)) {
					var inst = pub_inst;
					if (expr.inner != null && !expr.inner.is_pure ()) {
						// instance expression has side-effects
						// store in temp. variable
						var temp_var = get_temp_variable (expr.inner.value_type);
						emit_temp_var (temp_var);
						var ctemp = new CCodeIdentifier (temp_var.name);
						inst = new CCodeAssignment (ctemp, pub_inst);
						set_cvalue (expr.inner, ctemp);
					}
					var base_class = (Class) m.base_method.parent_symbol;
					var vclass = new CCodeFunctionCall (new CCodeIdentifier ("%s_GET_CLASS".printf (get_ccode_upper_case_name (base_class, null))));
					vclass.add_argument (inst);
					set_cvalue (expr, new CCodeMemberAccess.pointer (vclass, m.name));
				} else {
					set_cvalue (expr, new CCodeIdentifier (get_ccode_name (m.base_method)));
				}
			} else if (m.base_interface_method != null) {
				set_cvalue (expr, new CCodeIdentifier (get_ccode_name (m.base_interface_method)));
			} else if (m is CreationMethod) {
				set_cvalue (expr, new CCodeIdentifier (get_ccode_real_name (m)));
			} else {
				set_cvalue (expr, new CCodeIdentifier (get_ccode_name (m)));
			}
		} else if (expr.symbol_reference is ArrayLengthField) {
			var array_type = (ArrayType) expr.inner.value_type;
			if (array_type.fixed_length) {
				var csizeof = new CCodeFunctionCall (new CCodeIdentifier ("sizeof"));
				csizeof.add_argument (pub_inst);
				var csizeofelement = new CCodeFunctionCall (new CCodeIdentifier ("sizeof"));
				csizeofelement.add_argument (new CCodeElementAccess (pub_inst, new CCodeConstant ("0")));
				set_cvalue (expr, new CCodeBinaryExpression (CCodeBinaryOperator.DIV, csizeof, csizeofelement));
			} else {
				set_cvalue (expr, new CCodeMemberAccess (pub_inst, "length"));
			}
		} else if (expr.symbol_reference is Field) {
			var f = (Field) expr.symbol_reference;
			expr.target_value = load_field (f, expr.inner != null ? expr.inner.target_value : null);
		} else if (expr.symbol_reference is Vala.EnumValue) {
			var ev = (Vala.EnumValue) expr.symbol_reference;

			generate_enum_declaration ((Enum) ev.parent_symbol, cfile);

			set_cvalue (expr, new CCodeConstant (get_ccode_name (ev)));
		} else if (expr.symbol_reference is Constant) {
			var c = (Constant) expr.symbol_reference;

			generate_constant_declaration (c, cfile);

			set_cvalue (expr, new CCodeIdentifier (get_ccode_name (c)));
		} else if (expr.symbol_reference is Property) {
			var prop = (Property) expr.symbol_reference;

			if (!(prop is DynamicProperty)) {
				generate_property_accessor_declaration (prop.get_accessor, cfile);

				if (!prop.external && prop.external_package) {
					// internal VAPI properties
					// only add them once per source file
					if (add_generated_external_symbol (prop)) {
						visit_property (prop);
					}
				}
			}

			if (expr.inner is BaseAccess) {
				if (prop.base_property != null) {
					var base_class = (Class) prop.base_property.parent_symbol;
					var vcast = new CCodeFunctionCall (new CCodeIdentifier ("%s_CLASS".printf (get_ccode_upper_case_name (base_class, null))));
					vcast.add_argument (new CCodeIdentifier ("%s_parent_class".printf (get_ccode_lower_case_name (current_class, null))));

					var ccall = new CCodeFunctionCall (new CCodeMemberAccess.pointer (vcast, "get_%s".printf (prop.name)));
					ccall.add_argument (get_cvalue (expr.inner));
					set_cvalue (expr, ccall);
					return;
				} else if (prop.base_interface_property != null) {
					var base_iface = (Interface) prop.base_interface_property.parent_symbol;
					string parent_iface_var = "%s_%s_parent_iface".printf (get_ccode_lower_case_name (current_class, null), get_ccode_lower_case_name (base_iface, null));

					var ccall = new CCodeFunctionCall (new CCodeMemberAccess.pointer (new CCodeIdentifier (parent_iface_var), "get_%s".printf (prop.name)));
					ccall.add_argument (get_cvalue (expr.inner));
					set_cvalue (expr, ccall);
					return;
				}
			}

			var base_property = prop;
			if (prop.base_property != null) {
				base_property = prop.base_property;
			} else if (prop.base_interface_property != null) {
				base_property = prop.base_interface_property;
			}
			string getter_cname = get_ccode_name (base_property.get_accessor);
			var ccall = new CCodeFunctionCall (new CCodeIdentifier (getter_cname));

			if (prop.binding == MemberBinding.INSTANCE) {
				ccall.add_argument (pub_inst);
			}

			set_cvalue (expr, ccall);
		} else if (expr.symbol_reference is LocalVariable) {
			var local = (LocalVariable) expr.symbol_reference;
			expr.target_value = load_local (local);
		} else if (expr.symbol_reference is Vala.Parameter) {
			var p = (Vala.Parameter) expr.symbol_reference;
			expr.target_value = load_parameter (p);
		}
	}

	public TargetValue get_local_cvalue (LocalVariable local) {
		var result = new AroopValue (local.variable_type);

		if (local.is_result) {
			// used in postconditions
			result.cvalue = new CCodeIdentifier ("result");
		} else if (local.captured) {
			result.cvalue = get_local_cvalue_for_block(local);
		} else {
			result.cvalue = get_variable_cexpression (local.name);
		}

		return result;
	}

	public TargetValue get_parameter_cvalue (Vala.Parameter p) {
		var result = new AroopValue (p.variable_type);

		if (p.name == self_instance) {
			if (current_method != null && current_method.coroutine) {
				// use closure
				result.cvalue = new CCodeMemberAccess.pointer (new CCodeIdentifier ("data"), self_instance);
			} else {
				var st = current_type_symbol as Struct;
				result.cvalue = new CCodeIdentifier (self_instance);
			}
		} else {
			if (p.captured) {
				result.cvalue = get_parameter_cvalue_for_block(p);
			} else {
				if (current_method != null && current_method.coroutine) {
					// use closure
					result.cvalue = get_variable_cexpression (p.name);
				} else {
					var type_as_struct = p.variable_type.data_type as Struct;
					if (p.direction != Vala.ParameterDirection.IN
					    || (type_as_struct != null && !type_as_struct.is_simple_type () && !p.variable_type.nullable)) {
						if (p.variable_type is GenericType) {
							result.cvalue = get_variable_cexpression (p.name);
						} else {
							result.cvalue = get_variable_cexpression (p.name);
							//result.cvalue = new CCodeIdentifier ("(*%s)".printf (get_variable_cname (p.name)));
						}
					} else {
						// Property setters of non simple structs shall replace all occurences
						// of the "value" formal parameter with a dereferencing version of that
						// parameter.
						if (current_property_accessor != null &&
						    current_property_accessor.writable &&
						    current_property_accessor.value_parameter == p &&
						    current_property_accessor.prop.property_type.is_real_struct_type ()) {
							result.cvalue = new CCodeIdentifier ("(*value)");
						} else {
							result.cvalue = get_variable_cexpression (p.name);
						}
					}
				}
			}
		}

		return result;
	}
	
	public TargetValue get_field_cvalue (Field f, TargetValue? instance) {
		var result = new AroopValue (f.variable_type);
		
		if (f.binding == MemberBinding.INSTANCE) {
			CCodeExpression pub_inst = null;

			if (instance != null) {
				pub_inst = get_cvalue_ (instance);
			}

			var instance_target_type = get_data_type_for_symbol ((TypeSymbol) f.parent_symbol);

			//var cl = instance_target_type.data_type as Class;
			bool aroop_priv = false;
			if ((f.access == SymbolAccessibility.PRIVATE || f.access == SymbolAccessibility.INTERNAL)) {
				aroop_priv = true;
			}

			CCodeExpression inst = pub_inst;
			if (instance.value_type is StructValueType) {
				result.cvalue = get_field_cvalue_for_struct(f, inst);
			} else if (instance_target_type.data_type.is_reference_type () || (instance != null 
					&& (instance.value_type is PointerType))) {
				result.cvalue = new CCodeMemberAccess.pointer (inst, get_ccode_name (f));
			} else {
				result.cvalue = new CCodeMemberAccess (inst, get_ccode_name (f));
			}
		} else {
			generate_field_declaration (f, cfile, false);

			result.cvalue = new CCodeIdentifier (get_ccode_name (f));
		}

		return result;
	}

	TargetValue load_variable (Variable variable, TargetValue value) {
		return value;
	}

	public override TargetValue load_local (LocalVariable local) {
		return load_variable (local, get_local_cvalue (local));
	}

	public override TargetValue load_parameter (Vala.Parameter param) {
		return load_variable (param, get_parameter_cvalue (param));
	}

	public override TargetValue load_field (Field field, TargetValue? instance) {
		return load_variable (field, get_field_cvalue (field, instance));
	}
	protected bool hasVtables(Vala.Class given) {
		foreach (Method m in given.get_methods ()) {
			if (m.is_abstract || m.is_virtual) {
				return true;
			}
		}
		return false;
	}
}
