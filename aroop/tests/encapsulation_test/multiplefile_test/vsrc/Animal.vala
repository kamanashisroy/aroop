
using aroop;

public class Animal : Replicable {
	estr vc;
	public Animal() {
		vc = estr.set_string("Time is tiny, women are many.");
	}
	public virtual estr*voice() {
		return &vc;
	}
	public virtual void describe() {
		vc.describe();
	}
}
