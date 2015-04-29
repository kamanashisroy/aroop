using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.ElementModule : shotodolplug.Module {
	CSymbolResolve resolve;
	SourceEmitterModule emitter;
	public ElementModule() {
		base("Element", "0.0");
	}

	public override int init() {
		PluginManager.register("visit/field", new HookExtension(visit_field, this));
		PluginManager.register("generate/element/destruction", new HookExtension(generate_element_destruction_code_helper, this));
		PluginManager.register("generate/element/declaration", new HookExtension(generate_element_declaration_helper, this));
		PluginManager.register("generate/struct/cargument", new HookExtension(generate_cargument_for_struct_helper, this));
		PluginManager.register("generate/struct/instance/cargument", new HookExtension(generate_instance_cargument_for_struct_helper, this));
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

	Value? generate_element_destruction_code_helper(Value?givenArgs) {
		HashTable<string,Value?> args = (HashTable<string,Value?>)givenArgs;
		generate_element_destruction_code((Field)args["field"], (CCodeBlock)args["stmt"]);
		return null;
	}
	void generate_element_destruction_code(Field f, CCodeBlock stmt) {
		if (f.binding != MemberBinding.INSTANCE)  {
			return;
		}
		var array_type = f.variable_type as ArrayType;
		if (array_type != null && array_type.fixed_length) {
			// TODO cleanup array
			int i = 0;
			//for (int i = 0; i < array_type.length; i++) {
				var fld = new CCodeMemberAccess.pointer(new CCodeIdentifier(resolve.self_instance), resolve.get_ccode_name(f));
				var element = new CCodeElementAccess (fld, new CCodeConstant (i.to_string ()));
				if (resolve.requires_destroy (array_type.element_type))  {
					stmt.add_statement(new CCodeExpressionStatement(resolve.get_unref_expression(element, array_type.element_type)));
				}
			//}
			return;
		}
		if (resolve.requires_destroy (f.variable_type))  {
			stmt.add_statement(new CCodeExpressionStatement(resolve.get_unref_expression(new CCodeMemberAccess.pointer(new CCodeIdentifier(resolve.self_instance), resolve.get_ccode_name(f)), f.variable_type)));
		}
	}

	Value? generate_element_declaration_helper(Value?givenArgs) {
		HashTable<string,Value?> args = (HashTable<string,Value?>)givenArgs;
		generate_element_declaration(
			(Field)args["field"]
			, (CCodeStruct)args["container"]
			, (CCodeFile)args["decl_space"]
			, (((string?)args["internalSymbol"]) == "1")
		);
		return null;
	}

	void generate_element_declaration(Field f, CCodeStruct container, CCodeFile decl_space, bool internalSymbol = true) {
		if (f.binding != MemberBinding.INSTANCE)  {
			//visit_field(f);
			//print(" - we should have declared %s\n", get_ccode_name(f));
#if false
			AroopCodeGeneratorAdapter.generate_type_declaration (f.variable_type, decl_space);
			string field_ctype =  resolve.get_ccode_aroop_name(f.variable_type);
			if (f.is_volatile) {
				field_ctype = "volatile " + field_ctype;
			}
			
			var vbdecl = new CCodeDeclaration (field_ctype);
			vbdecl.add_declarator (new CCodeVariableDeclarator (/*"aroop_file_var_" + */resolve.get_ccode_name (f)));
			if(internalSymbol)
				vbdecl.modifiers |= CCodeModifiers.STATIC;
			else
				vbdecl.modifiers &= ~CCodeModifiers.STATIC;
			cfile.add_type_member_declaration(vbdecl);
#endif
			return;
		}
		AroopCodeGeneratorAdapter.generate_type_declaration (f.variable_type, decl_space);
		string field_ctype =  resolve.get_ccode_aroop_name(f.variable_type);
		if (f.is_volatile) {
			field_ctype = "volatile " + field_ctype;
		}
		
		container.add_field (field_ctype, resolve.get_ccode_name (f) 
			//+ get_ccode_declarator_suffix (f.variable_type), null, generate_declarator_suffix_cexpr(f.variable_type));
			, resolve.get_ccode_declarator_suffix (f.variable_type));
	}

	Value? generate_instance_cargument_for_struct_helper(Value?givenArgs) { 
		HashTable<string,Value?> args = (HashTable<string,Value?>)givenArgs;
		return generate_instance_cargument_for_struct((MemberAccess)args["ma"], (Method)args["m"], (CCodeExpression)args["instance"]);	
	}
	
	CCodeExpression generate_instance_cargument_for_struct(MemberAccess ma, Method m, CCodeExpression instance) { 
		var returnval = instance;
		// we need to pass struct instance by reference
		var unary = instance as CCodeUnaryExpression;
		
		if (unary != null) {
			if(unary.operator == CCodeUnaryOperator.POINTER_INDIRECTION) {
				// *expr => expr
				//print("[%s]*expr => expr\n", m.name);
				
				returnval = unary.inner;
			}
		} else if (instance is CCodeIdentifier) {
			if(resolve.is_current_instance_struct((TypeSymbol)m.parent_symbol, instance)) {
				//print("[%s]'this' struct instance argument:%s\n", m.name, ((CCodeIdentifier)instance).name);
				return returnval;
			} else {
				//print("[%s]struct instance argument(it is not 'this' so it requires '&' operator):%s\n", m.name, ((CCodeIdentifier)instance).name);
				return new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, instance);
			}
		} else if(instance is CCodeMemberAccess) {
			//print("[%s]memberaccess:%s\n", m.name, expr.target_value.value_type.to_string());
			return new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, instance);
			//returnval = instance;
		} else {
			// if instance is e.g. a function call, we can't take the address of the expression
			// (tmp = expr, &tmp)
			var ccomma = new CCodeCommaExpression ();

			var temp_var = emitter.get_temp_variable (ma.inner.target_type);
			AroopCodeGeneratorAdapter.generate_temp_variable (temp_var);
			ccomma.append_expression (new CCodeAssignment (resolve.get_variable_cexpression (temp_var.name), instance));
			ccomma.append_expression (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, resolve.get_variable_cexpression (temp_var.name)));

			returnval = ccomma;
		}
		return returnval;
	}
	

	Value? generate_cargument_for_struct_helper (Value?givenArgs) {
		var args = (HashTable<string,Value?>)givenArgs;
		return generate_cargument_for_struct((Vala.Parameter)args["param"], (Expression)args["arg"], (CCodeExpression)args["cexpr"]);
	}
	CCodeExpression? generate_cargument_for_struct (Vala.Parameter param, Expression arg, CCodeExpression? cexpr) {
		if (!((arg.formal_target_type is StructValueType) || (arg.formal_target_type is PointerType))) {
			return cexpr;
		}

		if(arg.formal_target_type is PointerType) {
			if(arg.target_type is PointerType) {
				if (param.direction == Vala.ParameterDirection.IN) {
					CCodeUnaryExpression?unary = null;
					if ((unary = cexpr as CCodeUnaryExpression) != null) {
						if(unary.operator == CCodeUnaryOperator.ADDRESS_OF 
							&& unary.inner is CCodeIdentifier 
							&& ((CCodeIdentifier)unary.inner).name == resolve.self_instance) {// &this => this
							//print("working with1 : %s\n", param.name);
							return unary.inner;
						} else { 
							return cexpr;
						}
					} else if (cexpr is CCodeIdentifier || cexpr is CCodeMemberAccess) {
						return cexpr;
					} else {
						var ccomma = new CCodeCommaExpression ();
						ccomma.append_expression (cexpr);
						return ccomma;
					}
				}
			}
			return cexpr;
		}
#if false			
		if(arg.formal_target_type is StructValueType) {
			if (cexpr is CCodeIdentifier || cexpr is CCodeMemberAccess) {
				print("function argument struct passed by value : %s\n", param.name);
				return new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, cexpr);
			}
		}
#endif
		return cexpr;
	}
	
	CCodeExpression? handle_struct_argument (Vala.Parameter param, Expression arg, CCodeExpression? cexpr) {
		assert_not_reached ();
		return null;
	}

	public void generate_field_declaration (Field f, CCodeFile decl_space, bool defineHere = false) {
		if (!defineHere && emitter.add_symbol_declaration (decl_space, f, resolve.get_ccode_aroop_name (f))) {
			return;
		}
		assert(f.variable_type != null);
		AroopCodeGeneratorAdapter.generate_type_declaration (f.variable_type, decl_space);

		string field_ctype = resolve.get_ccode_aroop_name (f.variable_type);
		if (f.is_volatile) {
			field_ctype = "volatile " + field_ctype;
		}

		var cdecl = new CCodeDeclaration (field_ctype);
		cdecl.add_declarator (new CCodeVariableDeclarator (resolve.get_ccode_name (f), null, resolve.get_ccode_declarator_suffix (f.variable_type)));
		if (f.is_private_symbol ()) {
			cdecl.modifiers = CCodeModifiers.STATIC;
		} else if(!defineHere) {
			cdecl.modifiers = CCodeModifiers.EXTERN;
		}

		if (f.get_attribute ("ThreadLocal") != null) {
			cdecl.modifiers |= CCodeModifiers.THREAD_LOCAL;
		}

		decl_space.add_type_member_declaration (cdecl);
	}

	Value? visit_field (Value?givenArgs) {
		Field f = (Field?)givenArgs;
		if (f.binding == MemberBinding.CLASS) {
			generate_field_declaration (f, emitter.cfile, true);
			if (!f.is_internal_symbol ()) {
				generate_field_declaration (f, emitter.header_file, false);
			}
		} else if (f.binding == MemberBinding.STATIC)  {
			generate_field_declaration (f, emitter.cfile, true);

			if (!f.is_internal_symbol ()) {
				generate_field_declaration (f, emitter.header_file, false);
			}
		}
		return null;
	}


}

