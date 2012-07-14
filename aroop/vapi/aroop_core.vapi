
[CCode (cname = "SYNC_UWORD8_T", default_value = "0U")]
[IntegerType (rank = 3, min = 0, max = 255)]
public struct aroop_uword8 {
}

[CCode (cname = "SYNC_UWORD16_T", default_value = "0U")]
[IntegerType (rank = 5, min = 0, max = 65535)]
public struct aroop_uword16 {
}

[CCode (cname = "SYNC_UWORD32_T", default_value = "0U")]
[IntegerType (rank = 7)]
public struct aroop_uword32 {
}


[CCode (cname = "aroop_txt", cheader_filename = "core/txt.h")]
public class aroop.txt {
	aroop.txt*proto;
	int hash;
	int size;
	int len;
	char*str;
	[CCode (cname = "aroop_txt_new")]
	public txt(char*content, int len = 0, aroop.txt? proto = null, int scalability_index = 0);
	[CCode (cname = "aroop_txt_new_static")]
	public static aroop.txt*create_static(char*content);
	[CCode (cname = "aroop_txt_to_vala")]
	public string to_string();
}


