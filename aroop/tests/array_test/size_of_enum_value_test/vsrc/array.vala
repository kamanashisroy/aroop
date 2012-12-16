
using aroop;


class test_array : None {
	enum configuration {
#if EMBEDED
		COLLECTION_SIZE = 20
#else
		COLLECTION_SIZE = 200
#endif
	}
	const int CONST_COLLECTION_SIZE = 30;
	public static int main() {
		int list[CONST_COLLECTION_SIZE];
		int something_else[(configuration.COLLECTION_SIZE)];
		list[0] = 10;
		something_else[0] = 20;
		(new txt.from_static("Fine")).pray(prayer.DESCRIBE);
		return 0;
	}
}
