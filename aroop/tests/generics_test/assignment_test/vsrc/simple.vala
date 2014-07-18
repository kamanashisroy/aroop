
using aroop;

class SomeThing<G> : Replicable {
	G y;
	public SomeThing(G x) {
		y = x;
	}
}

class ContainerThing<G> : Replicable {
	SomeThing<G> a;
	public ContainerThing(G x) {
		a = new SomeThing<G>(x);
	}
}


class MainClass : Replicable {

	public static int main() {
		xtring msg = new xtring.copy_string("I am fine");
		ContainerThing<xtring> b = new ContainerThing<xtring>(msg);  
		return 0;
	}
}
