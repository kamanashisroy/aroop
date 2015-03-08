
using aroop;


class HashTableExample : Replicable {

	public static int main() {
		// ----------------------------------
		// HashTable creation
		HashTable<xtring,xtring> mymap = HashTable<xtring,xtring>(xtring.hCb, xtring.eCb); // creation
		// ----------------------------------

		xtring key = new xtring.set_static_string("greet");
		xtring x = new xtring.set_static_string("Have a nice day."); // create a xtring
		core.assert(key != null);
		core.assert(x != null);

		// ----------------------------------
		// set
		mymap.set(key, x);
		// ----------------------------------

		// ----------------------------------
		// get
		print("x = %s.\n", mymap.get(key).fly().to_string()); // each time the mymal[key] is called it does a tree search
		// ----------------------------------

		// ----------------------------------
		// It is recomended to get the reference of the value first to avoid searching each time
		xtring x2 = mymap.get(key); // each time the mymal[key] is called it does a tree search
		print("x2 = %s.\n", x2.fly().to_string());
		// ----------------------------------

		// ----------------------------------
		// Internally HashTable is managed by OPPList, so it can be iterated with `foreach` statement
		foreach(AroopPointer<xtring> pt3 in mymap) {
			unowned xtring x3 = pt3.getUnowned();
			print("%s\n", x3.fly().to_string());
		}
		// ----------------------------------

		// ----------------------------------
		// It is also possible to retrieve the key
		foreach(AroopHashTablePointer<xtring,xtring> pt3 in mymap) {
			unowned xtring key4 = pt3.key();
			unowned xtring x4 = pt3.getUnowned();
			print("%s=%s\n", key4.fly().to_string(), x4.fly().to_string());
		}
		// ----------------------------------
		return 0;
	}
}
