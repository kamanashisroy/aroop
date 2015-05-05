using GLib;
using Vala;
using shotodolplug;
using codegenplug;

internal class codegenplug.AroopCodeGeneratorAdapter {

	private AroopCodeGeneratorAdapter() {
	}
	
	public static CCodeExpression? generate_expression_transformation(CCodeExpression source_cexpr, DataType? expression_type, DataType? target_type, Expression? expr = null) {
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["source_cexpr"] = source_cexpr;
		args["expression_type"] = expression_type;
		args["target_type"] = target_type;
		args["expr"] = expr;
		CCodeExpression?result = (CCodeExpression?)PluginManager.swarmValue("generate/expression/transformation", args);
		if(result == null)
			print("Please report this bug, result for transformation should not be null\n");
		return result;
	}

	public static void generate_element_destruction_code(Field f, CCodeBlock stmt) {
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["field"] = f;
		args["stmt"] = stmt;
		PluginManager.swarmValue("generate/element/destruction", args);
	}

	public static void generate_constant_declaration(Constant c, CCodeFile decl_space) {
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["constant"] = c;
		args["decl_space"] = decl_space;
		PluginManager.swarmValue("generate/constant/declaration", args);
	}

	public static void generate_element_declaration(Field f, CCodeStruct container, CCodeFile decl_space, bool internalSymbol = true) {
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["field"] = f;
		args["container"] = container;
		args["decl_space"] = decl_space;
		args["internalSymbol"] = internalSymbol;
		PluginManager.swarmValue("generate/element/declaration", args);
	}

	public static void generate_field_declaration(Field f, CCodeFile decl_space, bool defineHere = false) {
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["field"] = f;
		args["decl_space"] = decl_space;
		args["defineHere"] = defineHere;
		PluginManager.swarmValue("generate/field/declaration", args);
	}

	public static void generate_struct_declaration (Struct st, CCodeFile decl_space) {
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["struct"] = st;
		args["decl_space"] = decl_space;
		PluginManager.swarmValue("generate/struct/declaration", args);
	}

	public static void generate_class_declaration (Class cl, CCodeFile decl_space) {
		if(cl == null);
			print("Cl is null\n");
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["class"] = cl;
		args["decl_space"] = decl_space;
		PluginManager.swarmValue("generate/class/declaration", args);
	}

	public static void generate_method_declaration (Method m, CCodeFile decl_space) {
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["method"] = m;
		args["decl_space"] = decl_space;
		PluginManager.swarmValue("generate/method/declaration", args);
	}

	public static void generate_interface_declaration (Interface iface, CCodeFile decl_space) {
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["interface"] = iface;
		args["decl_space"] = decl_space;
		PluginManager.swarmValue("generate/interface/declaration", args);
	}

	public static void generate_delegate_declaration (Delegate d, CCodeFile decl_space) {
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["delegate"] = d;
		args["decl_space"] = decl_space;
		PluginManager.swarmValue("generate/delegate/declaration", args);
	}

	public static CCodeExpression? generate_method_to_delegate_cast_expression(CCodeExpression source_cexpr, DataType? expression_type, DataType? target_type, Expression? expr) {
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["source_cexpr"] = source_cexpr;
		args["expression_type"] = expression_type;
		args["target_type"] = target_type;
		args["expr"] = expr;
		CCodeExpression?outexpr = (CCodeExpression?)PluginManager.swarmValue("generate/delegate/cast", args);
		if(outexpr == null)
			print("Please report this bug, outexpr should not be null\n");
		return outexpr;
	}
	public static CCodeFunctionCall? generate_delegate_method_call_ccode (MethodCall expr) {
		CCodeFunctionCall?ccall = (CCodeFunctionCall?)PluginManager.swarmValue("generate/delegate/method/call", expr);
		if(ccall == null)
			print("Please report this bug, ccall should not be null\n");
		return ccall;
	}

	public static void generate_enum_declaration (Enum en, CCodeFile decl_space) {
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["enum"] = en;
		args["decl_space"] = decl_space;
		PluginManager.swarmValue("generate/enum/declaration", args);
	}

	public static CCodeParameter?generate_instance_cparameter_for_struct(Method m, CCodeParameter?param, DataType this_type) {
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["method"] = m;
		args["param"] = param;
		args["type"] = this_type;
		CCodeParameter?result = (CCodeParameter?)PluginManager.swarmValue("generate/instance_cparam/struct", args);
		if(result == null)
			print("Please report this bug, result for instance_cparameter_for_struct should not be null\n");
		return result;
	}

	public static void generate_temp_variable(LocalVariable tmp) { // emit_temp_var
		PluginManager.swarmValue("generate/temp", tmp);
	}

	public static CCodeExpression?generate_local_captured_variable(LocalVariable local) {
		CCodeExpression? cvalue = (CCodeExpression?)PluginManager.swarmValue("generate/local_variable/captured", local);//get_local_cvalue_for_block(local);
		if(cvalue == null)
			print("Please report this bug, value should not be null\n");
		return cvalue;
	}

	public static void generate_error_domain_declaration (ErrorDomain edomain, CCodeFile decl_space) {
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["edomain"] = edomain;
		args["decl_space"] = decl_space;
		PluginManager.swarmValue("generate/error_domain/declaration", args);
	}
	/*public void set_context(CodeContext context) {
		return PluginManager.swarmValue("set/context", context);
	}

	public void set_csource_filename(string?fn) {
		return PluginManager.swarmValue("set/csource_filename", fn);
	}*/
	public static void generate_type_declaration (DataType type, CCodeFile decl_space) {
		if (type is ObjectType) {
			var object_type = (ObjectType) type;
			if (object_type.type_symbol is Class) {
				Class?cl = (Class)object_type.type_symbol;
				if(cl == null) {
					print("debug:omitting class declaration %s\n", object_type.to_string());
					return;
				}
				generate_class_declaration (cl, decl_space);
			} else if (object_type.type_symbol is Interface) {
				generate_interface_declaration ((Interface) object_type.type_symbol, decl_space);
			}
		} else if (type is DelegateType) {
			var deleg_type = (DelegateType) type;
			var d = deleg_type.delegate_symbol;
			generate_delegate_declaration (d, decl_space);
		} else if (type.data_type is Enum) {
			var en = (Enum) type.data_type;
			generate_enum_declaration (en, decl_space);
		} else if (type is ValueType) {
			var value_type = (ValueType) type;
			Struct?st = (Struct)value_type.type_symbol;
			if(st == null) {
				print("debug:omitting struct declaration %s\n", value_type.to_string());
				return;
			}
			generate_struct_declaration (st, decl_space);
		} else if (type is ArrayType) {
			var array_type = (ArrayType) type;
#if false
			generate_struct_declaration (emitter.array_struct, decl_space);
#endif
			var elem = (DataType) array_type.element_type;
			if(elem == null) {
				print("debug:omitting element declaration %s\n", array_type.to_string());
				return;
			}
			generate_type_declaration (elem, decl_space);
		} else if (type is PointerType) {
			var pointer_type = (PointerType) type;
			assert(pointer_type.base_type != null);
			generate_type_declaration (pointer_type.base_type, decl_space);
		}

		foreach (DataType type_arg in type.get_type_arguments ()) {
			if(type_arg != null)generate_type_declaration (type_arg, decl_space);
		}
	}

	public static void populate_variables_of_parent_closure(Block b, bool populate_self, CCodeFunction decl_space) {
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["block"] = b;
		args["populate_self"] = populate_self;
		args["decl_space"] = decl_space;
		PluginManager.swarmValue("populate/parent/closure", args);
        }

	public static CCodeExpression? generate_delegate_closure_argument(Expression arg) {
		CCodeExpression?result = (CCodeExpression?)PluginManager.swarmValue("generate/delegate/closure/argument", arg);
		if(result == null)
			print("Please report this bug, result for generate_delegate_closure_argument should not be null\n");
		return result;
	}
	
	public static CCodeExpression? generate_cargument_for_struct (Vala.Parameter param, Expression arg, CCodeExpression? cexpr) {
		var args = new HashTable<string,Value?>(str_hash, str_equal);
		args["param"] = param;
		args["arg"] = arg;
		args["cexpr"] = cexpr;
		CCodeExpression?result = (CCodeExpression?)PluginManager.swarmValue("generate/struct/cargument", args);
		if(result == null)
			print("Please report this bug, result for generate_cargument_for_struct should not be null\n");
		return result;
	}

	public static void generate_cparameters (Method m, CCodeFile decl_space, CCodeFunction func, CCodeFunctionDeclarator? vdeclarator = null, CCodeFunctionCall? vcall = null) {
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["method"] = m;
		args["decl_space"] = decl_space;
		args["func"] = func;
		args["vdeclarator"] = vdeclarator;
		args["vcall"] = vcall;
		PluginManager.swarmValue("generate/cparameter", args);
	}

	public static CCodeExpression?generate_instance_cast (CCodeExpression expr, TypeSymbol type) {
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["expr"] = expr;
		args["type"] = type;
		CCodeExpression?result = (CCodeExpression?)PluginManager.swarmValue("generate/instance/cast", args);
		if(result == null)
			print("Please report this bug, result for generate_instance_cast should not be null\n");
		return result;
	}

	public static string? generate_block_name(Block b) {
		string? result = (string?)PluginManager.swarmValue("generate/block/name", b);
		if(result == null)
			print("Please report this bug, result for generate_block_name should not be null\n");
		return result;
	}

	public static string? generate_block_var_name(Block b) {
		string? result = (string?)PluginManager.swarmValue("generate/block/var/name", b);
		if(result == null)
			print("Please report this bug, result for generate_block_var_name should not be null\n");
		return result;
	}

	public static void generate_block_finalization(Block b, CCodeFunction decl_space) {
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["block"] = b;
		args["decl_space"] = decl_space;
		PluginManager.swarmValue("generate/block/finalization", args);
	}

	public static void generate_property_accessor_declaration (PropertyAccessor acc, CCodeFile decl_space) {
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["acc"] = acc;
		args["decl_space"] = decl_space;
		PluginManager.swarmValue("generate/property_accessor/declaration", args);
	}

	public static CCodeExpression?generate_instance_cargument_for_struct(MemberAccess ma, Method m, CCodeExpression instance) { 
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["ma"] = ma;
		args["m"] = m;
		args["instance"] = instance;
		CCodeExpression?result = (CCodeExpression?)PluginManager.swarmValue("generate/struct/instance/cargument", args);
		if(result == null)
			print("Please report this bug, result for generate_instance_cargument_for_struct should not be null\n");
		return result;
	}

	public static void add_generic_type_arguments (CCodeFunctionCall ccall,Vala.List<DataType> type_args, CodeNode expr, bool is_chainup = false) {
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["ccall"] = ccall;
		args["type_args"] = type_args;
		args["expr"] = expr;
		args["is_chainup"] = is_chainup;
		PluginManager.swarmValue("add/generic_type_arguments", args);
	}

	public static void add_simple_check(CodeNode node, bool always_fails = false) { 
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["node"] = node;
		args["always_fails"] = always_fails;
		PluginManager.swarmValue("add/simple/check", args);
	}

	public static void append_local_free (Symbol sym, bool stop_at_loop = false, CodeNode? stop_at = null) {
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["sym"] = sym;
		args["stop_at_loop"] = stop_at_loop;
		args["stop_at"] = stop_at;
		PluginManager.swarmValue("append/cleanup/local", args);
	}


	public static void store_variable (Variable variable, TargetValue lvalue, TargetValue xvalue, bool initializer) {
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["variable"] = variable;
		args["lvalue"] = lvalue;
		args["xvalue"] = xvalue;
		args["initializer"] = initializer;
		PluginManager.swarmValue("store/variable", args);
	}

	public static void store_property (Property prop, Expression? instance, TargetValue xvalue) {
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["prop"] = prop;
		args["instance"] = instance;
		args["xvalue"] = xvalue;
		PluginManager.swarmValue("store/property", args);
	}
}
	
