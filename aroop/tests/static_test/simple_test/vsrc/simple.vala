
using aroop;

class Mango : Replicable {
	public static int get() {
		return 10;
	}
}

class test_array : Replicable {

	public static int main() {
		core.assert(Mango.get() == 10);
		return 0;
	}
}
