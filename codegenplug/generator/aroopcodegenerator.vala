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
		PluginManager.register("compiler/c/codegen", new HookExtension((Hook)getInstance, this));
		return 0;
	}

	public override int deinit() {
		return 0;
	}

	Object getInstance(Object?param) {
		if(cgen == null)
			print("giving back null code generator\n");
		else
			print("giving back current code generator\n");
		return (Object)cgen;
	}
}

internal class codegenplug.AroopCodeGenerator : CodeGenerator {
	public override void visit_source_file(SourceFile source_file) {
		string visit_exten= "visit/source_file";
		print("visiting source file\n");
		PluginManager.swarmObject(visit_exten, (Object)source_file);
	}
	public override void visit_namespace(Namespace ns) {
		string visit_exten= "visit/namespace";
		PluginManager.swarmObject(visit_exten, (Object)ns);
	}
	public override void visit_class(Class cl) {
		string visit_exten= "visit/class";
		print("visiting class\n");
		PluginManager.swarmObject(visit_exten, (Object)cl);
	}
	public override void visit_struct(Struct st) {
		string visit_exten= "visit/struct";
		print("visiting struct\n");
		PluginManager.swarmObject(visit_exten, (Object)st);
	}
	public override void visit_interface(Interface iface) {
		string visit_exten= "visit/interface";
		PluginManager.swarmObject(visit_exten, (Object)iface);
	}
	public override void visit_enum(Enum en) {
		string visit_exten= "visit/interface";
		PluginManager.swarmObject(visit_exten, (Object)en);
	}
	public override void visit_enum_value(Vala.EnumValue ev) {
		string visit_exten= "visit/enum_value";
		PluginManager.swarmObject(visit_exten, (Object)ev);
	}
	public override void visit_error_domain(ErrorDomain edomain) {
		string visit_exten= "visit/error_domain";
		PluginManager.swarmObject(visit_exten, (Object)edomain);
	}
	public override void visit_error_code(ErrorCode ecode) {
		string visit_exten= "visit/error_code";
		PluginManager.swarmObject(visit_exten, (Object)ecode);
	}
	public override void visit_delegate(Delegate d) {
		string visit_exten= "visit/delegate";
		PluginManager.swarmObject(visit_exten, (Object)d);
	}
	public override void visit_constant(Constant c) {
		string visit_exten= "visit/constant";
		PluginManager.swarmObject(visit_exten, (Object)c);
	}
	public override void visit_field(Field f) {
		string visit_exten= "visit/field";
		PluginManager.swarmObject(visit_exten, (Object)f);
	}
	public override void visit_method(Method m) {
		string visit_exten= "visit/method";
		PluginManager.swarmObject(visit_exten, (Object)m);
	}
	public override void visit_creation_method(CreationMethod m) {
		string visit_exten= "visit/creation_method";
		PluginManager.swarmObject(visit_exten, (Object)m);
	}
	public override void visit_formal_parameter(Vala.Parameter m) {
		string visit_exten= "visit/formal_parameter";
		PluginManager.swarmObject(visit_exten, (Object)m);
	}
	public override void visit_property(Property prop) {
		string visit_exten= "visit/property";
		PluginManager.swarmObject(visit_exten, (Object)prop);
	}
	public override void visit_property_accessor (PropertyAccessor acc) {
		string visit_exten= "visit/property_accessor";
		PluginManager.swarmObject(visit_exten, (Object)acc);
	}

	public override void visit_signal (Vala.Signal sig) {
		string visit_exten= "visit/signal";
		PluginManager.swarmObject(visit_exten, (Object)sig);
	}

	public override void visit_constructor (Constructor c) {
		string visit_exten= "visit/constructor";
		PluginManager.swarmObject(visit_exten, (Object)c);
	}

	public override void visit_destructor (Destructor d) {
		string visit_exten= "visit/destructor";
		PluginManager.swarmObject(visit_exten, (Object)d);
	}

	public override void visit_type_parameter (TypeParameter p) {
		string visit_exten= "visit/type_parameter";
		PluginManager.swarmObject(visit_exten, (Object)p);
	}

	public override void visit_using_directive (UsingDirective ns) {
		string visit_exten= "visit/using_directive";
		PluginManager.swarmObject(visit_exten, (Object)ns);
	}

	public override void visit_data_type (DataType type) {
		string visit_exten= "visit/data_type";
		PluginManager.swarmObject(visit_exten, (Object)type);
	}

	public override void visit_block (Block b) {
		string visit_exten= "visit/block";
		PluginManager.swarmObject(visit_exten, (Object)b);
	}

	public override void visit_empty_statement (EmptyStatement stmt) {
		string visit_exten= "visit/empty_statement";
		PluginManager.swarmObject(visit_exten, (Object)stmt);
	}

	public override void visit_declaration_statement (DeclarationStatement stmt) {
		string visit_exten= "visit/declaration_statement";
		PluginManager.swarmObject(visit_exten, (Object)stmt);
	}

	public override void visit_local_variable (LocalVariable local) {
		string visit_exten= "visit/local_variable";
		PluginManager.swarmObject(visit_exten, (Object)local);
	}

	public override void visit_initializer_list (InitializerList list) {
		string visit_exten= "visit/initializer_list";
		PluginManager.swarmObject(visit_exten, (Object)list);
	}

	public override void visit_expression_statement (ExpressionStatement stmt) {
		string visit_exten= "visit/expression_statement";
		PluginManager.swarmObject(visit_exten, (Object)stmt);
	}

	public override void visit_if_statement (IfStatement stmt) {
		string visit_exten= "visit/if_statement";
		PluginManager.swarmObject(visit_exten, (Object)stmt);
	}

	public override void visit_switch_statement (SwitchStatement stmt) {
		string visit_exten= "visit/switch_statement";
		PluginManager.swarmObject(visit_exten, (Object)stmt);
	}

	public override void visit_switch_section (SwitchSection section) {
		string visit_exten= "visit/switch_section";
		PluginManager.swarmObject(visit_exten, (Object)section);
	}

	public override void visit_switch_label (SwitchLabel label) {
		string visit_exten= "visit/switch_label";
		PluginManager.swarmObject(visit_exten, (Object)label);
	}

	public override void visit_loop (Loop stmt) {
		string visit_exten= "visit/loop";
		PluginManager.swarmObject(visit_exten, (Object)stmt);
	}

	public override void visit_while_statement (WhileStatement stmt) {
		string visit_exten= "visit/while_statement";
		PluginManager.swarmObject(visit_exten, (Object)stmt);
	}

	public override void visit_do_statement (DoStatement stmt) {
		string visit_exten= "visit/do_statement";
		PluginManager.swarmObject(visit_exten, (Object)stmt);
	}

	public override void visit_for_statement (ForStatement stmt) {
		string visit_exten= "visit/for_statement";
		PluginManager.swarmObject(visit_exten, (Object)stmt);
	}

	public override void visit_foreach_statement (ForeachStatement stmt) {
		string visit_exten= "visit/foreach_statement";
		PluginManager.swarmObject(visit_exten, (Object)stmt);
	}

	public override void visit_break_statement (BreakStatement stmt) {
		string visit_exten= "visit/break_statement";
		PluginManager.swarmObject(visit_exten, (Object)stmt);
	}

	public override void visit_continue_statement (ContinueStatement stmt) {
		string visit_exten= "visit/continue_statement";
		PluginManager.swarmObject(visit_exten, (Object)stmt);
	}

	public override void visit_return_statement (ReturnStatement stmt) {
		string visit_exten= "visit/return_statement";
		PluginManager.swarmObject(visit_exten, (Object)stmt);
	}

	public override void visit_yield_statement (YieldStatement y) {
		string visit_exten= "visit/yield_statement";
		PluginManager.swarmObject(visit_exten, (Object)y);
	}

	public override void visit_throw_statement (ThrowStatement stmt) {
		string visit_exten= "visit/throw_statement";
		PluginManager.swarmObject(visit_exten, (Object)stmt);
	}

	public override void visit_try_statement (TryStatement stmt) {
		string visit_exten= "visit/try_statement";
		PluginManager.swarmObject(visit_exten, (Object)stmt);
	}

	public override void visit_catch_clause (CatchClause clause) {
		string visit_exten= "visit/catch_clause";
		PluginManager.swarmObject(visit_exten, (Object)clause);
	}

	public override void visit_lock_statement (LockStatement stmt) {
		string visit_exten= "visit/lock_statement";
		PluginManager.swarmObject(visit_exten, (Object)stmt);
	}

	public override void visit_unlock_statement (UnlockStatement stmt) {
		string visit_exten= "visit/unlock_statement";
		PluginManager.swarmObject(visit_exten, (Object)stmt);
	}

	public override void visit_delete_statement (DeleteStatement stmt) {
		string visit_exten= "visit/delete_statement";
		PluginManager.swarmObject(visit_exten, (Object)stmt);
	}

	public override void visit_expression (Expression expr) {
		string visit_exten= "visit/expression";
		PluginManager.swarmObject(visit_exten, (Object)expr);
	}

	public override void visit_array_creation_expression (ArrayCreationExpression expr) {
		string visit_exten= "visit/array_creation_expression";
		PluginManager.swarmObject(visit_exten, (Object)expr);
	}

	public override void visit_boolean_literal (BooleanLiteral lit) {
		string visit_exten= "visit/boolean_literal";
		PluginManager.swarmObject(visit_exten, (Object)lit);
	}

	public override void visit_character_literal (CharacterLiteral lit) {
		string visit_exten= "visit/character_literal";
		PluginManager.swarmObject(visit_exten, (Object)lit);
	}

	public override void visit_integer_literal (IntegerLiteral lit) {
		string visit_exten= "visit/integer_literal";
		PluginManager.swarmObject(visit_exten, (Object)lit);
	}

	public override void visit_real_literal (RealLiteral lit) {
		string visit_exten= "visit/real_literal";
		PluginManager.swarmObject(visit_exten, (Object)lit);
	}

	public override void visit_regex_literal (RegexLiteral lit) {
		string visit_exten= "visit/regex_literal";
		PluginManager.swarmObject(visit_exten, (Object)lit);
	}

	public override void visit_string_literal (StringLiteral lit) {
		string visit_exten= "visit/string_literal";
		PluginManager.swarmObject(visit_exten, (Object)lit);
	}

	public override void visit_template (Template tmpl) {
		string visit_exten= "visit/template";
		PluginManager.swarmObject(visit_exten, (Object)tmpl);
	}

	public override void visit_tuple (Tuple tuple) {
		string visit_exten= "visit/tuple";
		PluginManager.swarmObject(visit_exten, (Object)tuple);
	}

	public override void visit_null_literal (NullLiteral lit) {
		string visit_exten= "visit/null_literal";
		PluginManager.swarmObject(visit_exten, (Object)lit);
	}

	public override void visit_member_access (MemberAccess expr) {
		string visit_exten= "visit/member_access";
		PluginManager.swarmObject(visit_exten, (Object)expr);
	}

	public override void visit_method_call (MethodCall expr) {
		string visit_exten= "visit/method_call";
		PluginManager.swarmObject(visit_exten, (Object)expr);
	}
	
	public override void visit_element_access (ElementAccess expr) {
		string visit_exten= "visit/element_access";
		PluginManager.swarmObject(visit_exten, (Object)expr);
	}

	public override void visit_slice_expression (SliceExpression expr) {
		string visit_exten= "visit/slice_expression";
		PluginManager.swarmObject(visit_exten, (Object)expr);
	}

	public override void visit_base_access (BaseAccess expr) {
		string visit_exten= "visit/base_access";
		PluginManager.swarmObject(visit_exten, (Object)expr);
	}

	public override void visit_postfix_expression (PostfixExpression expr) {
		string visit_exten= "visit/postfix_expression";
		PluginManager.swarmObject(visit_exten, (Object)expr);
	}

	public override void visit_object_creation_expression (ObjectCreationExpression expr) {
		string visit_exten= "visit/creation_expression";
		PluginManager.swarmObject(visit_exten, (Object)expr);
	}

	public override void visit_sizeof_expression (SizeofExpression expr) {
		string visit_exten= "visit/sizeof_expression";
		PluginManager.swarmObject(visit_exten, (Object)expr);
	}

	public override void visit_typeof_expression (TypeofExpression expr) {
		string visit_exten= "visit/typeof_expression";
		PluginManager.swarmObject(visit_exten, (Object)expr);
	}

	public override void visit_unary_expression (UnaryExpression expr) {
		string visit_exten= "visit/unary_expression";
		PluginManager.swarmObject(visit_exten, (Object)expr);
	}

	public override void visit_cast_expression (CastExpression expr) {
		string visit_exten= "visit/cast_expression";
		PluginManager.swarmObject(visit_exten, (Object)expr);
	}

	public override void visit_named_argument (NamedArgument expr) {
		string visit_exten= "visit/named_argument";
		PluginManager.swarmObject(visit_exten, (Object)expr);
	}

	public override void visit_pointer_indirection (PointerIndirection expr) {
		string visit_exten= "visit/pointer_indirection";
		PluginManager.swarmObject(visit_exten, (Object)expr);
	}

	public override void visit_addressof_expression (AddressofExpression expr) {
		string visit_exten= "visit/addressof_indirection";
		PluginManager.swarmObject(visit_exten, (Object)expr);
	}

	public override void visit_reference_transfer_expression (ReferenceTransferExpression expr) {
		string visit_exten= "visit/reference_transfer_expression";
		PluginManager.swarmObject(visit_exten, (Object)expr);
	}

	public override void visit_binary_expression (BinaryExpression expr) {
		string visit_exten= "visit/binary_expression";
		PluginManager.swarmObject(visit_exten, (Object)expr);
	}

	public override void visit_type_check (TypeCheck expr) {
		string visit_exten= "visit/type_check";
		print("visiting type check\n");
		PluginManager.swarmObject(visit_exten, (Object)expr);
	}

	public override void visit_conditional_expression (ConditionalExpression expr) {
		string visit_exten= "visit/conditional_expression";
		PluginManager.swarmObject(visit_exten, (Object)expr);
	}

	public override void visit_lambda_expression (LambdaExpression expr) {
		string visit_exten= "visit/lambda_expression";
		PluginManager.swarmObject(visit_exten, (Object)expr);
	}

	public override void visit_assignment (Assignment a) {
		string visit_exten= "visit/assignment";
		PluginManager.swarmObject(visit_exten, (Object)a);
	}

	public override void visit_end_full_expression (Expression expr) {
		string visit_exten= "visit/full_expression";
		PluginManager.swarmObject(visit_exten, (Object)expr);
	}

	public override LocalVariable create_local (DataType type) {
		string exten= "create/local";
		return (LocalVariable)PluginManager.swarmObject(exten, (Object)type);
	}

	public override TargetValue load_local (LocalVariable local) {
		string exten= "load/local";
		return (TargetValue)PluginManager.swarmObject(exten, (Object)local);
	}

	public override void store_local (LocalVariable local, TargetValue value, bool initializer) {
		string exten= "store/local";
		var args = new HashMap<string,Object>();
		args["local"] = (Object)local;
		args["value"] = (Object)value;
		args["initializer"] = (Object)initializer;
		PluginManager.swarmObject(exten, (Object)args);
	}

	public override TargetValue load_parameter (Vala.Parameter param) {
		string exten= "load/parameter";
		return (TargetValue)PluginManager.swarmObject(exten, (Object)param);
	}

	public override void store_parameter (Vala.Parameter param, TargetValue value, bool capturing_parameter = false) {
		string exten= "store/parameter";
		var args = new HashMap<string,Object>();
		args["param"] = (Object)param;
		args["value"] = (Object)value;
		args["capturing_parameter"] = (Object)(capturing_parameter?"1":"0");
		PluginManager.swarmObject(exten, (Object)args);
	}

	public override TargetValue load_field (Field field, TargetValue? instance) {
		string exten= "store/field";
		var args = new HashMap<string,Object>();
		args["field"] = (Object)field;
		args["instance"] = (Object)instance;
		return (TargetValue)PluginManager.swarmObject(exten, (Object)args);
	}

	public override void store_field (Field field, TargetValue? instance, TargetValue value) {
		string exten= "store/field";
		var args = new HashMap<string,Object>();
		args["field"] = (Object)field;
		args["instance"] = (Object)instance;
		args["value"] = (Object)value;
		PluginManager.swarmObject(exten, (Object)args);
	}

	public override void emit (CodeContext context) {
		string exten= "store/field";
		var args = new HashMap<string,Object>();
		args["context"] = (Object)context;
		args["visitor"] = (Object)this;
		PluginManager.swarmObject(exten, (Object)args);
	}
}

internal class codegenplug.AroopCodeGeneratorAdapter {
	
	public void generate_element_destruction_code(Field f, CCodeBlock stmt) {
		string visit_exten= "generate/element/destruction";
		var args = new HashMap<string,Object>();
		args["field"] = (Object)f;
		args["stmt"] = (Object)stmt;
		PluginManager.swarmObject(visit_exten, (Object)args);
	}

	public void generate_element_declaration(Field f, CCodeStruct container, CCodeFile decl_space, bool internalSymbol = true) {
		string visit_exten= "generate/element/declaration";
		var args = new HashMap<string,Object>();
		args["field"] = (Object)f;
		args["container"] = (Object)container;
		args["decl_space"] = (Object)decl_space;
		args["internalSymbol"] = internalSymbol?(Object)"1":(Object)"0";
		PluginManager.swarmObject(visit_exten, (Object)args);
	}
	public void generate_struct_declaration (Struct st, CCodeFile decl_space) {
		string visit_exten= "generate/struct/declaration";
		var args = new HashMap<string,Object>();
		args["struct"] = (Object)st;
		args["decl_space"] = (Object)decl_space;
		PluginManager.swarmObject(visit_exten, (Object)args);
	}

	public CCodeParameter?generate_instance_cparameter_for_struct(Method m, CCodeParameter?param, DataType this_type) {
		string visit_exten= "generate/instance_cparam/struct";
		var args = new HashMap<string,Object>();
		args["method"] = (Object)m;
		args["param"] = (Object)param;
		args["type"] = (Object)this_type;
		return (CCodeParameter)PluginManager.swarmObject(visit_exten, (Object)args);
	}

	public CCodeParameter?generate_temp_variable(LocalVariable tmp) {
		string visit_exten= "generate/temp";
		return (CCodeParameter)PluginManager.swarmObject(visit_exten, (Object)tmp);
	}

}
	
