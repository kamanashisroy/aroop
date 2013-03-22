
using aroop;

internal struct struggle {
	int x;
	internal int hardship() {
		return x;
	}
}

public delegate void do_cb(int x);

internal class Life : Replicable {
	internal int val;
	internal Life() {
		val = 10;
	}
	internal void do(do_cb cb) {
		cb(4);
	}
}

class MainClass : Replicable {
	//int myval = 20;
	internal static void evaluate(struggle*s) {
		Life mylife = new Life();
		mylife.do((x) => {
				print("arg = %d,value = %d,myval = %d\n", x, mylife.val, 20/*myval*/);
				return;
			}
		);
	}
	internal static void evaluate2(struggle*s) {
		Life mylife = new Life();
		mylife.do((x) => {
				return;
			}
		);
	}
	public static int main() {
		struggle s = struggle();
		evaluate(&s);
		evaluate2(&s);
		return 0;
	}
}
