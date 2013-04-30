
using aroop;


class test_array : Replicable {
	
	public static int go(string[] say, int count) {
		print("%s", say[0]);
		return 0;
	}

	public static int main() {
		string sayings[] = {"Good\r\n", "Bad\r\n"};
		go(sayings, 2);
		return 0;
	}
}
