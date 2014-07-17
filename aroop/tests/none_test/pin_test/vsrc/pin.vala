
using aroop;

internal class Orchard : Replicable {
	str mango;
	str jackfruit;
	internal Orchard() {
		mango = new str.copy_static_string("There are four mango trees.");
		jackfruit = new str.copy_static_string("There are four jackfruit trees.");
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
