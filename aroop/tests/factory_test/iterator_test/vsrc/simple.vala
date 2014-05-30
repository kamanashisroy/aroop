using aroop;

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
		Iterator<Mango> it = Iterator<Mango>(&mangoes, Replica_flags.ALL, 0, i);
		core.assert(it.next());
		Mango x = it.get();
		print("Here we are %d-%d\n", x.id, i);
		core.assert(i == x.id);
  }

	public static int main() {
		mangoes = SearchableFactory<Mango>.for_type(16, 1, 0);
    buildall();
    test1();
		mangoes.destroy();
		return 0;
	}
}
