
using aroop;

class SomeThing<G> : Replicable {
	public SomeThing(G x) {
	}
}

class ContainerThing<G> : Replicable {
	Factory<SomeThing<G>> sandbox;
	public ContainerThing(G x) {
		sandbox = Factory<SomeThing<G>>.for_type();
		SomeThing<G> a = sandbox.alloc_full();
	}
}


class MainClass : Replicable {

	public static int main() {
		xtring msg = new xtring.copy_static_string("I am fine");
		ContainerThing<xtring> b = new ContainerThing<xtring>(msg);  
		return 0;
	}
}
