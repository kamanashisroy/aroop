
using aroop;

class MainClass : Replicable {
	public static int main() {
		HashTable<str> ht;
		ht = HashTable<str>();
		str key = new str.copy_static_string("The key");
		str val = new str.copy_static_string("Test Successful");
		ht.set(key, val);
		unowned str? res = ht.get(key);
		core.assert(res != null);
		core.assert(res.ecast().equals(val));
		print("%s\n", res.ecast().to_string());
		ht.destroy();
		return 0;
	}
}
