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
		return cgen;
	}
}

internal class codegenplug.AroopCodeGenerator : CodeGenerator {
	public override void visit_source_file(SourceFile source_file) {
		string visit_exten= "visit/source_file";
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
		PluginManager.swarmValue(visit_exten, cl);
	}
	public override void visit_struct(Struct st) {
		string visit_exten= "visit/struct";
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
		PluginManager.swarmValue("visit/error_domain", edomain);
	}
	public override void visit_error_code(ErrorCode ecode) {
		PluginManager.swarmValue("visit/error_code", ecode);
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
		PluginManager.swarmValue("visit/formal_parameter", m);
	}
	public override void visit_property(Property prop) {
		PluginManager.swarmValue("visit/property", prop);
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

	/*public override void visit_data_type (DataType type) {
		string visit_exten= "visit/data_type";
		PluginManager.swarmValue(visit_exten, type);
	}*/

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
		PluginManager.swarmValue("visit/try_statement", stmt);
	}

	public override void visit_catch_clause (CatchClause clause) {
		PluginManager.swarmValue("visit/catch_clause", clause);
	}

	public override void visit_lock_statement (LockStatement stmt) {
		PluginManager.swarmValue("visit/lock_statement", stmt);
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
		string visit_exten= "visit/object_creation_expression";
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
		string visit_exten= "visit/end_full_expression";
		PluginManager.swarmValue(visit_exten, expr);
	}

	public override LocalVariable create_local (DataType type) {
		string exten= "create/local";
		LocalVariable result = (LocalVariable?)PluginManager.swarmValue(exten, type);
		if(result == null)
			print("Please report this bug, result for create_local should not be null\n");
		return result;
	}

	public override TargetValue load_local (LocalVariable local) {
		TargetValue?result = (TargetValue)PluginManager.swarmValue("load/local", local);
		if(result == null)
			print("Please report this bug, result for load_local should not be null\n");
		return result;
	}

	public override void store_local (LocalVariable local, TargetValue xvalue, bool initializer) {
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["local"] = local;
		args["xvalue"] = xvalue;
		args["initializer"] = initializer;
		PluginManager.swarmValue("store/local", args);
	}

	public override TargetValue load_parameter (Vala.Parameter param) {
		TargetValue?result = (TargetValue)PluginManager.swarmValue("load/parameter", param);
		if(result == null)
			print("Please report this bug, result for load_parameter should not be null\n");
		return result;
	}

	public override void store_parameter (Vala.Parameter param, TargetValue xvalue, bool capturing_parameter = false) {
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["param"] = param;
		args["xvalue"] = xvalue;
		args["capturing_parameter"] = capturing_parameter;
		PluginManager.swarmValue("store/parameter", args);
	}

	public override TargetValue load_field (Field field, TargetValue? instance) {
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["field"] = field;
		args["instance"] = instance;
		TargetValue? result = (TargetValue)PluginManager.swarmValue("load/field", args);
		if(result == null)
			print("Please report this bug, result for load_field should not be null\n");
		return result;
	}

	public override void store_field (Field field, TargetValue? instance, TargetValue xvalue) {
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["field"] = field;
		args["instance"] = instance;
		args["xvalue"] = xvalue;
		PluginManager.swarmValue("store/field", args);
	}

	public override void emit (CodeContext context) {
		string exten= "source/emit";
		var args = new HashTable<string,Value?>(str_hash,str_equal);
		args["context"] = context;
		args["visitor"] = this;
		PluginManager.swarmValue(exten, args);
	}
}

