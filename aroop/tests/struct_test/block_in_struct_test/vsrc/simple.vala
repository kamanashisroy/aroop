
using aroop;

internal delegate void ODescribe(extring*x);
internal struct Orchard {
	internal extring mango;
	internal Orchard() {
		mango = extring.set_static_string("There are four mango trees.");
	}
	internal void doHelper(ODescribe cb) {
		cb(&mango);
	}
	internal void do() {
		extring fruit = extring();
		doHelper((x) => {
			fruit.rebuild_and_copy_shallow(x);
		});
		print("message:%s\n", fruit.to_string());
	}
}

class MainClass : Replicable {

	public static int main() {
		Orchard orchard = Orchard();
		orchard.do();
		return 0;
	}
}
