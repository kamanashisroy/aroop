
using aroop;

delegate int my_cb(int value);

class Simple : Replicable {
	my_cb? cb;
	public Simple() {
		cb = null;
	}
	void test(my_cb given) {
		cb = given;
		cb(0);
	}
	
	int cb_impl(int value) {
		return 0;
	}

	public static int main() {
		Simple smpl = new Simple();
		int i = 0;
		for(i=0;i<3;i++) {
			smpl.test(smpl.cb_impl);
		}
		return 0;
	}
}
