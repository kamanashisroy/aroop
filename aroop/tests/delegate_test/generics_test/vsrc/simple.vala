
using aroop;

delegate int my_cb<G>(G value);

class AnyObject<G> : Replicable {
  internal AnyObject() {
  }
	internal int my_cb_impl(G val) {
		//if(val instanceof xtring) {
			xtring mytxt = (xtring)val;
			core.assert(mytxt.fly().equals_string("fine"));
    	print("Working : %s\n", mytxt.fly().to_string());
		//}
		return 0;
	}
}

class Simple<G> : Replicable {

  internal void do_it(my_cb<G> cb, G x) {
		cb(x);
  }

	public static int main() {
    Simple<xtring> obj = new Simple<xtring>();
		xtring fine = new xtring.copy_string("fine");
		obj.do_it((my_cb<G>)(new AnyObject<xtring>()).my_cb_impl, fine);
		return 0;
	}
}
