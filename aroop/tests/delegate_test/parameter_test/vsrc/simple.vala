
using aroop;

delegate int my_cb(int value);

class SimpleObject : Replicable {
  internal SimpleObject() {
  }
	internal int my_cb_impl(int val) {
    print("Working : %d\n", val);
		return 0;
	}
}

class Simple : Replicable {

  static void do_it(my_cb cb, int x) {
		cb(0);
  }

	public static int main() {
    int val = 4;
    do_it((i)=>{
      print("Working : %d\n", val);
      return 0;
    }, 0);    
    do_it((new SimpleObject()).my_cb_impl, 0);
		return 0;
	}
}
