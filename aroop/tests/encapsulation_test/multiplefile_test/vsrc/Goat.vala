
using aroop;

internal class Goat : Mamal {
	estr vc;
	public Goat() {
		vc = estr.set_string("maahamaahamaahalo");
	}
	public override estr*voice() {
		return &vc;
	}
	public override void describe() {
		vc.describe();
	}
}

