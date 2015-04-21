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
	public virtual void dump() {
		print("\t[%s]\n", src.name);
	}
	/* Message passing */
	public virtual Value?actValue(Value?x) /*throws M100CommandError.ActionFailed*/ {
		return null;
	}
}
/** @}*/
