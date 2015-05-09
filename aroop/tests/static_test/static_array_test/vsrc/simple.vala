
using aroop;


struct Mango {
	int i;
}

class test_array : Replicable {
	static Mango mangoes[10];
	public static int main() {
		mangoes[1].i = 12;
		core.assert(mangoes[1].i == 12);
		return 0;
	}
}
