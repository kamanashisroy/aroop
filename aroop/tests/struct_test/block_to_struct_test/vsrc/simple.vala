
using aroop;

internal delegate void ODescribe(Orchard*x);
internal struct Orchard {
	internal extring mango;
	internal Orchard() {
		mango = extring.set_static_string("There are four mango trees.");
	}
	internal void do(ODescribe cb) {
		cb(&this);
	}
}

class MainClass : Replicable {

	public static int main() {
		Orchard orchard = Orchard();
		orchard.do((x) => {print("message:%s\n", x.mango.to_string());});
		return 0;
	}
}
