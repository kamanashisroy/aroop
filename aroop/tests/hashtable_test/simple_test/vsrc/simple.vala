
using aroop;

class MainClass : Replicable {
	public static int main() {
		HashTable<xtring> ht;
		ht = HashTable<xtring>();
		xtring key = new xtring.copy_static_string("The key");
		xtring val = new xtring.copy_static_string("Test Successful");
		ht.set(key, val);
		unowned xtring? res = ht.get(key);
		core.assert(res != null);
		core.assert(res.ecast().equals(val));
		print("%s\n", res.ecast().to_string());
		ht.destroy();
		return 0;
	}
}
