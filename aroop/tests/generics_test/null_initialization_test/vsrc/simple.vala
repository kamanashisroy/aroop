
using aroop;

delegate bool MyCallback();
class ContainerThing<G> : Replicable {
	public ContainerThing() {
	}
	void doIt(MyCallback cb) {
		cb();
	}
	public G?getIt() {
		G?x=null;
		doIt(() => {
			if(x == null)
				return false;
			return true;
		});
		return x;
	}
}


class MainClass : Replicable {

	public static int main() {
		ContainerThing<xtring> b = new ContainerThing<xtring>();  
		b.getIt();
		return 0;
	}
}
