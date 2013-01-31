
using aroop;

internal struct Orchard {
	internal Orchard() {
	}
	internal void call_by_value(Orchard other) {
	}
	internal void call_by_refernce(Orchard*other) {
	}
	internal void invert_call_by_value(Orchard other) {
		other.call_by_value(this);
	}
	internal void invert_call_by_refernce(Orchard*other) {
		other.call_by_refernce(this);
	}
}

class MainClass : Replicable {

	public static int main() {
		Orchard baikuntha = Orchard();
		Orchard heaven = Orchard();
		Orchard behesht = Orchard();
		heaven.call_by_value(baikuntha);
		baikuntha.call_by_refernce(behesht);
		return 0;
	}
}
