
using aroop;

delegate int my_cb<G>(G value);

class AnyObject<G> : Replicable {
  internal AnyObject() {
  }
	internal int my_cb_impl(G val) {
		//if(val instanceof txt) {
			txt mytxt = (txt)val;
			core.assert(mytxt.equals_string("fine"));
    	print("Working : %s\n", mytxt.to_string());
		//}
		return 0;
	}
}

class Simple<G> : Replicable {

  internal void do_it(my_cb<G> cb, G x) {
		cb(x);
  }

	public static int main() {
    Simple<txt> obj = new Simple<txt>();
		txt fine = new txt.from_static("fine");
		obj.do_it((my_cb<G>)(new AnyObject<txt>()).my_cb_impl, fine);
		return 0;
	}
}
