using aroop;
using shotodol;

public abstract class shotodol.Module : Replicable {
	etxt name;
	etxt version;
	public abstract int init();
	public abstract int deinit();
}

