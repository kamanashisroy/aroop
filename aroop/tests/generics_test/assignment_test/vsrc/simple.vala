
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
		str msg = new str.copy_string("I am fine");
		ContainerThing<str> b = new ContainerThing<str>(msg);  
		return 0;
	}
}
