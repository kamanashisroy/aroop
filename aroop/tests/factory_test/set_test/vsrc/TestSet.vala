
using aroop;


class TestOPPList : Replicable {
	static OPPList<xtring> chain;
	static SearchableOPPList<xtring> searchable_chain;

	public static int main() {
		chain = OPPList<xtring>();
		chain.destroy();
		searchable_chain = SearchableOPPList<xtring>();
		searchable_chain.destroy();
		return 0;
	}
}
