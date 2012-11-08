
using aroop;

internal class Fruit {
	protected int id;
}

internal class Mango : Fruit {
	internal Mango() {
		id = 1;
	}
}

class MainClass : God {

	public static int main() {
		var mango = new Mango();
		Fruit fr = null;
		fr = mango;
		return 0;
	}
}
