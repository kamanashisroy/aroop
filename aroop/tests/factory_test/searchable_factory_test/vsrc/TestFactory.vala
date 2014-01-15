
using aroop;


class TestFactory : Replicable {
	static SearchableFactory<SearchableString> fac;

	public static int main() {
		fac = SearchableFactory<SearchableString>.for_type();
		etxt fine = etxt.from_static("It is working fine");
		SearchableString?elem = fac.alloc_added_size((uint16)(fine.length()+1));
		elem.tdata.factory_build_by_memcopy_from_etxt_unsafe_no_length_check(&fine);
		elem.rehash();
		elem.pin();
		elem = null;
		aroop_hash h = fine.get_hash();
		elem = fac.search(h, (x) => {return ((SearchableString)x).tdata.equals(&fine)?0:1;});
		core.assert(elem != null);
		print("%s\n", elem.tdata.to_string());
		fac.destroy();
		return 0;
	}
}
