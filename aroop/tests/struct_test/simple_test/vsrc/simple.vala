
using aroop;

internal struct Orchard {
	extring mango;
	extring jackfruit;
	internal Orchard() {
		mango = extring.set_static_string("There are four mango trees.");
		jackfruit = extring.set_static_string("There are four jackfruit trees.");
	}
	internal void destroy() {
		mango.destroy();
		jackfruit.destroy();
	}
}

class MainClass : Replicable {

	public static int main() {
		Orchard orchard = Orchard();
		//orchard.describe();
		orchard.destroy();
		return 0;
	}
}
