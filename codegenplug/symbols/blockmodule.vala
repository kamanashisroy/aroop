
using Vala;
using shotodolplug;
using codegenplug;


/**
 * The link between a method and generated code.
 */
public class codegenplug.BlockModule : shotodolplug.Module {
	SourceEmitterModule?emitter = null;
	CSymbolResolve?resolve = null;
	public BlockModule() {
		base("Block", "0.0");
	}

	public override int init() {
		PluginManager.register("visit/block", new HookExtension(visit_block, this));
		PluginManager.register("generate/block/name", new HookExtension(generate_block_name, this));
		PluginManager.register("generate/block/var/name", new HookExtension(generate_block_var_name, this));
		PluginManager.register("generate/block/finalization", new HookExtension(generate_block_finalization_wrapper, this));
		PluginManager.register("populate/parent/closure", new HookExtension(populate_variables_of_parent_closure_wrapper, this));
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

	Value? visit_block (Value? givenValue) {
		Block b = (Block?)givenValue;
		emitter.emit_context.push_symbol (b);

		var local_vars = b.get_local_variables ();

		if (b.parent_node is Block || b.parent_node is SwitchStatement) {
			emitter.ccode.open_block ();
		}

		if (b.captured) {
			int block_id = emitter.get_block_id(b);
			var parent_block = emitter.next_closure_block (b.parent_symbol);

			generate_block_declaration(b, emitter.cfile);
			
			//var alloc_call = new CCodeFunctionCall (new CCodeIdentifier ("aroop_object_alloc"));
			//alloc_call.add_argument (new CCodeIdentifier ("sizeof(struct _%s)".printf (AroopCodeGeneratorAdapter.generate_block_name(b))));
			//alloc_call.add_argument (new CCodeIdentifier("%spray".printf (AroopCodeGeneratorAdapter.generate_block_name(b))));
			//vblock.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeIdentifier (resolve.self_instance), new CCodeCastExpression (alloc_call, "%s *".printf (resolve.get_ccode_aroop_name (emitter.current_type_symbol))))));
			
			var data_decl = new CCodeDeclaration (AroopCodeGeneratorAdapter.generate_block_name(b));
			data_decl.add_declarator (new CCodeVariableDeclarator (AroopCodeGeneratorAdapter.generate_block_var_name(b)));
			emitter.ccode.add_statement (data_decl);

			if (parent_block != null) {
				generate_block_parent_assignment(b);
			} else if ((emitter.current_method != null && emitter.current_method.binding == MemberBinding.INSTANCE) ||
			           (emitter.current_property_accessor != null && emitter.current_property_accessor.prop.binding == MemberBinding.INSTANCE)) {
				var ref_call = new CCodeFunctionCall (resolve.get_dup_func_expression (resolve.get_data_type_for_symbol(emitter.current_type_symbol), b.source_reference));
				ref_call.add_argument (new CCodeIdentifier (resolve.self_instance));

				print_debug("visit_block doing assignment for %s ========================= \n".printf(b.to_string()));
				emitter.ccode.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeMemberAccess (resolve.get_variable_cexpression (AroopCodeGeneratorAdapter.generate_block_var_name(b)), resolve.self_instance), ref_call)));
			}

			if (b.parent_symbol is Method) {
				var m = (Method) b.parent_symbol;

				// parameters are captured with the top-level block of the method
				foreach (var param in m.get_parameters ()) {
					if (param.captured) {
						capture_parameter (param, b);
					}
				}
			} else if (b.parent_symbol is PropertyAccessor) {
				var acc = (PropertyAccessor) b.parent_symbol;

				if (!acc.readable && acc.value_parameter.captured) {
					capture_parameter (acc.value_parameter, b);
				}
			}
		}

		foreach (Statement stmt in b.get_statements ()) {
			stmt.emit (emitter.visitor);
		}

		// free in reverse order
		for (int i = local_vars.size - 1; i >= 0; i--) {
			var local = local_vars[i];
			if (/*!local.floating &&*/ !local.captured && resolve.requires_destroy (local.variable_type)) {
				var ma = new MemberAccess.simple (local.name);
				ma.symbol_reference = local;
				emitter.ccode.add_statement (
					new CCodeExpressionStatement (
						resolve.get_unref_expression (
							resolve.get_variable_cexpression (local.name)
							, local.variable_type
							, ma
						)
					)
				);
			}
		}

		if (b.parent_symbol is Method) {
			var m = (Method) b.parent_symbol;
			foreach (Vala.Parameter param in m.get_parameters ()) {
				if (!param.captured && resolve.requires_destroy (param.variable_type) && param.direction == Vala.ParameterDirection.IN) {
					var ma = new MemberAccess.simple (param.name);
					ma.symbol_reference = param;
					emitter.ccode.add_statement (
						new CCodeExpressionStatement (
							resolve.get_unref_expression (resolve.get_variable_cexpression (param.name)
								, param.variable_type
								, ma)));
				}
			}
		}

		if (b.captured) {
			int block_id = emitter.get_block_id (b);

			var data_unref = new CCodeFunctionCall (new CCodeIdentifier (generate_block_finalize_function_name(b)));
			data_unref.add_argument (
				new CCodeUnaryExpression (
					CCodeUnaryOperator.ADDRESS_OF, 
					new CCodeIdentifier(AroopCodeGeneratorAdapter.generate_block_var_name(b))
				)
			);
			emitter.ccode.add_statement (new CCodeExpressionStatement (data_unref));
		}

		if (b.parent_node is Block || b.parent_node is SwitchStatement) {
			emitter.ccode.close ();
		}

		emitter.emit_context.pop_symbol ();
		return null;
	}


	void capture_parameter (Vala.Parameter param, Block b) {
		var param_type = param.variable_type.copy ();
		// create copy if necessary as captured variables may need to be kept alive
		CCodeExpression cparam = resolve.get_variable_cexpression (param.name);
		if (resolve.requires_copy (param_type) && !param.variable_type.value_owned)  {
			var ma = new MemberAccess.simple (param.name);
			ma.symbol_reference = param;
			ma.value_type = param.variable_type.copy ();
			// directly access parameters in ref expressions
			param.captured = false;
			cparam = resolve.get_ref_cexpression (param.variable_type, cparam, ma, param);
			param.captured = true;
		}

		print_debug("capture_parameter creating assignment for %s ++++++++++++++++++\n".printf(param.to_string()));
		emitter.ccode.add_assignment (
			new CCodeMemberAccess (
				resolve.get_variable_cexpression (
					AroopCodeGeneratorAdapter.generate_block_var_name(b)
				), resolve.get_variable_cname (param.name)), cparam);
	}

	Value? generate_block_name(Value? given) {
		Block b = (Block?)given;
		int block_id = emitter.get_block_id (b);
		return "Block%dData".printf (block_id);
	}
	
	Value? generate_block_var_name(Value? given) {
		Block b = (Block?)given;
		int block_id = emitter.get_block_id (b);
		return "_data%d_".printf (block_id);
	}

	string generate_block_finalize_function_name(Block b) {
		int block_id = emitter.get_block_id (b);
		return "block%d_data_finalize".printf (block_id);
	}
	
	void generate_block_finalize_function(Block b, CCodeBlock free_block, CCodeFile decl_space) {
		var unref_fun = new CCodeFunction (generate_block_finalize_function_name(b), "void");
		unref_fun.add_parameter (new CCodeParameter (AroopCodeGeneratorAdapter.generate_block_var_name(b), AroopCodeGeneratorAdapter.generate_block_name(b) + "*"));
		unref_fun.modifiers = CCodeModifiers.STATIC;
		decl_space.add_function_declaration (unref_fun);
		unref_fun.block = free_block;

		decl_space.add_function (unref_fun);
	}

	Value? generate_block_finalization_wrapper(Value?given_args) {
		var args = (HashTable<string,Value?>)given_args;
		generate_block_finalization(
			(Block?)args["block"]
			,(CCodeFunction?)args["decl_space"]
		);
		return null;
	}

	void generate_block_finalization(Block b, CCodeFunction decl_space) {

		var data_unref = new CCodeFunctionCall (new CCodeIdentifier (generate_block_finalize_function_name(b)));
		data_unref.add_argument (
			new CCodeUnaryExpression (
					CCodeUnaryOperator.ADDRESS_OF, 
					resolve.get_variable_cexpression(AroopCodeGeneratorAdapter.generate_block_var_name(b))
				));
		emitter.ccode.add_expression (data_unref);
	}
	
	void generate_block_declaration (Block b, CCodeFile decl_space) {
		// XXX multiple block is not working with add_symbol_declaration :((
		if (emitter.add_symbol_declaration (decl_space, b, resolve.get_ccode_name (b)) && false) {
			return;
		}
		var parent_block = emitter.next_closure_block (b.parent_symbol);
		var local_vars = b.get_local_variables ();
		var proto = new CCodeStructPrototype (AroopCodeGeneratorAdapter.generate_block_name(b));
		var free_block = new CCodeBlock ();
		var block_struct = proto.definition;
		
		if (parent_block != null) {
			// XXX this piece of code is not tested
			int parent_block_id = emitter.get_block_id (parent_block);

			block_struct.add_field (AroopCodeGeneratorAdapter.generate_block_name(parent_block) + "*"
				, AroopCodeGeneratorAdapter.generate_block_var_name(parent_block));

		} else if ((emitter.current_method != null && emitter.current_method.binding == MemberBinding.INSTANCE) ||
				   (emitter.current_property_accessor != null && emitter.current_property_accessor.prop.binding == MemberBinding.INSTANCE)) {
			//block_struct.add_field ("%s *".printf (resolve.get_ccode_aroop_name(emitter.current_symbol)), resolve.self_instance);
			block_struct.add_field ("%s *".printf (resolve.get_ccode_aroop_name(emitter.current_type_symbol)), resolve.self_instance);

			var ma = new MemberAccess.simple (resolve.self_instance);
			ma.symbol_reference = emitter.current_symbol;
			free_block.add_statement (
				new CCodeExpressionStatement (resolve.get_unref_expression (
				new CCodeMemberAccess.pointer (
				new CCodeIdentifier (
					AroopCodeGeneratorAdapter.generate_block_var_name(b)
				), resolve.self_instance), resolve.get_data_type_for_symbol(emitter.current_type_symbol), ma)));
		}
		foreach (var local in local_vars) {
			if (local.captured) {
				AroopCodeGeneratorAdapter.generate_type_declaration (local.variable_type, decl_space);

				//block_struct.add_field (resolve.get_ccode_aroop_name (local.variable_type), resolve.get_variable_cname (local.name) + resolve.get_ccode_declarator_suffix (local.variable_type), null, generate_declarator_suffix_cexpr(local.variable_type));
				block_struct.add_field (resolve.get_ccode_aroop_name (local.variable_type), resolve.get_variable_cname (local.name), resolve.get_ccode_declarator_suffix (local.variable_type));
			}
		}
		
		// free in reverse order
		for (int i = local_vars.size - 1; i >= 0; i--) {
			var local = local_vars[i];
			if (local.captured) {
				if (resolve.requires_destroy (local.variable_type)) {
					var ma = new MemberAccess.simple (local.name);
					ma.symbol_reference = local;
					ma.value_type = local.variable_type.copy ();
					free_block.add_statement (new CCodeExpressionStatement (
						resolve.get_unref_expression (new CCodeMemberAccess.pointer (
						new CCodeIdentifier (AroopCodeGeneratorAdapter.generate_block_var_name(b)), resolve.get_variable_cname (local.name)), local.variable_type, ma)));
				}
			}
		}
		
		if (b.parent_symbol is Method) {
			var m = (Method) b.parent_symbol;

			// parameters are captured with the top-level block of the method
			foreach (var param in m.get_parameters ()) {
				if (param.captured) {
					block_add_parameter (b, param, block_struct, free_block);
				}
			}
		} else if (b.parent_symbol is PropertyAccessor) {
			var acc = (PropertyAccessor) b.parent_symbol;

			if (!acc.readable && acc.value_parameter.captured) {
				block_add_parameter (b, acc.value_parameter, block_struct, free_block);
			}
		}

		
		decl_space.add_type_declaration (proto);
		proto.generate_type_declaration(decl_space);
		decl_space.add_type_definition (block_struct);
		generate_block_finalize_function(b, free_block, decl_space);
	}
	void block_add_parameter(Block b, Vala.Parameter param, CCodeStruct block_struct, CCodeBlock free_block) {
		AroopCodeGeneratorAdapter.generate_type_declaration (param.variable_type, emitter.cfile);
		var param_type = param.variable_type.copy ();
		//param_type.value_owned = true;
		block_struct.add_field (resolve.get_ccode_aroop_name (param_type), resolve.get_variable_cname (param.name));

		if (param.captured && resolve.requires_copy (param_type) && !param_type.value_owned && resolve.requires_destroy (param_type)) {
			var ma = new MemberAccess.simple (param.name);
			ma.symbol_reference = param;
			ma.value_type = param_type.copy ();
			free_block.add_statement (
				new CCodeExpressionStatement (
					resolve.get_unref_expression (
						new CCodeMemberAccess.pointer (
							new CCodeIdentifier (
								AroopCodeGeneratorAdapter.generate_block_var_name(b)
							), resolve.get_variable_cname (param.name)
						), param.variable_type, ma)
					)
				);
		}
	}
	void generate_block_parent_assignment(Block b) {
		var parent_block = emitter.next_closure_block (b.parent_symbol);

		print_debug("generate_block_parent_assignment doing assignment for %s ========================= \n".printf(b.to_string()));
		emitter.ccode.add_statement (
			new CCodeExpressionStatement (
				new CCodeAssignment (
					new CCodeMemberAccess (
						resolve.get_variable_cexpression (AroopCodeGeneratorAdapter.generate_block_var_name(b))
						, AroopCodeGeneratorAdapter.generate_block_var_name(parent_block)
					)
					, resolve.get_variable_cexpression (AroopCodeGeneratorAdapter.generate_block_var_name(parent_block))
				)
			)
		);
	}

	Value? populate_variables_of_parent_closure_wrapper(Value?given_args) {
		var args = (HashTable<string,Value?>)given_args;
		populate_variables_of_parent_closure(
			(Block?)args["block"]
			,(bool)args["populate_self"]
			,(CCodeFunction?)args["decl_space"]
		);
		return null;
	}

	void populate_variables_of_parent_closure(Block b, bool populate_self, CCodeFunction decl_space) {
		// add variables for parent closure blocks
		// as closures only have one parameter for the innermost closure block
		var closure_block = b;
		while (true) {
			var parent_closure_block = emitter.next_closure_block (b.parent_symbol);
			if (parent_closure_block == null) {
				break;
			}
			int parent_block_id = emitter.get_block_id (parent_closure_block);

			var parent_data = new CCodeMemberAccess.pointer (
				new CCodeIdentifier (
					AroopCodeGeneratorAdapter.generate_block_var_name(closure_block)
				), AroopCodeGeneratorAdapter.generate_block_var_name (parent_closure_block));
			var cdecl = new CCodeDeclaration (AroopCodeGeneratorAdapter.generate_block_name (parent_closure_block));
			cdecl.add_declarator (new CCodeVariableDeclarator (AroopCodeGeneratorAdapter.generate_block_var_name (parent_closure_block), parent_data));

			decl_space.add_statement (cdecl);

			closure_block = parent_closure_block;
		}
		
		if(populate_self) {
			var cself = new CCodeMemberAccess.pointer (
				new CCodeIdentifier (AroopCodeGeneratorAdapter.generate_block_var_name(closure_block))
				, resolve.self_instance);
			var cdecl = new CCodeDeclaration ("%s *".printf (resolve.get_ccode_aroop_name (emitter.current_type_symbol)));
			cdecl.add_declarator (new CCodeVariableDeclarator (resolve.self_instance, cself));

			decl_space.add_statement (cdecl);
		}
	}

}

