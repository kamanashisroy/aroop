using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.CSymbolResolve : shotodolplug.Module {

	Set<string> reserved_identifiers;
	public string self_instance = "self_data";
	public Map<string,string> variable_name_map = new HashMap<string,string> (str_hash, str_equal);
	SourceEmitterModule?emitter;
	//CodeGenerator cgen;
	public CSymbolResolve() {
		base("C Symbol Resolver", "0.0");
		reserved_identifiers = new HashSet<string> (str_hash, str_equal);
		// C99 keywords
		reserved_identifiers.add ("_Bool");
		reserved_identifiers.add ("_Complex");
		reserved_identifiers.add ("_Imaginary");
		reserved_identifiers.add ("auto");
		reserved_identifiers.add ("break");
		reserved_identifiers.add ("case");
		reserved_identifiers.add ("char");
		reserved_identifiers.add ("const");
		reserved_identifiers.add ("continue");
		reserved_identifiers.add ("default");
		reserved_identifiers.add ("do");
		reserved_identifiers.add ("double");
		reserved_identifiers.add ("else");
		reserved_identifiers.add ("enum");
		reserved_identifiers.add ("extern");
		reserved_identifiers.add ("float");
		reserved_identifiers.add ("for");
		reserved_identifiers.add ("goto");
		reserved_identifiers.add ("if");
		reserved_identifiers.add ("inline");
		reserved_identifiers.add ("int");
		reserved_identifiers.add ("long");
		reserved_identifiers.add ("register");
		reserved_identifiers.add ("restrict");
		reserved_identifiers.add ("return");
		reserved_identifiers.add ("short");
		reserved_identifiers.add ("signed");
		reserved_identifiers.add ("sizeof");
		reserved_identifiers.add ("static");
		reserved_identifiers.add ("struct");
		reserved_identifiers.add ("switch");
		reserved_identifiers.add ("typedef");
		reserved_identifiers.add ("union");
		reserved_identifiers.add ("unsigned");
		reserved_identifiers.add ("void");
		reserved_identifiers.add ("volatile");
		reserved_identifiers.add ("while");

		// reserved for Vala naming conventions
		reserved_identifiers.add ("result");
		reserved_identifiers.add ("this");
		reserved_identifiers.add (self_instance);
	}

	public override int init() {
		PluginManager.register("resolve/c/symbol", new HookExtension(getInterface, this));
		//PluginManager.register("load/local", new HookExtension((Hook)get_local_cvalue, this));
		//PluginManager.register("load/parameter", new HookExtension(get_parameter_cvalue, this));
		//PluginManager.register("load/field", new HookExtension(get_field_cvalue, this));
		PluginManager.register("rehash", new HookExtension(rehashHook, this));
		return 0;
	}

	public override int deinit() {
		return 0;
	}

	Value?rehashHook(Value?arg) {
		emitter = (SourceEmitterModule?)PluginManager.swarmValue("source/emitter", null);
		return null;
	}

	public Value?getInterface(Value?x) {
		return this;
	}

	public string get_ccode_aroop_name(CodeNode node) {
		return  CodegenPlugBaseModule.get_ccode_name (node);
	}

	public string get_ccode_upper_case_name (Symbol node, string? infix = null) {
		return CodegenPlugBaseModule.get_ccode_upper_case_name (node, infix);
	}

	public string get_ccode_name(CodeNode node) {
		return  CodegenPlugBaseModule.get_ccode_name (node);
	}

	public string get_ccode_copy_function(TypeSymbol node) {
		return CodegenPlugBaseModule.get_ccode_copy_function (node);
	}

	public string get_ccode_dup_function(TypeSymbol node) {
		return CodegenPlugBaseModule.get_ccode_dup_function (node);
	}

	public string get_ccode_ref_function(TypeSymbol node) {
		return CodegenPlugBaseModule.get_ccode_ref_function (node);
	}

	public string get_ccode_free_function(TypeSymbol node) {
		if (node is Vala.ErrorType || node is ErrorDomain || node is ErrorCode) {
			return "aroop_free_error";
		}
		return CodegenPlugBaseModule.get_ccode_free_function (node);
	}

	public string get_ccode_lower_case_prefix(Symbol node) {
		return CodegenPlugBaseModule.get_ccode_lower_case_prefix (node);
	}

	public string get_ccode_lower_case_suffix(Symbol node) {
		return CodegenPlugBaseModule.get_ccode_lower_case_suffix (node);
	}
	public string get_error_module_lower_case_name (CodeNode node, string? infix = null) {
		if (node is Vala.ErrorType) {
			Vala.ErrorType etype = node as Vala.ErrorType;
			//return "aroop_error_%s".printf(Symbol.camel_case_to_lower_case (etype.name));
			return "aroop_error";
		} else if(node is ErrorDomain) {
			ErrorDomain edomain = node as ErrorDomain;
			return "aroop_error_domain_%s".printf(Symbol.camel_case_to_lower_case (edomain.name));
		} else if(node is ErrorCode) {
			ErrorCode ecode = node as ErrorCode;
			return "aroop_error_code_%s".printf(Symbol.camel_case_to_lower_case (ecode.name));
		}
		assert_not_reached ();
		return "";
	}
	public string get_ccode_lower_case_name(CodeNode node, string?infix=null) {
		if (node is Vala.ErrorType || node is ErrorDomain || node is ErrorCode) {
			//assert(false);
			return get_error_module_lower_case_name(node,infix);
		}
		return CodegenPlugBaseModule.get_ccode_lower_case_name (node, infix);
	}
	public string get_ccode_real_name(Method node) {
		return CodegenPlugBaseModule.get_ccode_real_name (node);
	}

	public string get_ccode_vfunc_name(Method node) {
		return CodegenPlugBaseModule.get_ccode_vfunc_name (node);
	}

	public string get_ccode_aroop_definition(ObjectTypeSymbol node) {
		if(node.external_package) {
			return get_ccode_aroop_name(node);
		} else {
			return "struct _%s".printf (get_ccode_aroop_name (node));
		}
	}

	public string get_generic_class_variable_cname(int tparams = 0) {
		return "_generic_type_%d".printf(tparams);
	}
	
	public string get_aroop_type_cname() {
		return "aroop_type_desc";
	}

	public CCodeExpression get_unref_expression (CCodeExpression cvar, DataType type, Expression? expr = null) {
		return destroy_value (new AroopValue (type, cvar));
	}

	public CCodeExpression destroy_value (TargetValue value) {
		var type = value.value_type;
		var cvar = get_cvalue_ (value);

		var ccall = new CCodeFunctionCall (get_destroy_func_expression (type));

		if ((type is ValueType && !type.nullable) || type is DelegateType) {
			// normal value type, no null check
			ccall.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, cvar));
			ccall.add_argument (new CCodeConstant ("0"));
			ccall.add_argument (new CCodeConstant ("NULL"));
			ccall.add_argument (new CCodeConstant ("0"));

			return ccall;
		}

#if false
		/* (foo == NULL ? NULL : foo = (unref (foo), NULL)) */

		/* can be simplified to
		 * foo = (unref (foo), NULL)
		 * if foo is of static type non-null
		 */

		var cisnull = new CCodeBinaryExpression (CCodeBinaryOperator.EQUALITY, cvar, new CCodeConstant ("NULL"));
		if (type.type_parameter != null) {
			if (!(emitter.current_type_symbol is Class) || emitter.current_class.is_compact) {
				return new CCodeConstant ("NULL");
			}

			// unref functions are optional for type parameters
			var cunrefisnull = new CCodeBinaryExpression (CCodeBinaryOperator.EQUALITY, get_destroy_func_expression (type), new CCodeConstant ("NULL"));
			cisnull = new CCodeBinaryExpression (CCodeBinaryOperator.OR, cisnull, cunrefisnull);
		}
#else
		ccall.add_argument (new CCodeIdentifier(get_ccode_aroop_name(type)));
		if(type is ClassType) {
			ccall.add_argument (new CCodeConstant("NULL"));
		} else if(type is GenericType) {
			ccall.add_argument(new CCodeMemberAccess.pointer (new CCodeIdentifier (self_instance), get_generic_class_variable_cname()));
		} else {
			ccall.add_argument (new CCodeConstant("NULL"));
		}
#endif
		ccall.add_argument (cvar);
		
#if false
		/* set freed references to NULL to prevent further use */
		var ccomma = new CCodeCommaExpression ();

		ccomma.append_expression (ccall);
		ccomma.append_expression (new CCodeConstant ("NULL"));

		var castexpr = new CCodeCastExpression (ccomma, get_ccode_aroop_name (type));
		var cassign = new CCodeAssignment (cvar, castexpr);

		return new CCodeConditionalExpression (cisnull, new CCodeConstant ("NULL"), cassign);
#else
#if false
		var castexpr = new CCodeCastExpression (ccall, get_ccode_aroop_name (type));
		var cassign = new CCodeAssignment (cvar, castexpr);
		return cassign;
#else
		return new CCodeAssignment (cvar, ccall);
#endif
#endif
	}
	public string get_variable_cname (string name) {
		if (name[0] == '.') {
			// compiler-internal variable
			if (!variable_name_map.contains (name)) {
				variable_name_map.set (name, "_tmp%d_".printf (emitter.next_temp_var_id));
				emitter.next_temp_var_id++;
			}
			return variable_name_map.get (name);
		} else if (reserved_identifiers.contains (name)) {
			return "_%s_".printf (name);
		} else {
			return name;
		}
	}

	public CCodeExpression? generate_delegate_init_expr() {
			var clist = new CCodeInitializerList ();
			clist.append (new CCodeConstant ("0"));
			clist.append (new CCodeConstant ("0"));
			return clist;
	}
	public CCodeExpression? get_destroy_func_expression (DataType type, bool is_chainup = false) {
		if (type is GenericType || type.type_parameter is GenericType) {
			return new CCodeIdentifier ("aroop_generic_object_unref");
		} else if (type.data_type is Class && ((Class)type.data_type).is_compact) {
			return new CCodeIdentifier(get_ccode_unref_function((ObjectTypeSymbol)type.data_type)); //new CCodeIdentifier ("aroop_object_unref");
		} else if (type is ObjectType) {
			return new CCodeIdentifier ("aroop_object_unref");
		} else if (type.data_type != null) {
			string unref_function;
			if (type is ReferenceType) {
				if (is_reference_counting (type.data_type)) {
					unref_function = get_ccode_unref_function ((ObjectTypeSymbol) type.data_type);
				} else {
					unref_function = get_ccode_free_function (type.data_type);
				}
			} else {
				if (type.nullable) {
					unref_function = get_ccode_free_function (type.data_type);
					if (unref_function == null) {
						unref_function = "free";
					}
				} else {
					var st = (Struct) type.data_type;
					unref_function = get_ccode_free_function (st);
				}
			}
			if (unref_function == null) {
				return new CCodeConstant ("aroop_no_unref");
			}
			return new CCodeIdentifier (unref_function);
		} else if (type.type_parameter != null && emitter.current_type_symbol is Class) {
			// FIXME ask type for dup/ref function
			return new CCodeIdentifier ("aroop_object_unref");
		} else if (type is ArrayType) {
			return new CCodeIdentifier ("aroop_object_unref");
		} else if (type is DelegateType) {
			return new CCodeConstant ("aroop_donothing4");
		} else if (type is PointerType) {
			PointerType pt = (PointerType)type;
			if(pt.base_type != null) {
				return get_destroy_func_expression(pt.base_type, is_chainup);
			}
			return new CCodeIdentifier ("free");
		} else {
			return new CCodeConstant ("NULL");
		}
	}



	public void set_cvalue (Expression expr, CCodeExpression? cvalue) {
		var aroop_value = (AroopValue) expr.target_value;
		if (aroop_value == null) {
			aroop_value = new AroopValue (expr.value_type);
			expr.target_value = aroop_value;
		}
		aroop_value.cvalue = cvalue;
	}

	public CCodeExpression? get_cvalue (Expression expr) {
		if (expr.target_value == null) {
			return null;
		}
		var aroop_value = (AroopValue) expr.target_value;
		return aroop_value.cvalue;
	}
	public CCodeExpression? get_cvalue_ (TargetValue value) {
		var aroop_value = (AroopValue) value;
		return aroop_value.cvalue;
	}

	public string get_ccode_vtable_var(Class cl, Class of_class) {
		return "vtable_%sovrd_%s".printf(get_ccode_lower_case_prefix(cl)
			, CodegenPlugBaseModule.get_ccode_lower_case_suffix(of_class));
	}
	public /*static*/ DataType get_data_type_for_symbol (TypeSymbol sym) {
		DataType type = null;

		if (sym is Class) {
			type = new ObjectType ((Class) sym);
		} else if (sym is Interface) {
			type = new ObjectType ((Interface) sym);
		} else if (sym is Struct) {
			var st = (Struct) sym;
			if (st.is_boolean_type ()) {
				type = new BooleanType (st);
			} else if (st.is_integer_type ()) {
				type = new IntegerType (st);
			} else if (st.is_floating_type ()) {
				type = new FloatingType (st);
			} else {
				type = new StructValueType (st);
			}
		} else if (sym is Enum) {
			type = new Vala.EnumValueType ((Enum) sym);
		} else {
			Report.error (null, "internal error: `%s' is not a supported type".printf (sym.get_full_name ()));
			return new InvalidType ();
		}

		return type;
	}
	public CCodeExpression get_type_private_from_type (ObjectTypeSymbol type_symbol, CCodeExpression type_expression) {
		if (type_symbol is Class) {
			// class
			return type_expression;/*CCodeIdentifier (get_ccode_aroop_name (type_symbol));*/
		} else {
			// interface
			var get_interface = new CCodeFunctionCall (new CCodeIdentifier ("aroop_type_get_interface"));
			get_interface.add_argument (type_expression);
			get_interface.add_argument (new CCodeIdentifier ("%s_type".printf (get_ccode_lower_case_name (type_symbol))));
			return new CCodeCastExpression (get_interface, "%sTypePrivate *".printf (CodegenPlugBaseModule.get_ccode_name (type_symbol)));
		}
	}
	bool is_in_generic_type (DataType type) {
		if (type.type_parameter.parent_symbol is TypeSymbol
		    && (emitter.current_method == null || emitter.current_method.binding == MemberBinding.INSTANCE)) {
			return true;
		} else {
			return false;
		}
	}


	public CCodeExpression get_type_id_expression (DataType type, bool is_chainup = false, bool for_type_custing = false) {
		if (type is GenericType) {
			string var_name = "%s_type".printf (type.type_parameter.name.down ());
			if (is_in_generic_type (type) && !is_chainup) {
				return get_type_private_from_type (
					(ObjectTypeSymbol) type.type_parameter.parent_symbol
					, new CCodeMemberAccess.pointer (new CCodeIdentifier (self_instance), get_generic_class_variable_cname()));
			} else {
				return new CCodeIdentifier (var_name);
			}
		} else {
			var ret = new CCodeIdentifier (get_ccode_aroop_name((ObjectTypeSymbol)type.data_type));
			if(for_type_custing) {
				return ret;
			}
			if(((ObjectTypeSymbol)type.data_type) != null && ((ObjectTypeSymbol)type.data_type) is Class) {
				var tmp = new CCodeFunctionCall(new CCodeIdentifier ("aroop_generic_type_for_class"));
				tmp.add_argument(ret);
				return tmp;
			}
			return ret;
		}
	}

	public bool hasVtables(Vala.Class given) {
		foreach (Method m in given.get_methods ()) {
			if (m.is_abstract || m.is_virtual) {
				return true;
			}
		}
		return false;
	}
	public bool requires_destroy (DataType type) {
		if (!type.is_disposable ()) {
			return false;
		}

		var deleg_type = type as DelegateType;
		if(deleg_type != null) {
			return false;
		}

		var array_type = type as ArrayType;
		if (array_type != null && array_type.inline_allocated) {
			return requires_destroy (array_type.element_type);
		}

		if(type.data_type != null && type.data_type is Class) {
			var cl = type.data_type as Class;
			if (is_reference_counting (cl)
			    && get_ccode_unref_function (cl) == "") {
				// empty unref_function => no unref necessary
				return false;
			}
		}

		if (type.type_parameter != null) {
			return false;
		}

		return true;
	}
	public string get_ccode_unref_function (ObjectTypeSymbol node) {
		//return "OPPUNREF";
		return CodegenPlugBaseModule.get_ccode_unref_function (node);
	}

	public CCodeDeclaratorSuffix? get_ccode_declarator_suffix (DataType type) {
		var array_type = type as ArrayType;
		if (array_type != null) {
			if (array_type.fixed_length) {
				return new CCodeDeclaratorSuffix.with_array (get_ccodenode (array_type.length));
			} else if (array_type.inline_allocated) {
				return new CCodeDeclaratorSuffix.with_array ();
			}
		}
		return null;
	}
	public CCodeExpression? get_ccodenode (Expression node) {
		if (get_cvalue (node) == null) {
			//node.emit (cgen);
			node.emit (emitter.visitor);
		}
		return get_cvalue (node);
	}


	public bool is_reference_counting (TypeSymbol node) {
		return CodegenPlugBaseModule.is_reference_counting (node);
	}

	public CCodeExpression get_variable_cexpression (string name) {
		if(name == "this") {
			return new CCodeIdentifier (self_instance);
		}
		return new CCodeIdentifier (get_variable_cname (name));
	}

	public TargetValue get_local_cvalue (LocalVariable local) {
		var result = new AroopValue (local.variable_type);

		if (local.is_result) {
			// used in postconditions
			result.cvalue = new CCodeIdentifier ("result");
		} else if (local.captured) {
			result.cvalue = AroopCodeGeneratorAdapter.generate_local_captured_variable(local);
		} else {
			result.cvalue = get_variable_cexpression (local.name);
		}

		return result;
	}

	CCodeExpression get_parameter_cvalue_for_block(Vala.Parameter p) {
		// captured variables are stored on the heap
		var block = p.parent_symbol as Block;
		if (block == null) {
			block = ((Method) p.parent_symbol).body;
		}
		
		var cblock_val = get_variable_cexpression (AroopCodeGeneratorAdapter.generate_block_var_name(block));
		if(block == emitter.current_closure_block && emitter.current_closure_block.parent_symbol == emitter.current_method) {
			return new CCodeMemberAccess (cblock_val, get_variable_cname (p.name));
		} else {
			return new CCodeMemberAccess.pointer (cblock_val, get_variable_cname (p.name));
		}
	}
	public TargetValue get_parameter_cvalue (Vala.Parameter p) {
		var result = new AroopValue (p.variable_type);

		if (p.name == self_instance) {
			if (emitter.current_method != null && emitter.current_method.coroutine) {
				// use closure
				result.cvalue = new CCodeMemberAccess.pointer (new CCodeIdentifier ("data"), self_instance);
			} else {
				var st = emitter.current_type_symbol as Struct;
				result.cvalue = new CCodeIdentifier (self_instance);
			}
		} else {
			if (p.captured) {
				/*result.cvalue = (CCodeExpression?)PluginManager.swarmValue("resolve/parameter/block", p);
				if(result.cvalue == null)
					print("Please report this bug, result.value should not be null\n");*/
				result.cvalue = get_parameter_cvalue_for_block(p);
			} else {
				if (emitter.current_method != null && emitter.current_method.coroutine) {
					// use closure
					result.cvalue = get_variable_cexpression (p.name);
				} else {
					var type_as_struct = p.variable_type.data_type as Struct;
					if (p.direction != Vala.ParameterDirection.IN
					    || (type_as_struct != null && !type_as_struct.is_simple_type () && !p.variable_type.nullable)) {
						if (p.variable_type is GenericType) {
							result.cvalue = get_variable_cexpression (p.name);
						} else {
							result.cvalue = get_variable_cexpression (p.name);
							//result.cvalue = new CCodeIdentifier ("(*%s)".printf (get_variable_cname (p.name)));
						}
					} else {
						// Property setters of non simple structs shall replace all occurences
						// of the "value" formal parameter with a dereferencing version of that
						// parameter.
						if (emitter.current_property_accessor != null &&
						    emitter.current_property_accessor.writable &&
						    emitter.current_property_accessor.value_parameter == p &&
						    emitter.current_property_accessor.prop.property_type.is_real_struct_type ()) {
							result.cvalue = new CCodeIdentifier ("(*value)");
						} else {
							result.cvalue = get_variable_cexpression (p.name);
						}
					}
				}
			}
		}

		return result;
	}
	
	public bool is_current_instance_struct(TypeSymbol instanceType, CCodeExpression cexpr) {
		CCodeIdentifier?cid = null;
		if(!(cexpr is CCodeIdentifier) || (cid = (CCodeIdentifier)cexpr) == null || cid.name == null) {
			return false;
		}
		//print("[%s]member access identifier:%s\n", instanceType.name, cid.name);
		return (instanceType == emitter.current_type_symbol && (cid.name) == self_instance);
	}

	public CCodeExpression get_field_cvalue_for_struct(Field f, CCodeExpression cexpr) {
		if(is_current_instance_struct((TypeSymbol) f.parent_symbol, cexpr)) {
			return new CCodeMemberAccess.pointer (cexpr, get_ccode_name (f));
		}
		unowned CCodeUnaryExpression?cuop = null;
		if((cexpr is CCodeUnaryExpression) 
			&& (cuop = (CCodeUnaryExpression)cexpr) != null
			&& cuop.operator == CCodeUnaryOperator.POINTER_INDIRECTION) {
			return new CCodeMemberAccess.pointer (cuop.inner, get_ccode_name (f));
		}
		return new CCodeMemberAccess (cexpr, get_ccode_name (f));
	}

	public TargetValue get_field_cvalue (Field f, TargetValue? instance) {
		var result = new AroopValue (f.variable_type);
		
		if (f.binding == MemberBinding.INSTANCE) {
			CCodeExpression pub_inst = null;

			if (instance != null) {
				pub_inst = get_cvalue_ (instance);
			}

			var instance_target_type = get_data_type_for_symbol ((TypeSymbol) f.parent_symbol);

			//var cl = instance_target_type.data_type as Class;
			bool aroop_priv = false;
			if ((f.access == SymbolAccessibility.PRIVATE || f.access == SymbolAccessibility.INTERNAL)) {
				aroop_priv = true;
			}

			CCodeExpression inst = pub_inst;
			if (instance.value_type is StructValueType) {
				result.cvalue = get_field_cvalue_for_struct(f, inst);
			} else if (instance_target_type.data_type.is_reference_type () || (instance != null 
					&& (instance.value_type is PointerType))) {
				result.cvalue = new CCodeMemberAccess.pointer (inst, get_ccode_name (f));
			} else {
				result.cvalue = new CCodeMemberAccess (inst, get_ccode_name (f));
			}
		} else {
			AroopCodeGeneratorAdapter.generate_field_declaration (f, emitter.cfile, false);
			result.cvalue = new CCodeIdentifier (get_ccode_name (f));
		}

		return result;
	}

	public CCodeExpression? default_value_for_type (DataType type, bool initializer_expression) {
		Struct?st = null;
		if(type.data_type is Struct)
			st = type.data_type as Struct;
		ArrayType? array_type = null;
		if(type.data_type is ArrayType)
			array_type = type as ArrayType;
		if (type is GenericType) {
			var gen_init = new CCodeFunctionCall (new CCodeIdentifier ("aroop_generic_type_init_val"));
			gen_init.add_argument (get_type_id_expression (type));
			return gen_init;
		} else if (initializer_expression && !type.nullable &&
		    ((st != null && st.get_fields ().size > 0) ||
		     array_type != null)) {
			// 0-initialize struct with struct initializer { 0 }
			// only allowed as initializer expression in C
			var clist = new CCodeInitializerList ();
			clist.append (new CCodeConstant ("0"));
			return clist;
		} else if ((type.data_type != null && type.data_type.is_reference_type ())
		           || type.nullable
		           || type is PointerType) {
			return new CCodeConstant ("NULL");
		} else if ((type.data_type != null && type.data_type.is_reference_type ())
		           || type is DelegateType) {
			return generate_delegate_init_expr();
		} else if (type.data_type != null && get_ccode_default_value (type.data_type) != "") {
			return new CCodeConstant (get_ccode_default_value (type.data_type));
		}
		return null;
	}

	public string get_ccode_default_value (TypeSymbol node) {
		return CodegenPlugBaseModule.get_ccode_default_value (node);
	}

	public CCodeExpression? get_dup_func_expression (DataType type
		, SourceReference? source_reference, bool is_chainup = false) {
		if (type.data_type != null) {
			string dup_function = "";
			if (is_reference_counting (type.data_type)) {
				dup_function = get_ccode_ref_function (type.data_type);
			} else if (type is ValueType) {
				dup_function = get_ccode_dup_function (type.data_type);
				if (dup_function == null) {
					dup_function = "";
				}
			}

			return new CCodeIdentifier (dup_function);
		} else if (type.type_parameter != null) {
			return null;
		} else if (type is ArrayType) {
			return new CCodeIdentifier ("aroop_object_ref");
		} else if (type is DelegateType) {
			return null;
		} else if (type is PointerType) {
			var pointer_type = (PointerType) type;
			return get_dup_func_expression (pointer_type.base_type, source_reference);
		} else {
			return new CCodeConstant ("NULL");
		}
	}

	public bool method_has_wrapper (Method method) {
		return (method.get_attribute ("NoWrapper") == null);
	}

	public bool requires_copy (DataType type) {
		if (!type.is_disposable ()) {
			return false;
		}

		if(type.data_type != null && type.data_type is Class) {
			var cl = type.data_type;
			if (is_reference_counting (cl) && get_ccode_ref_function (cl) == "") {
				// empty ref_function => no ref necessary
				return false;
			}
		}

		if (type.type_parameter != null) {
			return false;
		}

		return true;
	}

	public bool get_ccode_ref_function_void (Class node) {
		return CodegenPlugBaseModule.get_ccode_ref_function_void (node);
	}

	public double get_ccode_instance_pos (CodeNode node) {
		return CodegenPlugBaseModule.get_ccode_instance_pos (node);
	}

	public string get_ccode_sentinel (Method m) {
		return CodegenPlugBaseModule.get_ccode_sentinel (m);
	}

	public string? get_custom_creturn_type (Method m) {
		var attr = m.get_attribute ("CCode");
		if (attr != null) {
			string type = attr.get_string ("type");
			if (type != null) {
				return type;
			}
		}
		return null;
	}

	bool is_ref_function_void (DataType type) {
		if(type.data_type != null && type.data_type is Class) {
			var cl = type.data_type as Class;
			if (get_ccode_ref_function_void (cl))
				return true;
		}
		return false;
	}

	public CCodeExpression? get_ref_cexpression (DataType expression_type, CCodeExpression cexpr, Expression? expr, CodeNode node) {
		if(!requires_destroy (expression_type)) {
			//return get_cvalue (expr);
			return cexpr;
		}

		if (expression_type is ValueType && !expression_type.nullable) {
			// normal value type, no null check
			// (copy (&temp, 0, &expr, 0), temp)

			var decl = emitter.get_temp_variable (expression_type, false, node);
			AroopCodeGeneratorAdapter.generate_temp_variable(decl);
			print("get_ref_cexpression is creating temporary variable %s for %s\n", decl.to_string(), expr.to_string());

			var ctemp = get_variable_cexpression (decl.name);

			var vt = (ValueType) expression_type;
			var st = (Struct) vt.type_symbol;
			var copy_call = new CCodeFunctionCall (new CCodeIdentifier (get_ccode_copy_function (st)));
			copy_call.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, ctemp));
			copy_call.add_argument (new CCodeConstant ("0"));
			copy_call.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, cexpr));
			copy_call.add_argument (new CCodeConstant ("0"));

			var ccomma = new CCodeCommaExpression ();

			ccomma.append_expression (copy_call);
			ccomma.append_expression (ctemp);

			return ccomma;
		}

		/* (temp = expr, temp == NULL ? NULL : ref (temp))
		 *
		 * can be simplified to
		 * ref (expr)
		 * if static type of expr is non-null
		 */

		var dupexpr = get_dup_func_expression (expression_type, node.source_reference);

		if (dupexpr == null) {
			node.error = true;
			return null;
		}

		var ccall = new CCodeFunctionCall (dupexpr);

		if (expr != null && expr.is_non_null ()
		    && !is_ref_function_void (expression_type)) {
			// expression is non-null
			ccall.add_argument (get_cvalue (expr));

			return new CCodeCastExpression(ccall, get_ccode_aroop_name (expression_type));
		} else {
#if true
			var decl = emitter.get_temp_variable (expression_type, false, node);
			AroopCodeGeneratorAdapter.generate_temp_variable(decl);
			print("get_ref_cexpression is creating temporary variable %s for %s\n", decl.to_string(), expr.to_string());

			var ctemp = get_variable_cexpression (decl.name);

			var cisnull = new CCodeBinaryExpression (CCodeBinaryOperator.EQUALITY, ctemp, new CCodeConstant ("NULL"));
			if (expression_type.type_parameter != null) {
				// dup functions are optional for type parameters
				var cdupisnull = new CCodeBinaryExpression (CCodeBinaryOperator.EQUALITY, get_dup_func_expression (expression_type, node.source_reference), new CCodeConstant ("NULL"));
				cisnull = new CCodeBinaryExpression (CCodeBinaryOperator.OR, cisnull, cdupisnull);
			}

			ccall.add_argument (ctemp);

			var ccomma = new CCodeCommaExpression ();
			ccomma.append_expression (new CCodeAssignment (ctemp, cexpr));

			var cifnull = new CCodeConstant ("NULL");
			ccomma.append_expression (new CCodeConditionalExpression (cisnull, cifnull, new CCodeCastExpression(ccall, get_ccode_aroop_name (expression_type))));

			// repeat temp variable at the end of the comma expression
			// if the ref function returns void
			if (is_ref_function_void (expression_type)) {
				ccomma.append_expression (ctemp);
			}

			return ccomma;
#else
			return new CCodeCastExpression(ccall, get_ccode_aroop_name (expression_type));
#endif
		}
	}



}
public class Vala.AroopValue : TargetValue {
	public CCodeExpression cvalue;

	public AroopValue (DataType? value_type = null, CCodeExpression? cvalue = null) {
		base (value_type);
		this.cvalue = cvalue;
	}
}

/**
 * Represents a struct declaration in the C code.
 */
public class codegenplug.CCodeStructPrototype : Vala.CCodeNode {
        /**
         * The struct name.
         */
		private string type_name { get; set; }
		private string name { get; set; }
		public CCodeStruct definition;
        public CCodeStructPrototype (string name) {
            this.name = "_%s".printf (name);
			this.type_name = name;
			definition = new CCodeStruct(this.name);
        }

		public void generate_type_declaration(CCodeFile decl_space) {
			decl_space.add_type_declaration (new CCodeTypeDefinition ("struct _%s".printf (type_name), new CCodeVariableDeclarator (type_name)));
		}
	
        public override void write (CCodeWriter writer) {
                writer.write_string ("struct ");
                writer.write_string (name);
                writer.write_string (";");
                writer.write_newline ();
                writer.write_newline ();
        }
}


