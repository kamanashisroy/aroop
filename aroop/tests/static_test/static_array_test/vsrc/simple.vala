
using aroop;


struct Mango {
	int i;
}

class test_array : Replicable {
	static Mango mangoes[10];
	public static int main() {
		mangoes[1].i = 10;
		core.assert(mangoes[1].i == 10);
		return 0;
	}
}
