
using aroop;

enum configuration {
#if EMBEDED
	COLLECTION_SIZE = 20
#else
	COLLECTION_SIZE = 200
#endif
}

class test_array : God {

	public static int main() {
		int list[COLLECTION_SIZE];
		int something_else[COLLECTION_SIZE];
		list[0] = 10;
		return 0;
	}
}
