using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.SourceFileModule : shotodolplug.Module {
	SourceEmitterModule?emitter = null;
	CodeContext?context;
	string? csource_filename;
	public SourceFileModule() {
		base("SourceFile", "0.0");
		csource_filename = null;
	}

	public override int init() {
		PluginManager.register("visit/source_file", new HookExtension(visit_source_file, this));
		PluginManager.register("set/context", new HookExtension(set_context, this));
		PluginManager.register("rehash", new HookExtension(rehashHook, this));
		return 0;
	}

	public override int deinit() {
		return 0;
	}

	Value? set_context(Value?param) {
		context = (CodeContext?)param;
		return null;
	}

	Value?rehashHook(Value?arg) {
		emitter = (SourceEmitterModule?)PluginManager.swarmValue("source/emitter", null);
		return null;
	}

	public Value? visit_source_file (Value? inmsg) {
		var args = (HashTable<string,Value?>)inmsg;
		SourceFile source_file = (SourceFile)args["source_file"];
		if (csource_filename == null) {
			csource_filename = source_file.get_csource_filename ();
			PluginManager.swarmValue("set/csource_filename", csource_filename);
		} else {
			var writer = new CCodeWriter (source_file.get_csource_filename ());
			if (!writer.open (context.version_header)) {
				Report.error (null, "unable to open `%s' for writing".printf (writer.filename));
				return null;
			}
			writer.close ();
		}

		source_file.accept_children (emitter.visitor);

		if (context.report.get_errors () > 0) {
			return null;
		}
		return null;
	}
}

