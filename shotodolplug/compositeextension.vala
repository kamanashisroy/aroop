/* valaextension.vala
 *
 * Author:
 * 	Kamanashis Roy <kamanashisroy@gmail.com>
 */

using Vala;

/** \addtogroup Plugin
 *  @{
 */
public class shotodolplug.CompositeExtension : Extension {
	HashTable<string, Extension> registry;
	public CompositeExtension(Module mod) {
		base(mod);
		registry = new HashTable<string, Extension>(str_hash, str_equal);
	}
	public int register(string target, Extension e) {
		assert(e != null);
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
	public Extension?getExtension(string target) {
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
	public Value? swarmValue(string target, Value?inmsg) {
		//print("CompositeExtension:getting extension for [%s]\n", target);
		Extension?root = getExtension(target);
		if(root == null)
			print("CompositeExtension:no extension found for [%s]\n", target);
		Value?output = null;
		while(root != null) {
			//print("CompositeExtension:acting [%s]\n", target);
			output = root.actValue(inmsg); // Note we did not concat the output for shake of simplicity
			if(output != null)
				break;
			Extension?next = root.getNext();
			root = next;
		}
		return output;
	}
	public void acceptVisitor(string target, ExtensionVisitor visitor) {
		Extension?root = getExtension(target);
		while(root != null) {
			visitor(root);
			Extension?next = root.getNext();
			root = next;
		}
	}
	public override void dump() {
		print("There are %d extensions registered\n", (int)registry.length);
		foreach(var entry in registry.get_keys()) {
			Extension e = registry.get(entry);
			print("\t[%s] extension is %s\n", entry, (e == null)?"NULL":"available");
			e.dump();
		}
		foreach(var entry in registry.get_values()) {
			entry.dump();
		}
	}
}
/** @}*/
