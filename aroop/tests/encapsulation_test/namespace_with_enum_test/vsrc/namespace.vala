
using aroop;

namespace simple {

enum someenum {
	VALUE = 10,
}

struct test_struct {
	someenum value;
}

class test_namespace : Replicable {

	public static int main() {
		someenum i = someenum.VALUE;
		if(i == someenum.VALUE) {
			(new xtring.copy_string("fine")).pray(prayer.DESCRIBE);
		}
		return 0;
	}
}
}
