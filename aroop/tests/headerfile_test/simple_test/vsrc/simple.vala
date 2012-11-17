
using aroop;

internal abstract class orchard.Fruit : God {
}


public class orchard.Mango : God {
	orchard.Fruit?fr;
	orchard.olive*fr2;
	public static int get() {
		return 10;
	}
}

class test_array : God {
	public static int main() {
		core.assert(orchard.Mango.get() == 10);
		return 0;
	}
}
