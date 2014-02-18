
using aroop;

delegate int my_cb(int value);

class Simple : Replicable {
	public static int main() {
		my_cb cb = null;
		core.assert(cb == null);
		return 0;
	}
}
