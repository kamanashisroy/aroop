
using aroop;

internal class Goat : Mamal {
	extring vc;
	public Goat() {
		vc = extring.set_string("maahamaahamaahalo");
	}
	public override extring*voice() {
		return &vc;
	}
	public override void describe() {
		vc.describe();
	}
}

