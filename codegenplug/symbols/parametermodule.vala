
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.ParameterModule : shotodolplug.Module {
	SourceEmitterModule?emitter = null;
	CSymbolResolve?resolve = null;
	public ParameterModule() {
		base("Parameter", "0.0");
	}

	public override int init() {
		PluginManager.register("generate/cparameter", new HookExtension(generate_cparameters_helper, this));
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
	Value? generate_cparameters_helper (Value?given_args) {
		var args = (HashTable<string,Value?>)given_args;
		generate_cparameters(
			(Method?)args["method"]
			, (CCodeFile?)args["decl_space"]
			, (CCodeFunction?)args["func"]
			, (CCodeFunctionDeclarator?)args["vdeclarator"]
			, (CCodeFunctionCall?)args["vcall"]
		);
		return null;
	}

	void generate_cparameters (Method m, CCodeFile decl_space, CCodeFunction func, CCodeFunctionDeclarator? vdeclarator = null, CCodeFunctionCall? vcall = null) {
		CCodeParameter instance_param = null;
		if (m.closure) {
			var closure_block = emitter.current_closure_block;
			instance_param = new CCodeParameter (
				emitter.generate_block_var_name (closure_block)
				, emitter.generate_block_name (closure_block) + "*");
		} else if (m.parent_symbol is Class && m is CreationMethod) {
			if (vcall == null) {
				instance_param = new CCodeParameter (resolve.self_instance, resolve.get_ccode_aroop_name (((Class) m.parent_symbol)) + "*");
			}
		} else if (m.binding == MemberBinding.INSTANCE) {
			TypeSymbol parent_type = find_parent_type (m);
			var this_type = resolve.get_data_type_for_symbol (parent_type);

			AroopCodeGeneratorAdapter.generate_type_declaration (this_type, decl_space);

			if (m.base_interface_method != null && !m.is_abstract && !m.is_virtual) {
				var base_type = new ObjectType ((Interface) m.base_interface_method.parent_symbol);
				instance_param = new CCodeParameter ("base_instance", resolve.get_ccode_aroop_name (base_type));
			} else if (m.overrides) {
				var base_type = new ObjectType ((Class)m.base_method.parent_symbol);
				AroopCodeGeneratorAdapter.generate_type_declaration (base_type, decl_space);
				instance_param = new CCodeParameter ("base_instance", resolve.get_ccode_aroop_name (base_type));
			} else {
				if (m.parent_symbol is Struct) {
					instance_param = AroopCodeGeneratorAdapter.generate_instance_cparameter_for_struct(m, instance_param, this_type);
				} else {
					instance_param = new CCodeParameter (resolve.self_instance, resolve.get_ccode_aroop_name (this_type));
				}
			}
		}
		if (instance_param != null) {
			func.add_parameter (instance_param);
			if (vdeclarator != null) {
				vdeclarator.add_parameter (instance_param);
			}
		}

		if (m is CreationMethod) {
			if(emitter.type_class != null)AroopCodeGeneratorAdapter.generate_class_declaration (emitter.type_class, decl_space);

			if (m.parent_symbol is Class) {
				var cl = (Class) m.parent_symbol;
				foreach (TypeParameter type_param in cl.get_type_parameters ()) {
					var cparam = new CCodeParameter ("%s_type".printf (type_param.name.down ()), resolve.get_aroop_type_cname());
					if (vcall != null) {
						func.add_parameter (cparam);
					}
				}
			}
		} else {
			foreach (TypeParameter type_param in m.get_type_parameters ()) {
				var cparam = new CCodeParameter ("%s_type".printf (type_param.name.down ()), resolve.get_aroop_type_cname());
				func.add_parameter (cparam);
				if (vdeclarator != null) {
					vdeclarator.add_parameter (cparam);
				}
				if (vcall != null) {
					vcall.add_argument (new CCodeIdentifier ("%s_type".printf (type_param.name.down ())));
				}
			}
		}

		foreach (Vala.Parameter param in m.get_parameters ()) {
			CCodeParameter cparam;
			if (!param.ellipsis) {
				string ctypename = resolve.get_ccode_aroop_name (param.variable_type);

				AroopCodeGeneratorAdapter.generate_type_declaration (param.variable_type, decl_space);

				if (param.direction != Vala.ParameterDirection.IN && !(param.variable_type is GenericType)) {
					ctypename += "*";
				}

				cparam = new CCodeParameter (resolve.get_variable_cname (param.name), ctypename);
			} else {
				cparam = new CCodeParameter.with_ellipsis ();
			}

			func.add_parameter (cparam);
			if (vdeclarator != null) {
				vdeclarator.add_parameter (cparam);
			}
#if false
			if (param.variable_type is DelegateType) {
				CCodeParameter xparam = new CCodeParameter (resolve.get_variable_cname (param.name)+"_closure_data", "void*");
				func.add_parameter (xparam);
				if (vdeclarator != null) {
					vdeclarator.add_parameter (xparam);
				}
			}
#endif
			
			
			if (vcall != null) {
				if (param.name != null) {
					vcall.add_argument (resolve.get_variable_cexpression (param.name));
				}
			}
		}

		if (m.parent_symbol is Class && m is CreationMethod && vcall != null) {
			func.return_type = resolve.get_ccode_aroop_name ((m.parent_symbol)) + "*";
		} else {
			if (m.return_type is GenericType) {
				func.add_parameter (new CCodeParameter ("result", "void **"));
				if (vdeclarator != null) {
					vdeclarator.add_parameter (new CCodeParameter ("result", "void **"));
				}
			} else {
				Struct?st = null;
				if(m.parent_symbol is Struct)
					st = m.parent_symbol as Struct;
				if (m is CreationMethod && st != null && (st.is_boolean_type () || st.is_integer_type () || st.is_floating_type ())) {
					func.return_type = resolve.get_ccode_aroop_name (st);
				} else {
					func.return_type = resolve.get_ccode_aroop_name (m.return_type);
				}
			}

			AroopCodeGeneratorAdapter.generate_type_declaration (m.return_type, decl_space);
		}
		
		if(m.tree_can_fail) {
			var cparam = new CCodeParameter ("aroop_internal_err", "aroop_wrong**");
			emitter.current_method_inner_error = true;

			func.add_parameter (cparam);
			if (vdeclarator != null) {
				vdeclarator.add_parameter (cparam);
			}
		}
	}


}
