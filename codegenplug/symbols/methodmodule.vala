
using Vala;
using shotodolplug;
using codegenplug;


/**
 * The link between a method and generated code.
 */
public class codegenplug.MethodModule : shotodolplug.Module {
	SourceEmitterModule?emitter = null;
	CSymbolResolve?resolve = null;
	public MethodModule() {
		base("Method", "0.0");
	}

	public override int init() {
		PluginManager.register("visit/method", new HookExtension(visit_method, this));
		PluginManager.register("generate/method/declaration", new HookExtension(generate_method_declaration_helper, this));
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

	/*public override bool method_has_wrapper (Method method) {
		return (method.get_attribute ("NoWrapper") == null);
	}*/

	/*public override string? get_custom_creturn_type (Method m) {
		var attr = m.get_attribute ("CCode");
		if (attr != null) {
			string type = attr.get_string ("type");
			if (type != null) {
				return type;
			}
		}
		return null;
	}*/

	Value? generate_method_declaration_helper (Value?given_args) {
		var args = (HashTable<string,Value?>)given_args;
		generate_method_declaration((Method?)args["method"], (CCodeFile?)args["decl_space"]);
		return null;
	}

	void generate_method_declaration (Method m, CCodeFile decl_space) {
		if (emitter.add_symbol_declaration (decl_space, m, resolve.get_ccode_name (m))) {
			return;
		}

		if (m.is_abstract || m.is_virtual) {
			// TODO remove the __VA_ARGS__ for single argument function
			int count = m.get_parameters().size; // get the number of parameters
			if (m.return_type is GenericType) {
				count++;
			}
			var macro_function = "%s(x".printf(resolve.get_ccode_name(m));
			var macro_body = "((%s*)x)->vtable->%s(x".printf(resolve.get_ccode_aroop_name((Class) m.parent_symbol), m.name);
			if(count != 0 || m.get_error_types().size != 0) {
				macro_function += ", ...";
				macro_body += ", __VA_ARGS__";
			}
			var func_macro = new CCodeMacroReplacement(macro_function + ")", macro_body + ")");
			decl_space.add_type_declaration (func_macro);
			// for base
#if false
			macro_function = "%s(x".printf(resolve.get_ccode_base_name(m));
			macro_body = "((%s*)x)->vtable->_base_vtable->%s(x".printf(resolve.get_ccode_aroop_name((Class) m.parent_symbol), m.name);
			if(count != 0 || m.get_error_types().size != 0) {
				macro_function += ", ...";
				macro_body += ", __VA_ARGS__";
			}
			func_macro = new CCodeMacroReplacement(macro_function + ")", macro_body + ")");
			decl_space.add_type_declaration (func_macro);
#endif
		} else {
			var function = new CCodeFunction (resolve.get_ccode_name (m));

			if (m.is_internal_symbol ()) {
				function.modifiers |= CCodeModifiers.STATIC;
				if (m.is_inline) {
					function.modifiers |= CCodeModifiers.INLINE;
				}
			}

			AroopCodeGeneratorAdapter.generate_cparameters (m, decl_space, function, null, new CCodeFunctionCall (new CCodeIdentifier ("fake")));

			decl_space.add_function_declaration (function);
		}
		if (m is CreationMethod && m.parent_symbol != null && m.parent_symbol is Class) {
			AroopCodeGeneratorAdapter.generate_class_declaration ((Class) m.parent_symbol, decl_space);

			// _init function
			var function = new CCodeFunction (resolve.get_ccode_real_name (m));

			if (m.is_internal_symbol ()) {
				function.modifiers |= CCodeModifiers.STATIC;
			}

			AroopCodeGeneratorAdapter.generate_cparameters (m, decl_space, function);

			decl_space.add_function_declaration (function);
		}
	}

	Value? visit_method (Value?args) {
		Method m = (Method?)args;
		emitter.push_context (new EmitContext (m));

		foreach (Vala.Parameter param in m.get_parameters ()) {
			param.accept (emitter.visitor);
		}

		foreach (Expression precondition in m.get_preconditions ()) {
			precondition.emit (emitter.visitor);
		}

		foreach (Expression postcondition in m.get_postconditions ()) {
			postcondition.emit (emitter.visitor);
		}

		generate_method_declaration (m, emitter.cfile);

		if (!m.is_internal_symbol ()) {
			generate_method_declaration (m, emitter.header_file);
		}

		var function = new CCodeFunction (resolve.get_ccode_real_name (m));

		AroopCodeGeneratorAdapter.generate_cparameters (m, emitter.cfile, function);

		// generate *_real_* functions for virtual methods
		if (!m.is_abstract) {
			if (m.base_method != null || m.base_interface_method != null) {
				// declare *_real_* function
#if true
				function.modifiers |= CCodeModifiers.STATIC;
#else
				emitter.header_file.add_function_declaration(function);
#endif
				emitter.cfile.add_function_declaration (function);
			} else if (m.is_internal_symbol ()) {
				function.modifiers |= CCodeModifiers.STATIC;
			}

			if (m.body != null) {
				emitter.push_function (function);

				if(m.overrides || (m.base_interface_method != null && !m.is_abstract && !m.is_virtual)) {
					emitter.ccode.add_declaration("%s *".printf (resolve.get_ccode_aroop_name(emitter.current_class)), new CCodeVariableDeclarator (resolve.self_instance));
					var lop = new CCodeIdentifier (resolve.self_instance);
					var rop = new CCodeCastExpression (new CCodeIdentifier ("base_instance"), "%s *".printf (resolve.get_ccode_aroop_name(emitter.current_class)));
					print_debug("visit_method creating assignment for %s ++++++++++++++++++\n".printf(m.to_string()));
					emitter.ccode.add_assignment (lop, rop);
				}
		
#if false
				// what does it do ??
				if (emitter.context.module_init_method == m) {
					add_module_init ();
				}
#endif

				if (m.closure) {
					AroopCodeGeneratorAdapter.populate_variables_of_parent_closure(
						emitter.current_closure_block
						, m.binding == MemberBinding.INSTANCE
						, emitter.ccode
					);
				}
				foreach (Vala.Parameter param in m.get_parameters ()) {
					if (param.ellipsis) {
						break;
					}

					var t = param.variable_type.data_type;
					if (t != null && t.is_reference_type ()) {
						if (param.direction == Vala.ParameterDirection.OUT) {
							// ensure that the passed reference for output parameter is cleared
							var a = new CCodeAssignment (new CCodeUnaryExpression (CCodeUnaryOperator.POINTER_INDIRECTION, resolve.get_variable_cexpression (param.name)), new CCodeConstant ("NULL"));
							var cblock = new CCodeBlock ();
							cblock.add_statement (new CCodeExpressionStatement (a));

							var condition = new CCodeBinaryExpression (CCodeBinaryOperator.INEQUALITY, new CCodeIdentifier (param.name), new CCodeConstant ("NULL"));
							var if_statement = new CCodeIfStatement (condition, cblock);
							emitter.ccode.add_statement (if_statement);
						}
					}
				}

				m.body.emit (emitter.visitor);

				if (emitter.current_method_inner_error) {
					/* always separate error parameter and inner_error local variable
					 * as error may be set to NULL but we're always interested in inner errors
					 */
#if false
					if (m.coroutine) {
						closure_struct.add_field ("aroop_wrong*", "_inner_error_");

						// no initialization necessary, closure struct is zeroed
					} else {
#endif
						emitter.ccode.add_declaration ("aroop_wrong*", new CCodeVariableDeclarator.zero ("_inner_error_", new CCodeConstant ("NULL")));
#if false
					}
#endif
				}

				if (!(m.return_type is VoidType) && !(m.return_type is GenericType)) {
					var cdecl = new CCodeDeclaration (resolve.get_ccode_aroop_name (m.return_type));
					cdecl.add_declarator (new CCodeVariableDeclarator.zero ("result", resolve.default_value_for_type (m.return_type, true)));
					emitter.ccode.add_statement (cdecl);

					//ccode.add_statement (new CCodeReturnStatement (new CCodeIdentifier ("result")));
				}


				var st = m.parent_symbol as Struct;
				if (m is CreationMethod && st != null && (st.is_boolean_type () || st.is_integer_type () || st.is_floating_type ())) {
					var cdecl = new CCodeDeclaration (resolve.get_ccode_aroop_name (st));
					cdecl.add_declarator (new CCodeVariableDeclarator (resolve.self_instance, new CCodeConstant ("0")));
					emitter.ccode.add_statement (cdecl);

					emitter.ccode.add_statement (new CCodeReturnStatement (new CCodeIdentifier (resolve.self_instance)));
				}				
				emitter.cfile.add_function (function);
			}
		}

		if (m.is_abstract || m.is_virtual) {
			AroopCodeGeneratorAdapter.generate_class_declaration ((Class) emitter.object_class, emitter.cfile);
		}
		emitter.pop_context ();

		if (m.entry_point) {
			AroopCodeGeneratorAdapter.generate_type_declaration (new StructValueType (emitter.array_struct), emitter.cfile);

			// m is possible entry point, add appropriate startup code
			var cmain = new CCodeFunction ("AROOP_MAIN_ENTRY_POINT", "int");
			cmain.line = function.line;
			cmain.add_parameter (new CCodeParameter ("argc", "int"));
			cmain.add_parameter (new CCodeParameter ("argv", "char **"));

			emitter.push_function (cmain);

#if false
			var aroop_init_call = new CCodeFunctionCall (new CCodeIdentifier ("aroop_init"));
			aroop_init_call.add_argument (new CCodeIdentifier ("argc"));
			aroop_init_call.add_argument (new CCodeIdentifier ("argv"));
			emitter.ccode.add_statement (new CCodeExpressionStatement (aroop_init_call));
#endif
			var cdecl = new CCodeDeclaration ("int");
			cdecl.add_declarator (new CCodeVariableDeclarator ("result", new CCodeConstant ("0")));
			emitter.ccode.add_statement (cdecl);

			var main_call = new CCodeFunctionCall (new CCodeIdentifier ("aroop_main0"));
			if (m.get_parameters ().size == 1) {
				main_call = new CCodeFunctionCall (new CCodeIdentifier ("aroop_main1"));
			}
			main_call.add_argument (new CCodeIdentifier ("argc"));
			main_call.add_argument (new CCodeIdentifier ("argv"));
			main_call.add_argument (new CCodeIdentifier (function.name));
			//ccode.add_statement (new CCodeExpressionStatement (aroop_init_call));

			add_module_init ();


			//var main_call = new CCodeFunctionCall (new CCodeIdentifier (function.name));

#if false
			if (m.get_parameters ().size == 1) {
				// create Aroop array from C array
				// should be replaced by Aroop list
				var array_creation = new CCodeFunctionCall (new CCodeIdentifier ("aroop_array_create"));
				array_creation.add_argument (new CCodeFunctionCall (new CCodeIdentifier ("string_type_get")));
				array_creation.add_argument (new CCodeIdentifier ("argc"));

				cdecl = new CCodeDeclaration ("AroopArray");
				cdecl.add_declarator (new CCodeVariableDeclarator ("args", array_creation));
				emitter.ccode.add_statement (cdecl);

				var array_data = new CCodeMemberAccess (new CCodeIdentifier ("args"), "data");

				cdecl = new CCodeDeclaration ("string_t*");
				cdecl.add_declarator (new CCodeVariableDeclarator ("args_data", array_data));
				emitter.ccode.add_statement (cdecl);

				cdecl = new CCodeDeclaration ("int");
				cdecl.add_declarator (new CCodeVariableDeclarator ("argi"));
				emitter.ccode.add_statement (cdecl);

				var string_creation = new CCodeFunctionCall (new CCodeIdentifier ("string_create_from_cstring"));
				string_creation.add_argument (new CCodeElementAccess (new CCodeIdentifier ("argv"), new CCodeIdentifier ("argi")));

				var loop_block = new CCodeBlock ();
				loop_block.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeElementAccess (new CCodeIdentifier ("args_data"), new CCodeIdentifier ("argi")), string_creation)));

				var for_stmt = new CCodeForStatement (new CCodeBinaryExpression (CCodeBinaryOperator.LESS_THAN, new CCodeIdentifier ("argi"), new CCodeIdentifier ("argc")), loop_block);
				for_stmt.add_initializer (new CCodeAssignment (new CCodeIdentifier ("argi"), new CCodeConstant ("0")));
				for_stmt.add_iterator (new CCodeUnaryExpression (CCodeUnaryOperator.POSTFIX_INCREMENT, new CCodeIdentifier ("argi")));
				emitter.ccode.add_statement (for_stmt);

				main_call.add_argument (new CCodeIdentifier ("args"));
			}
#endif

			var aroop_deinit_call = new CCodeFunctionCall (new CCodeIdentifier ("aroop_deinit"));
			if (m.return_type is VoidType) {
				// method returns void, always use 0 as exit code
				var main_stmt = new CCodeExpressionStatement (main_call);
				main_stmt.line = cmain.line;
				emitter.ccode.add_statement (main_stmt);
				emitter.ccode.add_statement (new CCodeExpressionStatement (aroop_deinit_call));
			} else {
				var main_stmt = new CCodeExpressionStatement (new CCodeAssignment (new CCodeIdentifier ("result"), main_call));
				main_stmt.line = cmain.line;
				emitter.ccode.add_statement (main_stmt);
				emitter.ccode.add_statement (new CCodeExpressionStatement (aroop_deinit_call));
			}

			
			var ret_stmt = new CCodeReturnStatement (new CCodeIdentifier ("result"));
			ret_stmt.line = cmain.line;
			emitter.ccode.add_statement (ret_stmt);

			emitter.pop_function ();

			emitter.cfile.add_function (cmain);
		}
		return null;
	}
	
	void add_module_init () {
#if false
// TODO write static init here ..
		foreach (var field in static_fields) {
			field.initializer.emit (emitter.visitor);

			var lhs = new CCodeIdentifier (resolve.get_ccode_name (field));
			var rhs = get_cvalue (field.initializer);

			print_debug("add_module_init creating assignment for %s ++++++++++++++++++\n".printf(field.to_string()));
			emitter.ccode.add_assignment (lhs, rhs);
		}
#endif
	}
}

