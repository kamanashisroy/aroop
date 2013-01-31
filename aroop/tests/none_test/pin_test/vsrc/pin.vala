
using aroop;

internal class Orchard : Replicable {
	txt mango;
	txt jackfruit;
	internal Orchard() {
		mango = new txt.from_static("There are four mango trees.");
		jackfruit = new txt.from_static("There are four jackfruit trees.");
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
