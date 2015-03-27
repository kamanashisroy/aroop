using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.AroopCodeGeneratorModule : shotodolplug.Module {
	
	public AroopCodeGeneratorModule() {
		base("Codevisitor", "0.0");
	}

	public override int init() {
	}

	public override int deinit() {
	}
}

internal abstract class codegenplug.AroopCodeGenerator : CodeGenerator {
	public override void visit_source_file(SourceFile source_file) {
		string visit_exten= "visit/source_file";
		PluginManager.swarm(visit_exten, source_file);
	}
	public override void visit_namespace(Namespace ns) {
		string visit_exten= "visit/namespace";
		PluginManager.swarm(visit_exten, ns);
	}
}

internal class codegenplug.AroopCodeGeneratorAdapter {
	
	public void generate_element_destruction_code(Field f, CCodeBlock stmt) {
		string visit_exten= "visit/typical";
		var cb =  PluginManager.getInterface(visit_exten, target);
		cb(f, stmt);
	}

	public void generate_element_declaration(Field f, CCodeStruct container, CCodeFile decl_space, bool internalSymbol = true) {
		// TODO fill me
	}
	public void generate_struct_declaration (Struct st, CCodeFile decl_space) {
		// TODO fill me
	}

	public CCodeParameter?generate_instance_cparameter_for_struct(Method m, CCodeParameter?param, DataType this_type) {
		// TODO fill me
	}
}
	
