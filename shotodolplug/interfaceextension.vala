/* valaextension.vala
 *
 * Author:
 * 	Kamanashis Roy <kamanashisroy@gmail.com>
 */

using GLib;

/** \addtogroup Plugin
 *  @{
 */
public class shotodolplug.InterfaceExtension : Extension {
	Object?iface;
	public InterfaceExtension(Object?gInterface, Module mod) {
		base(mod);
		iface = gInterface;
	}
	public override Object?getInterface(string service) {
		return iface;
	}
#if false
	public override int desc(OutputStream pad) {
		base.desc(pad);
		extring dlg = extring.set_static_string("\tInterface,\n");
		pad.write(&dlg);
		return 0;
	}
#endif
}
/** @} */
