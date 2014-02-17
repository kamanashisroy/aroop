
using aroop;

delegate int my_cb(int value);

internal class TwiceDeep : Replicable {
	my_cb? deep;
	public TwiceDeep() {
		deep = null;
	}
	public void setCB(my_cb given) {
		deep = given;
	}
	public void go() {
		deep(1);
	}
}

internal class SimpleDelegate : Replicable {
	etxt val;
	int k;
	public SimpleDelegate() {
		k = 99;
		val = etxt.from_static("Successful\n");
	}
		
	public int cb_impl(int value) {
		print("%s\n", val.to_string());
		core.assert(k == 99);
		return 0;
	}


	public static int main() {
		SimpleDelegate smpl = new SimpleDelegate();
		TwiceDeep td = new TwiceDeep();
		td.setCB(smpl.cb_impl);
		td.go();
		return 0;
	}
}
