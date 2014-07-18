
using aroop;

class MainClass : Replicable {
	public static int main() {
		extring nandan = extring.set_static_string("mango:16,pineapple:18");
		nandan.concat_string("fine");
		nandan.rebuild_and_set_static_string("pineapple");
		core.assert(nandan.equals_string("pineapple"));
		return 0;
	}
}
