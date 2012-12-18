
using aroop;

internal struct Orchard {
	etxt tree;
	internal Orchard(etxt plant) {
		plant.to_string();
		filter(&plant);
	}
	private void filter(etxt*plant) {
		plant.to_string();
		tree = etxt(plant.to_string());
	}
	internal void my_copy(Orchard other) {
		tree = other.tree;
	}
	internal void copy_by_value(Orchard*other) {
		tree = other.tree;
	}
	internal void copy_inverse(Orchard*other) {
		other.copy_by_value(&this);
	}
}

class MainClass : None {

	public static int main() {
		etxt plant = etxt.from_static("There are four mango trees.");
		Orchard orchard = Orchard(plant);
		return 0;
	}
}
