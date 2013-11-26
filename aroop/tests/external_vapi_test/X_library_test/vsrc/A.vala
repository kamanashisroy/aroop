using X;
using aroop;

public struct X.B {
	public C c;
	private static B single;
	public static B*get() {
		return &single;
	}
}

public class X.A {
	B*b;
	public A(C arg) {
		b = B.get();
		b.c = arg;
	}
	public static int test(B unused) {
		return 0;
	}
}

public abstract class X.AAbstract : Replicable {
	int i;
	public AAbstract() {
	}
}
public class X.ASimple : Replicable {
	int i;
	public ASimple() {
	}
	public int do() {
		return 0;
	}
}
