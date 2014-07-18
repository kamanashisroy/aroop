using aroop;
using shotodol;

public abstract class shotodol.Module : Replicable {
	extring name;
	extring version;
	public abstract int init();
	public abstract int deinit();
}

