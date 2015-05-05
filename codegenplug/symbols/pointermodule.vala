using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.PointerModule : shotodolplug.Module {
	SourceEmitterModule emitter;
	CSymbolResolve resolve;
	public PointerModule() {
		base("Pointer", "0.0");
	}

	public override int init() {
		PluginManager.register("visit/addressof_expression", new HookExtension(visit_addressof_expression, this));
		PluginManager.register("visit/pointer_indirection", new HookExtension(visit_pointer_indirection, this));
		PluginManager.register("visit/reference_transfer_expression", new HookExtension(visit_reference_transfer_expression, this));
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

	Value?visit_addressof_expression (Value?given) {
		AddressofExpression?expr = (AddressofExpression?)given;
		resolve.set_cvalue (expr, new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, resolve.get_cvalue (expr.inner)));
		return null;
	}

	Value?visit_pointer_indirection (Value?given) {
		PointerIndirection?expr = (PointerIndirection?)given;
		resolve.set_cvalue (expr, new CCodeUnaryExpression (CCodeUnaryOperator.POINTER_INDIRECTION, resolve.get_cvalue (expr.inner)));
		return null;
	}

	Value?visit_reference_transfer_expression (Value?given) {
		ReferenceTransferExpression?expr = (ReferenceTransferExpression?)given;
		/* (tmp = var, var = null, tmp) */
		var ccomma = new CCodeCommaExpression ();
		var temp_decl = emitter.get_temp_variable (expr.value_type, true, expr);
		AroopCodeGeneratorAdapter.generate_temp_variable (temp_decl);
		var cvar = resolve.get_variable_cexpression (temp_decl.name);

		ccomma.append_expression (new CCodeAssignment (cvar, resolve.get_cvalue (expr.inner)));
		ccomma.append_expression (new CCodeAssignment (resolve.get_cvalue (expr.inner), new CCodeConstant ("NULL")));
		ccomma.append_expression (cvar);
		resolve.set_cvalue (expr, ccomma);
		return null;
	}
}

