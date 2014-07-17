
using aroop;

internal struct Orchard {
	estr tree;
	internal Orchard(estr plant) {
		plant.to_string();
		filter(&plant);
	}
	private void filter(estr*plant) {
		plant.to_string();
		tree = estr.set_string(plant.to_string());
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

class MainClass : Replicable {

	public static int main() {
		estr plant = estr.set_static_string("There are four mango trees.");
		Orchard orchard = Orchard(plant);
		return 0;
	}
}
