
using aroop;

internal class Counter<G> : Replicable {
  int i;
  internal Counter(int val) {
    i = val;
  }
	internal int match_int_unowned(AroopPointer<G> can) {
		unowned Mango x = (Mango)can.getUnowned();
		print("Comparing %d-%d\n", x.id, i);
		core.assert(i == x.id);
		return 0;
	}
	internal int match_int(AroopPointer<G> can) {
		Mango x = (Mango)can.getUnowned();
		print("Comparing %d-%d\n", x.id, i);
		core.assert(i == x.id);
		return 0;
	}
}

internal class Mango : Replicable {
	internal int id;
	internal Mango() {
	}
	internal int build(int val) {
		this.id = val;
		print("New mango %d\n", val);
		return 0;
	}
}

internal class Orchard : Replicable {
	static OPPFactory<Mango> tree;
	static SearchableOPPList<Mango> buscket;
  
  static void buildall() {
		int i = 0;
		for(i=10;i != 0;i--) {
			Mango x = tree.alloc_full(4, 0, false, null);
			core.assert(x != null);
			x.build(i);
			buscket.add_pointer(x, i);
		}
  }

  static void test1() {
    int i = 5;
    Counter<Mango> cr = new Counter<Mango>(i);
		var y = buscket.search(i, cr.match_int);
    core.assert(y != null);
  }

  static void test2() {
    int i = 5;
    Counter<Mango> cr = new Counter<Mango>(i);
		var y = buscket.search(i, cr.match_int_unowned);
    core.assert(y != null);
  }

	public static int main() {
		tree = OPPFactory<Mango>.for_type(16, 1, 0);
		buscket = SearchableOPPList<Mango>();
    buildall();
    test1();
    test2();
		buscket.destroy();
		tree.destroy();
		return 0;
	}
}
