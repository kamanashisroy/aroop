namespace GLib {
[CCode (cname = "aroop_none")]
public class Object {
	[CCode (cname = "OPPREF")]
	public void pin();
	[CCode (cname = "aroop_none_unpin")]
	public void unpin();
}
[CCode (cname = "aroop_none")]
public struct Type { // this should be the vtable or something ..
}
[CCode (cname = "aroop_none")]
public struct Value {
	[CCode (cname = "aroop_donothing")]
	public Type type ();
}
[CCode (cname = "aroop_none")]
public class Variant {
}
[CCode (cname = "opp_factory_t", cheader_filename = "aroop/aroop_factory.h", has_copy_function=true, copy_function="aroop_factory_cpy_or_destroy", has_free_function = true, free_function = "aroop_factory_cpy_or_destroy", has_destroy_function=true, destroy_function="opp_factory_destroy_and_remove_profile")]
public class List {
}
[CCode (cname = "opp_factory_t", cheader_filename = "aroop/aroop_factory.h", has_copy_function=true, copy_function="aroop_memcpy_struct",has_free_function=true, free_function = "aroop_factory_cpy_or_destroy",  has_destroy_function=true, destroy_function="opp_factory_destroy_and_remove_profile")]
public class SList {
}
[CCode (cname = "opp_factory_t", cheader_filename = "aroop/aroop_factory.h", has_copy_function=true, copy_function="aroop_factory_cpy_or_destroy", has_free_function = true, free_function = "aroop_factory_cpy_or_destroy", has_destroy_function=true, destroy_function="opp_factory_destroy_and_remove_profile")]
public class Array {
}
[CCode (cname = "aroop_none")]
public class ValueArray {
}
[Compact]
[ErrorBase]
[CCode (cname = "aroop_wrong", cheader_filename = "aroop/aroop_error.h")]
public class Error {
	[CCode (cname = "aroop_error_to_string")]
	public unowned string to_string();
}
[CCode (cname = "aroop_none")]
public class Regex {
}
[CCode (cname = "aroop_none")]
public class Source {
}
}


