using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.CSymbolResolve : shotodolplug.Module {

	public string self_instance = "self_data";
	public CSymbolResolve() {
		base("C Symbol Resolver", "0.0");
	}

	public override int init() {
		PluginManager.register("c/symbol", new AnyInterfaceExtension(this, this));
	}

	public override int deinit() {
	}

	public string get_ccode_aroop_name(CodeNode node) {
		// TODO fill me
	}

	public string get_ccode_name(CodeNode node) {
		// TODO fill me
	}

	public string get_ccode_copy_function(CodeNode node) {
		// TODO fill me
	}

	public string get_ccode_dup_function(CodeNode node) {
		// TODO fill me
	}

	public string get_ccode_ref_function(CodeNode node) {
		// TODO fill me
	}

	public string get_ccode_free_function(CodeNode node) {
		// TODO fill me
	}

	public string get_ccode_lower_case_prefix(CodeNode node) {
		// TODO fill me
	}

	public string get_ccode_lower_case_suffix(CodeNode node) {
		// TODO fill me
	}
	public string get_ccode_lower_case_name(CodeNode node) {
		// TODO fill me
	}
	public string get_ccode_real_name(CodeNode node) {
		// TODO fill me
	}

	public string get_ccode_vfunc_name(CodeNode node) {
		// TODO fill me
	}

	public string get_generic_class_variable_cname(int tparams = 0) {
		return "_generic_type_%d".printf(tparams);
	}
	
	public string get_aroop_type_cname() {
		return "aroop_type_desc";
	}



	public CCodeExpression get_unref_expression (CCodeExpression cvar, DataType type, Expression? expr = null) {
		return destroy_value (new AroopValue (type, cvar));
	}

	public void set_cvalue (Expression expr, CCodeExpression? cvalue) {
		var aroop_value = (AroopValue) expr.target_value;
		if (aroop_value == null) {
			aroop_value = new AroopValue (expr.value_type);
			expr.target_value = aroop_value;
		}
		aroop_value.cvalue = cvalue;
	}

	public CCodeExpression? get_cvalue (Expression expr) {
		if (expr.target_value == null) {
			return null;
		}
		var aroop_value = (AroopValue) expr.target_value;
		return aroop_value.cvalue;
	}
	public CCodeExpression? get_cvalue_ (TargetValue value) {
		var aroop_value = (AroopValue) value;
		return aroop_value.cvalue;
	}

	public string get_ccode_vtable_var(Class cl, Class of_class) {
		return "vtable_%sovrd_%s".printf(get_ccode_lower_case_prefix(cl)
			, CCodeBaseModule.get_ccode_lower_case_suffix(of_class));
	}
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
		} else {
			Report.error (null, "internal error: `%s' is not a supported type".printf (sym.get_full_name ()));
			return new InvalidType ();
		}

		return type;
	}

	public CCodeExpression get_type_id_expression (DataType type, bool is_chainup = false, bool for_type_custing = false) {
		if (type is GenericType) {
			string var_name = "%s_type".printf (type.type_parameter.name.down ());
			if (is_in_generic_type (type) && !is_chainup) {
				return get_type_private_from_type (
					(ObjectTypeSymbol) type.type_parameter.parent_symbol
					, new CCodeMemberAccess.pointer (new CCodeIdentifier (self_instance), get_generic_class_variable_cname()));
			} else {
				return new CCodeIdentifier (var_name);
			}
		} else {
			var ret = new CCodeIdentifier (get_ccode_aroop_name((ObjectTypeSymbol)type.data_type));
			if(for_type_custing) {
				return ret;
			}
			if(((ObjectTypeSymbol)type.data_type) != null && ((ObjectTypeSymbol)type.data_type) is Class) {
				var tmp = new CCodeFunctionCall(new CCodeIdentifier ("aroop_generic_type_for_class"));
				tmp.add_argument(ret);
				return tmp;
			}
			return ret;
		}
	}

	public bool hasVtables(Vala.Class given) {
		foreach (Method m in given.get_methods ()) {
			if (m.is_abstract || m.is_virtual) {
				return true;
			}
		}
		return false;
	}
	public bool requires_destroy (DataType type) {
		if (!type.is_disposable ()) {
			return false;
		}

		var deleg_type = type as DelegateType;
		if(deleg_type != null) {
			return false;
		}

		var array_type = type as ArrayType;
		if (array_type != null && array_type.inline_allocated) {
			return requires_destroy (array_type.element_type);
		}

		if(type.data_type != null && type.data_type is Class) {
			var cl = type.data_type as Class;
			if (is_reference_counting (cl)
			    && get_ccode_unref_function (cl) == "") {
				// empty unref_function => no unref necessary
				return false;
			}
		}

		if (type.type_parameter != null) {
			return false;
		}

		return true;
	}

}
public class Vala.AroopValue : TargetValue {
	public CCodeExpression cvalue;

	public AroopValue (DataType? value_type = null, CCodeExpression? cvalue = null) {
		base (value_type);
		this.cvalue = cvalue;
	}
}

/**
 * Represents a struct declaration in the C code.
 */
public class codegenplug.CCodeStructPrototype : Vala.CCodeNode {
        /**
         * The struct name.
         */
		private string type_name { get; set; }
		private string name { get; set; }
		public CCodeStruct definition;
        public CCodeStructPrototype (string name) {
            this.name = "_%s".printf (name);
			this.type_name = name;
			definition = new CCodeStruct(this.name);
        }

		public void generate_type_declaration(CCodeFile decl_space) {
			decl_space.add_type_declaration (new CCodeTypeDefinition ("struct _%s".printf (type_name), new CCodeVariableDeclarator (type_name)));
		}
	
        public override void write (CCodeWriter writer) {
                writer.write_string ("struct ");
                writer.write_string (name);
                writer.write_string (";");
                writer.write_newline ();
                writer.write_newline ();
        }
}


