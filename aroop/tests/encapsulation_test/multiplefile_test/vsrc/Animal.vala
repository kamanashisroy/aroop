
using aroop;

public class Animal : Replicable {
	extring vc;
	public Animal() {
		vc = extring.set_string("Time is tiny, women are many.");
	}
	public virtual extring*voice() {
		return &vc;
	}
	public virtual void describe() {
		vc.describe();
	}
}
