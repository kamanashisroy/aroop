
using aroop;

class Mango : Replicable {
	public static int cvar = 15;
	public static int get() {
		return cvar;
	}
}

class test_array : Replicable {

	public static int main() {
		Mango.cvar = 20;
		core.assert(Mango.get() == 20);
		return 0;
	}
}
