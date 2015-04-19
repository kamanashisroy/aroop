/* valaextension.vala
 *
 * Author:
 * 	Kamanashis Roy <kamanashisroy@gmail.com>
 */

using GLib;

/** \addtogroup Plugin
 *  @{
 */
//public delegate int shotodolplug.Hook(extring*msg, extring*output);
public delegate Object? shotodolplug.Hook(Object x);
public class shotodolplug.HookExtension : Extension {
	shotodolplug.Hook hook;
	public HookExtension(shotodolplug.Hook?gHook, Module mod) {
		base(mod);
		hook = gHook;
	}
	public override Object?actObject(Object?x) {
		return hook(x);
	}
#if false
	public override int desc(OutputStream pad) {
		base.desc(pad);
		extring dlg = extring.set_static_string("\tHook,\n");
		pad.write(&dlg);
		return 0;
	}
#endif
}
/** @} */
