using GLib;
using Vala;

public abstract class Vala.AroopBlockModule : AroopStructModule {
	
	public override void generate_block_finalization(Block b, CCodeFunction decl_space) {

		var data_unref = new CCodeFunctionCall (new CCodeIdentifier (generate_block_finalize_function_name(b)));
		data_unref.add_argument (
			new CCodeUnaryExpression (
					CCodeUnaryOperator.ADDRESS_OF, 
					get_variable_cexpression(generate_block_var_name(b))
				));
		ccode.add_expression (data_unref);
	}
	
	private string generate_block_finalize_function_name(Block b) {
		int block_id = get_block_id (b);
		return "block%d_data_finalize".printf (block_id);
	}
	
	private void generate_block_finalize_function(Block b, CCodeBlock free_block, CCodeFile decl_space) {
		var unref_fun = new CCodeFunction (generate_block_finalize_function_name(b), "void");
		unref_fun.add_parameter (new CCodeParameter (generate_block_var_name(b), generate_block_name(b) + "*"));
		unref_fun.modifiers = CCodeModifiers.STATIC;
		decl_space.add_function_declaration (unref_fun);
		unref_fun.block = free_block;

		decl_space.add_function (unref_fun);
	}
	
	public string generate_block_name(Block b) {
		int block_id = get_block_id (b);
		return "Block%dData".printf (block_id);
	}
	
	public string generate_block_var_name(Block b) {
		int block_id = get_block_id (b);
		return "_data%d_".printf (block_id);
	}

	void block_add_parameter(Block b, Parameter param, CCodeStruct block_struct, CCodeBlock free_block) {
		generate_type_declaration (param.variable_type, cfile);
		var param_type = param.variable_type.copy ();
		param_type.value_owned = true;
		block_struct.add_field (get_ccode_aroop_name (param_type), get_variable_cname (param.name));

		if (requires_destroy (param_type)) {
			var ma = new MemberAccess.simple (param.name);
			ma.symbol_reference = param;
			ma.value_type = param_type.copy ();
			free_block.add_statement (
				new CCodeExpressionStatement (
					get_unref_expression (
						new CCodeMemberAccess.pointer (
							new CCodeIdentifier (
								generate_block_var_name(b)
							), get_variable_cname (param.name)
						), param.variable_type, ma)
					)
				);
		}
	}
		
	private void generate_block_declaration (Block b, CCodeFile decl_space) {
		// XXX multiple block is not working with add_symbol_declaration :((
		if (add_symbol_declaration (decl_space, b, get_ccode_name (b)) && false) {
			return;
		}
		var parent_block = next_closure_block (b.parent_symbol);
		var local_vars = b.get_local_variables ();
		var proto = new CCodeStructPrototype (generate_block_name(b));
		var free_block = new CCodeBlock ();
		var block_struct = proto.definition;
		
		if (parent_block != null) {
			// XXX this piece of code is not tested
			int parent_block_id = get_block_id (parent_block);

			block_struct.add_field (generate_block_name(parent_block) + "*"
				, generate_block_var_name(parent_block));

		} else if ((current_method != null && current_method.binding == MemberBinding.INSTANCE) ||
				   (current_property_accessor != null && current_property_accessor.prop.binding == MemberBinding.INSTANCE)) {
			block_struct.add_field ("%s *".printf (get_ccode_aroop_name (current_class)), self_instance);

			var ma = new MemberAccess.simple (self_instance);
			ma.symbol_reference = current_class;
			free_block.add_statement (
				new CCodeExpressionStatement (get_unref_expression (
				new CCodeMemberAccess.pointer (
				new CCodeIdentifier (
					generate_block_var_name(b)
				), self_instance), new ObjectType (current_class), ma)));
		}
		foreach (var local in local_vars) {
			if (local.captured) {
				generate_type_declaration (local.variable_type, decl_space);

				block_struct.add_field (get_ccode_aroop_name (local.variable_type), get_variable_cname (local.name) + get_ccode_declarator_suffix (local.variable_type), null, generate_declarator_suffix_cexpr(local.variable_type));
			}
		}
		
		// free in reverse order
		for (int i = local_vars.size - 1; i >= 0; i--) {
			var local = local_vars[i];
			if (local.captured) {
				if (requires_destroy (local.variable_type)) {
					var ma = new MemberAccess.simple (local.name);
					ma.symbol_reference = local;
					ma.value_type = local.variable_type.copy ();
					free_block.add_statement (new CCodeExpressionStatement (
						get_unref_expression (new CCodeMemberAccess.pointer (
						new CCodeIdentifier (generate_block_var_name(b)), get_variable_cname (local.name)), local.variable_type, ma)));
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
	
	private void generate_block_parent_assignment(Block b) {
		var parent_block = next_closure_block (b.parent_symbol);

		ccode.add_statement (
			new CCodeExpressionStatement (
				new CCodeAssignment (
					new CCodeMemberAccess (
						get_variable_cexpression (generate_block_var_name(b))
						, generate_block_var_name(parent_block)
					)
					, get_variable_cexpression (generate_block_var_name(parent_block))
				)
			)
		);
	}
	
	public override void visit_block (Block b) {
		emit_context.push_symbol (b);

		var local_vars = b.get_local_variables ();

		if (b.parent_node is Block || b.parent_node is SwitchStatement) {
			ccode.open_block ();
		}

		if (b.captured) {
			int block_id = get_block_id(b);
			var parent_block = next_closure_block (b.parent_symbol);

			generate_block_declaration(b, cfile);
			
			//var alloc_call = new CCodeFunctionCall (new CCodeIdentifier ("aroop_object_alloc"));
			//alloc_call.add_argument (new CCodeIdentifier ("sizeof(struct _%s)".printf (generate_block_name(b))));
			//alloc_call.add_argument (new CCodeIdentifier("%spray".printf (generate_block_name(b))));
			//vblock.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeIdentifier (self_instance), new CCodeCastExpression (alloc_call, "%s *".printf (get_ccode_aroop_name (current_type_symbol))))));
			
			var data_decl = new CCodeDeclaration (generate_block_name(b));
			data_decl.add_declarator (new CCodeVariableDeclarator (generate_block_var_name(b)));
			ccode.add_statement (data_decl);

			if (parent_block != null) {
				generate_block_parent_assignment(b);
			} else if ((current_method != null && current_method.binding == MemberBinding.INSTANCE) ||
			           (current_property_accessor != null && current_property_accessor.prop.binding == MemberBinding.INSTANCE)) {
				var ref_call = new CCodeFunctionCall (get_dup_func_expression (new ObjectType (current_class), b.source_reference));
				ref_call.add_argument (new CCodeIdentifier (self_instance));

				ccode.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeMemberAccess (get_variable_cexpression (generate_block_var_name(b)), self_instance), ref_call)));
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
			stmt.emit (this);
		}

		// free in reverse order
		for (int i = local_vars.size - 1; i >= 0; i--) {
			var local = local_vars[i];
			if (!local.floating && !local.captured && requires_destroy (local.variable_type)) {
				var ma = new MemberAccess.simple (local.name);
				ma.symbol_reference = local;
				ccode.add_statement (
					new CCodeExpressionStatement (
						get_unref_expression (
							get_variable_cexpression (local.name)
							, local.variable_type
							, ma
						)
					)
				);
			}
		}

		if (b.parent_symbol is Method) {
			var m = (Method) b.parent_symbol;
			foreach (Parameter param in m.get_parameters ()) {
				if (!param.captured && requires_destroy (param.variable_type) && param.direction == ParameterDirection.IN) {
					var ma = new MemberAccess.simple (param.name);
					ma.symbol_reference = param;
					ccode.add_statement (new CCodeExpressionStatement (get_unref_expression (get_variable_cexpression (param.name), param.variable_type, ma)));
				}
			}
		}

		if (b.captured) {
			int block_id = get_block_id (b);

			var data_unref = new CCodeFunctionCall (new CCodeIdentifier (generate_block_finalize_function_name(b)));
			data_unref.add_argument (
				new CCodeUnaryExpression (
					CCodeUnaryOperator.ADDRESS_OF, 
					new CCodeIdentifier(generate_block_var_name(b))
				)
			);
			ccode.add_statement (new CCodeExpressionStatement (data_unref));
		}

		if (b.parent_node is Block || b.parent_node is SwitchStatement) {
			ccode.close ();
		}

		emit_context.pop_symbol ();
	}


	void capture_parameter (Parameter param, Block b) {
		var param_type = param.variable_type.copy ();
		// create copy if necessary as captured variables may need to be kept alive
		CCodeExpression cparam = get_variable_cexpression (param.name);
		if (requires_copy (param_type) && !param.variable_type.value_owned)  {
			var ma = new MemberAccess.simple (param.name);
			ma.symbol_reference = param;
			ma.value_type = param.variable_type.copy ();
			// directly access parameters in ref expressions
			param.captured = false;
			cparam = get_ref_cexpression (param.variable_type, cparam, ma, param);
			param.captured = true;
		}

		ccode.add_assignment (
			new CCodeMemberAccess (
				get_variable_cexpression (
					generate_block_var_name(b)
				), get_variable_cname (param.name)), cparam);
	}
	
	public override void initialize_local_variable_in_block(LocalVariable local, CCodeExpression rhs, CCodeFunction decl_space) {
		ccode.add_assignment (
			new CCodeMemberAccess (
				get_variable_cexpression (
				generate_block_var_name((Block) local.parent_symbol))
				, get_variable_cname (local.name)), rhs);
	}

	protected void populate_variables_of_parent_closure(Block b, bool populate_self, CCodeFunction decl_space) {
		// add variables for parent closure blocks
		// as closures only have one parameter for the innermost closure block
		var closure_block = b;
		while (true) {
			var parent_closure_block = next_closure_block (b.parent_symbol);
			if (parent_closure_block == null) {
				break;
			}
			int parent_block_id = get_block_id (parent_closure_block);

			var parent_data = new CCodeMemberAccess.pointer (
				new CCodeIdentifier (
					generate_block_var_name(closure_block)
				), generate_block_var_name (parent_closure_block));
			var cdecl = new CCodeDeclaration (generate_block_name (parent_closure_block));
			cdecl.add_declarator (new CCodeVariableDeclarator (generate_block_var_name (parent_closure_block), parent_data));

			decl_space.add_statement (cdecl);

			closure_block = parent_closure_block;
		}
		
		if(populate_self) {
			var cself = new CCodeMemberAccess.pointer (
				new CCodeIdentifier (generate_block_var_name(closure_block))
				, self_instance);
			var cdecl = new CCodeDeclaration ("%s *".printf (get_ccode_aroop_name (current_class)));
			cdecl.add_declarator (new CCodeVariableDeclarator (self_instance, cself));

			decl_space.add_statement (cdecl);
		}
	}
	
	protected CCodeExpression get_parameter_cvalue_for_block(Parameter p) {
		// captured variables are stored on the heap
		var block = p.parent_symbol as Block;
		if (block == null) {
			block = ((Method) p.parent_symbol).body;
		}
		
		var cblock_val = get_variable_cexpression (generate_block_var_name (block));
		if(block == current_closure_block && current_closure_block.parent_symbol == current_method) {
			return new CCodeMemberAccess (cblock_val, get_variable_cname (p.name));
		} else {
			return new CCodeMemberAccess.pointer (cblock_val, get_variable_cname (p.name));
		}
	}
	
	protected CCodeExpression get_local_cvalue_for_block(LocalVariable local) {
		// captured variables are stored on the heap
		var block = (Block) local.parent_symbol;
		CCodeExpression cblock = get_variable_cexpression (generate_block_var_name (block));
		string local_name = get_variable_cname (local.name);
		if(block == current_closure_block && current_closure_block.parent_symbol == current_method) {
			return new CCodeMemberAccess (cblock, local_name);
		} else {
			return new CCodeMemberAccess.pointer (cblock, local_name);
		}
	}
}
