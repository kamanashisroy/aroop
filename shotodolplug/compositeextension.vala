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
		assert(e != null);
		assert(e.src != null);
		if(e == null) {
			print("Extension cannot be null\n");
		}
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
	public Object? swarmObject(string target, Object?inmsg) {
		Extension?root = get(target);
		Object?output = null;
		while(root != null) {
			print("getting extension for %s\n", target);
			output = root.actObject(inmsg); // Note we did not concat the output for shake of simplicity
			if(output != null)
				break;
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
	public override void dump() {
		print("There are %d extensions registered\n", registry.size);
		foreach(var entry in registry.get_keys()) {
			print("\textension registered at %s\n", entry);
			Extension e = registry.get(entry);
			e.dump();
		}
	}
}
/** @}*/
