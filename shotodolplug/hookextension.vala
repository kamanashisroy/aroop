/* valaextension.vala
 *
 * Author:
 * 	Kamanashis Roy <kamanashisroy@gmail.com>
 */

using Vala;

/** \addtogroup Plugin
 *  @{
 */

public delegate Value? shotodolplug.Hook(Value?x);
public class shotodolplug.HookExtension : Extension {
	shotodolplug.Hook hook;
	public HookExtension(shotodolplug.Hook?gHook, Module mod) {
		base(mod);
		hook = gHook;
	}
	public override Value?actValue(Value?x) {
		//print("HookExtension:acting\n");
		assert(hook != null);
		return hook(x);
	}
	public override void dump() {
		base.dump();
		print("\tHook,%s\n", (hook == null)?"is null":"available");
	}
}
/** @} */
