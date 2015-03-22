/* valaplugin.vala
 *
 * Author:
 * 	Kamanashis Roy <kamanashisroy@gmail.com>
 */

using GLib;

/** \addtogroup Plugin
 *  @{
 */
public abstract class shotodolplug.Module {
	string name;
	string version;
	public Module(string nm,string ver) {
		name = nm;
		version = ver;
	}
	public virtual string getNameAs() {
		return name;
	}
	public virtual string getVersion() {
		return version;
	}
	public abstract int init();
	public abstract int deinit();
}
/** @}*/
