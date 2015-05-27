
using aroop;

internal class orchard.Seed : Replicable {
	int x;
	internal Seed() {
	}
	public void doNothing() {
	}
}


public class orchard.Fruit : Replicable {
	Seed x;
	public int doNothing() {
		return 10;
	}
}

class SimpleTest : Replicable {
	public static int main() {
		(new orchard.Fruit()).doNothing();
		return 0;
	}
}
