
using X;
using aroop;

public class X.YSimple : AAbstract {
}

class D : Replicable {

	public static int nomain() {
		C c = 10;
		A a = new A(c);
		txt str = new txt.from_static("Fine");
		str.pray(prayer.DESCRIBE);
		return 0;
	}
}
