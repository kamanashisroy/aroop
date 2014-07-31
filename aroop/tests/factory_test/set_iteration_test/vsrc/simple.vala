
using aroop;

internal class Counter : Replicable {
  int i;
  internal Counter(int val) {
    i = val;
  }
	internal int do(Replicable data) {
		unowned Mango x = ((AroopPointer<Mango>)data).get();
		print("Here we are %d-%d\n", x.id, i);
		core.assert(i == x.id);
		return -1;
	}
}

internal class Mango : Searchable {
	internal int id;
	internal Mango() {
	}
	internal int build(int val) {
		this.id = val;
		set_hash(val);
		print("New mango %d, hash %d\n", val, (int)get_hash());
		return 0;
	}
}

internal class Orchard : Replicable {
	static SearchableFactory<Mango> mangoes;
	static Set<Mango> tree;
  
  static void buildall() {
		int i = 0;
		for(i=10;i != 0;i--) {
			Mango x = mangoes.alloc_full(4, 0, false, null);
			core.assert(x != null);
			x.build(i);
			tree.add(x);
		}
  }

  static void test1() {
    int i = 5;
    Counter cr = new Counter(i);
		tree.visit_each(cr.do, Replica_flags.ALL, 0, Replica_flags.ALL, 0, 0, 5);
  }

	public static int main() {
		mangoes = SearchableFactory<Mango>.for_type(16, 1, 0);
		tree = Set<Mango>(16);
    buildall();
    test1();
		tree.destroy();
		mangoes.destroy();
		return 0;
	}
}
