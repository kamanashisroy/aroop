/* valaaroopmethodmodule.vala
 *
 * Copyright (C) 2007-2009  Jürg Billeter
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Jürg Billeter <j@bitron.ch>
 */

/**
 * The link between a method and generated code.
 */
public abstract class Vala.AroopMethodModule : AroopStructModule {
	public override bool method_has_wrapper (Method method) {
		return (method.get_attribute ("NoWrapper") == null);
	}

	public override string? get_custom_creturn_type (Method m) {
		var attr = m.get_attribute ("CCode");
		if (attr != null) {
			string type = attr.get_string ("type");
			if (type != null) {
				return type;
			}
		}
		return null;
	}
	
	public override void visit_method (Method m) {
		push_context (new EmitContext (m));

		foreach (Parameter param in m.get_parameters ()) {
			param.accept (this);
		}

		foreach (Expression precondition in m.get_preconditions ()) {
			precondition.emit (this);
		}

		foreach (Expression postcondition in m.get_postconditions ()) {
			postcondition.emit (this);
		}

		generate_method_declaration (m, cfile);

		if (!m.is_internal_symbol ()) {
			generate_method_declaration (m, header_file);
		}

		var function = new CCodeFunction (get_ccode_real_name (m));

		generate_cparameters (m, cfile, function);


		// generate *_real_* functions for virtual methods
		if (!m.is_abstract) {
			if (m.base_method != null || m.base_interface_method != null) {
				// declare *_real_* function
				function.modifiers |= CCodeModifiers.STATIC;
				cfile.add_function_declaration (function);
			} else if (m.is_internal_symbol ()) {
				function.modifiers |= CCodeModifiers.STATIC;
			}

			if (m.body != null) {
				push_function (function);

				if(m.overrides || (m.base_interface_method != null && !m.is_abstract && !m.is_virtual)) {
					ccode.add_declaration("%s *".printf (get_ccode_aroop_name(current_class)), new CCodeVariableDeclarator ("this"));
					var lop = new CCodeIdentifier ("this");
					var rop = new CCodeCastExpression (new CCodeIdentifier ("base_instance"), "%s *".printf (get_ccode_aroop_name(current_class)));
					ccode.add_assignment (lop, rop);
				}
		

				if (context.module_init_method == m) {
					add_module_init ();
				}

				if (m.closure) {
					// add variables for parent closure blocks
					// as closures only have one parameter for the innermost closure block
					var closure_block = current_closure_block;
					int block_id = get_block_id (closure_block);
					while (true) {
						var parent_closure_block = next_closure_block (closure_block.parent_symbol);
						if (parent_closure_block == null) {
							break;
						}
						int parent_block_id = get_block_id (parent_closure_block);

						var parent_data = new CCodeMemberAccess.pointer (new CCodeIdentifier ("_data%d_".printf (block_id)), "_data%d_".printf (parent_block_id));
						var cdecl = new CCodeDeclaration ("Block%dData*".printf (parent_block_id));
						cdecl.add_declarator (new CCodeVariableDeclarator ("_data%d_".printf (parent_block_id), parent_data));

						ccode.add_statement (cdecl);

						closure_block = parent_closure_block;
						block_id = parent_block_id;
					}

					// add self variable for closures
					// as closures have block data parameter
					if (m.binding == MemberBinding.INSTANCE) {
						var cself = new CCodeMemberAccess.pointer (new CCodeIdentifier ("_data%d_".printf (block_id)), "this");
						var cdecl = new CCodeDeclaration ("%s *".printf (get_ccode_aroop_name (current_class)));
						cdecl.add_declarator (new CCodeVariableDeclarator ("this", cself));

						ccode.add_statement (cdecl);
					}
				}
				foreach (Parameter param in m.get_parameters ()) {
					if (param.ellipsis) {
						break;
					}

					var t = param.variable_type.data_type;
					if (t != null && t.is_reference_type ()) {
						if (param.direction == ParameterDirection.OUT) {
							// ensure that the passed reference for output parameter is cleared
							var a = new CCodeAssignment (new CCodeUnaryExpression (CCodeUnaryOperator.POINTER_INDIRECTION, get_variable_cexpression (param.name)), new CCodeConstant ("NULL"));
							var cblock = new CCodeBlock ();
							cblock.add_statement (new CCodeExpressionStatement (a));

							var condition = new CCodeBinaryExpression (CCodeBinaryOperator.INEQUALITY, new CCodeIdentifier (param.name), new CCodeConstant ("NULL"));
							var if_statement = new CCodeIfStatement (condition, cblock);
							ccode.add_statement (if_statement);
						}
					}
				}

				m.body.emit (this);

				if (current_method_inner_error) {
					/* always separate error parameter and inner_error local variable
					 * as error may be set to NULL but we're always interested in inner errors
					 */
#if false
					if (m.coroutine) {
						closure_struct.add_field ("aroop_wrong*", "_inner_error_");

						// no initialization necessary, closure struct is zeroed
					} else {
#endif
						ccode.add_declaration ("aroop_wrong*", new CCodeVariableDeclarator.zero ("_inner_error_", new CCodeConstant ("NULL")));
#if false
					}
#endif
				}

				if (!(m.return_type is VoidType) && !(m.return_type is GenericType)) {
					var cdecl = new CCodeDeclaration (get_ccode_aroop_name (m.return_type));
					cdecl.add_declarator (new CCodeVariableDeclarator.zero ("result", default_value_for_type (m.return_type, true)));
					ccode.add_statement (cdecl);

					//ccode.add_statement (new CCodeReturnStatement (new CCodeIdentifier ("result")));
				}


				var st = m.parent_symbol as Struct;
				if (m is CreationMethod && st != null && (st.is_boolean_type () || st.is_integer_type () || st.is_floating_type ())) {
					var cdecl = new CCodeDeclaration (get_ccode_aroop_name (st));
					cdecl.add_declarator (new CCodeVariableDeclarator ("this", new CCodeConstant ("0")));
					ccode.add_statement (cdecl);

					ccode.add_statement (new CCodeReturnStatement (new CCodeIdentifier ("this")));
				}				
				cfile.add_function (function);
			}
		}

		if (m.is_abstract || m.is_virtual) {
			generate_class_declaration ((Class) object_class, cfile);
		}
		pop_context ();

		if (m.entry_point) {
			generate_type_declaration (new StructValueType (array_struct), cfile);

			// m is possible entry point, add appropriate startup code
			var cmain = new CCodeFunction ("main", "int");
			cmain.line = function.line;
			cmain.add_parameter (new CCodeParameter ("argc", "int"));
			cmain.add_parameter (new CCodeParameter ("argv", "char **"));

			push_function (cmain);

			var aroop_init_call = new CCodeFunctionCall (new CCodeIdentifier ("aroop_init"));
			aroop_init_call.add_argument (new CCodeIdentifier ("argc"));
			aroop_init_call.add_argument (new CCodeIdentifier ("argv"));
			ccode.add_statement (new CCodeExpressionStatement (aroop_init_call));

			add_module_init ();

			var cdecl = new CCodeDeclaration ("int");
			cdecl.add_declarator (new CCodeVariableDeclarator ("result", new CCodeConstant ("0")));
			ccode.add_statement (cdecl);

			var main_call = new CCodeFunctionCall (new CCodeIdentifier (function.name));

			if (m.get_parameters ().size == 1) {
				// create Aroop array from C array
				// should be replaced by Aroop list
				var array_creation = new CCodeFunctionCall (new CCodeIdentifier ("aroop_array_create"));
				array_creation.add_argument (new CCodeFunctionCall (new CCodeIdentifier ("string_type_get")));
				array_creation.add_argument (new CCodeIdentifier ("argc"));

				cdecl = new CCodeDeclaration ("AroopArray");
				cdecl.add_declarator (new CCodeVariableDeclarator ("args", array_creation));
				ccode.add_statement (cdecl);

				var array_data = new CCodeMemberAccess (new CCodeIdentifier ("args"), "data");

				cdecl = new CCodeDeclaration ("string_t*");
				cdecl.add_declarator (new CCodeVariableDeclarator ("args_data", array_data));
				ccode.add_statement (cdecl);

				cdecl = new CCodeDeclaration ("int");
				cdecl.add_declarator (new CCodeVariableDeclarator ("argi"));
				ccode.add_statement (cdecl);

				var string_creation = new CCodeFunctionCall (new CCodeIdentifier ("string_create_from_cstring"));
				string_creation.add_argument (new CCodeElementAccess (new CCodeIdentifier ("argv"), new CCodeIdentifier ("argi")));

				var loop_block = new CCodeBlock ();
				loop_block.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeElementAccess (new CCodeIdentifier ("args_data"), new CCodeIdentifier ("argi")), string_creation)));

				var for_stmt = new CCodeForStatement (new CCodeBinaryExpression (CCodeBinaryOperator.LESS_THAN, new CCodeIdentifier ("argi"), new CCodeIdentifier ("argc")), loop_block);
				for_stmt.add_initializer (new CCodeAssignment (new CCodeIdentifier ("argi"), new CCodeConstant ("0")));
				for_stmt.add_iterator (new CCodeUnaryExpression (CCodeUnaryOperator.POSTFIX_INCREMENT, new CCodeIdentifier ("argi")));
				ccode.add_statement (for_stmt);

				main_call.add_argument (new CCodeIdentifier ("args"));
			}

			if (m.return_type is VoidType) {
				// method returns void, always use 0 as exit code
				var main_stmt = new CCodeExpressionStatement (main_call);
				main_stmt.line = cmain.line;
				ccode.add_statement (main_stmt);
			} else {
				var main_stmt = new CCodeExpressionStatement (new CCodeAssignment (new CCodeIdentifier ("result"), main_call));
				main_stmt.line = cmain.line;
				ccode.add_statement (main_stmt);
			}

			
			var ret_stmt = new CCodeReturnStatement (new CCodeIdentifier ("result"));
			ret_stmt.line = cmain.line;
			ccode.add_statement (ret_stmt);

			pop_function ();

			cfile.add_function (cmain);
		}
	}
	
	void add_module_init () {
		foreach (var field in static_fields) {
			field.initializer.emit (this);

			var lhs = new CCodeIdentifier (get_ccode_name (field));
			var rhs = get_cvalue (field.initializer);

			ccode.add_assignment (lhs, rhs);
		}
	}
}

