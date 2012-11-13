
using aroop;

delegate int my_cb(int value);

class Simple : God {

	public static int cb_impl(int value) {
		return 0;
	}


	public static int main() {
		my_cb cb = cb_impl;
		cb(0);
		return 0;
	}
}
