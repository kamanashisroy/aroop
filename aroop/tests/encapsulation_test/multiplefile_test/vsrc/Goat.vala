
using aroop;

internal class Goat : Mamal {
	etxt vc;
	public Goat() {
		vc = etxt.from_static("maahamaahamaahalo");
	}
	public override etxt*voice() {
		return &vc;
	}
	public override void describe() {
		vc.describe();
	}
}

