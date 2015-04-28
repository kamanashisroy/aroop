using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.PropertyModule : shotodolplug.Module {
	SourceEmitterModule?emitter = null;
	CSymbolResolve?resolve = null;
	public PropertyModule() {
		base("Property", "0.0");
	}

	public override int init() {
		//PluginManager.register("visit/property", new HookExtension(visit_property_helper, this));
		PluginManager.register("generate/property_accessor/declaration", new HookExtension(generate_property_accessor_declaration_helper, this));
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

	Value? generate_property_accessor_declaration_helper (Value?given_args) {
		var args = (HashTable<string,Value?>)given_args;
		generate_property_accessor_declaration(
			(PropertyAccessor?)args["acc"]
			,(CCodeFile?)args["decl_space"]
		);
		return null;
	}

	void generate_property_accessor_declaration (PropertyAccessor acc, CCodeFile decl_space) {
		if (emitter.add_symbol_declaration (decl_space, acc.prop, resolve.get_ccode_name (acc))) {
			return;
		}

		var prop = (Property) acc.prop;

		AroopCodeGeneratorAdapter.generate_type_declaration (acc.value_type, decl_space);

		CCodeFunction function;

		if (acc.readable) {
			function = new CCodeFunction (resolve.get_ccode_name (acc), resolve.get_ccode_aroop_name (acc.value_type));
		} else {
			function = new CCodeFunction (resolve.get_ccode_name (acc), "void");
		}

		if (prop.binding == MemberBinding.INSTANCE) {
			DataType this_type;
			if (prop.parent_symbol is Struct) {
				var st = (Struct) prop.parent_symbol;
				this_type = resolve.get_data_type_for_symbol (st);
			} else {
				var t = (ObjectTypeSymbol) prop.parent_symbol;
				this_type = new ObjectType (t);
			}

			AroopCodeGeneratorAdapter.generate_type_declaration (this_type, decl_space);
			var cselfparam = new CCodeParameter (resolve.self_instance, resolve.get_ccode_aroop_name (this_type));

			function.add_parameter (cselfparam);
		}

		if (acc.writable) {
			var cvalueparam = new CCodeParameter ("value", resolve.get_ccode_aroop_name (acc.value_type));
			function.add_parameter (cvalueparam);
		}

		if (prop.is_internal_symbol () || acc.is_internal_symbol ()) {
			function.modifiers |= CCodeModifiers.STATIC;
		}
		decl_space.add_function_declaration (function);

		if (prop.is_abstract || prop.is_virtual) {
			string param_list = "(%s *this".printf (resolve.get_ccode_aroop_name (prop.parent_symbol));
			if (!acc.readable) {
				param_list += ", ";
				param_list += resolve.get_ccode_aroop_name (acc.value_type);
			}
			param_list += ")";

			var override_func = new CCodeFunction ("%soverride_%s_%s".printf (resolve.get_ccode_lower_case_prefix (prop.parent_symbol), acc.readable ? "get" : "set", prop.name));
			override_func.add_parameter (new CCodeParameter ("type", resolve.get_aroop_type_cname()));
			override_func.add_parameter (new CCodeParameter ("(*function) %s".printf (param_list), acc.readable ? resolve.get_ccode_aroop_name (acc.value_type) : "void"));

			decl_space.add_function_declaration (override_func);
		}
	}


}

