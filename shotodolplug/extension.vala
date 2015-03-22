/* valaextension.vala
 *
 * Author:
 * 	Kamanashis Roy <kamanashisroy@gmail.com>
 */

using GLib;

/** \addtogroup Plugin
 *  @{
 */
public class shotodolplug.Extension {
	internal Extension?next;
	internal unowned Module?src;
	public Extension(Module mod) {
		next = null;
		src = mod;
	}
	internal Extension?getNext() {
		return next;
	}
	public virtual Object?getInterface(string service) {
		return null;
	}
#if false
	public virtual int desc(OutputStream pad) {
		extring dlg = extring.stack(128);
		extring name = extring();
		src.getNameAs(&name);
		dlg.concat_char('\t');
		dlg.concat_char('[');
		dlg.concat(&name);
		dlg.concat_char(']');
		dlg.concat_char('\t');
		dlg.concat_char('\t');
		pad.write(&dlg);
		return 0;
	}
#endif
	/* Message passing */
	public virtual string?act(string*args) /*throws M100CommandError.ActionFailed*/ {
		return null;
	}
}
/** @}*/
