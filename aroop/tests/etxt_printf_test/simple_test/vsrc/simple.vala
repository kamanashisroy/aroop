
using aroop;

class MainClass : Replicable {
	public static int main() {
		estr fine = estr.set_string("Fine");
		estr out = estr();
		out.stack(128);
		out.printf_extra("I am %T\n", &fine);
		out.describe();
		return 0;
	}
}
