
using aroop;

internal class Mango : Replicable {
	public int id {public get{return hidid;}}
	public int hidid;
	public Mango() {
		hidid = 10;
	}
}

class test_array : Replicable {

	public static int main() {
		Mango mg = new Mango();
		core.assert(mg.id == 10);
		return 0;
	}
}
