using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.AroopCodeGeneratorModule : shotodolplug.Module {
	AroopCodeGenerator cgen;	
	public AroopCodeGeneratorModule() {
		base("CodeGenerator", "0.0");
		cgen = new AroopCodeGenerator();
	}

	public override int init() {
		PluginManager.register("compiler/c/codegen", new HookExtension(getInstance, this));
		return 0;
	}

	public override int deinit() {
		return 0;
	}

	Value?getInstance(Value?param) {
		print("get interface cb\n");
		return cgen;
	}
}

internal class codegenplug.AroopCodeGenerator : CodeGenerator {
	public override void visit_source_file(SourceFile source_file) {
		string visit_exten= "visit/source_file";
		print("visiting source file\n");
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["source_file"] = source_file;
		PluginManager.swarmValue(visit_exten, args);
	}
	public override void visit_namespace(Namespace ns) {
		string visit_exten= "visit/namespace";
		PluginManager.swarmValue(visit_exten, ns);
	}
	public override void visit_class(Class cl) {
		string visit_exten= "visit/class";
		print("visiting class\n");
		PluginManager.swarmValue(visit_exten, cl);
	}
	public override void visit_struct(Struct st) {
		string visit_exten= "visit/struct";
		print("visiting struct\n");
		PluginManager.swarmValue(visit_exten, st);
	}
	public override void visit_interface(Interface iface) {
		string visit_exten= "visit/interface";
		PluginManager.swarmValue(visit_exten, iface);
	}
	public override void visit_enum(Enum en) {
		string visit_exten= "visit/interface";
		PluginManager.swarmValue(visit_exten, en);
	}
	public override void visit_enum_value(Vala.EnumValue ev) {
		string visit_exten= "visit/enum_value";
		PluginManager.swarmValue(visit_exten, ev);
	}
	public override void visit_error_domain(ErrorDomain edomain) {
		string visit_exten= "visit/error_domain";
		PluginManager.swarmValue(visit_exten, edomain);
	}
	public override void visit_error_code(ErrorCode ecode) {
		string visit_exten= "visit/error_code";
		PluginManager.swarmValue(visit_exten, ecode);
	}
	public override void visit_delegate(Delegate d) {
		string visit_exten= "visit/delegate";
		PluginManager.swarmValue(visit_exten, d);
	}
	public override void visit_constant(Constant c) {
		string visit_exten= "visit/constant";
		PluginManager.swarmValue(visit_exten, c);
	}
	public override void visit_field(Field f) {
		string visit_exten= "visit/field";
		PluginManager.swarmValue(visit_exten, f);
	}
	public override void visit_method(Method m) {
		string visit_exten= "visit/method";
		PluginManager.swarmValue(visit_exten, m);
	}
	public override void visit_creation_method(CreationMethod m) {
		string visit_exten= "visit/creation_method";
		PluginManager.swarmValue(visit_exten, m);
	}
	public override void visit_formal_parameter(Vala.Parameter m) {
		string visit_exten= "visit/formal_parameter";
		PluginManager.swarmValue(visit_exten, m);
	}
	public override void visit_property(Property prop) {
		string visit_exten= "visit/property";
		PluginManager.swarmValue(visit_exten, prop);
	}
	public override void visit_property_accessor (PropertyAccessor acc) {
		string visit_exten= "visit/property_accessor";
		PluginManager.swarmValue(visit_exten, acc);
	}

	public override void visit_signal (Vala.Signal sig) {
		string visit_exten= "visit/signal";
		PluginManager.swarmValue(visit_exten, sig);
	}

	public override void visit_constructor (Constructor c) {
		string visit_exten= "visit/constructor";
		PluginManager.swarmValue(visit_exten, c);
	}

	public override void visit_destructor (Destructor d) {
		string visit_exten= "visit/destructor";
		PluginManager.swarmValue(visit_exten, d);
	}

	public override void visit_type_parameter (TypeParameter p) {
		string visit_exten= "visit/type_parameter";
		PluginManager.swarmValue(visit_exten, p);
	}

	public override void visit_using_directive (UsingDirective ns) {
		string visit_exten= "visit/using_directive";
		PluginManager.swarmValue(visit_exten, ns);
	}

	public override void visit_data_type (DataType type) {
		string visit_exten= "visit/data_type";
		PluginManager.swarmValue(visit_exten, type);
	}

	public override void visit_block (Block b) {
		string visit_exten= "visit/block";
		PluginManager.swarmValue(visit_exten, b);
	}

	public override void visit_empty_statement (EmptyStatement stmt) {
		string visit_exten= "visit/empty_statement";
		PluginManager.swarmValue(visit_exten, stmt);
	}

	public override void visit_declaration_statement (DeclarationStatement stmt) {
		string visit_exten= "visit/declaration_statement";
		PluginManager.swarmValue(visit_exten, stmt);
	}

	public override void visit_local_variable (LocalVariable local) {
		string visit_exten= "visit/local_variable";
		PluginManager.swarmValue(visit_exten, local);
	}

	public override void visit_initializer_list (InitializerList list) {
		string visit_exten= "visit/initializer_list";
		PluginManager.swarmValue(visit_exten, list);
	}

	public override void visit_expression_statement (ExpressionStatement stmt) {
		PluginManager.swarmValue("visit/expression_statement", stmt);
	}

	public override void visit_if_statement (IfStatement stmt) {
		string visit_exten= "visit/if_statement";
		PluginManager.swarmValue(visit_exten, stmt);
	}

	public override void visit_switch_statement (SwitchStatement stmt) {
		string visit_exten= "visit/switch_statement";
		PluginManager.swarmValue(visit_exten, stmt);
	}

	public override void visit_switch_section (SwitchSection section) {
		string visit_exten= "visit/switch_section";
		PluginManager.swarmValue(visit_exten, section);
	}

	public override void visit_switch_label (SwitchLabel label) {
		string visit_exten= "visit/switch_label";
		PluginManager.swarmValue(visit_exten, label);
	}

	public override void visit_loop (Loop stmt) {
		string visit_exten= "visit/loop";
		PluginManager.swarmValue(visit_exten, stmt);
	}

	public override void visit_while_statement (WhileStatement stmt) {
		string visit_exten= "visit/while_statement";
		PluginManager.swarmValue(visit_exten, stmt);
	}

	public override void visit_do_statement (DoStatement stmt) {
		string visit_exten= "visit/do_statement";
		PluginManager.swarmValue(visit_exten, stmt);
	}

	public override void visit_for_statement (ForStatement stmt) {
		string visit_exten= "visit/for_statement";
		PluginManager.swarmValue(visit_exten, stmt);
	}

	public override void visit_foreach_statement (ForeachStatement stmt) {
		string visit_exten= "visit/foreach_statement";
		PluginManager.swarmValue(visit_exten, stmt);
	}

	public override void visit_break_statement (BreakStatement stmt) {
		string visit_exten= "visit/break_statement";
		PluginManager.swarmValue(visit_exten, stmt);
	}

	public override void visit_continue_statement (ContinueStatement stmt) {
		string visit_exten= "visit/continue_statement";
		PluginManager.swarmValue(visit_exten, stmt);
	}

	public override void visit_return_statement (ReturnStatement stmt) {
		string visit_exten= "visit/return_statement";
		PluginManager.swarmValue(visit_exten, stmt);
	}

	public override void visit_yield_statement (YieldStatement y) {
		string visit_exten= "visit/yield_statement";
		PluginManager.swarmValue(visit_exten, y);
	}

	public override void visit_throw_statement (ThrowStatement stmt) {
		string visit_exten= "visit/throw_statement";
		PluginManager.swarmValue(visit_exten, stmt);
	}

	public override void visit_try_statement (TryStatement stmt) {
		string visit_exten= "visit/try_statement";
		PluginManager.swarmValue(visit_exten, stmt);
	}

	public override void visit_catch_clause (CatchClause clause) {
		string visit_exten= "visit/catch_clause";
		PluginManager.swarmValue(visit_exten, clause);
	}

	public override void visit_lock_statement (LockStatement stmt) {
		string visit_exten= "visit/lock_statement";
		PluginManager.swarmValue(visit_exten, stmt);
	}

	public override void visit_unlock_statement (UnlockStatement stmt) {
		string visit_exten= "visit/unlock_statement";
		PluginManager.swarmValue(visit_exten, stmt);
	}

	public override void visit_delete_statement (DeleteStatement stmt) {
		string visit_exten= "visit/delete_statement";
		PluginManager.swarmValue(visit_exten, stmt);
	}

	public override void visit_expression (Expression expr) {
		PluginManager.swarmValue("visit/expression", expr);
	}

	public override void visit_array_creation_expression (ArrayCreationExpression expr) {
		string visit_exten= "visit/array_creation_expression";
		PluginManager.swarmValue(visit_exten, expr);
	}

	public override void visit_boolean_literal (BooleanLiteral lit) {
		string visit_exten= "visit/boolean_literal";
		PluginManager.swarmValue(visit_exten, lit);
	}

	public override void visit_character_literal (CharacterLiteral lit) {
		string visit_exten= "visit/character_literal";
		PluginManager.swarmValue(visit_exten, lit);
	}

	public override void visit_integer_literal (IntegerLiteral lit) {
		string visit_exten= "visit/integer_literal";
		PluginManager.swarmValue(visit_exten, lit);
	}

	public override void visit_real_literal (RealLiteral lit) {
		string visit_exten= "visit/real_literal";
		PluginManager.swarmValue(visit_exten, lit);
	}

	public override void visit_regex_literal (RegexLiteral lit) {
		string visit_exten= "visit/regex_literal";
		PluginManager.swarmValue(visit_exten, lit);
	}

	public override void visit_string_literal (StringLiteral lit) {
		PluginManager.swarmValue("visit/string_literal", lit);
	}

	public override void visit_template (Template tmpl) {
		string visit_exten= "visit/template";
		PluginManager.swarmValue(visit_exten, tmpl);
	}

	public override void visit_tuple (Tuple tuple) {
		string visit_exten= "visit/tuple";
		PluginManager.swarmValue(visit_exten, tuple);
	}

	public override void visit_null_literal (NullLiteral lit) {
		string visit_exten= "visit/null_literal";
		PluginManager.swarmValue(visit_exten, lit);
	}

	public override void visit_member_access (MemberAccess expr) {
		string visit_exten= "visit/member_access";
		PluginManager.swarmValue(visit_exten, expr);
	}

	public override void visit_method_call (MethodCall expr) {
		PluginManager.swarmValue("visit/method_call", expr);
	}
	
	public override void visit_element_access (ElementAccess expr) {
		string visit_exten= "visit/element_access";
		PluginManager.swarmValue(visit_exten, expr);
	}

	public override void visit_slice_expression (SliceExpression expr) {
		string visit_exten= "visit/slice_expression";
		PluginManager.swarmValue(visit_exten, expr);
	}

	public override void visit_base_access (BaseAccess expr) {
		string visit_exten= "visit/base_access";
		PluginManager.swarmValue(visit_exten, expr);
	}

	public override void visit_postfix_expression (PostfixExpression expr) {
		string visit_exten= "visit/postfix_expression";
		PluginManager.swarmValue(visit_exten, expr);
	}

	public override void visit_object_creation_expression (ObjectCreationExpression expr) {
		string visit_exten= "visit/creation_expression";
		PluginManager.swarmValue(visit_exten, expr);
	}

	public override void visit_sizeof_expression (SizeofExpression expr) {
		string visit_exten= "visit/sizeof_expression";
		PluginManager.swarmValue(visit_exten, expr);
	}

	public override void visit_typeof_expression (TypeofExpression expr) {
		string visit_exten= "visit/typeof_expression";
		PluginManager.swarmValue(visit_exten, expr);
	}

	public override void visit_unary_expression (UnaryExpression expr) {
		string visit_exten= "visit/unary_expression";
		PluginManager.swarmValue(visit_exten, expr);
	}

	public override void visit_cast_expression (CastExpression expr) {
		string visit_exten= "visit/cast_expression";
		PluginManager.swarmValue(visit_exten, expr);
	}

	public override void visit_named_argument (NamedArgument expr) {
		string visit_exten= "visit/named_argument";
		PluginManager.swarmValue(visit_exten, expr);
	}

	public override void visit_pointer_indirection (PointerIndirection expr) {
		string visit_exten= "visit/pointer_indirection";
		PluginManager.swarmValue(visit_exten, expr);
	}

	public override void visit_addressof_expression (AddressofExpression expr) {
		string visit_exten= "visit/addressof_indirection";
		PluginManager.swarmValue(visit_exten, expr);
	}

	public override void visit_reference_transfer_expression (ReferenceTransferExpression expr) {
		string visit_exten= "visit/reference_transfer_expression";
		PluginManager.swarmValue(visit_exten, expr);
	}

	public override void visit_binary_expression (BinaryExpression expr) {
		string visit_exten= "visit/binary_expression";
		PluginManager.swarmValue(visit_exten, expr);
	}

	public override void visit_type_check (TypeCheck expr) {
		string visit_exten= "visit/type_check";
		PluginManager.swarmValue(visit_exten, expr);
	}

	public override void visit_conditional_expression (ConditionalExpression expr) {
		string visit_exten= "visit/conditional_expression";
		PluginManager.swarmValue(visit_exten, expr);
	}

	public override void visit_lambda_expression (LambdaExpression expr) {
		string visit_exten= "visit/lambda_expression";
		PluginManager.swarmValue(visit_exten, expr);
	}

	public override void visit_assignment (Assignment a) {
		string visit_exten= "visit/assignment";
		PluginManager.swarmValue(visit_exten, a);
	}

	public override void visit_end_full_expression (Expression expr) {
		string visit_exten= "visit/full_expression";
		PluginManager.swarmValue(visit_exten, expr);
	}

	public override LocalVariable create_local (DataType type) {
		string exten= "create/local";
		return (LocalVariable)PluginManager.swarmValue(exten, type);
	}

	public override TargetValue load_local (LocalVariable local) {
		string exten= "load/local";
		return (TargetValue)PluginManager.swarmValue(exten, local);
	}

	public override void store_local (LocalVariable local, TargetValue value, bool initializer) {
		string exten= "store/local";
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["local"] = local;
		args["value"] = value;
		args["initializer"] = initializer;
		PluginManager.swarmValue(exten, args);
	}

	public override TargetValue load_parameter (Vala.Parameter param) {
		string exten= "load/parameter";
		return (TargetValue)PluginManager.swarmValue(exten, param);
	}

	public override void store_parameter (Vala.Parameter param, TargetValue value, bool capturing_parameter = false) {
		string exten= "store/parameter";
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["param"] = param;
		args["value"] = value;
		args["capturing_parameter"] = capturing_parameter?"1":"0";
		PluginManager.swarmValue(exten, args);
	}

	public override TargetValue load_field (Field field, TargetValue? instance) {
		string exten= "store/field";
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["field"] = field;
		args["instance"] = instance;
		return (TargetValue)PluginManager.swarmValue(exten, args);
	}

	public override void store_field (Field field, TargetValue? instance, TargetValue value) {
		string exten= "store/field";
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["field"] = field;
		args["instance"] = instance;
		args["value"] = value;
		PluginManager.swarmValue(exten, args);
	}

	public override void emit (CodeContext context) {
		string exten= "source/emit";
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["context"] = context;
		args["visitor"] = this;
		PluginManager.swarmValue(exten, args);
	}
}

internal class codegenplug.AroopCodeGeneratorAdapter {

	private AroopCodeGeneratorAdapter() {
	}
	
	public static void generate_element_destruction_code(Field f, CCodeBlock stmt) {
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["field"] = f;
		args["stmt"] = stmt;
		PluginManager.swarmValue("generate/element/destruction", args);
	}

	public static void generate_element_declaration(Field f, CCodeStruct container, CCodeFile decl_space, bool internalSymbol = true) {
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["field"] = f;
		args["container"] = container;
		args["decl_space"] = decl_space;
		args["internalSymbol"] = internalSymbol?"1":"0";
		PluginManager.swarmValue("generate/element/declaration", args);
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
		assert(cl != null);
		args["class"] = cl;
		args["decl_space"] = decl_space;
		PluginManager.swarmValue("generate/class/declaration", args);
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
		return (CCodeParameter?)PluginManager.swarmValue("generate/instance_cparam/struct", args);
	}

	public static CCodeParameter?generate_temp_variable(LocalVariable tmp) {
		return (CCodeParameter?)PluginManager.swarmValue("generate/temp", tmp);
	}

	/*public void set_context(CodeContext context) {
		return PluginManager.swarmValue("set/context", context);
	}

	public void set_csource_filename(string?fn) {
		return PluginManager.swarmValue("set/csource_filename", fn);
	}*/
	public static void generate_type_declaration (DataType type, CCodeFile decl_space) {
		// TODO fill me
		if (type is ObjectType) {
			var object_type = (ObjectType) type;
			if (object_type.type_symbol is Class) {
				generate_class_declaration ((Class) object_type.type_symbol, decl_space);
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
			generate_struct_declaration ((Struct) value_type.type_symbol, decl_space);
		} else if (type is ArrayType) {
			var array_type = (ArrayType) type;
#if false
			generate_struct_declaration (emitter.array_struct, decl_space);
#endif
			assert(array_type.element_type != null);
			generate_type_declaration (array_type.element_type, decl_space);
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
		args["populate_self"] = populate_self?"1":"0";
		args["decl_space"] = decl_space;
		PluginManager.swarmValue("populate/parent/closure", args);
        }
	
	public static CCodeExpression? generate_cargument_for_struct (Vala.Parameter param, Expression arg, CCodeExpression? cexpr) {
		var args = new HashTable<string,Value?>(str_hash, str_equal);
		args["param"] = param;
		args["arg"] = arg;
		args["cexpr"] = cexpr;
		PluginManager.swarmValue("generate/struct/cargument", args);
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

	public static string? generate_block_name(Block b) {
		return (string?)PluginManager.swarmValue("generate/block/name", b);
	}

	public static string? generate_block_var_name(Block b) {
		return (string?)PluginManager.swarmValue("generate/block/var/name", b);
	}
	public static CCodeExpression?generate_instance_cargument_for_struct(MemberAccess ma, Method m, CCodeExpression instance) { 
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["ma"] = ma;
		args["m"] = m;
		args["instance"] = instance;
		return (CCodeExpression?)PluginManager.swarmValue("generate/struct/instance/cargument", args);
	}
}
	
