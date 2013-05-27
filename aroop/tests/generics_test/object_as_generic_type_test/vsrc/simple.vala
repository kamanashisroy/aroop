
using aroop;

class BirdCage<G> : Replicable {
	G?bd;
	Sparrow?sp;
	public void put(G x) {
		bd = x;
	}
	public void put_sparrow(Sparrow x) {
		sp = x;
	}
	public G?remove() {
		G?ret = bd;
		bd = null;
		return ret;
	}
	public G?remove_2() {
		G?ret = null;
		generihack<G,Replicable>.swap(ret,bd);
		return ret;
	}
	public Sparrow?remove_sparrow() {
		Sparrow?ret = sp;
		sp = null;
		return ret;
	}
	public Sparrow?remove_sparrow_2() {
		Sparrow?ret = null;
		generihack<Sparrow,Sparrow>.swap(ret,sp);
		return ret;
	}
}

class Sparrow : Replicable {
	public Sparrow() {
	}
	int eat() {
		return 0;
	}
}


class MainClass : Replicable {

	public static int test1() {
		BirdCage<Sparrow> cage = new BirdCage<Sparrow>();
		Sparrow spr = new Sparrow();
		cage.put(spr);
		Sparrow gt = cage.remove();
		core.assert(gt == spr);
		return 0;
	}

	public static int test2() {
		BirdCage<Sparrow> cage = new BirdCage<Sparrow>();
		Sparrow spr = new Sparrow();
		cage.put(spr);
		Sparrow gt = cage.remove_2();
		core.assert(gt == spr);
		return 0;
	}

	public static int test3() {
		BirdCage<Sparrow> cage = new BirdCage<Sparrow>();
		Sparrow spr = new Sparrow();
		cage.put_sparrow(spr);
		Sparrow gt = cage.remove_sparrow();
		core.assert(gt == spr);
		return 0;
	}

	public static int test4() {
		BirdCage<Sparrow> cage = new BirdCage<Sparrow>();
		Sparrow spr = new Sparrow();
		cage.put_sparrow(spr);
		Sparrow gt = cage.remove_sparrow_2();
		core.assert(gt == spr);
		return 0;
	}

	public static int main() {
		test1();
		test2();
		test3();
		test4();
		return 0;
	}
}
