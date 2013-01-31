
using aroop;

internal abstract class orchard.Fruit : Replicable {
}


public class orchard.Mango : Replicable {
	orchard.Fruit?fr;
	orchard.olive*fr2;
	public static int get() {
		return 10;
	}
}

class test_array : Replicable {
	public static int main() {
		core.assert(orchard.Mango.get() == 10);
		return 0;
	}
}
