
using aroop;

internal class Orchard : Replicable {
	public int add(extring garden) {
		extring mango = extring();
		extring field = extring.copy_deep(&garden);
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
	public int addHeapAlloc(extring*garden) {
		extring mango = extring();
		extring field = extring();
		field.rebuild_in_heap(garden.length()+1);
		field.concat(garden);
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
	public int addPointer(extring*garden) {
		extring mango = extring();
		xtring field = new xtring.copy_deep(garden);
		print("field:%s\n", field.fly().to_string());
		field.fly().shift_token(":", &mango); // mango
		print("mango:%s\n", mango.to_string());
		field.fly().shift_token(",", &mango); // 16
		print("mango count:%s\n", mango.to_string());
		core.assert(mango.to_int() == 16);
		core.assert(mango.char_at(0) == '1');
		core.assert(mango.contains_char('6'));
		return 0;
	}
	public int addCopyOnDemand(extring*garden) {
		extring mango = extring();
		xtring field = new xtring.copy_on_demand(garden);
		print("field:%s\n", field.fly().to_string());
		field.fly().shift_token(":", &mango); // mango
		print("mango:%s\n", mango.to_string());
		field.fly().shift_token(",", &mango); // 16
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
		xtring nandan2 = new xtring.copy_deep(&nandan);
		core.assert(nandan.equals(nandan2));
		
		heaven.add(nandan);
		heaven.addHeapAlloc(&nandan);
		heaven.addPointer(&nandan);
		heaven.addCopyOnDemand(&nandan);
		return 0;
	}
}
