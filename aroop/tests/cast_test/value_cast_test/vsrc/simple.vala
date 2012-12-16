
using aroop;

class MainClass : None {

	public static int main() {
		int x = 10;
		void*data = &x;
		int y = *((int*)data);
		return 0;
	}
}
