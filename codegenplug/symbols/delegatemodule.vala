
using Vala;
using shotodolplug;
using codegenplug;


/**
 * The link between a method and generated code.
 */
public class codegenplug.DelegateModule : shotodolplug.Module {
	SourceEmitterModule?emitter = null;
	CSymbolResolve?resolve = null;
	public DelegateModule() {
		base("Block", "0.0");
	}

	public override int init() {
		PluginManager.register("generate/delegate/declaration", new HookExtension(generate_delegate_declaration_helper, this));
		PluginManager.register("generate/delegate/closure/argument", new HookExtension(generate_delegate_closure_argument_helper, this));
		PluginManager.register("visit/delegate", new HookExtension(visit_delegate, this));
		PluginManager.register("visit/binary_expression/delegate", new HookExtension(visit_binary_expression_for_delegate, this));
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

	Value? generate_delegate_declaration_helper (Value? given_args) {
		var args = (HashTable<string,Value?>)given_args;
		generate_delegate_declaration(
			(Delegate?)args["delegate"]
			,(CCodeFile?)args["decl_space"]
		);
		return null;
	}

	void generate_delegate_declaration (Delegate d, CCodeFile decl_space) {
		if (emitter.add_symbol_declaration (decl_space, d, resolve.get_ccode_aroop_name (d))) {
			return;
		}
		var proto = new CCodeStructPrototype (resolve.get_ccode_aroop_name (d));
		if(d.is_internal_symbol() && decl_space.is_header) {
			// declare prototype	
			decl_space.add_type_definition (proto);
			proto.generate_type_declaration(decl_space);
			return;
		}
		var return_type = "int ";
		if (d.return_type is GenericType) {
			return_type = "void *";
		} else {
			return_type = resolve.get_ccode_name (d.return_type);
		}
		var cb_type = new CCodeTypeDefinition (
		    return_type
		    , generate_invoke_function (d, decl_space));
		decl_space.add_type_definition (cb_type);
		var instance_struct = proto.definition;
		instance_struct.add_field ("void*", "aroop_closure_data", null);
		instance_struct.add_field (resolve.get_ccode_aroop_name (d)+"_aroop_delegate_cb", "aroop_cb", null);
		proto.generate_type_declaration(decl_space);
		decl_space.add_type_definition (instance_struct);
	}

	CCodeFunctionDeclarator generate_invoke_function (Delegate d, CCodeFile decl_space) {
		var function = new CCodeFunctionDeclarator (resolve.get_ccode_aroop_name (d)+"_aroop_delegate_cb");
		
		function.add_parameter (new CCodeParameter ("_closure_data", "void*"));
		
		foreach (Vala.Parameter param in d.get_parameters ()) {
			AroopCodeGeneratorAdapter.generate_type_declaration (param.variable_type, decl_space);

			function.add_parameter (new CCodeParameter (param.name, resolve.get_ccode_name (param.variable_type)));
		}
		return function;
	}

	Value? generate_delegate_closure_argument_helper(Value?given) {
		return generate_delegate_closure_argument((Expression?)given);
	}

	CCodeExpression? generate_delegate_closure_argument(Expression arg) {
		CCodeExpression?dleg_expr = null;
		do {
			var cast_expr = arg as CastExpression;
			if(cast_expr != null) {
				return generate_delegate_closure_argument(cast_expr.inner);
			}
			var ma22 = arg as MemberAccess;
			if(ma22 != null) {
				Method? m22 = null;
				m22 = ((MethodType) arg.value_type).method_symbol;
				if (m22 != null && m22.binding == MemberBinding.INSTANCE) {
					var instance22 = resolve.get_cvalue (ma22.inner);
					var st22 = m22.parent_symbol as Struct;
					if (st22 != null && !st22.is_simple_type ()) {
						instance22 = AroopCodeGeneratorAdapter.generate_instance_cargument_for_struct(ma22, m22, instance22);
					}
					dleg_expr = instance22;
				}
			} else if(emitter.current_closure_block != null) {
				Block b = emitter.current_closure_block;
				dleg_expr = new CCodeUnaryExpression (
					CCodeUnaryOperator.ADDRESS_OF, 
					new CCodeIdentifier(AroopCodeGeneratorAdapter.generate_block_var_name(b))
				);
			} else if(emitter.current_method != null && emitter.current_method.binding == MemberBinding.INSTANCE) {
				dleg_expr = new CCodeIdentifier(resolve.self_instance); // will it cause security exception ?
			} else {
				dleg_expr = new CCodeIdentifier("NULL");
			}
			if(dleg_expr == null) {
				Vala.Parameter? pm = (Vala.Parameter)arg;
				if(pm != null)
					dleg_expr = new CCodeIdentifier(pm.to_string() + "_closure_data");
				else
					dleg_expr = new CCodeIdentifier("NULL");
			}
		} while(false);
		return dleg_expr;
	}

	Value? visit_delegate (Value? given_args) {
		Delegate?d = (Delegate?)given_args;
		d.accept_children (emitter.visitor);

		generate_delegate_declaration (d, emitter.cfile);

		if (!d.is_internal_symbol ()) {
			generate_delegate_declaration (d, emitter.header_file);
		}
		return null;
	}
	
#if false
	public override void store_delegate (Variable variable, TargetValue?pinstance, Expression exp, bool initializer) {
		var deleg_arg = generate_delegate_closure_argument(exp);
		var closure_exp = new CCodeFunctionCall(new CCodeIdentifier("aroop_assign_closure_as_it_is_of_delegate"));
		if(variable is LocalVariable) {
			closure_exp.add_argument(resolve.get_cvalue_(get_local_cvalue ((LocalVariable)variable)));
		} else if(variable is Field) {
			closure_exp.add_argument(resolve.get_cvalue_(get_field_cvalue ((Field)variable,pinstance)));
		} else {
			assert("I do not know this!" == null);
		}
#if false
		if(value.value_type is MethodType) {
			closure_exp.add_argument(new CCodeConstant("NULL"));
		} else {
			closure_exp.add_argument(resolve.get_cvalue_ (value));
		}
#endif
		closure_exp.add_argument(deleg_arg);
		ccode.add_expression(closure_exp);
		base.store_delegate(variable, pinstance, exp, initializer);
	}
#endif


	CCodeFunctionCall? generate_delegate_method_call_ccode (MethodCall expr) {
		var ccall = new CCodeFunctionCall (new CCodeMemberAccess(resolve.get_cvalue(expr.call),"aroop_cb"));
		ccall.add_argument (new CCodeMemberAccess(resolve.get_cvalue(expr.call),"aroop_closure_data"));
		return ccall;
	}

	CCodeExpression get_delegate_cb(Expression expr) {
		if(expr.value_type is DelegateType) {
			return new CCodeMemberAccess(resolve.get_cvalue(expr), "aroop_cb");
		}
		return resolve.get_cvalue(expr);
	}

	CCodeExpression get_delegate_cb_closure(Expression expr) {
		if(expr.value_type is DelegateType) {
			return new CCodeMemberAccess(resolve.get_cvalue(expr), "aroop_closure_data");
		}
		return generate_delegate_closure_argument(expr);
	}

	Value?visit_binary_expression_for_delegate (Value?given_args) {
		BinaryExpression?expr = (BinaryExpression?)given_args;
		var cbleft = get_delegate_cb(expr.left);
		var cbright = get_delegate_cb(expr.right);
		var cbbinary = new CCodeBinaryExpression(expr.operator == BinaryOperator.EQUALITY?CCodeBinaryOperator.EQUALITY:CCodeBinaryOperator.INEQUALITY, cbright, cbleft);
		if(expr.left.value_type is NullType || expr.right.value_type is NullType) {
			resolve.set_cvalue(expr, cbbinary);
			return null;
		}
		var closure_left = get_delegate_cb_closure(expr.left);
		var closure_right = get_delegate_cb_closure(expr.right);
		var closure_binary = new CCodeBinaryExpression(expr.operator == BinaryOperator.EQUALITY?CCodeBinaryOperator.EQUALITY:CCodeBinaryOperator.INEQUALITY, closure_right, closure_left);
		resolve.set_cvalue(expr, new CCodeBinaryExpression(CCodeBinaryOperator.AND, cbbinary, closure_binary));
		return null;
	}

#if false
	public override CCodeExpression? generate_delegate_init_expr() {
		var clist = new CCodeInitializerList ();
		clist.append (new CCodeConstant ("0"));
		clist.append (new CCodeConstant ("0"));
		return clist;
	}
#endif
}
