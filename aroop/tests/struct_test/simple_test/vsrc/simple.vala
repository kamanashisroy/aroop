
using aroop;

internal struct Orchard {
	etxt mango;
	etxt jackfruit;
	internal Orchard() {
		mango = etxt.from_static("There are four mango trees.");
		jackfruit = etxt.from_static("There are four jackfruit trees.");
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
