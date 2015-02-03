namespace GLib {
[CCode (cname = "aroop_none")]
public interface Object {
	[CCode (cname = "OPPREF")]
	public void pin();
	[CCode (cname = "aroop_none_unpin")]
	public void unpin();
}
[CCode (cname = "aroop_none")]
public interface Type { // this should be the vtable or something ..
}
[CCode (cname = "aroop_none")]
public interface Value {
}
[CCode (cname = "aroop_none")]
public interface Variant {
}
[CCode (cname = "opp_factory_t", cheader_filename = "aroop/aroop_factory.h", has_copy_function=true, copy_function="aroop_factory_cpy_or_destroy", has_free_function = true, free_function = "aroop_factory_cpy_or_destroy", has_destroy_function=true, destroy_function="opp_factory_destroy_and_remove_profile")]
public struct List {
}
[CCode (cname = "opp_factory_t", cheader_filename = "aroop/aroop_factory.h", has_copy_function=true, copy_function="aroop_memcpy_struct",has_free_function=true, free_function = "aroop_factory_cpy_or_destroy",  has_destroy_function=true, destroy_function="opp_factory_destroy_and_remove_profile")]
public struct SList {
}
[CCode (cname = "opp_factory_t", cheader_filename = "aroop/aroop_factory.h", has_copy_function=true, copy_function="aroop_factory_cpy_or_destroy", has_free_function = true, free_function = "aroop_factory_cpy_or_destroy", has_destroy_function=true, destroy_function="opp_factory_destroy_and_remove_profile")]
public struct Array {
}
[CCode (cname = "aroop_none")]
public struct ValueArray {
}
[CCode (cname = "aroop_none")]
public struct Error {
}
[CCode (cname = "aroop_none")]
public struct Regex {
}
[CCode (cname = "aroop_none")]
public struct Source {
}
}


