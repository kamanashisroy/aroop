
using aroop;

public errordomain SomeErrorType {
	SOME_ERROR,
}

internal abstract class Orchard : Replicable {
	internal virtual void test_throw_error() throws SomeErrorType {
		throw new SomeErrorType.SOME_ERROR("Bad way");
	}
}
internal class BotanicalGarden : Orchard {
	internal override void test_throw_error() throws SomeErrorType {
		throw new SomeErrorType.SOME_ERROR("Bad day");
	}
}

class MainClass : Replicable {

	public static int main() {
		try {
			BotanicalGarden y = new BotanicalGarden();
			y.test_throw_error();
		} catch (SomeErrorType e) {
			print("error:%s\n", ((AroopWrong*)e).to_string());
		} finally {
		}
		return 0;
	}
}
