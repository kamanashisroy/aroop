
using aroop;

internal abstract class Organ {
	public abstract int get();
}

internal abstract class Fruit : Organ {
	int pid;
	internal Fruit(int id) {
		pid = id;
	}
	public override int get() {
		return pid;
	}
}

internal class Mango : Fruit {
	protected int id;
	internal Mango() {
		id = 1;
		base(2);
	}
	public override int get() {
		if(false) {
			get();
		}
		return id+base.get();
	}
}

class MainClass : Replicable {

	public static int main() {
		var mango = new Mango();
		Fruit fr = null;
		fr = mango;
		core.assert(3 == fr.get());
		return 0;
	}
}
