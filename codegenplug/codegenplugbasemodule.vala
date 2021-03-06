/* valaccodebasemodule.vala
 *
 * Copyright (C) 2006-2011  Jürg Billeter
 * Copyright (C) 2006-2008  Raffaele Sandrini
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
 * 	Raffaele Sandrini <raffaele@sandrini.ch>
 */

using Vala;

/**
 * Code visitor generating C Code.
 */
public abstract class codegenplug.CodegenPlugBaseModule {

	public static int ccode_attribute_cache_index = -1;
	public static DataType get_data_type_for_symbol (TypeSymbol sym) {
		DataType type = null;

		if (sym is Class) {
			type = new ObjectType ((Class) sym);
		} else if (sym is Interface) {
			type = new ObjectType ((Interface) sym);
		} else if (sym is Struct) {
			var st = (Struct) sym;
			if (st.is_boolean_type ()) {
				type = new BooleanType (st);
			} else if (st.is_integer_type ()) {
				type = new IntegerType (st);
			} else if (st.is_floating_type ()) {
				type = new FloatingType (st);
			} else {
				type = new StructValueType (st);
			}
		} else if (sym is Enum) {
			type = new Vala.EnumValueType ((Enum) sym);
		} else if (sym is ErrorDomain) {
			type = new Vala.ErrorType ((ErrorDomain) sym, null);
		} else if (sym is ErrorCode) {
			type = new Vala.ErrorType ((ErrorDomain) sym.parent_symbol, (ErrorCode) sym);
		} else {
			Report.error (null, "internal error: `%s' is not a supported type".printf (sym.get_full_name ()));
			return new InvalidType ();
		}

		return type;
	}

	public static CodegenPlugAttribute get_ccode_attribute (CodeNode node) {
		if(ccode_attribute_cache_index == -1) {
			ccode_attribute_cache_index = CodeNode.get_attribute_cache_index ();
		}
		var attr = node.get_attribute_cache (ccode_attribute_cache_index);
		if (attr == null) {
			attr = new CodegenPlugAttribute (node);
			node.set_attribute_cache (ccode_attribute_cache_index, attr);
		}
		return (CodegenPlugAttribute) attr;
	}

	public static string get_ccode_name (CodeNode node) {
		return get_ccode_attribute(node).name;
	}

	public static string get_ccode_const_name (CodeNode node) {
		return get_ccode_attribute(node).const_name;
	}

	public static string get_ccode_type_name (Interface iface) {
		return get_ccode_attribute(iface).type_name;
	}

	public static string get_ccode_lower_case_name (CodeNode node, string? infix = null) {
		var sym = node as Symbol;
		if (sym != null) {
			if (infix == null) {
				infix = "";
			}
			if (sym is Delegate) {
				return "%s%s%s".printf (get_ccode_lower_case_prefix (sym.parent_symbol), infix, Symbol.camel_case_to_lower_case (sym.name));
			} else if (sym is ErrorCode) {
				return get_ccode_name (sym).down ();
			} else if (sym is Class) {
				return "%s%s".printf (get_ccode_lower_case_prefix (sym.parent_symbol), Symbol.camel_case_to_lower_case(sym.name)/*, get_ccode_lower_case_suffix (sym)*/);
				//return "aroop_cl_%s%s".printf(get_ccode_lower_case_prefix (sym.parent_symbol), get_ccode_lower_case_suffix(sym));
			} else {
				return "%s%s%s".printf (get_ccode_lower_case_prefix (sym.parent_symbol), infix, get_ccode_lower_case_suffix (sym));
			}
		} else if (node is Vala.ErrorType) {
			var type = (Vala.ErrorType) node;
			if (type.error_domain == null) {
				if (infix == null) {
					return "g_error";
				} else {
					return "g_%s_error".printf (infix);
				}
			} else if (type.error_code == null) {
				return get_ccode_lower_case_name (type.error_domain, infix);
			} else {
				return get_ccode_lower_case_name (type.error_code, infix);
			}
		} else {
			var type = (DataType) node;
			return get_ccode_lower_case_name (type.data_type, infix);
		}
	}

	public static string get_ccode_upper_case_name (Symbol sym, string? infix = null) {
		if (sym is Property) {
			return "%s_%s".printf (get_ccode_lower_case_name (sym.parent_symbol), Symbol.camel_case_to_lower_case (sym.name)).up ();
		} else {
			return get_ccode_lower_case_name (sym, infix).up ();
		}
	}

	public static string get_ccode_header_filenames (Symbol sym) {
		if(ccode_attribute_cache_index == -1) {
			ccode_attribute_cache_index = CodeNode.get_attribute_cache_index ();
		}
		return get_ccode_attribute(sym).header_filenames;
	}

	public static string get_ccode_prefix (Symbol sym) {
		return get_ccode_attribute(sym).prefix;
	}

	public static string get_ccode_lower_case_prefix (Symbol sym) {
		/*if (sym != null) {
			if (sym is Class) {
				return "aroop_cl_%s%s".printf(get_ccode_lower_case_prefix (sym.parent_symbol), get_ccode_lower_case_suffix(sym));
			}
		}*/
		return get_ccode_attribute(sym).lower_case_prefix;
	}

	public static string get_ccode_lower_case_suffix (Symbol sym) {
		return get_ccode_attribute(sym).lower_case_suffix;
	}

	public static string get_ccode_ref_function (TypeSymbol sym) {
		return get_ccode_attribute(sym).ref_function;
	}

	public static string get_quark_name (ErrorDomain edomain) {
		return get_ccode_lower_case_name (edomain) + "-quark";
	}

	public static bool is_reference_counting (TypeSymbol sym) {
		if (sym is Class) {
			return get_ccode_ref_function (sym) != null;
		} else if (sym is Interface) {
			return true;
		} else {
			return false;
		}
	}

	public static bool get_ccode_ref_function_void (Class cl) {
		return get_ccode_attribute(cl).ref_function_void;
	}

	public static bool get_ccode_free_function_address_of (Class cl) {
		return get_ccode_attribute(cl).free_function_address_of;
	}

	public static string get_ccode_unref_function (ObjectTypeSymbol sym) {
		return get_ccode_attribute(sym).unref_function;
	}

	public static string get_ccode_ref_sink_function (ObjectTypeSymbol sym) {
		return get_ccode_attribute(sym).ref_sink_function;
	}

	public static string get_ccode_copy_function (TypeSymbol sym) {
		return get_ccode_attribute(sym).copy_function;
	}

	public static string get_ccode_destroy_function (TypeSymbol sym) {
		return get_ccode_attribute(sym).destroy_function;
	}

	public static string? get_ccode_dup_function (TypeSymbol sym) {
		if (sym is Struct) {
			if (sym.external_package) {
				return null;
			} else {
				return get_ccode_lower_case_prefix (sym) + "dup";
			}
		}
		return get_ccode_copy_function (sym);
	}

	public static string get_ccode_free_function (TypeSymbol sym) {
		return get_ccode_attribute(sym).free_function;
	}

	public static bool get_ccode_is_gboxed (TypeSymbol sym) {
		return get_ccode_free_function (sym) == "g_boxed_free";
	}

	public static string get_ccode_type_id (CodeNode node) {
		return get_ccode_attribute(node).type_id;
	}

	public static string get_ccode_marshaller_type_name (CodeNode node) {
		return get_ccode_attribute(node).marshaller_type_name;
	}

	public static string get_ccode_get_value_function (CodeNode sym) {
		return get_ccode_attribute(sym).get_value_function;
	}

	public static string get_ccode_set_value_function (CodeNode sym) {
		return get_ccode_attribute(sym).set_value_function;
	}

	public static string get_ccode_take_value_function (CodeNode sym) {
		return get_ccode_attribute(sym).take_value_function;
	}

	public static string get_ccode_param_spec_function (CodeNode sym) {
		return get_ccode_attribute(sym).param_spec_function;
	}

	public static string get_ccode_type_check_function (TypeSymbol sym) {
		Class?cl = null;
		if(sym is Class)
			cl = sym as Class;
		var a = sym.get_attribute_string ("CCode", "type_check_function");
		if (cl != null && a != null) {
			return a;
		} else if ((cl != null && cl.is_compact) || sym is Struct || sym is Enum || sym is Delegate) {
			return "";
		} else {
			return get_ccode_upper_case_name (sym, "IS_");
		}
	}

	public static string get_ccode_default_value (TypeSymbol sym) {
		return get_ccode_attribute(sym).default_value;
	}

	public static bool get_ccode_has_copy_function (Struct st) {
		return st.get_attribute_bool ("CCode", "has_copy_function", true);
	}

	public static bool get_ccode_has_destroy_function (Struct st) {
		return st.get_attribute_bool ("CCode", "has_destroy_function", true);
	}

	public static double get_ccode_instance_pos (CodeNode node) {
		if (node is Delegate) {
			return node.get_attribute_double ("CCode", "instance_pos", -2);
		} else {
			return node.get_attribute_double ("CCode", "instance_pos", 0);
		}
	}

	public static bool get_ccode_array_length (CodeNode node) {
		return get_ccode_attribute(node).array_length;
	}

	public static string? get_ccode_array_length_type (CodeNode node) {
		return get_ccode_attribute(node).array_length_type;
	}

	public static bool get_ccode_array_null_terminated (CodeNode node) {
		return get_ccode_attribute(node).array_null_terminated;
	}

	public static string? get_ccode_array_length_name (CodeNode node) {
		return get_ccode_attribute(node).array_length_name;
	}

	public static string? get_ccode_array_length_expr (CodeNode node) {
		return get_ccode_attribute(node).array_length_expr;
	}

	public static double get_ccode_array_length_pos (CodeNode node) {
		var a = node.get_attribute ("CCode");
		if (a != null && a.has_argument ("array_length_pos")) {
			return a.get_double ("array_length_pos");
		}
		if (node is Vala.Parameter) {
			var param = (Vala.Parameter) node;
			return get_ccode_pos (param) + 0.1;
		} else {
			return -3;
		}
	}

	public static double get_ccode_delegate_target_pos (CodeNode node) {
		var a = node.get_attribute ("CCode");
		if (a != null && a.has_argument ("delegate_target_pos")) {
			return a.get_double ("delegate_target_pos");
		}
		if (node is Vala.Parameter) {
			var param = (Vala.Parameter) node;
			return get_ccode_pos (param) + 0.1;
		} else {
			return -3;
		}
	}

	public static double get_ccode_destroy_notify_pos (CodeNode node) {
		var a = node.get_attribute ("CCode");
		if (a != null && a.has_argument ("destroy_notify_pos")) {
			return a.get_double ("destroy_notify_pos");
		}
		if (node is Vala.Parameter) {
			var param = (Vala.Parameter) node;
			return get_ccode_pos (param) + 0.1;
		} else {
			return -3;
		}
	}

	public static bool get_ccode_delegate_target (CodeNode node) {
		return get_ccode_attribute(node).delegate_target;
	}

	public static string get_ccode_delegate_target_name (Variable variable) {
		return get_ccode_attribute(variable).delegate_target_name;
	}

	public static double get_ccode_pos (Vala.Parameter param) {
		return get_ccode_attribute(param).pos;
	}

	public static string? get_ccode_type (CodeNode node) {
		return get_ccode_attribute(node).ctype;
	}

	public static bool get_ccode_simple_generics (Method m) {
		return m.get_attribute_bool ("CCode", "simple_generics");
	}

	public static string get_ccode_real_name (Symbol sym) {
		return get_ccode_attribute(sym).real_name;
	}

	public static string get_ccode_constructv_name (CreationMethod m) {
		const string infix = "constructv";

		Class?parent = null;
		if(m.parent_symbol is Class)
			parent = m.parent_symbol as Class;

		if (m.name == ".new") {
			return "%s%s".printf (get_ccode_lower_case_prefix (parent), infix);
		} else {
			return "%s%s_%s".printf (get_ccode_lower_case_prefix (parent), infix, m.name);
		}
	}

	public static string get_ccode_vfunc_name (Method m) {
		return get_ccode_attribute(m).vfunc_name;
	}

	public static string get_ccode_finish_name (Method m) {
		return get_ccode_attribute(m).finish_name;
	}

	public static string get_ccode_finish_vfunc_name (Method m) {
		return get_ccode_attribute(m).finish_vfunc_name;
	}

	public static string get_ccode_finish_real_name (Method m) {
		return get_ccode_attribute(m).finish_real_name;
	}

	public static bool get_ccode_no_accessor_method (Property p) {
		return p.get_attribute ("NoAccessorMethod") != null;
	}

	public static bool get_ccode_concrete_accessor (Property p) {
		return p.get_attribute ("ConcreteAccessor") != null;
	}

	public static bool get_ccode_has_type_id (TypeSymbol sym) {
		return sym.get_attribute_bool ("CCode", "has_type_id", true);
	}

	public static bool get_ccode_has_new_function (Method m) {
		return m.get_attribute_bool ("CCode", "has_new_function", true);
	}

	public static bool get_ccode_has_generic_type_parameter (Method m) {
		var a = m.get_attribute ("CCode");
		return a != null && a.has_argument ("generic_type_pos");
	}

	public static double get_ccode_generic_type_pos (Method m) {
		return m.get_attribute_double ("CCode", "generic_type_pos");
	}

	public static string get_ccode_sentinel (Method m) {
		return get_ccode_attribute(m).sentinel;
	}

	public static bool get_ccode_notify (Property prop) {
		return prop.get_attribute_bool ("CCode", "notify", true);
	}

	public static string get_ccode_nick (Property prop) {
		var nick = prop.get_attribute_string ("Description", "nick");
		if (nick == null) {
			nick = prop.name.replace ("_", "-");
		}
		return nick;
	}

	public static string get_ccode_blurb (Property prop) {
		var blurb = prop.get_attribute_string ("Description", "blurb");
		if (blurb == null) {
			blurb = prop.name.replace ("_", "-");
		}
		return blurb;
	}

	public static CCodeConstant get_enum_value_canonical_cconstant (Vala.EnumValue ev) {
		var str = new StringBuilder ("\"");

		string i = ev.name;

		while (i.length > 0) {
			unichar c = i.get_char ();
			if (c == '_') {
				str.append_c ('-');
			} else {
				str.append_unichar (c.tolower ());
			}

			i = i.next_char ();
		}

		str.append_c ('"');

		return new CCodeConstant (str.str);
	}

}

