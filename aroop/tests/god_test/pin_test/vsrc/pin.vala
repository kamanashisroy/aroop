
using aroop;

internal class Orchard : God {
	etxt mango;
	etxt jackfruit;
	internal Orchard() {
		mango = etxt.from_static("There are four mango trees.");
		jackfruit = etxt.from_static("There are four jackfruit trees.");
	}
}

class MainClass : God {

	public static int main() {
		Orchard orchard = new Orchard();
		orchard.pin();
		orchard.unpin();
		return 0;
	}
}
