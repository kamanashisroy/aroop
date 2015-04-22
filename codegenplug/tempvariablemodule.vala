using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.TempVariableModule : shotodolplug.Module {
	CSymbolResolve resolve;
	SourceEmitterModule compiler;
	CodeGenerator cgen;
	public TempVariableModule() {
		base("TempVariableModule", "0.0");
	}

	public override int init() {
		PluginManager.register("generate/temp", new HookExtension((shotodolplug.Hook)generate_temp_variable, this));
		return 0;
	}

	public override int deinit() {
		return 0;
	}
	public void generate_temp_variable(LocalVariable local) {
		var cdecl = new CCodeDeclaration (resolve.get_ccode_aroop_name (local.variable_type));

		var vardecl = new CCodeVariableDeclarator (local.name, null, resolve.get_ccode_declarator_suffix (local.variable_type));
		cdecl.add_declarator (vardecl);

		Struct?st = null;
		if(local.variable_type.data_type is Struct)
			st = local.variable_type.data_type as Struct;
		ArrayType?array_type = null;
		if(local.variable_type is ArrayType)
			array_type = local.variable_type as ArrayType;

		if (local.name.has_prefix ("*")) {
			// do not dereference unintialized variable
			// initialization is not needed for these special
			// pointer temp variables
			// used to avoid side-effects in assignments
		} else if (local.variable_type is DelegateType) {
			vardecl.initializer = resolve.generate_delegate_init_expr();
			vardecl.init0 = ((vardecl.initializer == null) ? false : true);
		} else if (local.variable_type is GenericType) {
			var gen_init = new CCodeFunctionCall (new CCodeIdentifier ("aroop_generic_type_init_val"));
			gen_init.add_argument (resolve.get_type_id_expression (local.variable_type));

			vardecl.initializer = gen_init;
			vardecl.init0 = true;
		} else if (!local.variable_type.nullable &&
		           (st != null && st.get_fields ().size > 0) ||
		           array_type != null) {
			// 0-initialize struct with struct initializer { 0 }
			// necessary as they will be passed by reference
			var clist = new CCodeInitializerList ();
			clist.append (new CCodeConstant ("0"));

			vardecl.initializer = clist;
			vardecl.init0 = true;
		} else if (local.variable_type.is_reference_type_or_type_parameter () ||
		       local.variable_type.nullable) {
			vardecl.initializer = new CCodeConstant ("NULL");
			vardecl.init0 = true;
		}

		//if(!local.is_imaginary) {
			compiler.ccode.add_statement (cdecl);
		//}
	}
}

