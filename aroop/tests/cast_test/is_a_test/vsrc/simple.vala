
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
		var mango = new Mango();
		if(mango is Fruit) {
			mango = null;
		}
		return 0;
	}
}
