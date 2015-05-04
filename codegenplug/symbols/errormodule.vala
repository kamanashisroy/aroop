using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.ErrorModule : shotodolplug.Module {
	SourceEmitterModule emitter;
	CSymbolResolve resolve;
	public ErrorModule() {
		base("Error", "0.0");
	}

	public override int init() {
		PluginManager.register("visit/error_domain", new HookExtension(visit_error_domain, this));
		PluginManager.register("visit/throw_statement", new HookExtension(visit_throw_statement, this));
		PluginManager.register("visit/try_statement", new HookExtension(visit_try_statement, this));
		PluginManager.register("visit/catch_clause", new HookExtension(visit_catch_clause, this));
		PluginManager.register("add/simple/check", new HookExtension(add_simple_check_helper, this));
		PluginManager.register("generate/error_domain/declaration", new HookExtension(generate_error_domain_declaration_helper, this));
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


	int current_try_id = 0;
	int next_try_id = 0;
	bool is_in_catch = false;
#if false
	Vala.ErrorType gerror_type;
#endif

	private string generate_error_domain_description_function(ErrorDomain edomain) {
		return resolve.get_error_module_lower_case_name (edomain) + "_desc";
	}
	
	public CCodeFunction generate_error_domain_callback(ErrorDomain edomain) {
		string desc_func_name = generate_error_domain_description_function(edomain);
		var cdomain_desc = new CCodeFunction (desc_func_name, "char*");
		cdomain_desc.add_parameter(new CCodeParameter("code", "SYNC_UWORD32_T"));
		cdomain_desc.add_parameter(new CCodeParameter("msg", "char*"));
		return cdomain_desc;
	}

	Value? generate_error_domain_declaration_helper(Value?given_args) {
		var args = (HashTable<string,Value?>)given_args;
		generate_error_domain_declaration((ErrorDomain?)args["edomain"], (CCodeFile?)args["decl_space"]);
		return null;
	}
	void generate_error_domain_declaration (ErrorDomain edomain, CCodeFile decl_space) {
		if (emitter.add_symbol_declaration (decl_space, edomain, resolve.get_error_module_lower_case_name (edomain))) {
			return;
		}

		// provide error listing for the domain
		var cenum = new CCodeEnum (resolve.get_error_module_lower_case_name (edomain));

		foreach (ErrorCode ecode in edomain.get_codes ()) {
			if (ecode.value == null) {
				cenum.add_value (new CCodeEnumValue (resolve.get_error_module_lower_case_name (ecode)));
			} else {
				ecode.value.emit (emitter.visitor);
				cenum.add_value (new CCodeEnumValue (resolve.get_error_module_lower_case_name (ecode), resolve.get_cvalue (ecode.value)));
			}
		}

		decl_space.add_type_definition (cenum);
		// provide domain description
		decl_space.add_function_declaration (generate_error_domain_callback(edomain));
	}
	
	Value? visit_error_domain (Value? given_value) {
		ErrorDomain edomain = (ErrorDomain?)given_value;
		if (edomain.comment != null) {
			emitter.cfile.add_type_definition (new CCodeComment (edomain.comment.content));
		}

		generate_error_domain_declaration (edomain, emitter.cfile);

		if (!edomain.is_internal_symbol ()) {
			generate_error_domain_declaration (edomain, emitter.header_file);
		}
		if (!edomain.is_private_symbol ()) {
			generate_error_domain_declaration (edomain, emitter.cfile);
		}
		var cdomain_desc  = generate_error_domain_callback(edomain);
		emitter.push_function (cdomain_desc);
		// add description
		emitter.ccode.add_return (new CCodeConstant ("\"" + resolve.get_ccode_lower_case_name (edomain) + "-domain\""));
		emitter.pop_function ();
		emitter.cfile.add_function (cdomain_desc);
		return null;
	}

	Value? visit_throw_statement (Value?given_arg) {
		ThrowStatement?stmt = (ThrowStatement?)given_arg;
		var throw_exception = new CCodeFunctionCall(new CCodeIdentifier ("aroop_throw_exception"));
		throw_exception.add_argument(resolve.get_cvalue(stmt.error_expression));
		//throw_exception.add_argument(generate_error_domain_description_function ((ErrorDomain)stmt.data_type));
#if false
		// TODO check if the error is allowed to throw ..
		// if the error is throwable
		foreach (DataType error_type in emitter.current_method.get_error_types ()) {
			// Check the allowed error domains to propagate
			var domain_check = new CCodeBinaryExpression (CCodeBinaryOperator.EQUALITY, new CCodeMemberAccess.pointer
				("", "domain"), new CCodeIdentifier (generate_error_domain_description_function ((ErrorDomain)error_type.data_type)));
			if (ccond == null) {
				ccond = domain_check;
			} else {
				ccond = new CCodeBinaryExpression (CCodeBinaryOperator.OR, ccond, domain_check);
			}
		}
#endif		
		emitter.ccode.add_expression (throw_exception);
				
		// free local variables
		AroopCodeGeneratorAdapter.append_local_free (emitter.current_symbol, false);
		//add_simple_check(stmt, true);
		
		// return something
		if (emitter.current_method is CreationMethod && emitter.current_method.parent_symbol is Class) {
			var cl = (Class) emitter.current_method.parent_symbol;
			//emitter.ccode.add_expression (destroy_value (new GLibValue (new ObjectType (cl), new CCodeIdentifier (self_instance), true)));
			emitter.ccode.add_return ();
		} else if (is_in_coroutine ()) {
			emitter.ccode.add_return (new CCodeConstant ("FALSE"));
		} else {
			return_default_value (emitter.current_return_type);
		}
		return null;
	}

	void uncaught_error_statement (CCodeExpression inner_error, bool unexpected = false) {
		// free local variables
		AroopCodeGeneratorAdapter.append_local_free (emitter.current_symbol, false);

		var ccritical = new CCodeFunctionCall (new CCodeIdentifier ("aroop_unhandled_error"));
		ccritical.add_argument (inner_error);

		// print critical message
		emitter.ccode.add_expression (ccritical);

		if (is_in_constructor () || is_in_destructor ()) {
			// just print critical, do not return prematurely
		} else if (emitter.current_method is CreationMethod) {
			if (emitter.current_method.parent_symbol is Struct) {
				emitter.ccode.add_return ();
			} else {
				emitter.ccode.add_return (new CCodeConstant ("NULL"));
			}
		} else if (is_in_coroutine ()) {
			emitter.ccode.add_return (new CCodeConstant ("FALSE"));
		} else if (emitter.current_return_type != null) {
			return_default_value (emitter.current_return_type);
		}
	}

	bool in_finally_block (CodeNode node) {
		var current_node = node;
		while (current_node != null) {
			var try_stmt = current_node.parent_node as TryStatement;
			if (try_stmt != null && try_stmt.finally_body == current_node) {
				return true;
			}
			current_node = current_node.parent_node;
		}
		return false;
	}

	Value? add_simple_check_helper (Value?given_args) {
		var args = (HashTable<string,Value?>)given_args;
		add_simple_check((CodeNode?)args["node"], (bool)args["always_fails"]);
		return null;
	}

	/**
	 * This method adds if statement for failed statements.
	 *
	 * if(_inner_error_) {
	 *   goto catch_clause;
	 * }
	 *
         */
	void add_simple_check (CodeNode node, bool always_fails = false) {
		emitter.current_method_inner_error = true;

		var inner_error = resolve.get_variable_cexpression ("_inner_error_");

		print_debug("doing check: %s\n".printf(node.to_string()));
		if (always_fails) {
			// inner_error is always set, avoid unnecessary if statement
			print_debug("always fails : %s\n".printf(node.to_string()));
			// eliminates C warnings
		} else {
			var ccond = new CCodeBinaryExpression (CCodeBinaryOperator.INEQUALITY, inner_error, new CCodeConstant ("NULL"));
			emitter.ccode.open_if (ccond);
			print_debug("we opened an if statement for %s\n".printf(node.to_string()));
		}

		if (emitter.emit_context.current_try != null) {
			// surrounding try found
			print_debug("we should add open an if statement for %s\n".printf(node.to_string()));

			// free local variables
			if (is_in_catch) {
				AroopCodeGeneratorAdapter.append_local_free (emitter.current_symbol, false, emitter.emit_context.current_catch);
			} else {
				AroopCodeGeneratorAdapter.append_local_free (emitter.current_symbol, false, emitter.emit_context.current_try);
			}

			var error_types = new ArrayList<DataType> ();
			foreach (DataType node_error_type in node.get_error_types ()) {
				error_types.add (node_error_type);
			}

			bool has_general_catch_clause = false;

			if (!is_in_catch) {
				var handled_error_types = new ArrayList<DataType> ();
				foreach (CatchClause clause in emitter.emit_context.current_try.get_catch_clauses ()) {
					// keep track of unhandled error types
					foreach (DataType node_error_type in error_types) {
						if (clause.error_type == null || node_error_type.compatible (clause.error_type)) {
							handled_error_types.add (node_error_type);
						}
					}
					foreach (DataType handled_error_type in handled_error_types) {
						error_types.remove (handled_error_type);
					}
					handled_error_types.clear ();

#if false
					if (clause.error_type.equals (gerror_type)) {
						// general catch clause, this should be the last one
						has_general_catch_clause = true;
						emitter.ccode.add_goto (clause.clabel_name);
						break;
					} else {
#else
					{
#endif
						var catch_type = clause.error_type as Vala.ErrorType;

						if (catch_type.error_code != null) {
							/* catch clause specifies a specific error code */
							var error_match = new CCodeFunctionCall (new CCodeIdentifier ("g_error_matches"));
							error_match.add_argument (inner_error);
							error_match.add_argument (new CCodeIdentifier (resolve.get_ccode_upper_case_name (catch_type.data_type)));
							error_match.add_argument (new CCodeIdentifier (resolve.get_ccode_name (catch_type.error_code)));

							emitter.ccode.open_if (error_match);
						} else {
							/* catch clause specifies a full error domain */
							var ccond = new CCodeBinaryExpression (CCodeBinaryOperator.EQUALITY,
									new CCodeMemberAccess.pointer (inner_error, "domain"), new CCodeIdentifier
									(generate_error_domain_description_function ((ErrorDomain)clause.error_type.data_type)));

							emitter.ccode.open_if (ccond);
						}

						// go to catch clause if error domain matches
						emitter.ccode.add_goto (clause.clabel_name);
						emitter.ccode.close ();
					}
				}
			}

			if (has_general_catch_clause) {
				// every possible error is already caught
				// as there is a general catch clause
				// no need to do anything else
			} else if (error_types.size > 0) {
				// go to finally clause if no catch clause matches
				// and there are still unhandled error types
				emitter.ccode.add_goto ("__finally%d".printf (current_try_id));
			} else if (in_finally_block (node)) {
				// do not check unexpected errors happening within finally blocks
				// as jump out of finally block is not supported
			} else {
				// should never happen with correct bindings
				uncaught_error_statement (inner_error, true);
			}
		} else if (emitter.current_method != null && emitter.current_method.get_error_types ().size > 0) {
			// current method can fail, propagate error
			CCodeBinaryExpression ccond = null;

			foreach (DataType error_type in emitter.current_method.get_error_types ()) {
				// If GLib.Error is allowed we propagate everything
#if false
				if (error_type.equals (gerror_type)) {
					ccond = null;
					break;
				}
#endif

				// Check the allowed error domains to propagate
				var domain_check = new CCodeBinaryExpression (CCodeBinaryOperator.EQUALITY, new CCodeMemberAccess.pointer
					(inner_error, "domain"), new CCodeIdentifier (generate_error_domain_description_function ((ErrorDomain)error_type.data_type)));
				if (ccond == null) {
					ccond = domain_check;
				} else {
					ccond = new CCodeBinaryExpression (CCodeBinaryOperator.OR, ccond, domain_check);
				}
			}

#if false
			if (ccond != null) {
				emitter.ccode.open_if (ccond);
				return_with_exception (inner_error);

				emitter.ccode.add_else ();
				uncaught_error_statement (inner_error);
				emitter.ccode.close ();
			} else {
				return_with_exception (inner_error);
			}
#endif
		} else {
			uncaught_error_statement (inner_error);
		}

		if (!always_fails) {
			emitter.ccode.close ();
		}
	}


	public bool is_in_coroutine () {
		return emitter.current_method != null && emitter.current_method.coroutine;
	}

	public bool is_in_constructor () {
		if (emitter.current_method != null) {
			// make sure to not return true in lambda expression inside constructor
			return false;
		}
		var sym = emitter.current_symbol;
		while (sym != null) {
			if (sym is Constructor) {
				return true;
			}
			sym = sym.parent_symbol;
		}
		return false;
	}

	public bool is_in_destructor () {
		if (emitter.current_method != null) {
			// make sure to not return true in lambda expression inside constructor
			return false;
		}
		var sym = emitter.current_symbol;
		while (sym != null) {
			if (sym is Destructor) {
				return true;
			}
			sym = sym.parent_symbol;
		}
		return false;
	}

	public void return_default_value (DataType return_type) {
		emitter.ccode.add_return (resolve.default_value_for_type (return_type, false));
	}

	Value? visit_try_statement (Value?given_arg) {
		TryStatement?stmt = (TryStatement?)given_arg;
		int this_try_id = next_try_id++;

		var old_try = emitter.emit_context.current_try;
		var old_try_id = current_try_id;
		var old_is_in_catch = is_in_catch;
		var old_catch = emitter.emit_context.current_catch;
		emitter.emit_context.current_try = stmt;
		current_try_id = this_try_id;
		is_in_catch = true;

		foreach (CatchClause clause in stmt.get_catch_clauses ()) {
			clause.clabel_name = "__catch%d_%s".printf (this_try_id, resolve.get_ccode_lower_case_name (clause.error_type));
		}

		is_in_catch = false;
		stmt.body.emit (emitter.visitor);
		is_in_catch = true;

		foreach (CatchClause clause in stmt.get_catch_clauses ()) {
			emitter.emit_context.current_catch = clause;
			emitter.ccode.add_goto ("__finally%d".printf (this_try_id));
			clause.emit (emitter.visitor);
		}

		emitter.emit_context.current_try = old_try;
		current_try_id = old_try_id;
		is_in_catch = old_is_in_catch;
		emitter.emit_context.current_catch = old_catch;

		emitter.ccode.add_label ("__finally%d".printf (this_try_id));
		if (stmt.finally_body != null) {
			stmt.finally_body.emit (emitter.visitor);
		}

		// check for errors not handled by this try statement
		// may be handled by outer try statements or propagated
		add_simple_check (stmt, !stmt.after_try_block_reachable);
		return null;
	}

	Value? visit_catch_clause (Value?given_arg) {
		CatchClause?clause = (CatchClause?)given_arg;
		emitter.current_method_inner_error = true;

		var error_type = (Vala.ErrorType) clause.error_type;
		if (error_type.error_domain != null) {
			generate_error_domain_declaration (error_type.error_domain, emitter.cfile);
		}

		emitter.ccode.add_label (clause.clabel_name);

		emitter.ccode.open_block ();

#if true
		if (clause.error_variable != null) {
			emitter.visitor.visit_local_variable (clause.error_variable);
			emitter.ccode.add_assignment (resolve.get_variable_cexpression (resolve.get_variable_cname (clause.error_variable.name)), resolve.get_variable_cexpression ("_inner_error_"));
		}
#endif
		var cclear = new CCodeFunctionCall (new CCodeIdentifier ("aroop_handled_error"));
		cclear.add_argument (resolve.get_variable_cexpression ("_inner_error_"));
		emitter.ccode.add_expression (cclear);

		clause.body.emit (emitter.visitor);

		emitter.ccode.close ();
		return null;
	}

#if false
	protected override void append_scope_free (Symbol sym, CodeNode? stop_at = null) {
		base.append_scope_free (sym, stop_at);

		if (!(stop_at is TryStatement || stop_at is CatchClause)) {
			var finally_block = (Block) null;
			if (sym.parent_node is TryStatement) {
				finally_block = (sym.parent_node as TryStatement).finally_body;
			} else if (sym.parent_node is CatchClause) {
				finally_block = (sym.parent_node.parent_node as TryStatement).finally_body;
			}

			if (finally_block != null && finally_block != sym) {
				finally_block.emit (emitter.visitor);
			}
		}
	}
#endif
}

// vim:sw=8 noet
