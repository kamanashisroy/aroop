
using aroop;

internal class Counter : Replicable {
  int i;
  internal Counter(int val) {
    i = val;
  }
	internal int match_int_unowned(Replicable data) {
		unowned Mango x = data as Mango;
		print("Comparing %d-%d\n", x.id, i);
		core.assert(i == x.id);
		return 0;
	}
	internal int match_int(Replicable data) {
		Mango x = data as Mango;
		print("Comparing %d-%d\n", x.id, i);
		core.assert(i == x.id);
		return 0;
	}
}

internal class Mango : Searchable {
	internal int id;
	internal Mango() {
	}
	internal int build(int val) {
		//this.memclean(sizeof(Mango));
		this.id = val;
		set_hash(val);
		print("New mango %d, hash %d\n", val, (int)get_hash());
		return 0;
	}
}

internal class Orchard : Replicable {
	static SearchableFactory<Mango> mangoes;
  
  static void buildall() {
		int i = 0;
		for(i=10;i != 0;i--) {
			Mango x = mangoes.alloc_full(4, 0, false, null);
			core.assert(x != null);
      x.pin();
			x.build(i);
		}
  }

  static void test1() {
    int i = 5;
    Counter cr = new Counter(i);
		var y = mangoes.search(i, cr.match_int);
    core.assert(y != null);
  }

  static void test2() {
    int i = 5;
    Counter cr = new Counter(i);
		var y = mangoes.search(i, cr.match_int_unowned);
    core.assert(y != null);
  }

	public static int main() {
		mangoes = SearchableFactory<Mango>.for_type(16, 1, 0);
    buildall();
    test1();
    test2();
		mangoes.destroy();
		return 0;
	}
}
