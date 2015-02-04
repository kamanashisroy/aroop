
using aroop;

class Mango : Replicable {
	public static Mango singleton;
	int x;
	public Mango(int val) {
		x = val;
	}
	public static int getVal() {
		return singleton.x;
	}
}

class test_array : Replicable {

	public static int main() {
		Mango.singleton = new Mango(20);
		core.assert(Mango.getVal() == 20);
		return 0;
	}
}
