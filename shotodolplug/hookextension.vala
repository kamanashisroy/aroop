/* valaextension.vala
 *
 * Author:
 * 	Kamanashis Roy <kamanashisroy@gmail.com>
 */

using GLib;

/** \addtogroup Plugin
 *  @{
 */
public delegate Object? shotodolplug.Hook(Object?x);
public class shotodolplug.HookExtension : Extension {
	shotodolplug.Hook hook;
	public HookExtension(shotodolplug.Hook?gHook, Module mod) {
		base(mod);
		hook = gHook;
	}
	public override Object?actObject(Object?x) {
		return hook(x);
	}
	public override void dump() {
		base.dump();
		print("\tHook,%s\n", (hook == null)?"is null":"available");
	}
}
/** @} */
