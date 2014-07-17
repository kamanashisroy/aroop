
using aroop;

public delegate void do_cb();

internal class Life : Replicable {
	internal void do(do_cb cb) {
		cb();
	}
}

class MainClass : Replicable {
	internal void test(str meaning) {
		Life mylife = new Life();
		mylife.do(() => {
				meaning.describe();
			}
		);
		meaning.describe();
	}

	public static int main() {
		str meaning = new str.copy_string("Survive");
		(new MainClass()).test(meaning);
		return 0;
	}
}
