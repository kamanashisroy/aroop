[SimpleType]
[CCode (cname = "unichar", cheader_filename = "aroop_core.h")]
[IntegerType (rank = 7)]
public struct aroop.unichar {
	public bool validate ();
	public bool isalnum ();
	public bool isalpha ();
	public bool iscntrl ();
	public bool isdigit ();
	public bool isgraph ();
	public bool islower ();
	public bool ismark ();
	public bool isprint ();
	public bool ispunct ();
	public bool isspace ();
	public bool isupper ();
	public bool isxdigit ();
	public bool istitle ();
	public bool isdefined ();
	public bool iswide ();
	public bool iswide_cjk ();
	public bool iszerowidth ();
	public unichar toupper ();
	public unichar tolower ();
	public unichar totitle ();
	public int digit_value ();
	public int xdigit_value ();
}
