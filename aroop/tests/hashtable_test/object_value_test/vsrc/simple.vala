
using aroop;

internal class Container : Replicable {
	internal xtring content;
	public Container(xtring x) {
		content = x;
	}
}

class MainClass : Replicable {
	public static int main() {
		HashTable<xtring,Container> ht = HashTable<xtring,Container>(xtring.hCb, xtring.eCb);
		xtring key = new xtring.copy_static_string("The key");
		xtring content = new xtring.copy_static_string("Test Successful");
		Container val = new Container(content);
		ht.set(key, val);
		unowned Container? res = ht.get(key);
		core.assert(res != null);
		core.assert(res.content.fly().equals(content));
		print("%s\n", res.content.fly().to_string());
		ht.destroy();
		return 0;
	}
}
