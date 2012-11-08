
using aroop;

class MainClass : God {

	public static int main() {
		int x = 10;
		void*data = &x;
		int y = *((int*)data);
		return 0;
	}
}
