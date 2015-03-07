
using aroop;


class OPPListExample : Replicable {

	public static int main() {
		OPPList<xtring> mylist = OPPList<xtring>(12, factory_flags.EXTENDED);
		xtring x = new xtring.set_static_string("Have a nice day."); // create a xtring
		core.assert(x != null);
		//print("Token of x is %d\n", x.get_token());
		AroopPointer<xtring> pt = mylist.add_pointer(x); // It adds xtring containing "Have a nice day" into the list
		core.assert(pt != null);
		print("Token of pt is %d\n", pt.get_token());
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

		//mylist.destroy();
		return 0;
	}
}
