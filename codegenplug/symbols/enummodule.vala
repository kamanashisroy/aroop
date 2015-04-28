
using Vala;
using shotodolplug;
using codegenplug;


public class codegenplug.EnumModule : shotodolplug.Module {
	SourceEmitterModule?emitter = null;
	CSymbolResolve?resolve = null;
	public EnumModule() {
		base("Enum", "0.0");
	}

	public override int init() {
		PluginManager.register("visit/enum", new HookExtension(visit_enum, this));
		PluginManager.register("generate/enum/declaration", new HookExtension(generate_enum_declaration_helper, this));
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

	Value? generate_enum_declaration_helper (Value?givenArgs) {
		HashTable<string,Value?> args = (HashTable<string,Value?>)givenArgs;
		generate_enum_declaration((Enum?)args["enum"], (CCodeFile?)args["decl_space"]);
		return null;
	}

	public void generate_enum_declaration (Enum en, CCodeFile decl_space) {
		if(!en.is_internal_symbol() && !decl_space.is_header) {
			generate_enum_declaration (en, emitter.header_file);
			return;
		}
		if(en.is_internal_symbol() && decl_space.is_header) {
			return;
		}
		if (emitter.add_symbol_declaration (decl_space, en, resolve.get_ccode_aroop_name (en))) {
			return;
		}

		var cenum = new CCodeEnum (resolve.get_ccode_aroop_name (en));

		foreach (Vala.EnumValue ev in en.get_values ()) {
			if (ev.value == null) {
				cenum.add_value (new CCodeEnumValue (resolve.get_ccode_name (ev)));
			} else {
				ev.value.emit (emitter.visitor);
				cenum.add_value (new CCodeEnumValue (resolve.get_ccode_name (ev), resolve.get_cvalue (ev.value)));
			}
		}

		decl_space.add_type_definition (cenum);
		decl_space.add_type_definition (new CCodeNewline ());
	}


	Value?visit_enum (Value?givenValue) {
		Enum?en = (Enum?)givenValue;
		en.accept_children (emitter.visitor);

		generate_enum_declaration (en, emitter.cfile);

		if (!en.is_internal_symbol ()) {
			generate_enum_declaration (en, emitter.header_file);
		}
		return null;
	}


}
