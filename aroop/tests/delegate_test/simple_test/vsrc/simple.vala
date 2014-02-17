
using aroop;

delegate int my_cb(int value);

class Simple : Replicable {
	public int z;
	public int cb_impl(int value) {
		core.assert(z == 5);
		return 0;
	}


	public static int main() {
		Simple smpl = new Simple();
		smpl.z = 5;
		my_cb cb = smpl.cb_impl;
		cb(0);
		return 0;
	}
}
