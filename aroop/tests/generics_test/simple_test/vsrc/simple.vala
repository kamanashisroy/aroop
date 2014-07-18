
using aroop;

class SomeThing<G> : Replicable {
	public SomeThing(G x) {
	}
}

class ContainerThing<G> : Replicable {
	public ContainerThing(G x) {
		SomeThing<G> a = new SomeThing<G>(x);
	}
}


class MainClass : Replicable {

	public static int main() {
		xtring msg = new xtring.copy_static_string("I am fine");
		ContainerThing<xtring> b = new ContainerThing<xtring>(msg);  
		return 0;
	}
}
