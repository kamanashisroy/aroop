
using aroop;


class TestFactory : Replicable {
	static Factory<TestFactory> simpleFac;
	static Factory<TestFactory> sizedFac;
	static SearchableFactory<TestFactory> simpleSFac;
	static SearchableFactory<TestFactory> sizedSFac;

	public static int main() {
		simpleFac = Factory<TestFactory>.for_type();
		simpleFac.destroy();
		sizedFac = Factory<TestFactory>.for_type_full(12, (uint)sizeof(TestFactory));
		sizedFac.destroy();
		simpleSFac = SearchableFactory<TestFactory>.for_type();
		simpleSFac.destroy();
		sizedSFac = SearchableFactory<TestFactory>.for_type_full(12, (uint)sizeof(TestFactory));
		sizedSFac.destroy();
		return 0;
	}
}
