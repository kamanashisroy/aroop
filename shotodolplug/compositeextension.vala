/* valaextension.vala
 *
 * Author:
 * 	Kamanashis Roy <kamanashisroy@gmail.com>
 */

using GLib;
using Vala;

/** \addtogroup Plugin
 *  @{
 */
public class shotodolplug.CompositeExtension : Extension {
	HashMap<string, Extension> registry = new HashMap<string, Extension> ();
	public CompositeExtension(Module mod) {
		base(mod);
	}
	public int register(string target, Extension e) {
		assert(e.src != null);
		Extension?root = registry.get(target);
		if(root == null) {
			registry.set(target, e);
			return 0;
		}
		while(root.next != null) {
			Extension next = root.next;
			root = next;
		}
		root.next = e;
		return 0;
	}
	public Extension?get(string target) {
		return registry.get(target);
	}
	public int unregister(string target, Extension e) {
		Extension?root = registry.get(target);
		if(root == null) return 0;
		if(root == e) {
			registry.set(target, root.next);
			return 0;
		}
		while(root.next != null) {
			Extension next = root.next;
			root = next;
			if(root.next == e) {
				root.next = e.next;
				return 0;
			}
		}
		return 0;
	}
	public string?swarm(string target, string inmsg) {
		Extension?root = get(target);
		string?output = null;
		while(root != null) {
			output = root.act(inmsg); // Note we did not concat the output for shake of simplicity
			Extension?next = root.getNext();
			root = next;
		}
		return output;
	}
	public void acceptVisitor(string target, ExtensionVisitor visitor) {
		Extension?root = get(target);
		while(root != null) {
			visitor(root);
			Extension?next = root.getNext();
			root = next;
		}
	}
}
/** @}*/
