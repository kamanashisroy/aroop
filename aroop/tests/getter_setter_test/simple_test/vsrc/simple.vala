
using aroop;

internal class Mango : Replicable {
	public int id {public get;public set;}
	public static int pid {public get;public set;}
	public Mango() {
		id = 10;
		pid = 10;
	}
}

class test_array : Replicable {

	public static int main() {
		Mango mg = new Mango();
		core.assert(mg.id == 10);
		core.assert(Mango.pid == 10);
		return 0;
	}
}
