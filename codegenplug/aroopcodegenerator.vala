using GLib;
using Vala;
using shotodolplug;
using codegenplug;

public class codegenplug.AroopCodeGeneratorModule : shotodolplug.Module {
	
	public AroopCodeGeneratorModule() {
		base("Codevisitor", "0.0");
	}

	public override int init() {
		return 0;
	}

	public override int deinit() {
		return 0;
	}
}

internal abstract class codegenplug.AroopCodeGenerator : CodeGenerator {
	public override void visit_source_file(SourceFile source_file) {
		string visit_exten= "visit/source_file";
		PluginManager.swarmObject(visit_exten, (Object)source_file);
	}
	public override void visit_namespace(Namespace ns) {
		string visit_exten= "visit/namespace";
		PluginManager.swarmObject(visit_exten, (Object)ns);
	}
}

internal class codegenplug.AroopCodeGeneratorAdapter {
	
	public void generate_element_destruction_code(Field f, CCodeBlock stmt) {
		string visit_exten= "generate/element/destruction";
		Object[] args = {(Object)f,(Object)stmt};
		PluginManager.swarmObject(visit_exten, (Object)args);
	}

	public void generate_element_declaration(Field f, CCodeStruct container, CCodeFile decl_space, bool internalSymbol = true) {
		string visit_exten= "generate/element/declaration";
		Object args[] = {(Object)f,(Object)container,(Object)decl_space,(Object)internalSymbol};
		PluginManager.swarmObject(visit_exten, (Object)args);
	}
	public void generate_struct_declaration (Struct st, CCodeFile decl_space) {
		string visit_exten= "generate/struct/declaration";
		Object args[] = {(Object)st,(Object)decl_space};
		PluginManager.swarmObject(visit_exten, (Object)args);
	}

	public CCodeParameter?generate_instance_cparameter_for_struct(Method m, CCodeParameter?param, DataType this_type) {
		string visit_exten= "generate/instance_cparam/struct";
		Object args[] = {(Object)m,(Object)param,(Object)this_type};
		return (CCodeParameter)PluginManager.swarmObject(visit_exten, (Object)args);
	}

	public CCodeParameter?generate_temp_variable(LocalVariable tmp) {
		string visit_exten= "generate/temp";
		return (CCodeParameter)PluginManager.swarmObject(visit_exten, (Object)tmp);
	}

}
	
