
using Vala;
using shotodolplug;
using codegenplug;


public class codegenplug.MemberAccessModule : shotodolplug.Module {
	SourceEmitterModule?emitter = null;
	CSymbolResolve?resolve = null;
	public MemberAccessModule() {
		base("MemberAccess", "0.0");
	}

	public override int init() {
		PluginManager.register("visit/member_access", new HookExtension(visit_member_access, this));
		PluginManager.register("resolve/parameter/block", new HookExtension(visit_member_access, this));
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

	string get_ccode_vtable_var(Class cl, Class of_class) {
		return "vtable_%sovrd_%s".printf(resolve.get_ccode_lower_case_prefix(cl)
			, resolve.get_ccode_lower_case_suffix(of_class));
	}

#if false
	string get_vtable_var(Class cl, Class of_class) {
		print_debug("%s grephere %s\n".printf(resolve.get_ccode_aroop_name(cl), resolve.get_ccode_aroop_name(of_class)));
		if(of_class == null) {
			return "unknown";
		}
		if(of_class.base_class != null) {
			return get_vtable_var(cl, of_class.base_class);
		}
		if(resolve.hasVtables(of_class)) {
			return resolve.get_ccode_vtable_var(cl, of_class);
		}
		return "unknown";
	}
#endif

	string get_vtable_var_for_method(Class cl, Class of_class, Method m) {
		print_debug("%s grephere %s\n".printf(resolve.get_ccode_aroop_name(cl), resolve.get_ccode_aroop_name(of_class)));
		if(of_class == null) {
			return "unknown";
		}
		if(of_class.base_class != null) {
			if(resolve.hasVtables(of_class.base_class) && of_class.base_class.get_methods().contains(m) ) {
				return get_vtable_var_for_method(cl, of_class.base_class, m);
			}
			return get_ccode_vtable_var(cl, of_class);
		}
		if(resolve.hasVtables(of_class)) {
			return get_ccode_vtable_var(cl, of_class);
		}
		return "unknown";
	}

	Value? visit_member_access (Value? given_args) {
		MemberAccess?expr = (MemberAccess?)given_args;
		CCodeExpression pub_inst = null;
		DataType base_type = null;

		if (expr.inner != null) {
			pub_inst = resolve.get_cvalue (expr.inner);

			if (expr.inner.value_type != null) {
				base_type = expr.inner.value_type;
			}
		}

		if (expr.symbol_reference is Method) {
			var m = (Method) expr.symbol_reference;

			if (!(m is DynamicMethod)) {
				AroopCodeGeneratorAdapter.generate_method_declaration (m, emitter.cfile);

				if (!m.external && m.external_package) {
					// internal VAPI methods
					// only add them once per source file
					if (emitter.add_generated_external_symbol (m)) {
						emitter.visitor.visit_method (m);
					}
				}
			}

			if (expr.inner is BaseAccess) {
				if (m.base_method != null/* && !m.base_method.is_abstract*/) {

					//generate_type_declaration (m.base_method.parent_symbol, emitter.cfile);
					Class?mb_class = null;
					Class?b_class = null;
					if(m.base_method.parent_symbol is Class)
						mb_class = (Class) m.base_method.parent_symbol;
					if(emitter.current_class.base_class is Class)
						b_class = (Class) emitter.current_class.base_class;
					assert(b_class != null);
					if(b_class.base_class != null) {
						//b_class = b_class.base_class;
					}
					var aroop_base_method_call = new CCodeFunctionCall (new CCodeIdentifier ("aroop_base_method_call"));
					aroop_base_method_call.add_argument (new CCodeConstant(get_vtable_var_for_method (b_class, mb_class, m)));
					//aroop_base_method_call.add_argument (new CCodeConstant(m.base_method.name));
					aroop_base_method_call.add_argument (new CCodeConstant(resolve.get_ccode_vfunc_name(m)));
					resolve.set_cvalue (expr, aroop_base_method_call);
					//resolve.set_cvalue (expr, new CCodeIdentifier (resolve.get_ccode_base_name (m.base_method)));
					return null;
				} else if (m.base_interface_method != null) {
					var base_iface = (Interface) m.base_interface_method.parent_symbol;

					resolve.set_cvalue (expr, new CCodeIdentifier ("%s_base_%s".printf (resolve.get_ccode_lower_case_name (base_iface, null), m.name)));
					return null;
				}
			}

			if (m.base_method != null) {
				if (!resolve.method_has_wrapper (m.base_method)) {
					var inst = pub_inst;
					if (expr.inner != null && !expr.inner.is_pure ()) {
						// instance expression has side-effects
						// store in temp. variable
						var temp_var = emitter.get_temp_variable (expr.inner.value_type);
						AroopCodeGeneratorAdapter.generate_temp_variable (temp_var);
						var ctemp = new CCodeIdentifier (temp_var.name);
						inst = new CCodeAssignment (ctemp, pub_inst);
						resolve.set_cvalue (expr.inner, ctemp);
					}
					var base_class = (Class) m.base_method.parent_symbol;
					var vclass = new CCodeFunctionCall (new CCodeIdentifier ("%s_GET_CLASS".printf (resolve.get_ccode_upper_case_name (base_class, null))));
					vclass.add_argument (inst);
					resolve.set_cvalue (expr, new CCodeMemberAccess.pointer (vclass, m.name));
				} else {
					resolve.set_cvalue (expr, new CCodeIdentifier (resolve.get_ccode_name (m.base_method)));
				}
			} else if (m.base_interface_method != null) {
				resolve.set_cvalue (expr, new CCodeIdentifier (resolve.get_ccode_name (m.base_interface_method)));
			} else if (m is CreationMethod) {
				resolve.set_cvalue (expr, new CCodeIdentifier (resolve.get_ccode_real_name (m)));
			} else {
				resolve.set_cvalue (expr, new CCodeIdentifier (resolve.get_ccode_name (m)));
			}
		} else if (expr.symbol_reference is ArrayLengthField) {
			var array_type = (ArrayType) expr.inner.value_type;
			if (array_type.fixed_length) {
				var csizeof = new CCodeFunctionCall (new CCodeIdentifier ("sizeof"));
				csizeof.add_argument (pub_inst);
				var csizeofelement = new CCodeFunctionCall (new CCodeIdentifier ("sizeof"));
				csizeofelement.add_argument (new CCodeElementAccess (pub_inst, new CCodeConstant ("0")));
				resolve.set_cvalue (expr, new CCodeBinaryExpression (CCodeBinaryOperator.DIV, csizeof, csizeofelement));
			} else {
				resolve.set_cvalue (expr, new CCodeMemberAccess (pub_inst, "length"));
			}
		} else if (expr.symbol_reference is Field) {
			var f = (Field) expr.symbol_reference;
			expr.target_value = emitter.visitor.load_field (f, expr.inner != null ? expr.inner.target_value : null);
		} else if (expr.symbol_reference is Vala.EnumValue) {
			var ev = (Vala.EnumValue) expr.symbol_reference;

			AroopCodeGeneratorAdapter.generate_enum_declaration ((Enum) ev.parent_symbol, emitter.cfile);

			resolve.set_cvalue (expr, new CCodeConstant (resolve.get_ccode_name (ev)));
		} else if (expr.symbol_reference is Constant) {
			var c = (Constant) expr.symbol_reference;

			AroopCodeGeneratorAdapter.generate_constant_declaration (c, emitter.cfile);

			resolve.set_cvalue (expr, new CCodeIdentifier (resolve.get_ccode_name (c)));
		} else if (expr.symbol_reference is Property) {
			var prop = (Property) expr.symbol_reference;

			if (!(prop is DynamicProperty)) {
				AroopCodeGeneratorAdapter.generate_property_accessor_declaration (prop.get_accessor, emitter.cfile);

				if (!prop.external && prop.external_package) {
					// internal VAPI properties
					// only add them once per source file
					if (emitter.add_generated_external_symbol (prop)) {
						emitter.visitor.visit_property (prop);
					}
				}
			}

			if (expr.inner is BaseAccess) {
				if (prop.base_property != null) {
					var base_class = (Class) prop.base_property.parent_symbol;
					var vcast = new CCodeFunctionCall (new CCodeIdentifier ("%s_CLASS".printf (resolve.get_ccode_upper_case_name (base_class, null))));
					vcast.add_argument (new CCodeIdentifier ("%s_parent_class".printf (resolve.get_ccode_lower_case_name (emitter.current_class, null))));

					var ccall = new CCodeFunctionCall (new CCodeMemberAccess.pointer (vcast, "get_%s".printf (prop.name)));
					ccall.add_argument (resolve.get_cvalue (expr.inner));
					resolve.set_cvalue (expr, ccall);
					return null;
				} else if (prop.base_interface_property != null) {
					var base_iface = (Interface) prop.base_interface_property.parent_symbol;
					string parent_iface_var = "%s_%s_parent_iface".printf (resolve.get_ccode_lower_case_name (emitter.current_class, null), resolve.get_ccode_lower_case_name (base_iface, null));

					var ccall = new CCodeFunctionCall (new CCodeMemberAccess.pointer (new CCodeIdentifier (parent_iface_var), "get_%s".printf (prop.name)));
					ccall.add_argument (resolve.get_cvalue (expr.inner));
					resolve.set_cvalue (expr, ccall);
					return null;
				}
			}

			var base_property = prop;
			if (prop.base_property != null) {
				base_property = prop.base_property;
			} else if (prop.base_interface_property != null) {
				base_property = prop.base_interface_property;
			}
			string getter_cname = resolve.get_ccode_name (base_property.get_accessor);
			var ccall = new CCodeFunctionCall (new CCodeIdentifier (getter_cname));

			if (prop.binding == MemberBinding.INSTANCE) {
				ccall.add_argument (pub_inst);
			}

			resolve.set_cvalue (expr, ccall);
		} else if (expr.symbol_reference is LocalVariable) {
			var local = (LocalVariable) expr.symbol_reference;
			expr.target_value = emitter.visitor.load_local (local);
		} else if (expr.symbol_reference is Vala.Parameter) {
			var p = (Vala.Parameter) expr.symbol_reference;
			expr.target_value = emitter.visitor.load_parameter (p);
		}
		return null;
	}

	TargetValue get_local_cvalue (LocalVariable local) {
		var result = new AroopValue (local.variable_type);

		if (local.is_result) {
			// used in postconditions
			result.cvalue = new CCodeIdentifier ("result");
		} else if (local.captured) {
			result.cvalue = get_local_cvalue_for_block(local);
		} else {
			result.cvalue = resolve.get_variable_cexpression (local.name);
		}

		return result;
	}

	CCodeExpression get_local_cvalue_for_block(LocalVariable local) {
		// captured variables are stored on the heap
		var block = (Block) local.parent_symbol;
		CCodeExpression cblock = resolve.get_variable_cexpression (AroopCodeGeneratorAdapter.generate_block_var_name(block));
		string local_name = resolve.get_variable_cname (local.name);
		if(block == emitter.current_closure_block && emitter.current_closure_block.parent_symbol == emitter.current_method) {
			return new CCodeMemberAccess (cblock, local_name);
		} else {
			return new CCodeMemberAccess.pointer (cblock, local_name);
		}
	}

	Value? get_parameter_cvalue_for_block_helper(Value?given) {
		return get_parameter_cvalue_for_block((Vala.Parameter?)given);
	}

	CCodeExpression get_parameter_cvalue_for_block(Vala.Parameter p) {
		// captured variables are stored on the heap
		var block = p.parent_symbol as Block;
		if (block == null) {
			block = ((Method) p.parent_symbol).body;
		}
		
		var cblock_val = resolve.get_variable_cexpression (AroopCodeGeneratorAdapter.generate_block_var_name(block));
		if(block == emitter.current_closure_block && emitter.current_closure_block.parent_symbol == emitter.current_method) {
			return new CCodeMemberAccess (cblock_val, resolve.get_variable_cname (p.name));
		} else {
			return new CCodeMemberAccess.pointer (cblock_val, resolve.get_variable_cname (p.name));
		}
	}
}

