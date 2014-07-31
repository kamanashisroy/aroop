
using aroop;

class MainClass : Replicable {
	public static int main() {
		HashTable<xtring,xtring> ht;
		ht = HashTable<xtring,xtring>(xtring.hCb, xtring.eCb);
		xtring key = new xtring.copy_static_string("The key");
		xtring val = new xtring.copy_static_string("Test Successful");
		ht.set(key, val);
		unowned xtring? res = ht.get(key);
		core.assert(res != null);
		core.assert(res.fly().equals(val));
		print("%s\n", res.fly().to_string());
		ht.destroy();
		return 0;
	}
}
