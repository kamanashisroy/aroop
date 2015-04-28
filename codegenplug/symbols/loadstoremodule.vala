
using Vala;
using shotodolplug;
using codegenplug;


/**
 * The link between a method and generated code.
 */
public class codegenplug.LoadStoreModule : shotodolplug.Module {
	SourceEmitterModule?emitter = null;
	CSymbolResolve?resolve = null;
	public LoadStoreModule() {
		base("Load Store", "0.0");
	}

	public override int init() {
		//PluginManager.register("load/variable", new HookExtension(load_variable_helper, this));
		PluginManager.register("store/variable", new HookExtension(store_variable_helper, this));
		PluginManager.register("store/property", new HookExtension(store_property_helper, this));
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

	Value?store_variable_helper(Value?given_args) {
		var args = (HashTable<string,Value?>)given_args;
		store_variable((Variable?)args["variable"], (TargetValue?)args["lvalue"], (TargetValue?)args["xvalue"], ((string?)args["initializer"]) == "1");
		return null;
	}

	void store_variable (Variable variable, TargetValue lvalue, TargetValue xvalue, bool initializer) {
#if false
		var generic_type = (lvalue.value_type as GenericType);
		if (generic_type == null) {
			base.store_variable (variable, lvalue, xvalue, initializer);
			return;
		}

		var ccall = new CCodeFunctionCall (new CCodeIdentifier ("aroop_type_value_copy"));
		if (generic_type.type_parameter.parent_symbol is TypeSymbol) {
			// generic type
			ccall.add_argument (new CCodeMemberAccess.pointer (new CCodeIdentifier (resolve.self_instance), resolve.get_generic_class_variable_cname()));
		} else {
			// generic method
			ccall.add_argument (new CCodeIdentifier ("%s_type".printf (generic_type.type_parameter.name.down ())));
		}
		ccall.add_argument (resolve.get_cvalue_ (lvalue));
		ccall.add_argument (new CCodeConstant ("0"));
		ccall.add_argument (resolve.get_cvalue_ (value));
		ccall.add_argument (new CCodeConstant ("0"));

		emitter.ccode.add_expression (ccall);
#endif
	}

	Value?store_property_helper(Value?given_args) {
		var args = (HashTable<string,Value?>)given_args;
		store_property((Property?)args["prop"], (Expression?)args["instance"], (TargetValue?)args["xvalue"]);
		return null;
	}

	void store_property (Property prop, Expression? instance, TargetValue value) {
		string set_func;

		var base_property = prop;
		if (prop.base_property != null) {
			base_property = prop.base_property;
		} else if (prop.base_interface_property != null) {
			base_property = prop.base_interface_property;
		}

		AroopCodeGeneratorAdapter.generate_property_accessor_declaration (base_property.set_accessor, emitter.cfile);
		set_func = resolve.get_ccode_name (base_property.set_accessor);

		if (!prop.external && prop.external_package) {
			// internal VAPI properties
			// only add them once per source file
			if (emitter.add_generated_external_symbol (prop)) {
				emitter.visitor.visit_property (prop);
			}
		}

		var ccall = new CCodeFunctionCall (new CCodeIdentifier (set_func));

		if (prop.binding == MemberBinding.INSTANCE) {
			/* target instance is first argument */
			ccall.add_argument ((CCodeExpression) resolve.get_ccodenode (instance));
		}

		ccall.add_argument (resolve.get_cvalue_ (value));

		emitter.ccode.add_expression (ccall);
	}
}
