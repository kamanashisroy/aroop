
using aroop;

public class Animal : Replicable {
	etxt vc;
	public Animal() {
		vc = etxt.from_static("Time is tiny, women are many.");
	}
	public virtual etxt*voice() {
		return &vc;
	}
	public virtual void describe() {
		vc.describe();
	}
}
