
using aroop;

class MainClass : Replicable {
	public static int main() {
    etxt fine = etxt.from_static("Fine");
    etxt out = etxt.EMPTY();
    out.stack(128);
    out.printf_extra("I am %T\n", &fine);
    out.describe();
		return 0;
	}
}
