
using aroop;

class Mango : None {
	public static int get() {
		return 10;
	}
}

class test_array : None {

	public static int main() {
		core.assert(Mango.get() == 10);
		return 0;
	}
}
