
using aroop;

class MainClass : Replicable {
	public static int main() {
		HashTable<txt> ht;
		ht = HashTable<txt>();
		txt key = new txt("The key");
		txt val = new txt("Test Successful");
		ht.set(key, val);
		unowned txt? res = ht.get(key);
		core.assert(res != null);
		core.assert(res.equals(val));
		print("%s\n", res.to_string());
		ht.destroy();
		return 0;
	}
}
