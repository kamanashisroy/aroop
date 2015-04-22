/* valaplugin.vala
 *
 * Author:
 * 	Kamanashis Roy <kamanashisroy@gmail.com>
 */

using GLib;

/**
 * \defgroup plugin Plugin
 * refer to external coupling
 */

/** \addtogroup Plugin
 *  @{
 */
public delegate void shotodolplug.ExtensionVisitor(Extension e);
public class shotodolplug.PluginManager : Module {
	static CompositeExtension?x;
	public PluginManager() {
		string nm = "PluginManager";
		string ver = "0.0.0";
		base(nm,ver);
		x = null;
	}
	public static int register(string target, Extension e) {
		return x.register(target, e);
	}
	public static int unregister(string target, Extension e) {
		return x.unregister(target, e);
	}
	public static Value? swarmValue(string target, Value?inmsg) {
		return x.swarmValue(target, inmsg);
	}
	public static void acceptVisitor(string target, ExtensionVisitor visitor) {
		x.acceptVisitor(target, visitor);
	}

	public static void dump() {
		x.dump();
	}
	
	public override int init() {
		x = new CompositeExtension(this);
		return 0;
	}
	public override int deinit() {
		x = null;
		return 0;
	}
}
/** @}*/
