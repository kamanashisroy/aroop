
using aroop;


class SearchableOPPListExample : Replicable {

	public static int main() {
		SearchableOPPList<xtring> mylist = SearchableOPPList<xtring>();
		xtring x = new xtring.set_static_string("Have a nice day."); // create a xtring
		core.assert(x != null);
		AroopPointer<xtring> pt = mylist.add_pointer(x, x.fly().getStringHash()); // It adds xtring containing "Have a nice day" into the list
		core.assert(pt != null);
		print("Token of pt is %d\n", pt.get_token());
#if false // these are the same as OPPList
		int token = pt.get_token(); // get the token of the pointer

		AroopPointer<xtring> pt2 = mylist.get_by_token(token); // retrieve the AroopPointer from the list
		core.assert(pt2 != null);
		unowned xtring x2 = pt2.getUnowned();
		core.assert(x2 != null);

		print("x and x2 are %s.\n", x2 == x ? "equal" : "not equal");

		foreach(AroopPointer<xtring> pt3 in mylist) {
			unowned xtring x3 = pt3.getUnowned();
			print("%s\n", x3.fly().to_string());
		}
#endif

		// searching
		AroopPointer<xtring> pt4 = mylist.search(x.fly().getStringHash(), null);
		core.assert(pt4 != null);
		xtring x4 = pt4.getUnowned();
		core.assert(x4 != null);
		print("Found: %s\n", x4.fly().to_string());

#if false
		// pruning
		print("object count %d\n", mylist.count_unsafe());
		mylist.prune(x, x.fly().getStringHash());
		print("object count %d\n", mylist.count_unsafe());
		core.assert(mylist.count_unsafe() == 0);
#endif
		return 0;
	}
}
