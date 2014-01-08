
using aroop;

delegate int my_cb(int value);

class Simple : Replicable {

	public int cb_impl(int val) {
		core.assert(val == 0);
		print("Test is successful\n");
		return 0;
	}

	public int recurse(int val, my_cb cb) {
		if(val != 0) {
			recurse(val-1, cb);
		} else {
			cb(val);
		}
		return 0;
	}

	public static int main() {
		Simple x = new Simple();
		x.recurse(10, x.cb_impl);
		return 0;
	}
}
