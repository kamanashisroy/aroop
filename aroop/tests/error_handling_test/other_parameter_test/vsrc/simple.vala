
using aroop;

public errordomain SomeErrorType {
	SOME_ERROR,
}

internal class Orchard : Replicable {
	internal Orchard(int val) throws SomeErrorType {
		core.assert(val == 4);
	}
	internal void test_throw_error(int val) throws SomeErrorType {
		core.assert(val == 4);
	}
}

class MainClass : Replicable {

	public static int main() {
		try {
			Orchard x = new Orchard(4);
			x.test_throw_error(4);
		} catch (SomeErrorType e) {
		} finally {
		}
		return 0;
	}
}
