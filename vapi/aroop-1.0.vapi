/* aroop-1.0.vala
 *
 *
 * Author:
 * 	Kamanashis Roy (kamanashisroy@gmail.com)
 */

[CCode (cprefix = "Aroop", lower_case_cprefix = "aroop_", cheader_filename = "aroop_core.h", gir_namespace = "Aroop", gir_version = "1.0")]
namespace Aroop {
	[CCode (type_id = "aroop_any_type", marshaller_type_name = "OPPANY", get_value_function = "aroop_any_get_value", set_value_function = "aroop_any_set_value")]
}
