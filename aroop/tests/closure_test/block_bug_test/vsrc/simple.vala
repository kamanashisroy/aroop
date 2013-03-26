
using aroop;

public delegate void do_cb();

internal class Life : Replicable {
	internal void do(do_cb cb) {
		cb();
	}
}

class MainClass : Replicable {
	internal void test(txt meaning) {
		Life mylife = new Life();
		mylife.do(() => {
				meaning.describe();
			}
		);
		meaning.describe();
	}

	public static int main() {
		txt meaning = new txt.from_static("Survive");
		(new MainClass()).test(meaning);
		return 0;
	}
}
