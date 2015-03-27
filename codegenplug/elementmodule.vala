using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class ccodegenplug.ElementModule : shotodolplug.Module {
	CSymbolResolve resolve;
	CompilerModule compiler;
	CodeGenerator cgen;
	AroopCodeGeneratorAdapter cgenAdapter;
	public ElementModule() {
		base("Element", "0.0");
	}

	public override int init() {
		PluginManager.register("generate/element", new HookExtension(generate_element_destruction_code, this));
	}

	public override int deinit() {
	}

	public void generate_element_destruction_code(Field f, CCodeBlock stmt) {
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

	public void generate_element_declaration(Field f, CCodeStruct container, CCodeFile decl_space, bool internalSymbol = true) {
		if (f.binding != MemberBinding.INSTANCE)  {
			//visit_field(f);
			//print(" - we should have declared %s\n", get_ccode_name(f));
#if false
			compiler.generate_type_declaration (f.variable_type, decl_space);
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
		compiler.generate_type_declaration (f.variable_type, decl_space);
		string field_ctype =  resolve.get_ccode_aroop_name(f.variable_type);
		if (f.is_volatile) {
			field_ctype = "volatile " + field_ctype;
		}
		
		container.add_field (field_ctype, resolve.get_ccode_name (f) 
			//+ get_ccode_declarator_suffix (f.variable_type), null, generate_declarator_suffix_cexpr(f.variable_type));
			, resolve.get_ccode_declarator_suffix (f.variable_type));
	}

	public bool is_current_instance_struct(TypeSymbol instanceType, CCodeExpression cexpr) {
		CCodeIdentifier?cid = null;
		if(!(cexpr is CCodeIdentifier) || (cid = (CCodeIdentifier)cexpr) == null || cid.name == null) {
			return false;
		}
		//print("[%s]member access identifier:%s\n", instanceType.name, cid.name);
		return (instanceType == compiler.current_type_symbol && (cid.name) == resolve.self_instance);
	}
	
	public CCodeExpression get_field_cvalue_for_struct(Field f, CCodeExpression cexpr) {
		if(is_current_instance_struct((TypeSymbol) f.parent_symbol, cexpr)) {
			return new CCodeMemberAccess.pointer (cexpr, resolve.get_ccode_name (f));
		}
		unowned CCodeUnaryExpression?cuop = null;
		if((cexpr is CCodeUnaryExpression) 
			&& (cuop = (CCodeUnaryExpression)cexpr) != null
			&& cuop.operator == CCodeUnaryOperator.POINTER_INDIRECTION) {
			return new CCodeMemberAccess.pointer (cuop.inner, resolve.get_ccode_name (f));
		}
		return new CCodeMemberAccess (cexpr, resolve.get_ccode_name (f));
	}

	
	public CCodeExpression generate_instance_cargument_for_struct(MemberAccess ma, Method m, CCodeExpression instance) { 
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
			if(is_current_instance_struct((TypeSymbol)m.parent_symbol, instance)) {
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

			var temp_var = compiler.get_temp_variable (ma.inner.target_type);
			emit_temp_var (temp_var);
			ccomma.append_expression (new CCodeAssignment (compiler.get_variable_cexpression (temp_var.name), instance));
			ccomma.append_expression (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, compiler.get_variable_cexpression (temp_var.name)));

			returnval = ccomma;
		}
		return returnval;
	}
	

	public CCodeExpression? generate_cargument_for_struct (Vala.Parameter param, Expression arg, CCodeExpression? cexpr) {
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
	
	public CCodeExpression? handle_struct_argument (Vala.Parameter param, Expression arg, CCodeExpression? cexpr) {
		assert_not_reached ();
		return null;
	}
}

