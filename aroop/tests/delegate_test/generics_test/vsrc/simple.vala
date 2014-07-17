
using aroop;

delegate int my_cb<G>(G value);

class AnyObject<G> : Replicable {
  internal AnyObject() {
  }
	internal int my_cb_impl(G val) {
		//if(val instanceof str) {
			str mytxt = (str)val;
			core.assert(mytxt.ecast().equals_string("fine"));
    	print("Working : %s\n", mytxt.ecast().to_string());
		//}
		return 0;
	}
}

class Simple<G> : Replicable {

  internal void do_it(my_cb<G> cb, G x) {
		cb(x);
  }

	public static int main() {
    Simple<str> obj = new Simple<str>();
		str fine = new str.copy_string("fine");
		obj.do_it((my_cb<G>)(new AnyObject<str>()).my_cb_impl, fine);
		return 0;
	}
}
