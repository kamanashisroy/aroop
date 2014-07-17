
using aroop;


class TestSet : Replicable {
	static Set<str> chain;
	static SearchableSet<str> searchable_chain;

	public static int main() {
		chain = Set<str>();
		chain.destroy();
		searchable_chain = SearchableSet<str>();
		searchable_chain.destroy();
		return 0;
	}
}
