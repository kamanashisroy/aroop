
using aroop;

delegate int my_cb(int val);

internal class SimpleDoThings : Replicable {
	public int do(my_cb x) {
		x(15);
		return 0;
	}
}

internal class Simple : Replicable {
	int instance_var;
	public Simple() {
		instance_var = 10;
	}
	public int do() {
		SimpleDoThings y = new SimpleDoThings();
		y.do((val) => {
			print("Value is %d,%d\n", val, instance_var);
			return 0;
		});
		return 0;
	}
	public static int main() {
		Simple x = new Simple();
		x.do();
		return 0;
	}
}
