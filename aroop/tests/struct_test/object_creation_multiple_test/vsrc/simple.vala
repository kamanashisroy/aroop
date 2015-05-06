
using aroop;

class MainClass : Replicable {

	public static int main() {
		extring goodluck = extring.set_static_string("goodluck");
		extring fine = extring.set_static_string("fine");
		goodluck.rebuild_and_copy_shallow(&fine);
		fine.destroy();
		return 0;
	}
}
