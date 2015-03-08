
using aroop;


class OPPFactoryExample : Replicable {

	public static int main() {
		var pool = OPPFactory<xtring>.for_type_full(32, (uint)sizeof(xtring)+64);
		//xtring x = pool.alloc_full();
		//x.fly().concat_string("Have a nice time with pool"); // crashes , I do not know why !

		xtring x2 = new xtring.set_static_string("set", &pool);
		xtring x3 = new xtring.copy_static_string("copied", &pool);
		
		foreach(xtring x4 in pool) {
			print("%s\n", x4.fly().to_string());
		}

		return 0;
	}
}
