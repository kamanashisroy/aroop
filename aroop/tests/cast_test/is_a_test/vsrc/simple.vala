
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
		var mg = new Mango();
		if(mg is Fruit) {
			mg = null;
		}
		return 0;
	}
}
