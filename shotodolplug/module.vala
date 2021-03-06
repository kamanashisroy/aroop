/* valaplugin.vala
 *
 * Author:
 * 	Kamanashis Roy <kamanashisroy@gmail.com>
 */

using Vala;

/** \addtogroup Plugin
 *  @{
 */
public abstract class shotodolplug.Module {
	public string name;
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
	public bool debug_is_enabled = false;
	public void print_debug(string content) {
		if(debug_is_enabled)
			print(content);
	}
}
/** @}*/
