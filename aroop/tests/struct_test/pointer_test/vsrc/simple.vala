
using aroop;

internal struct Orchard {
	etxt tree;
	internal Orchard(etxt plant) {
		string bingo = plant.to_string();
		filter(&plant);
	}
	private void filter(etxt*plant) {
		string bingo = plant.to_string();
		tree = etxt(plant.to_string());
	}
}

class MainClass : None {

	public static int main() {
		etxt plant = etxt.from_static("There are four mango trees.");
		Orchard orchard = Orchard(plant);
		return 0;
	}
}
