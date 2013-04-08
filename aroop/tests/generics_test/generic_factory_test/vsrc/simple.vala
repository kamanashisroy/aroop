
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
		txt msg = new txt.from_static("I am fine");
		ContainerThing<txt> b = new ContainerThing<txt>(msg);  
		return 0;
	}
}
