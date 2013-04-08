
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
		txt msg = new txt.from_static("I am fine");
		ContainerThing<txt> b = new ContainerThing<txt>(msg);  
		return 0;
	}
}
