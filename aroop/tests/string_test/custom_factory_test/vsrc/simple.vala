
using aroop;

class MainClass : Replicable {
	public static int main() {
		OPPFactory<xtring> fac = OPPFactory<xtring>.for_type();
		extring pineapple = extring.set_static_string("pineapple");
		xtring?x = new xtring.copy_deep(&pineapple, &fac);
		core.assert(x.fly().equals_string("pineapple"));
		x = null;
		fac.destroy();
		return 0;
	}
}
