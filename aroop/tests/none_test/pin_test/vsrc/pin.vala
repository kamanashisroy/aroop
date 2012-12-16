
using aroop;

internal class Orchard : None {
	txt mango;
	txt jackfruit;
	internal Orchard() {
		mango = new txt.from_static("There are four mango trees.");
		jackfruit = new txt.from_static("There are four jackfruit trees.");
	}
}

class MainClass : None {

	public static int main() {
		Orchard orchard = new Orchard();
		orchard.pin();
		orchard.unpin();
		return 0;
	}
}
