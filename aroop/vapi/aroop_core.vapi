/*
 * This file part of aroop.
 *
 * Copyright (C) 2012  Kamanashis Roy
 *
 * Aroop is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * MiniIM is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Aroop.  If not, see <http://www.gnu.org/licenses/>.
 *
 *  Created on: Jul 15, 2012
 *  Author: Kamanashis Roy (kamanashisroy@gmail.com)
 */


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

[CCode (cprefix = "OPPN_ACTION_", cname = "int")]
public enum aroop.pray {
	DESCRIBE,
}

[CCode (cname = "aroop_god")]
public interface aroop.God {
#if NOREFFF
	[CCode (cname = "OPPREF")]
	public static void ref();
	[CCode (cname = "OPPUNREF")]
	public static void unref();
#endif
	[CCode (cname = "aroop_god_pray")]
	public void pray(int callback, void*cb_data = null);
	[CCode (cname = "aroop_god_is_same")]
	public bool is_same(aroop.God another);
}

[CCode (cname = "aroop_txt", cheader_filename = "core/txt.h")]
public class aroop.txt : aroop.God {
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
	[CCode (cname = "aroop_txt_length")]
	public int length();
	[CCode (cname = "BLANK_STRING")]
	public static aroop.txt BLANK_STRING;
}


