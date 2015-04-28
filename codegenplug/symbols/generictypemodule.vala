using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.GenericTypeModule : shotodolplug.Module {
	SourceEmitterModule?emitter = null;
	CSymbolResolve?resolve = null;
	public GenericTypeModule() {
		base("GenericType", "0.0");
	}

	public override int init() {
		PluginManager.register("add/generic_type_arguments", new HookExtension(add_generic_type_arguments_helper, this));
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

	Value? add_generic_type_arguments_helper (Value?given_args) {
		var args = (HashTable<string,Value?>)given_args;
		add_generic_type_arguments(
			(CCodeFunctionCall?)args["ccall"]
			,(Vala.List<DataType>?)args["type_args"]
			,(CodeNode?)args["expr"]
			,((string?)args["is_chainup"]) == "1"
		);
		return null;
	}

	void add_generic_type_arguments (CCodeFunctionCall ccall,Vala.List<DataType> type_args, CodeNode expr, bool is_chainup = false) {
		foreach (var type_arg in type_args) {
			var targ = resolve.get_type_id_expression (type_arg, is_chainup);
			ccall.add_argument (targ);
		}
	}
}
