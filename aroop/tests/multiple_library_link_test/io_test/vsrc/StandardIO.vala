using aroop;
using shotodol;

public class shotodol.StandardIO : Module {

	public int say_static(string x) {
		extring saying = extring.set_string(x);
		saying.describe();
		return 0;
	}

	public override int init() {
		// TODO fill me
		return 0;
	}

	public override int deinit() {
		// TODO fill me
		return 0;
	}
  public static int main() {
    return 0;
  }
}
