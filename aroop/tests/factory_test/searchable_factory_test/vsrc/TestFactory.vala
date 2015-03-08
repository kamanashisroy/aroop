
using aroop;


class TestOPPFactory : Replicable {
	static SearchableOPPFactory<SearchableString> fac;

	public static int main() {
		fac = SearchableOPPFactory<SearchableString>.for_type();
		extring fine = extring.set_string("It is working fine");
		SearchableString?elem = fac.alloc_added_size((uint16)(fine.length()+1));
		elem.tdata.factory_build_and_copy_on_tail_no_length_check(&fine);
		elem.rehash();
		elem.pin();
		elem = null;
		aroop_hash h = fine.getStringHash();
		elem = fac.search(h, (x) => {return ((SearchableString)x).tdata.equals(&fine)?0:1;});
		core.assert(elem != null);
		print("%s\n", elem.tdata.to_string());
		fac.destroy();
		return 0;
	}
}
