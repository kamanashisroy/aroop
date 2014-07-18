
using aroop;

public errordomain SomeErrorType {
	SOME_ERROR,
}

internal class Orchard : Replicable {
	xtring mango;
	internal Orchard() throws SomeErrorType {
		mango = new xtring.copy_string("There are four mango trees.");
		throw new SomeErrorType.SOME_ERROR("Bad day");
	}
	internal void describe() {
		mango.describe();
	}
	internal void test_throw_error() throws SomeErrorType {
		throw new SomeErrorType.SOME_ERROR("Bad day");
	}
	~Orchard() {
		mango = null;
	}
}

class MainClass : Replicable {

	public static int main() {
		try {
			Orchard x = new Orchard();
			x.describe();
			x.test_throw_error();
		} catch (SomeErrorType e) {
		} finally {
		}
		return 0;
	}
}
