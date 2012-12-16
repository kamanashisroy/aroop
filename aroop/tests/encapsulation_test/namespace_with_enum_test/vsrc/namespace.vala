
using aroop;

namespace simple {

enum someenum {
	VALUE = 10,
}

struct test_struct {
	someenum value;
}

class test_namespace : None {

	public static int main() {
		someenum i = someenum.VALUE;
		if(i == someenum.VALUE) {
			(new txt.from_static("fine")).pray(prayer.DESCRIBE);
		}
		return 0;
	}
}
}
