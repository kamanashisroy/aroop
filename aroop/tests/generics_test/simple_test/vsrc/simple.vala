
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
		str msg = new str.copy_static_string("I am fine");
		ContainerThing<str> b = new ContainerThing<str>(msg);  
		return 0;
	}
}
