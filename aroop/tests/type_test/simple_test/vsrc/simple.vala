
using aroop;

internal class Orchard : Replicable {
	xtring mango;
}

class MainClass : Replicable {
	public static int main() {
		var x = new Orchard();
		core.assert(x is Orchard);
		return 0;
	}
}
