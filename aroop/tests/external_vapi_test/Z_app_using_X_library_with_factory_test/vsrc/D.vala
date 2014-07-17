
using X;
using aroop;


class D : Replicable {

	public static int main() {
		C c = 10;
		A a = new A(c);
		Factory<ASimple> fac = Factory<ASimple>.for_type();
		ASimple smpl = fac.alloc_full();
		smpl.do();
		str s = new str.copy_string("Fine");
		s.pray(prayer.DESCRIBE);
		return 0;
	}
}
