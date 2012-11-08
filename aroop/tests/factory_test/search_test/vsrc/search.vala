
using aroop;

internal class Mango : Searchable {
	int id;
	internal Mango() {
	}
	internal int constr(int value) {
		core.memclean_raw(this, sizeof(hashable_ext));
		this.id = value;
		set_hash(value);
		return 0;
	}
	internal static int match_int_unowned(God data, void*compare_data) {
		unowned Mango x = data as Mango;
		int value = *(int*)compare_data;
		if(value == x.id) {
			return 0;
		}
		return -1;
	}
	internal static int match_int(God data, void*compare_data) {
		Mango x = data as Mango;
		int value = *(int*)compare_data;
		if(value == x.id) {
			return 0;
		}
		return -1;
	}
}

internal class Orchard : God {
	static SearchableFactory<Mango> mangoes;

	public static int main() {
		int i = 0;
		mangoes = SearchableFactory<Mango>.for_type(16, 1, factory_flags.HAS_LOCK | factory_flags.SWEEP_ON_UNREF | factory_flags.EXTENDED | factory_flags.SEARCHABLE);
		for(i=10;i != 0;i--) {
			Mango x = mangoes.alloc_full(0, 1);
			x.constr(i);
		}
		i = 5;
		var y = mangoes.search(i, Mango.match_int, &i);
		y = mangoes.search(i, Mango.match_int_unowned, &i);

		mangoes.destroy();
		return 0;
	}
}
