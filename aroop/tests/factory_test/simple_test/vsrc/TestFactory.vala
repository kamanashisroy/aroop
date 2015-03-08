
using aroop;


class TestOPPFactory : Replicable {
	static OPPFactory<TestOPPFactory> simpleFac;
	static OPPFactory<TestOPPFactory> sizedFac;
	static SearchableOPPFactory<TestOPPFactory> simpleSFac;
	static SearchableOPPFactory<TestOPPFactory> sizedSFac;

	public static int main() {
		simpleFac = OPPFactory<TestOPPFactory>.for_type();
		simpleFac.destroy();
		sizedFac = OPPFactory<TestOPPFactory>.for_type_full(12, (uint)sizeof(TestOPPFactory));
		sizedFac.destroy();
		simpleSFac = SearchableOPPFactory<TestOPPFactory>.for_type();
		simpleSFac.destroy();
		sizedSFac = SearchableOPPFactory<TestOPPFactory>.for_type_full(12, (uint)sizeof(TestOPPFactory));
		sizedSFac.destroy();
		return 0;
	}
}
