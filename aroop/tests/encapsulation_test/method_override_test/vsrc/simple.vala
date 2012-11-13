
using aroop;

internal abstract class Fruit {
	protected int pid;
	public abstract int get();
}

internal class Mango : Fruit {
	protected int id;
	internal Mango() {
		id = 1;
		pid = 2;
	}
	public override int get() {
		return id+pid;
	}
}

class MainClass : God {

	public static int main() {
		var mango = new Mango();
		Fruit fr = null;
		fr = mango;
		fr.get();
		return 0;
	}
}
