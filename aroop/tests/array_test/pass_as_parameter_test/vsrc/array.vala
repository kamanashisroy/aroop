
using aroop;


class test_array : Replicable {

	static int myFunc(int[]tbl) {
		return tbl[1];
	}

	public static int main() {
		int tbl[10] = {0,1,2,3,4,5,6,7,8};
		core.assert(myFunc(tbl) == 1);
		return 0;
	}
}
