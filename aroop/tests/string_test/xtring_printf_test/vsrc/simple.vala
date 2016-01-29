
using aroop;

class MainClass : Replicable {
	public static int main() {
		extring fine = extring.set_string("Fine");
		extring good = extring();
		good = extring.stack(128);
		good.printf_extra("I am %T\n", &fine);
		good.describe();
		return 0;
	}
}
