
using aroop;


class MainClass : Replicable {
	protected xtring mango;
	extring emango;
	OPPFactory<xtring> fac;
	MainClass() {
		mango = new xtring.copy_static_string("mango");
		emango = extring.copy_deep(mango);
		fac = OPPFactory<xtring>.for_type();
		mango = new xtring.copy_static_string("mango", &fac);
	}
	~MainClass() {
		int i = 0;
		i++;
		mango = null;
		emango.destroy();
		print("%d\n", i);
	}
	static int testCode() {
		MainClass x = new MainClass();
		print("%s\n", x.mango.fly().to_string());
		return 0;
	}
	public static int main() {
		testCode();
		return 0;
	}
}
