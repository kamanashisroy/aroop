using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.LocalVariableModule : shotodolplug.Module {
	SourceEmitterModule emitter;
	CSymbolResolve resolve;
	public LocalVariableModule() {
		base("LocalVariable", "0.0");
	}

	public override int init() {
		PluginManager.register("visit/local_variable", new HookExtension(visit_local_variable, this));
		PluginManager.register("rehash", new HookExtension(rehashHook, this));
		return 0;
	}

	public override int deinit() {
		return 0;
	}

	Value?rehashHook(Value?arg) {
		emitter = (SourceEmitterModule?)PluginManager.swarmValue("source/emitter", null);
		resolve = (CSymbolResolve?)PluginManager.swarmValue("resolve/c/symbol",null);
		return null;
	}

	Value? visit_local_variable (Value?given_args) {
		LocalVariable?local = (LocalVariable?)given_args;
		if (local.initializer != null) {
			local.initializer.emit (emitter.visitor);

			emitter.visitor.visit_end_full_expression (local.initializer);
		}

		AroopCodeGeneratorAdapter.generate_type_declaration (local.variable_type, emitter.cfile);

		CCodeExpression rhs = null;
		if (local.initializer != null && resolve.get_cvalue (local.initializer) != null) {
			rhs = resolve.get_cvalue (local.initializer);
		}

		if (local.captured) {
			if (local.initializer != null) {
				initialize_local_variable_in_block(local, rhs, emitter.ccode);
			}
		} else {
			//var cvar = new CCodeVariableDeclarator (resolve.get_variable_cname (local.name), has_simple_struct_initializer (local)?rhs:null, resolve.get_ccode_declarator_suffix (local.variable_type), generate_declarator_suffix_cexpr(local.variable_type));
			var cvar = new CCodeVariableDeclarator (resolve.get_variable_cname (local.name), has_simple_struct_initializer (local)?rhs:null, resolve.get_ccode_declarator_suffix (local.variable_type));

			var cdecl = new CCodeDeclaration (resolve.get_ccode_aroop_name (local.variable_type));
			cdecl.add_declarator (cvar);
			emitter.ccode.add_statement (cdecl);

			// try to initialize uninitialized variables
			// initialization not necessary for variables stored in closure
			if (cvar.initializer == null) {
				cvar.initializer = resolve.default_value_for_type (local.variable_type, true);
				cvar.init0 = true;
			}
		}

		if (rhs != null) {
			if (!has_simple_struct_initializer (local)) {
				emitter.visitor.store_local (local, local.initializer.target_value, true);
			}
		}
		if (local.initializer != null && local.initializer.tree_can_fail) {
			//add_simple_check (local.initializer);
			PluginManager.swarmValue("simple_check", local.initializer);
		}

		local.active = true;
		return null;
	}

	bool has_simple_struct_initializer (LocalVariable local) {
		Struct?st = null;
		if(local.variable_type.data_type is Struct)
			st = local.variable_type.data_type as Struct;
		var initializer = local.initializer as ObjectCreationExpression;
		if (st != null && (!st.is_simple_type () || resolve.get_ccode_name (st) == "va_list") && !local.variable_type.nullable &&
		    initializer != null && initializer.get_object_initializer ().size == 0) {
			return true;
		} else {
			return false;
		}
	}
	void initialize_local_variable_in_block(LocalVariable local, CCodeExpression rhs, CCodeFunction decl_space) {
		emitter.ccode.add_assignment (
			new CCodeMemberAccess (
				resolve.get_variable_cexpression (
					AroopCodeGeneratorAdapter.generate_block_var_name((Block) local.parent_symbol)
				)
				, resolve.get_variable_cname (local.name)), rhs);
	}



}

