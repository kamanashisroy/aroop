
using aroop;


class TestSet : Replicable {
	static Set<txt> chain;
	static SearchableSet<txt> searchable_chain;

	public static int main() {
		chain = Set<txt>();
		chain.destroy();
		searchable_chain = SearchableSet<txt>();
		searchable_chain.destroy();
		return 0;
	}
}
