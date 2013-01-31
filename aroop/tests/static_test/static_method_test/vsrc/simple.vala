
using aroop;


internal struct Mango {
	int element;
	public static int pulse() {
		return 10;
	}
}

class test_array : Replicable {
	public static int main() {
		core.assert(Mango.pulse() == 10);
		return 0;
	}
}
