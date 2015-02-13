
using aroop;

internal class Orchard : Replicable {
	public int add(extring garden) {
		extring mango = extring();
		extring field = extring.copy_shallow(&garden);
		print("field:%s\n", field.to_string());
		field.shift_token(":", &mango); // mango
		print("mango:%s\n", mango.to_string());
		field.shift_token(",", &mango); // 16
		print("mango count:%s\n", mango.to_string());
		core.assert(mango.to_int() == 16);
		core.assert(mango.char_at(0) == '1');
		core.assert(mango.contains_char('6'));
		return 0;
	}
}

class MainClass : Replicable {
	public static int main() {
		Orchard heaven = new Orchard();
		extring nandan = extring.copy_static_string("mango:16,pineapple:18");
		heaven.add(nandan);
		return 0;
	}
}
