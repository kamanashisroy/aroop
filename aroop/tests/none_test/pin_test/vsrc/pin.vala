
using aroop;

internal class Orchard : Replicable {
	xtring mango;
	xtring jackfruit;
	internal Orchard() {
		mango = new xtring.copy_static_string("There are four mango trees.");
		jackfruit = new xtring.copy_static_string("There are four jackfruit trees.");
	}
}

class MainClass : Replicable {

	public static int main() {
		Orchard orchard = new Orchard();
		orchard.pin();
		orchard.unpin();
		return 0;
	}
}
