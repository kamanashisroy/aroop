
using aroop;


class TestSet : Replicable {
	static Set<xtring> chain;
	static SearchableSet<xtring> searchable_chain;

	public static int main() {
		chain = Set<xtring>();
		chain.destroy();
		searchable_chain = SearchableSet<xtring>();
		searchable_chain.destroy();
		return 0;
	}
}
