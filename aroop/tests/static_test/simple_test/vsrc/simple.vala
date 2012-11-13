
using aroop;

class Mango : God {
	public static int get() {
		return 10;
	}
}

class test_array : God {

	public static int main() {
		core.assert(Mango.get() == 10);
		return 0;
	}
}
