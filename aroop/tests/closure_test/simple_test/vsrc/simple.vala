
using aroop;

public delegate void do_cb();

internal class Life : Replicable {
	internal void do(do_cb cb) {
		cb();
	}
}

class MainClass : Replicable {
	public static int main() {
		str meaning = new str.copy_string("Survive");
		Life mylife = new Life();
		meaning.describe();
		mylife.do(() => {
				meaning.describe();
			}
		);
		return 0;
	}
}
