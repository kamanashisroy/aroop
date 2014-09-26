
using aroop;

class MainClass : Replicable {
	public static int main() {
		extring x = extring.stack(64);
		x.concat_string("x");
		core.assert(x.char_at(0) == 'x');
		return 0;
	}
}
