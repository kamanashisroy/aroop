
using aroop;

internal abstract class orchard.Fruit : None {
}


public class orchard.Mango : None {
	orchard.Fruit?fr;
	orchard.olive*fr2;
	public static int get() {
		return 10;
	}
}

class test_array : None {
	public static int main() {
		core.assert(orchard.Mango.get() == 10);
		return 0;
	}
}
