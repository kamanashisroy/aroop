
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
		txt msg = new txt.from_static("I am fine");
		ContainerThing<txt> b = new ContainerThing<txt>(msg);  
		return 0;
	}
}
