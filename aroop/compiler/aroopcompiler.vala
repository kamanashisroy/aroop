/* valacompiler.vala
 *
 * Copyright (C) 2006-2010  Jürg Billeter
 * Copyright (C) 1996-2002, 2004, 2005, 2006 Free Software Foundation, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Jürg Billeter <j@bitron.ch>
 */

using GLib;
using Vala;

class aroop.Compiler {
	static string basedir;
	static string directory;
	static bool version;
	static bool show_vapi_install_prefix;
	static bool show_c_includedir;
	static bool show_c_libdir;
	[CCode (array_length = false, array_null_terminated = true)]
	static string[] sources;
	[CCode (array_length = false, array_null_terminated = true)]
	static string[] vapi_directories;
	[CCode (array_length = false, array_null_terminated = true)]
	static string[] gir_directories;
	[CCode (array_length = false, array_null_terminated = true)]
	static string[] metadata_directories;
	static string vapi_filename;
	static string library;
	static string gir;
	[CCode (array_length = false, array_null_terminated = true)]
	static string[] packages;
	[CCode (array_length = false, array_null_terminated = true)]
	static string[] fast_vapis;
	static string target_glib;

	static bool ccode_only;
	static string header_filename;
	static bool use_header;
	static string internal_header_filename;
	static string internal_vapi_filename;
	static string fast_vapi_filename;
	static string symbols_filename;
	static string includedir;
	static bool compile_only;
	static bool static_link;
	static string output;
	static bool debug;
	static bool thread;
	static bool mem_profiler;
	static bool disable_assert;
	static bool enable_checking;
	static bool deprecated;
	static bool experimental;
	static bool experimental_non_null;
	static bool disable_warnings;
	static string cc_command;
	[CCode (array_length = false, array_null_terminated = true)]
	static string[] cc_options;
	static string dump_tree;
	static bool save_temps;
	[CCode (array_length = false, array_null_terminated = true)]
	static string[] defines;
	static bool quiet_mode;
	static bool verbose_mode;
	static string profile;
	static bool nostdpkg;
	static bool enable_version_header;
	static bool disable_version_header;
	static bool fatal_warnings;
	static string dependencies;

	static string entry_point;

	static bool run_output;

	private CodeCompilerContext context;

	const OptionEntry[] options = {
		{ "vapidir", 0, 0, OptionArg.FILENAME_ARRAY, ref vapi_directories, "Look for package bindings in DIRECTORY", "DIRECTORY..." },
		{ "girdir", 0, 0, OptionArg.FILENAME_ARRAY, ref gir_directories, "Look for .gir files in DIRECTORY", "DIRECTORY..." },
		{ "metadatadir", 0, 0, OptionArg.FILENAME_ARRAY, ref metadata_directories, "Look for GIR .metadata files in DIRECTORY", "DIRECTORY..." },
		{ "pkg", 0, 0, OptionArg.STRING_ARRAY, ref packages, "Include binding for PACKAGE", "PACKAGE..." },
		{ "vapi", 0, 0, OptionArg.FILENAME, ref vapi_filename, "Output VAPI file name", "FILE" },
		{ "library", 0, 0, OptionArg.STRING, ref library, "Library name", "NAME" },
		{ "gir", 0, 0, OptionArg.STRING, ref gir, "GObject-Introspection repository file name", "NAME-VERSION.gir" },
		{ "basedir", 'b', 0, OptionArg.FILENAME, ref basedir, "Base source directory", "DIRECTORY" },
		{ "directory", 'd', 0, OptionArg.FILENAME, ref directory, "Output directory", "DIRECTORY" },
		{ "version", 0, 0, OptionArg.NONE, ref version, "Display version number", null },
		{ "show-vapidir", 0, 0, OptionArg.NONE, ref show_vapi_install_prefix, "Display the default install prefix for vapi", null },
		{ "show-c-includedir", 0, 0, OptionArg.NONE, ref show_c_includedir, "Display the includedir for C headers", null },
		{ "show-c-libdir", 0, 0, OptionArg.NONE, ref show_c_libdir, "Display the libdir for C linker", null },
		{ "ccode", 'C', 0, OptionArg.NONE, ref ccode_only, "Output C code", null },
		{ "header", 'H', 0, OptionArg.FILENAME, ref header_filename, "Output C header file", "FILE" },
		{ "static-link", 0, 0, OptionArg.NONE, ref static_link, "Tell the linker to link statically", null },
		{ "use-header", 0, 0, OptionArg.NONE, ref use_header, "Use C header file", null },
		{ "includedir", 0, 0, OptionArg.FILENAME, ref includedir, "Directory used to include the C header file", "DIRECTORY" },
		{ "internal-header", 'h', 0, OptionArg.FILENAME, ref internal_header_filename, "Output internal C header file", "FILE" },
		{ "internal-vapi", 0, 0, OptionArg.FILENAME, ref internal_vapi_filename, "Output vapi with internal api", "FILE" },
		{ "fast-vapi", 0, 0, OptionArg.STRING, ref fast_vapi_filename, "Output vapi without performing symbol resolution", null },
		{ "use-fast-vapi", 0, 0, OptionArg.STRING_ARRAY, ref fast_vapis, "Use --fast-vapi output during this compile", null },
		{ "deps", 0, 0, OptionArg.STRING, ref dependencies, "Write make-style dependency information to this file", null },
		{ "symbols", 0, 0, OptionArg.FILENAME, ref symbols_filename, "Output symbols file", "FILE" },
		{ "compile", 'c', 0, OptionArg.NONE, ref compile_only, "Compile but do not link", null },
		{ "output", 'o', 0, OptionArg.FILENAME, ref output, "Place output in file FILE", "FILE" },
		{ "debug", 'g', 0, OptionArg.NONE, ref debug, "Produce debug information", null },
		{ "thread", 0, 0, OptionArg.NONE, ref thread, "Enable multithreading support", null },
		{ "enable-mem-profiler", 0, 0, OptionArg.NONE, ref mem_profiler, "Enable GLib memory profiler", null },
		{ "define", 'D', 0, OptionArg.STRING_ARRAY, ref defines, "Define SYMBOL", "SYMBOL..." },
		{ "main", 0, 0, OptionArg.STRING, ref entry_point, "Use SYMBOL as entry point", "SYMBOL..." },
		{ "nostdpkg", 0, 0, OptionArg.NONE, ref nostdpkg, "Do not include standard packages", null },
		{ "disable-assert", 0, 0, OptionArg.NONE, ref disable_assert, "Disable assertions", null },
		{ "enable-checking", 0, 0, OptionArg.NONE, ref enable_checking, "Enable additional run-time checks", null },
		{ "enable-deprecated", 0, 0, OptionArg.NONE, ref deprecated, "Enable deprecated features", null },
		{ "enable-experimental", 0, 0, OptionArg.NONE, ref experimental, "Enable experimental features", null },
		{ "disable-warnings", 0, 0, OptionArg.NONE, ref disable_warnings, "Disable warnings", null },
		{ "fatal-warnings", 0, 0, OptionArg.NONE, ref fatal_warnings, "Treat warnings as fatal", null },
		{ "enable-experimental-non-null", 0, 0, OptionArg.NONE, ref experimental_non_null, "Enable experimental enhancements for non-null types", null },
		{ "cc", 0, 0, OptionArg.STRING, ref cc_command, "Use COMMAND as C compiler command", "COMMAND" },
		{ "Xcc", 'X', 0, OptionArg.STRING_ARRAY, ref cc_options, "Pass OPTION to the C compiler", "OPTION..." },
		{ "dump-tree", 0, 0, OptionArg.FILENAME, ref dump_tree, "Write code tree to FILE", "FILE" },
		{ "save-temps", 0, 0, OptionArg.NONE, ref save_temps, "Keep temporary files", null },
		{ "profile", 0, 0, OptionArg.STRING, ref profile, "Use the given profile instead of the default", "PROFILE" },
		{ "quiet", 'q', 0, OptionArg.NONE, ref quiet_mode, "Do not print messages to the console", null },
		{ "verbose", 'v', 0, OptionArg.NONE, ref verbose_mode, "Print additional messages to the console", null },
		{ "target-glib", 0, 0, OptionArg.STRING, ref target_glib, "Target version of glib for code generation", "MAJOR.MINOR" },
		{ "enable-version-header", 0, 0, OptionArg.NONE, ref enable_version_header, "Write vala build version in generated files", null },
		{ "disable-version-header", 0, 0, OptionArg.NONE, ref disable_version_header, "Do not write vala build version in generated files", null },
		{ "", 0, 0, OptionArg.FILENAME_ARRAY, ref sources, null, "FILE..." },
		{ null }
	};
	
	private int quit () {
		if (context.ccode.report.get_errors () == 0 && context.ccode.report.get_warnings () == 0) {
			return 0;
		}
		if (context.ccode.report.get_errors () == 0 && (!fatal_warnings || context.ccode.report.get_warnings () == 0)) {
			if (!quiet_mode) {
				stdout.printf ("Compilation succeeded - %d warning(s)\n", context.ccode.report.get_warnings ());
			}
			return 0;
		} else {
			if (!quiet_mode) {
				stdout.printf ("Compilation failed: %d error(s), %d warning(s)\n", context.ccode.report.get_errors (), context.ccode.report.get_warnings ());
			}
			return 1;
		}
	}

	//ArrayList<shotodolplug.Module> modules = new ArrayList<shotodolplug.Module>();
	shotodolplug.Module[] modules = new shotodolplug.Module[128];
	int moduleCount = 0;
	void loadModulesHelper(shotodolplug.Module x) {
		x.init();
		modules[moduleCount++] = x;
	}
	void loadModules() {
		loadModulesHelper(new shotodolplug.PluginManager());
		loadModulesHelper(new codegenplug.AroopCodeGeneratorModule());
		loadModulesHelper(new codegenplug.SourceEmitterModule());
		loadModulesHelper(new codegenplug.TempVariableModule());
		loadModulesHelper(new codegenplug.CSymbolResolve());
		loadModulesHelper(new codegenplug.ElementModule());
		loadModulesHelper(new codegenplug.MemberAccessModule());
		loadModulesHelper(new codegenplug.BaseAccessModule());
		loadModulesHelper(new codegenplug.ParameterModule());
		loadModulesHelper(new codegenplug.MethodModule());
		loadModulesHelper(new codegenplug.DelegateModule());
		loadModulesHelper(new codegenplug.MethodCallModule());
		loadModulesHelper(new codegenplug.ControlFlowModule());
		loadModulesHelper(new codegenplug.CleanUpModule());
		loadModulesHelper(new codegenplug.BlockModule());
		loadModulesHelper(new codegenplug.StructModule());
		loadModulesHelper(new codegenplug.StringModule());
		loadModulesHelper(new codegenplug.ObjectModule());
		loadModulesHelper(new codegenplug.ObjectCreationModule());
		loadModulesHelper(new codegenplug.ValueModule());
		loadModulesHelper(new codegenplug.LocalVariableModule());
		loadModulesHelper(new codegenplug.PropertyModule());
		loadModulesHelper(new codegenplug.EnumModule());
		loadModulesHelper(new codegenplug.LoadStoreModule());
		loadModulesHelper(new codegenplug.LiteralModule());
		loadModulesHelper(new codegenplug.ExpressionModule());
		loadModulesHelper(new codegenplug.PostfixExpressionModule());
		loadModulesHelper(new codegenplug.UnaryExpressionModule());
		loadModulesHelper(new codegenplug.CastExpressionModule());
		loadModulesHelper(new codegenplug.AssignmentModule());
		loadModulesHelper(new codegenplug.GenericTypeModule());
		loadModulesHelper(new codegenplug.ErrorModule());
		loadModulesHelper(new codegenplug.SourceFileModule());
		shotodolplug.PluginManager.swarmValue("rehash", null);
	}

	private int run () {
		loadModules();
		context = CodeCompilerContext();
		CodeContext.push (context.ccode);

		// default to build executable
		if (!ccode_only && !compile_only && output == null) {
			// strip extension if there is one
			// else we use the default output file of the C compiler
			if (sources[0].last_index_of_char ('.') != -1) {
				int dot = sources[0].last_index_of_char ('.');
				output = Path.get_basename (sources[0].substring (0, dot));
			}
		}

		context.ccode.assert = !disable_assert;
		context.ccode.checking = enable_checking;
		context.ccode.deprecated = deprecated;
		context.ccode.experimental = experimental;
		context.ccode.experimental_non_null = experimental_non_null;
		context.ccode.report.enable_warnings = !disable_warnings;
		context.ccode.report.set_verbose_errors (!quiet_mode);
		context.ccode.verbose_mode = verbose_mode;
		context.ccode.version_header = !disable_version_header;

		context.ccode.ccode_only = ccode_only;
		context.ccode.compile_only = compile_only;
		context.static_link = static_link;
		context.ccode.header_filename = header_filename;
		if (header_filename == null && use_header) {
			Report.error (null, "--use-header may only be used in combination with --header");
		}
		context.ccode.use_header = use_header;
		context.ccode.internal_header_filename = internal_header_filename;
		context.ccode.symbols_filename = symbols_filename;
		context.ccode.includedir = includedir;
		context.ccode.output = output;
		if (basedir == null) {
			context.ccode.basedir = CodeContext.realpath (".");
		} else {
			context.ccode.basedir = CodeContext.realpath (basedir);
		}
		if (directory != null) {
			context.ccode.directory = CodeContext.realpath (directory);
		} else {
			context.ccode.directory = context.ccode.basedir;
		}
		context.ccode.vapi_directories = new string[1024];
		int i = 0;
		foreach(string x in vapi_directories) {
			context.ccode.vapi_directories[i] = x;
			i++;
		}
		context.ccode.vapi_directories[i] = Config.VAPI_INSTALL_PREFIX;
		//context.ccode.vapi_directories = vapi_directories;
		context.ccode.gir_directories = gir_directories;
		context.ccode.metadata_directories = metadata_directories;
		context.ccode.debug = debug;
		context.ccode.thread = thread;
		//context.profile = profile;
		context.ccode.mem_profiler = mem_profiler;
		context.ccode.save_temps = save_temps;
		context.ccode.add_define("AROOP"); // #define AROOP
		nostdpkg |= fast_vapi_filename != null;
		context.ccode.nostdpkg = nostdpkg;

		context.ccode.entry_point_name = entry_point;

		context.ccode.run_output = run_output;

		if (defines != null) {
			foreach (string define in defines) {
				context.ccode.add_define (define);
			}
		}

		for (i = 2; i <= 26; i += 2) {
			context.ccode.add_define ("VALA_0_%d".printf (i));
		}

		if (!nostdpkg) {
			context.profile = Profile.POSIX;
			context.ccode.add_define ("POSIX");
			/* default package */
			// XXX should I load posix ?? context.ccode.add_external_package ("posix");
			context.ccode.add_external_package ("aroop-1.0");
			context.ccode.add_external_package ("aroop_core-1.0");
		}

		if (packages != null) {
			foreach (string package in packages) {
				context.ccode.add_external_package (package);
			}
			packages = null;
		}

		if (fast_vapis != null) {
			foreach (string vapi in fast_vapis) {
				var rpath = CodeContext.realpath (vapi);
				var source_file = new SourceFile (context.ccode, SourceFileType.FAST, rpath);
				context.ccode.add_source_file (source_file);
			}
		}
		
		if (context.ccode.report.get_errors () > 0 || (fatal_warnings && context.ccode.report.get_warnings () > 0)) {
			return quit ();
		}

		//shotodolplug.PluginManager.dump();
		context.ccode.codegen = (CodeGenerator)shotodolplug.PluginManager.swarmValue("compiler/c/codegen", null); //new AroopCCodegenImpl ();
		assert(context.ccode.codegen != null);

		bool has_c_files = false;

		foreach (string source in sources) {
			if (context.ccode.add_source_filename (source, run_output)) {
				if (source.has_suffix (".c")) {
					has_c_files = true;
				}
			}
		}
		sources = null;
		
		if (context.ccode.report.get_errors () > 0 || (fatal_warnings && context.ccode.report.get_warnings () > 0)) {
			return quit ();
		}
		
		var parser = new Parser ();
		parser.parse (context.ccode);

		var genie_parser = new Genie.Parser ();
		genie_parser.parse (context.ccode);

		var gir_parser = new GirParser ();
		gir_parser.parse (context.ccode);

		if (context.ccode.report.get_errors () > 0 || (fatal_warnings && context.ccode.report.get_warnings () > 0)) {
			return quit ();
		}

		if (fast_vapi_filename != null) {
			var interface_writer = new CodeWriter (CodeWriterType.FAST);
			interface_writer.write_file (context.ccode, fast_vapi_filename);
			return quit ();
		}

		context.ccode.check ();

		if (context.ccode.report.get_errors () > 0 || (fatal_warnings && context.ccode.report.get_warnings () > 0)) {
			return quit ();
		}

		if (!ccode_only && !compile_only && library == null) {
			// building program, require entry point
			if (!has_c_files && context.ccode.entry_point == null) {
				Report.error (null, "program does not contain a static `main' method");
			}
		}

		if (dump_tree != null) {
			var code_writer = new CodeWriter (CodeWriterType.DUMP);
			code_writer.write_file (context.ccode, dump_tree);
		}

		if (context.ccode.report.get_errors () > 0 || (fatal_warnings && context.ccode.report.get_warnings () > 0)) {
			return quit ();
		}

		print("emitting \n");
		context.ccode.codegen.emit (context.ccode);
		print("done \n");

		if (context.ccode.report.get_errors () > 0 || (fatal_warnings && context.ccode.report.get_warnings () > 0)) {
			return quit ();
		}

		if (vapi_filename == null && library != null) {
			// keep backward compatibility with --library option
			vapi_filename = "%s.vapi".printf (library);
		}

		if (library != null) {
			if (gir != null) {
				gir = null;
			}

			library = null;
		}

		// The GIRWriter places the gir_namespace and gir_version into the top namespace, so write the vapi after that stage
		if (vapi_filename != null) {
			var interface_writer = new CodeWriter ();

			// put .vapi file in current directory unless -d has been explicitly specified
			if (directory != null && !Path.is_absolute (vapi_filename)) {
				vapi_filename = "%s%c%s".printf (context.ccode.directory, Path.DIR_SEPARATOR, vapi_filename);
			}

			interface_writer.write_file (context.ccode, vapi_filename);
		}

		if (internal_vapi_filename != null) {
			if (internal_header_filename == null ||
			    header_filename == null) {
				Report.error (null, "--internal-vapi may only be used in combination with --header and --internal-header");
				return quit();
			}

			var interface_writer = new CodeWriter (CodeWriterType.INTERNAL);
			interface_writer.set_cheader_override(header_filename, internal_header_filename);
			string vapi_filename = internal_vapi_filename;

			// put .vapi file in current directory unless -d has been explicitly specified
			if (directory != null && !Path.is_absolute (vapi_filename)) {
				vapi_filename = "%s%c%s".printf (context.ccode.directory, Path.DIR_SEPARATOR, vapi_filename);
			}

			interface_writer.write_file (context.ccode, vapi_filename);

			internal_vapi_filename = null;
		}

		if (dependencies != null) {
			context.ccode.write_dependencies (dependencies);
		}

		if (!ccode_only) {
			var ccompiler = new CCodeCompiler ();
			if (cc_command == null && Environment.get_variable ("CC") != null) {
				cc_command = Environment.get_variable ("CC");
			}
			if (cc_options == null) {
				ccompiler.compile (&context, cc_command, new string[] { });
			} else {
				ccompiler.compile (&context, cc_command, cc_options);
			}
		}

		return quit ();
	}

#if false
	static int run_source (string[] args) {
		int i = 1;
		if (args[i] != null && args[i].has_prefix ("-")) {
			try {
				string[] compile_args;
				Shell.parse_argv ("valac " + args[1], out compile_args);

				var opt_context = new OptionContext ("- Vala");
				opt_context.set_help_enabled (true);
				opt_context.add_main_entries (options, null);
				unowned string[] temp_args = compile_args;
				opt_context.parse (ref temp_args);
			} catch (ShellError e) {
				stdout.printf ("%s\n", e.message);
				return 1;
			} catch (OptionError e) {
				stdout.printf ("%s\n", e.message);
				stdout.printf ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
				return 1;
			}

			i++;
		}

		if (args[i] == null) {
			stderr.printf ("No source file specified.\n");
			return 1;
		}

		sources = { args[i] };
		output = "%s/%s.XXXXXX".printf (Environment.get_tmp_dir (), Path.get_basename (args[i]));
		int outputfd = FileUtils.mkstemp (output);
		if (outputfd < 0) {
			return 1;
		}

		run_output = true;
		disable_warnings = true;
		quiet_mode = true;

		var compiler = new Compiler ();
		int ret = compiler.run ();
		if (ret != 0) {
			return ret;
		}

		FileUtils.close (outputfd);
		if (FileUtils.chmod (output, 0700) != 0) {
			FileUtils.unlink (output);
			return 1;
		}

		string[] target_args = { output };
		while (i < args.length) {
			target_args += args[i];
			i++;
		}

		try {
			Pid pid;
			var loop = new MainLoop ();
			int child_status = 0;

			Process.spawn_async (null, target_args, null, SpawnFlags.CHILD_INHERITS_STDIN | SpawnFlags.DO_NOT_REAP_CHILD | SpawnFlags.FILE_AND_ARGV_ZERO, null, out pid);

			FileUtils.unlink (output);
			ChildWatch.add (pid, (pid, status) => {
				child_status = (status & 0xff00) >> 8;
				loop.quit ();
			});

			loop.run ();

			return child_status;
		} catch (SpawnError e) {
			stdout.printf ("%s\n", e.message);
			return 1;
		}
	}
#endif

	static int main (string[] args) {
		// initialize locale
		Intl.setlocale (LocaleCategory.ALL, "");

#if false
		if (Path.get_basename (args[0]) == "vala" || Path.get_basename (args[0]) == "vala" + Config.PACKAGE_SUFFIX) {
			return run_source (args);
		}
#endif

		try {
			var opt_context = new OptionContext ("- Vala Compiler");
			opt_context.set_help_enabled (true);
			opt_context.add_main_entries (options, null);
			opt_context.parse (ref args);
		} catch (OptionError e) {
			stdout.printf ("%s\n", e.message);
			stdout.printf ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
			return 1;
		}
		
		if (show_vapi_install_prefix) {
			stdout.printf ("%s\n", Config.VAPI_INSTALL_PREFIX);
			return 0;
		}
		if (show_c_includedir) {
			stdout.printf ("%s\n", Config.C_INCLUDE_DIR);
			return 0;
		}
		if (show_c_libdir) {
			stdout.printf ("%s\n", Config.C_LIB_DIR);
			return 0;
		}
		if (version) {
			stdout.printf ("Vala %s\n", Config.PACKAGE_VERSION);
			return 0;
		}
		
		if (sources == null && fast_vapis == null) {
			stderr.printf ("No source file specified.\n");
			return 1;
		}
		
		var compiler = new Compiler ();
		return compiler.run ();
	}
}
