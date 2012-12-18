
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
	internal void calltest(Orchard*other) {
		tree = other.tree;
	}
	internal void my_copy(Orchard other) {
		tree = other.tree;
		calltest(&other);
	}
	internal void copy_by_reference(Orchard*other) {
		tree = other.tree;
		calltest(other);
	}
	internal void copy_inverse(Orchard*other) {
		// TODO try to do something, so that we can do things like
		//other.copy_by_reference(this);
		other.copy_by_reference(&this);
	}
}

class MainClass : None {

	public static int main() {
		etxt plant = etxt.from_static("There are four mango trees.");
		Orchard orchard = Orchard(plant);
		return 0;
	}
}
