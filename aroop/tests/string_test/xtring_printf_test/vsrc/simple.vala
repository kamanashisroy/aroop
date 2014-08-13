
using aroop;

class MainClass : Replicable {
	public static int main() {
		extring fine = extring.set_string("Fine");
		extring out = extring();
		out.stack(128);
		out.printf_extra("I am %T\n", &fine);
		out.describe();
		return 0;
	}
}
