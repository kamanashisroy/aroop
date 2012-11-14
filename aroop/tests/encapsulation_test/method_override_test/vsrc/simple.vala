
using aroop;

internal interface Tree {
	public abstract int get_height();
}

internal abstract class Fruit {
	protected int pid;
	public abstract int get();
	public virtual void set() {
		pid = -1;
	}
}

internal class Mango : Fruit,Tree {
	protected int id;
	internal Mango() {
		id = 1;
		pid = 2;
	}
	public override int get() {
		return id+pid;
	}
	public new void set() {
		pid = 12;
	}
	public int get_height() {
		return pid*id;
	}
}

class MainClass : God {

	public static int main() {
		var mango = new Mango();
		Fruit fr = null;
		fr = mango;
		mango.set();
		core.assert(fr.get() == 13);
		fr.set();
		core.assert(fr.get() == 0);
		return 0;
	}
}
