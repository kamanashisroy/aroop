
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
		str msg = new str.copy_static_string("I am fine");
		ContainerThing<str> b = new ContainerThing<str>(msg);  
		return 0;
	}
}
