using X;

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
