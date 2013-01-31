
using aroop;

internal class Fruit {
	protected int id;
}

internal class Mango : Fruit {
	internal Mango() {
		id = 1;
	}
}

class MainClass : Replicable {

	public static int main() {
		unowned Mango x;
		Mango y;
		Fruit fr = new Mango();
		x = fr as Mango;
		y = fr as Mango;
		return 0;
	}
}
