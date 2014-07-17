using aroop;
using shotodol;

public abstract class shotodol.Module : Replicable {
	estr name;
	estr version;
	public abstract int init();
	public abstract int deinit();
}

