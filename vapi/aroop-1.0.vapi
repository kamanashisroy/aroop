/* aroop-1.0.vala
 *
 * Copyright (C) 20012-2014 Kamanashis Roy Shuva <kamanashisroy@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Kamanashis Roy (kamanashisroy@gmail.com)
 */

[CCode (cprefix = "Aroop", lower_case_cprefix = "aroop_", cheader_filename = "aroop_core.h", gir_namespace = "Aroop", gir_version = "1.0")]
namespace Aroop {
	/*[CCode (type_id = "aroop_any_type", marshaller_type_name = "AROOP", get_value_function = "aroop_any_get_value", set_value_function = "aroop_any_set_value")]*/

	[CCode (cname = "aroop_god")]
	public interface God {
		[CCode (cname = "OPPREF")]
		public static void ref();
		[CCode (cname = "OPPUNREF")]
		public static void unref();
	}
}
