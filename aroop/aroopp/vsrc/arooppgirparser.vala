/* arooppgirparser.aroopp
 *
 * Copyright (C) 2008-2010  Jürg Billeter
 * Copyright (C) 2011  Luca Bruno
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
 * 	Luca Bruno <lucabru@src.gnome.org>
 */

using aroopp;

/**
 * Code visitor parsing all GIR source files.
 *
 * Pipeline:
 * 1) Parse metadata
 * 2) Parse GIR with metadata, track unresolved GIR symbols, create aroopp symbols
 * 3) Reconciliate the tree by mapping tracked symbols
 * 4) Process the tree
 */
public class aroopp.GirParser : CodeVisitor {
	/*
	 * Metadata parser
	 */

	enum ArgumentType {
		SKIP,
		HIDDEN,
		TYPE,
		TYPE_ARGUMENTS,
		CHEADER_FILENAME,
		NAME,
		OWNED,
		UNOWNED,
		PARENT,
		NULLABLE,
		DEPRECATED,
		REPLACEMENT,
		DEPRECATED_SINCE,
		ARRAY,
		ARRAY_LENGTH_IDX,
		DEFAULT,
		OUT,
		REF,
		VFUNC_NAME,
		VIRTUAL,
		ABSTRACT,
		SCOPE,
		STRUCT,
		THROWS,
		PRINTF_FORMAT,
		ARRAY_LENGTH_FIELD,
		SENTINEL,
		CLOSURE,
		CPREFIX,
		LOWER_CASE_CPREFIX,
		ERRORDOMAIN;

		public static ArgumentType? from_string (string name) {
			var enum_class = (EnumClass) typeof(ArgumentType).class_ref ();
			var nick = name.replace ("_", "-");
			unowned aroopp.EnumValue? enum_value = enum_class.get_value_by_nick (nick);
			if (enum_value != null) {
				ArgumentType value = (ArgumentType) enum_value.value;
				return value;
			}
			return null;
		}
	}

	class Argument {
		public Expression expression;
		public SourceReference source_reference;

		public bool used = false;

		public Argument (Expression expression, SourceReference? source_reference = null) {
			this.expression = expression;
			this.source_reference = source_reference;
		}
	}

	class MetadataSet : Metadata {
		public MetadataSet (string? selector = null) {
			base ("", selector);
		}

		public void add_sibling (Metadata metadata) {
			foreach (var child in metadata.children) {
				add_child (child);
			}
			// merge arguments and take precedence
			foreach (var key in metadata.args.get_keys ()) {
				args[key] = metadata.args[key];
			}
		}
	}

	class Metadata {
		private static Metadata _empty = null;
		public static Metadata empty {
			get {
				if (_empty == null) {
					_empty = new Metadata ("");
				}
				return _empty;
			}
		}

		public PatternSpec pattern_spec;
		public string? selector;
		public SourceReference source_reference;

		public bool used = false;
		public aroopp.Map<ArgumentType,Argument> args = new HashMap<ArgumentType,Argument> ();
		public ArrayList<Metadata> children = new ArrayList<Metadata> ();

		public Metadata (string pattern, string? selector = null, SourceReference? source_reference = null) {
			this.pattern_spec = new PatternSpec (pattern);
			this.selector = selector;
			this.source_reference = source_reference;
		}

		public void add_child (Metadata metadata) {
			children.add (metadata);
		}

		public Metadata match_child (string name, string? selector = null) {
			var result = Metadata.empty;
			foreach (var metadata in children) {
				if ((selector == null || metadata.selector == null || metadata.selector == selector) && metadata.pattern_spec.match_string (name)) {
					metadata.used = true;
					if (result == Metadata.empty) {
						// first match
						result = metadata;
					} else {
						var ms = result as MetadataSet;
						if (ms == null) {
							// second match
							ms = new MetadataSet (selector);
							ms.add_sibling (result);
						}
						ms.add_sibling (metadata);
						result = ms;
					}
				}
			}
			return result;
		}

		public void add_argument (ArgumentType key, Argument value) {
			args.set (key, value);
		}

		public bool has_argument (ArgumentType key) {
			return args.contains (key);
		}

		public Expression? get_expression (ArgumentType arg) {
			var val = args.get (arg);
			if (val != null) {
				val.used = true;
				return val.expression;
			}
			return null;
		}

		public string? get_string (ArgumentType arg) {
			var lit = get_expression (arg) as StringLiteral;
			if (lit != null) {
				return lit.eval ();
			}
			return null;
		}

		public int get_integer (ArgumentType arg) {
			var unary = get_expression (arg) as UnaryExpression;
			if (unary != null && unary.operator == UnaryOperator.MINUS) {
				var lit = unary.inner as IntegerLiteral;
				if (lit != null) {
					return -int.parse (lit.value);
				}
			} else {
				var lit = get_expression (arg) as IntegerLiteral;
				if (lit != null) {
					return int.parse (lit.value);
				}
			}

			return 0;
		}

		public bool get_bool (ArgumentType arg, bool default_value = false) {
			var lit = get_expression (arg) as BooleanLiteral;
			if (lit != null) {
				return lit.value;
			}
			return default_value;
		}

		public SourceReference? get_source_reference (ArgumentType arg) {
			var val = args.get (arg);
			if (val != null) {
				return val.source_reference;
			}
			return null;
		}
	}

	class MetadataParser {
		/**
		 * Grammar:
		 * metadata ::= [ rule [ '\n' relativerule ]* ]
		 * rule ::= pattern ' ' [ args ]
		 * relativerule ::= '.' rule
		 * pattern ::= glob [ '#' selector ] [ '.' pattern ]
		 */
		private Metadata tree = new Metadata ("");
		private Scanner scanner;
		private SourceLocation begin;
		private SourceLocation end;
		private SourceLocation old_end;
		private TokenType current;
		private Metadata parent_metadata;

		public MetadataParser () {
			tree.used = true;
		}

		SourceReference get_current_src () {
			return new SourceReference (scanner.source_file, begin.line, begin.column, end.line, end.column);
		}

		SourceReference get_src (SourceLocation begin, SourceLocation? end = null) {
			var e = this.end;
			if (end != null) {
				e = end;
			}
			return new SourceReference (scanner.source_file, begin.line, begin.column, e.line, e.column);
		}

		public Metadata parse_metadata (SourceFile metadata_file) {
			scanner = new Scanner (metadata_file);
			next ();
			while (current != TokenType.EOF) {
				if (!parse_rule ()) {
					return Metadata.empty;
				}
			}
			return tree;
		}

		TokenType next () {
			old_end = end;
			current = scanner.read_token (out begin, out end);
			return current;
		}

		bool has_space () {
			return old_end.pos != begin.pos;
		}

		bool has_newline () {
			return old_end.line != begin.line;
		}

		string get_string (SourceLocation? begin = null, SourceLocation? end = null) {
			var b = this.begin;
			var e = this.end;
			if (begin != null) {
				b = begin;
			}
			if (end != null) {
				e = end;
			}
			return ((string) b.pos).substring (0, (int) (e.pos - b.pos));
		}

		string? parse_identifier (bool is_glob) {
			var begin = this.begin;

			if (current == TokenType.DOT || current == TokenType.HASH) {
				if (is_glob) {
					Report.error (get_src (begin), "expected glob-style pattern");
				} else {
					Report.error (get_src (begin), "expected identifier");
				}
				return null;
			}

			if (is_glob) {
				while (current != TokenType.EOF && current != TokenType.DOT && current != TokenType.HASH) {
					next ();
					if (has_space ()) {
						break;
					}
				}
			} else {
				next ();
			}

			return get_string (begin, old_end);
		}

		string? parse_selector () {
			if (current != TokenType.HASH || has_space ()) {
				return null;
			}
			next ();

			return parse_identifier (false);
		}

		Metadata? parse_pattern () {
			Metadata metadata;
			bool is_relative = false;
			if (current == TokenType.IDENTIFIER || current == TokenType.STAR) {
				// absolute pattern
				parent_metadata = tree;
			} else {
				// relative pattern
				if (current != TokenType.DOT) {
					Report.error (get_current_src (), "expected pattern or `.', got %s".printf (current.to_string ()));
					return null;
				}
				next ();
				is_relative = true;
			}

			if (parent_metadata == null) {
				Report.error (get_current_src (), "cannot determinate parent metadata");
				return null;
			}

			SourceLocation begin = this.begin;
			var pattern = parse_identifier (true);
			if (pattern == null) {
				return null;
			}
			metadata = new Metadata (pattern, parse_selector (), get_src (begin));
			parent_metadata.add_child (metadata);

			while (current != TokenType.EOF && !has_space ()) {
				if (current != TokenType.DOT) {
					Report.error (get_current_src (), "expected `.' got %s".printf (current.to_string ()));
					break;
				}
				next ();

				begin = this.begin;
				pattern = parse_identifier (true);
				if (pattern == null) {
					return null;
				}
				var child = new Metadata (pattern, parse_selector (), get_src (begin, old_end));
				metadata.add_child (child);
				metadata = child;
			}
			if (!is_relative) {
				parent_metadata = metadata;
			}

			return metadata;
		}

		Expression? parse_expression () {
			var begin = this.begin;
			var src = get_current_src ();
			Expression expr = null;
			switch (current) {
			case TokenType.NULL:
				expr = new NullLiteral (src);
				break;
			case TokenType.TRUE:
				expr = new BooleanLiteral (true, src);
				break;
			case TokenType.FALSE:
				expr = new BooleanLiteral (false, src);
				break;
			case TokenType.MINUS:
				next ();
				var inner = parse_expression ();
				if (inner == null) {
					Report.error (src, "expected expression after `-', got %s".printf (current.to_string ()));
				} else {
					expr = new UnaryExpression (UnaryOperator.MINUS, inner, get_src (begin));
				}
				return expr;
			case TokenType.INTEGER_LITERAL:
				expr = new IntegerLiteral (get_string (), src);
				break;
			case TokenType.REAL_LITERAL:
				expr = new RealLiteral (get_string (), src);
				break;
			case TokenType.STRING_LITERAL:
				expr = new StringLiteral (get_string (), src);
				break;
			case TokenType.IDENTIFIER:
				expr = new MemberAccess (null, get_string (), src);
				while (next () == TokenType.DOT) {
					if (next () != TokenType.IDENTIFIER) {
						Report.error (get_current_src (), "expected identifier got %s".printf (current.to_string ()));
						break;
					}
					expr = new MemberAccess (expr, get_string (), get_current_src ());
				}
				return expr;
			default:
				Report.error (src, "expected literal or symbol got %s".printf (current.to_string ()));
				break;
			}
			next ();
			return expr;
		}

		bool parse_args (Metadata metadata) {
			while (current != TokenType.EOF && has_space () && !has_newline ()) {
				SourceLocation begin = this.begin;
				var id = parse_identifier (false);
				if (id == null) {
					return false;
				}
				var arg_type = ArgumentType.from_string (id);
				if (arg_type == null) {
					Report.error (get_src (begin, old_end), "unknown argument");
					return false;
				}

				if (current != TokenType.ASSIGN) {
					// threat as `true'
					metadata.add_argument (arg_type, new Argument (new BooleanLiteral (true, get_src (begin)), get_src (begin)));
					continue;
				}
				next ();

				Expression expr = parse_expression ();
				if (expr == null) {
					return false;
				}
				metadata.add_argument (arg_type, new Argument (expr, get_src (begin)));
			}

			return true;
		}

		bool parse_rule () {
			var old_end = end;
			var metadata = parse_pattern ();
			if (metadata == null) {
				return false;
			}

			if (current == TokenType.EOF || old_end.line != end.line) {
				// eof or new rule
				return true;
			}
			return parse_args (metadata);
		}
	}

	/*
	 * GIR parser
	 */

	class Node {
		public static ArrayList<Node> new_namespaces = new ArrayList<Node> ();

		public weak Node parent;
		public string element_type;
		public string name;
		public Map<string,string> girdata = null;
		public Metadata metadata = Metadata.empty;
		public SourceReference source_reference = null;
		public ArrayList<Node> members = new ArrayList<Node> (); // guarantees fields order
		public HashMap<string, ArrayList<Node>> scope = new HashMap<string, ArrayList<Node>> (str_hash, str_equal);

		public Symbol symbol;
		public bool new_symbol;
		public bool merged;
		public bool processed;

		// function-specific
		public int return_array_length_idx = -1;
		public List<ParameterInfo> parameters;
		public ArrayList<int> array_length_parameters;
		public ArrayList<int> closure_parameters;
		public ArrayList<int> destroy_parameters;
		// record-specific
		public UnresolvedSymbol gtype_struct_for;
		// alias-specific
		public DataType base_type;

		public Node (string? name) {
			this.name = name;
		}

		public void add_member (Node node) {
			var nodes = scope[node.name];
			if (nodes == null) {
				nodes = new ArrayList<Node> ();
				scope[node.name] = nodes;
			}
			nodes.add (node);
			members.add (node);
			node.parent = this;
		}

		public void remove_member (Node node) {
			var nodes = scope[node.name];
			nodes.remove (node);
			if (nodes.size == 0) {
				scope.remove (node.name);
			}
			members.remove (node);
			node.parent = null;
		}

		public Node? lookup (string name, bool create_namespace = false, SourceReference? source_reference = null) {
			var nodes = scope[name];
			Node node = null;
			if (nodes != null) {
				node = nodes[0];
			}
			if (node == null) {
				Symbol sym = null;
				if (symbol != null) {
					sym = symbol.scope.lookup (name);
				}
				if (sym != null || create_namespace) {
					node = new Node (name);
					node.symbol = sym;
					node.new_symbol = node.symbol == null;
					node.source_reference = source_reference;
					add_member (node);

					if (sym == null) {
						new_namespaces.add (node);
					}
				}
			}
			return node;
		}

		public ArrayList<Node>? lookup_all (string name) {
			return scope[name];
		}

		public UnresolvedSymbol get_unresolved_symbol () {
			if (parent.name == null) {
				return new UnresolvedSymbol (null, name);
			} else {
				return new UnresolvedSymbol (parent.get_unresolved_symbol (), name);
			}
		}

		public string get_full_name () {
			if (parent == null) {
				return name;
			}

			if (name == null) {
				return parent.get_full_name ();
			}

			if (parent.get_full_name () == null) {
				return name;
			}

			return "%s.%s".printf (parent.get_full_name (), name);
		}

		public string get_gir_name () {
			var gir_name = girdata["name"];
			if (gir_name == null) {
				gir_name = girdata["aroopp:name"];
			}
			return gir_name;
		}

		public string get_lower_case_cprefix () {
			if (name == null) {
				return "";
			}

			var prefix = symbol.get_attribute_string ("CCode", "lower_case_cprefix");
			if (prefix == null && (symbol is ObjectTypeSymbol || symbol is Struct)) {
				if (metadata.has_argument (ArgumentType.CPREFIX)) {
					prefix = metadata.get_string (ArgumentType.CPREFIX);
				} else {
					prefix = symbol.get_attribute_string ("CCode", "cprefix");
				}
			}

			if (prefix == null) {
				prefix = get_default_lower_case_cprefix ();
			}
			return prefix;
		}

		public string get_default_lower_case_cprefix () {
			return "%s%s_".printf (parent.get_lower_case_cprefix (), get_lower_case_csuffix ());
		}

		public string get_lower_case_csuffix () {
			var suffix = symbol.get_attribute_string ("CCode", "lower_case_csuffix");

			// we can't rely on gir suffix if metadata changed the name
			if (suffix == null && girdata != null && girdata["c:symbol-prefix"] != null && !metadata.has_argument (ArgumentType.NAME)) {
				suffix = girdata["c:symbol-prefix"];
			}
			if (suffix == null) {
				suffix = get_default_lower_case_csuffix ();
			}
			return suffix;
		}

		public string get_default_lower_case_csuffix () {
			return Symbol.camel_case_to_lower_case (name);
		}

		public string get_cprefix () {
			if (name == null) {
				return "";
			}
			var prefix = symbol.get_attribute_string ("CCode", "cprefix");
			if (prefix == null && girdata != null) {
				prefix = girdata["c:identifier-prefixes"];
			}
			if (prefix == null) {
				if (symbol is Enum || symbol is ErrorDomain) {
					prefix = "%s%s".printf (parent.get_lower_case_cprefix ().up (), name);
				} else {
					prefix = get_cname ();
				}
			}
			return prefix;
		}

		public string get_cname () {
			if (name == null) {
				return "";
			}
			var cname = symbol.get_attribute_string ("CCode", "cname");
			if (girdata != null) {
				if (cname == null) {
					cname = girdata["c:identifier"];
				}
				if (cname == null) {
					cname = girdata["c:type"];
				}
			}
			if (cname == null) {
				cname = get_default_cname ();
			}
			return cname;
		}

		public string get_default_cname () {
			if (name == null) {
				return "";
			}
			if (symbol is Field) {
				if (((Field) symbol).binding == MemberBinding.STATIC) {
					return parent.get_lower_case_cprefix () + name;
				} else {
					return name;
				}
			} else if (symbol is Method) {
				return "%s%s".printf (parent.get_lower_case_cprefix (), name);
			} else {
				return "%s%s".printf (parent.get_cprefix (), name);
			}
		}

		public string get_finish_cname () {
			var finish_cname = symbol.get_attribute_string ("CCode", "finish_name");
			if (finish_cname == null) {
				finish_cname = get_cname ();
				if (finish_cname.has_suffix ("_async")) {
					finish_cname = finish_cname.substring (0, finish_cname.length - "_async".length);
				}
				finish_cname += "_finish";
			}
			return finish_cname;
		}

		public string get_cheader_filename () {
			if (metadata.has_argument (ArgumentType.CHEADER_FILENAME)) {
				return metadata.get_string (ArgumentType.CHEADER_FILENAME);
			}
			var cheader_filename = symbol.get_attribute_string ("CCode", "cheader_filename");
			if (cheader_filename != null) {
				return cheader_filename;
			}
			if (parent.name != null) {
				return parent.get_cheader_filename ();
			} else if (symbol.source_reference != null) {
				return symbol.source_reference.file.get_cinclude_filename ();
			}
			return "";
		}

		public void process (GirParser parser) {
			if (processed) {
				return;
			}

			if (symbol is Namespace && parent == parser.root) {
				// first process aliases since they have no assigned symbol
				foreach (var node in members) {
					if (node.element_type == "alias") {
						parser.process_alias (node);
					}
				}

				// auto reparent namespace methods, allowing node removals
				for (int i=0; i < members.size; i++) {
					var node = members[i];
					if (node.symbol is Method && node.new_symbol) {
						parser.process_namespace_method (this, node);
						if (i < members.size && members[i] != node) {
							// node removed in the middle
							i--;
						}
					}
				}
			}

			// process children
			foreach (var node in members) {
				node.process (parser);
			}

			if (girdata != null) {
				// GIR node processing
				if (symbol is Method) {
					var m = (Method) symbol;
					parser.process_callable (this);

					var colliding = parent.lookup_all (name);
					foreach (var node in colliding) {
						var sym = node.symbol;
						if (sym is Field && !(m.return_type is VoidType) && m.get_parameters().size == 0) {
							// assume method is getter
							merged = true;
						} else if (sym is Signal) {
							node.process (parser);
							var sig = (Signal) sym;
							if (m.is_virtual || m.is_abstract) {
								sig.is_virtual = true;
							} else {
								sig.set_attribute ("HasEmitter", true);
							}
							parser.assume_parameter_names (sig, m, false);
							if (m.get_parameters().size != sig.get_parameters().size) {
								Report.warning (symbol.source_reference, "Signal `%s' conflicts with method of the same name".printf (get_full_name ()));
							}
							merged = true;
						} else if (sym is Method && !(sym is CreationMethod) && node != this) {
							if (m.is_virtual || m.is_abstract) {
								bool different_invoker = false;
								var attr = m.get_attribute ("NoWrapper");
								if (attr != null) {
									/* no invoker but this method has the same name,
									   most probably the invoker has a different name
									   and g-ir-scanner missed it */
									var invoker = parser.find_invoker (this);
									if (invoker != null) {
										m.set_attribute_string ("CCode", "vfunc_name", m.name);
										m.name = invoker.symbol.name;
										m.set_attribute ("NoWrapper", false);
										invoker.merged = true;
										different_invoker = true;
									}
								}
								if (!different_invoker) {
									if (attr != null) {
										Report.warning (symbol.source_reference, "Virtual method `%s' conflicts with method of the same name".printf (get_full_name ()));
									}
									node.merged = true;
								}
							}
						}
					}
					if (!(m is CreationMethod)) {
						// merge custom vfunc
						if (metadata.has_argument (ArgumentType.VFUNC_NAME)) {
							var vfunc = parent.lookup (metadata.get_string (ArgumentType.VFUNC_NAME));
							if (vfunc != null && vfunc != this) {
								vfunc.processed = true;
								vfunc.merged = true;
							}
						}
					}
					if (m.coroutine) {
						parser.process_async_method (this);
					}
				} else if (symbol is Property) {
					var colliding = parent.lookup_all (name);
					foreach (var node in colliding) {
						if (node.symbol is Signal) {
							// properties take precedence
							node.processed = true;
							node.merged = true;
						} else if (node.symbol is Method) {
							// getter in C, but not in aroopp
							node.merged = true;
						}
					}

					var prop = (Property) symbol;

					// add accessors, can't do this before gir symbol resolution
					var readable = girdata["readable"];
					var writable = girdata["writable"];
					var construct_ = girdata["construct"];
					var construct_only = girdata["construct-only"];
					if (readable != "0") {
						prop.get_accessor = new PropertyAccessor (true, false, false, prop.property_type.copy (), null, null);
					}
					if (writable == "1" || construct_only == "1") {
						prop.set_accessor = new PropertyAccessor (false, (construct_only != "1") && (writable == "1"), (construct_only == "1") || (construct_ == "1"), prop.property_type.copy (), null, null);
					}

					// find virtual/abstract accessors to handle abstract properties properly

					Node getter = null;
					var getters = parent.lookup_all ("get_%s".printf (name));
					if (getters != null) {
						foreach (var g in getters) {
							if ((getter == null || !g.merged) && g.get_cname () == parent.get_lower_case_cprefix() + "get_" + name) {
								getter = g;
							}
						}
					}

					Node setter = null;
					var setters = parent.lookup_all ("set_%s".printf (name));
					if (setters != null) {
						foreach (var s in setters) {
							if ((setter == null || !s.merged) && s.get_cname () == parent.get_lower_case_cprefix() + "set_" + name) {
								setter = s;
							}
						}
					}

					prop.set_attribute ("NoAccessorMethod", false);
					if (prop.get_accessor != null) {
						var m = getter != null ? getter.symbol as Method : null;
						// ensure getter vfunc if the property is abstract
						if (m != null && (m.is_abstract || m.is_virtual || !prop.is_abstract)) {
							getter.process (parser);
							if (m.return_type is VoidType || m.get_parameters().size != 0) {
								prop.set_attribute ("NoAccessorMethod", true);
							} else {
								if (getter.name == name) {
									foreach (var node in colliding) {
										if (node.symbol is Method) {
											node.merged = true;
										}
									}
								}
								prop.get_accessor.value_type.value_owned = m.return_type.value_owned;
							}
						} else {
							prop.set_attribute ("NoAccessorMethod", true);
						}
					}
					if (prop.get_attribute ("NoAccessorMethod") == null && prop.set_accessor != null && prop.set_accessor.writable) {
						var m = setter != null ? setter.symbol as Method : null;
						// ensure setter vfunc if the property is abstract
						if (m != null && (m.is_abstract || m.is_virtual || !prop.is_abstract)) {
							setter.process (parser);
							if (!(m.return_type is VoidType) || m.get_parameters().size != 1) {
								prop.set_attribute ("NoAccessorMethod", true);
							} else {
								prop.set_accessor.value_type.value_owned = m.get_parameters()[0].variable_type.value_owned;
							}
						} else {
							prop.set_attribute ("NoAccessorMethod", true);
						}
					}
					if (prop.get_attribute ("NoAccessorMethod") != null) {
						// gobject defaults
						if (prop.get_accessor != null) {
							prop.get_accessor.value_type.value_owned = true;
						}
						if (prop.set_accessor != null) {
							prop.set_accessor.value_type.value_owned = false;
						}
					}
				} else if (symbol is Field) {
					var field = (Field) symbol;
					var colliding = parent.lookup_all (name);
					if (colliding.size > 1) {
						// whatelse has precedence over the field
						merged = true;
					}

					if (field.variable_type is DelegateType && parent.gtype_struct_for != null) {
						// virtual method field
						var d = ((DelegateType) field.variable_type).delegate_symbol;
						parser.process_virtual_method_field (this, d, parent.gtype_struct_for);
						merged = true;
					} else if (field.variable_type is ArrayType) {
						Node array_length;
						if (metadata.has_argument (ArgumentType.ARRAY_LENGTH_FIELD)) {
							array_length = parent.lookup (metadata.get_string (ArgumentType.ARRAY_LENGTH_FIELD));
						} else {
							array_length = parent.lookup ("n_%s".printf (field.name));
							if (array_length == null) {
								array_length = parent.lookup ("%s_length".printf (field.name));
							}
						}
						if (array_length != null && array_length.symbol is Field) {
							var length_field = (Field) array_length.symbol;
							// array has length
							field.set_attribute_string ("CCode", "array_length_cname", length_field.name);
							var length_type = length_field.variable_type.to_qualified_string ();
							if (length_type != "int") {
								var st = parser.root.lookup (length_type);
								if (st != null) {
									field.set_attribute_string ("CCode", "array_length_type", st.get_cname ());
								}
							}
							field.remove_attribute_argument ("CCode", "array_length");
							field.remove_attribute_argument ("CCode", "array_null_terminated");
						}
					}
				} else if (symbol is Signal || symbol is Delegate) {
					parser.process_callable (this);
				} else if (symbol is Interface) {
					parser.process_interface (this);
				} else if (symbol is Struct) {
					if (parent.symbol is ObjectTypeSymbol || parent.symbol is Struct) {
						// nested struct
						foreach (var fn in members) {
							var f = fn.symbol as Field;
							if (f != null) {
								if (f.binding == MemberBinding.INSTANCE) {
									f.set_attribute_string ("CCode", "cname", name + "." + fn.get_cname ());
								}
								f.name = symbol.name + "_" + f.name;
								fn.name = f.name;
								parent.add_member (fn);
							}
						}
						merged = true;
					} else {
						// record for a gtype
						var gtype_struct_for = girdata["aroopp:is-gtype-struct-for"];
						if (gtype_struct_for != null) {
							var iface = parser.resolve_node (parent, parser.parse_symbol_from_string (gtype_struct_for, source_reference));
							if (iface != null && iface.symbol is Interface && "%sIface".printf (iface.get_cname ()) != get_cname ()) {
								// set the interface struct name
								iface.symbol.set_attribute_string ("CCode", "type_cname", get_cname ());
							}
							merged = true;
						}
					}
				}

				// deprecation
				if (metadata.has_argument (ArgumentType.REPLACEMENT)) {
					symbol.set_attribute_string ("Deprecated", "replacement", metadata.get_string (ArgumentType.REPLACEMENT));
				}
				if (metadata.has_argument (ArgumentType.DEPRECATED_SINCE)) {
					symbol.set_attribute_string ("Deprecated", "since",  metadata.get_string (ArgumentType.DEPRECATED_SINCE));
				} else if (girdata["deprecated-version"] != null) {
					symbol.set_attribute_string ("Deprecated", "since", girdata.get ("deprecated-version"));
				}
				if (metadata.get_bool (ArgumentType.DEPRECATED)) {
					symbol.set_attribute ("Deprecated", true);
				}

				if (parent.symbol is Namespace) {
					// always write cheader filename for namespace children
					symbol.set_attribute_string ("CCode", "cheader_filename", get_cheader_filename ());
				} else if (metadata.has_argument (ArgumentType.CHEADER_FILENAME)) {
					symbol.set_attribute_string ("CCode", "cheader_filename", metadata.get_string (ArgumentType.CHEADER_FILENAME));
				}
				if (get_cname () != get_default_cname ()) {
					symbol.set_attribute_string ("CCode", "cname", get_cname ());
				}

				// lower_case_cprefix
				if (get_lower_case_cprefix () != get_default_lower_case_cprefix ()) {
					if (symbol is Class) {
						symbol.set_attribute_string ("CCode", "cprefix", get_lower_case_cprefix ());
					} else {
						symbol.set_attribute_string ("CCode", "lower_case_cprefix", get_lower_case_cprefix ());
					}
				}
				// lower_case_csuffix
				if (get_lower_case_csuffix () != get_default_lower_case_csuffix ()) {
					symbol.set_attribute_string ("CCode", "lower_case_csuffix", get_lower_case_csuffix ());
				}

				// set gir name if the symbol has been renamed
				if (is_container (symbol) && !(symbol is Namespace) && name != get_gir_name ()) {
					symbol.set_attribute_string ("GIR", "name", get_gir_name ());
				}
			}

			if (!(new_symbol && merged) && is_container (symbol)) {
				foreach (var node in members) {
					if (node.new_symbol && !node.merged && !metadata.get_bool (ArgumentType.HIDDEN)) {
						add_symbol_to_container (symbol, node.symbol);
					}
				}

				var cl = symbol as Class;
				if (cl != null && !cl.is_compact && cl.default_construction_method == null) {
					// always provide constructor in generated bindings
					// to indicate that implicit Object () chainup is allowed
					var cm = new CreationMethod (null, null, cl.source_reference);
					cm.has_construct_function = false;
					cm.access = SymbolAccessibility.PROTECTED;
					cl.add_method (cm);
				}
			}

			processed = true;
		}

		public string to_string () {
			if (parent.name == null) {
				return name;
			} else {
				return "%s.%s".printf (parent.to_string (), name);
			}
		}
	}

	static aroopp.Regex type_from_string_regex;

	MarkupReader reader;

	CodeContext context;
	Namespace aroopp_ns;

	SourceFile current_source_file;
	Node root;
	ArrayList<Metadata> metadata_roots = new ArrayList<Metadata> ();

	SourceLocation begin;
	SourceLocation end;
	MarkupTokenType current_token;

	string[] cheader_filenames;

	ArrayList<Metadata> metadata_stack;
	Metadata metadata;
	ArrayList<Node> tree_stack;
	Node current;
	Node old_current;

	Set<string> provided_namespaces = new HashSet<string> (str_hash, str_equal);
	HashMap<UnresolvedSymbol,Symbol> unresolved_symbols_map = new HashMap<UnresolvedSymbol,Symbol> (unresolved_symbol_hash, unresolved_symbol_equal);
	ArrayList<UnresolvedSymbol> unresolved_gir_symbols = new ArrayList<UnresolvedSymbol> ();

	/**
	 * Parses all .gir source files in the specified code
	 * context and builds a code tree.
	 *
	 * @param context a code context
	 */
	public void parse (CodeContext context) {
		this.context = context;
		aroopp_ns = context.root.scope.lookup ("aroopp") as Namespace;

		root = new Node (null);
		root.symbol = context.root;
		tree_stack = new ArrayList<Node> ();
		current = root;

		map_aroopp_to_gir ();

		context.accept (this);

		resolve_gir_symbols ();
		create_new_namespaces ();

		root.process (this);

		foreach (var metadata in metadata_roots) {
			report_unused_metadata (metadata);
		}
	}

	void map_aroopp_to_gir () {
		foreach (var source_file in context.get_source_files ()) {
			string gir_namespace = source_file.gir_namespace;
			string gir_version = source_file.gir_version;
			Namespace ns = null;
			if (gir_namespace == null) {
				foreach (var node in source_file.get_nodes ()) {
					if (node is Namespace) {
						ns = (Namespace) node;
						gir_namespace = ns.get_attribute_string ("CCode", "gir_namespace");
						if (gir_namespace != null) {
							gir_version = ns.get_attribute_string ("CCode", "gir_version");
							break;
						}
					}
				}
			}
			if (gir_namespace == null) {
				continue;
			}

			provided_namespaces.add ("%s-%s".printf (gir_namespace, gir_version));

			var gir_symbol = new UnresolvedSymbol (null, gir_namespace);
			if (gir_namespace != ns.name) {
				set_symbol_mapping (gir_symbol, ns);
			}

			foreach (var node in source_file.get_nodes ()) {
				if (node.has_attribute_argument ("GIR", "name")) {
					var map_from = new UnresolvedSymbol (gir_symbol, node.get_attribute_string ("GIR", "name"));
					set_symbol_mapping (map_from, (Symbol) node);
				}
			}
		}
	}

	public override void visit_source_file (SourceFile source_file) {
		if (source_file.filename.has_suffix (".gir")) {
			parse_file (source_file);
		}
	}

	public void parse_file (SourceFile source_file) {
		metadata_stack = new ArrayList<Metadata> ();
		metadata = Metadata.empty;

		this.current_source_file = source_file;
		reader = new MarkupReader (source_file.filename);

		// xml prolog
		next ();
		next ();

		next ();
		parse_repository ();

		reader = null;
		this.current_source_file = null;
	}

	void next () {
		current_token = reader.read_token (out begin, out end);

		// Skip *all* <doc> tags
		if (current_token == MarkupTokenType.START_ELEMENT && reader.name == "doc")
			skip_element();
	}

	void start_element (string name) {
		if (current_token != MarkupTokenType.START_ELEMENT || reader.name != name) {
			// error
			Report.error (get_current_src (), "expected start element of `%s'".printf (name));
		}
	}

	void end_element (string name) {
		if (current_token != MarkupTokenType.END_ELEMENT || reader.name != name) {
			// error
			Report.error (get_current_src (), "expected end element of `%s'".printf (name));
		}
		next ();
	}

	SourceReference get_current_src () {
		return new SourceReference (this.current_source_file, begin.line, begin.column, end.line, end.column);
	}

	const string GIR_VERSION = "1.2";

	static void add_symbol_to_container (Symbol container, Symbol sym) {
		if (container is Class) {
			unowned Class cl = (Class) container;

			if (sym is Class) {
				cl.add_class ((Class) sym);
			} else if (sym is Constant) {
				cl.add_constant ((Constant) sym);
			} else if (sym is Enum) {
				cl.add_enum ((Enum) sym);
			} else if (sym is Field) {
				cl.add_field ((Field) sym);
			} else if (sym is Method) {
				cl.add_method ((Method) sym);
			} else if (sym is Property) {
				cl.add_property ((Property) sym);
			} else if (sym is Signal) {
				cl.add_signal ((Signal) sym);
			} else if (sym is Struct) {
				cl.add_struct ((Struct) sym);
			}
		} else if (container is Enum) {
			unowned Enum en = (Enum) container;

			if (sym is EnumValue) {
				en.add_value ((EnumValue) sym);
			} else if (sym is Constant) {
				en.add_constant ((Constant) sym);
			} else if (sym is Method) {
				en.add_method ((Method) sym);
			}
		} else if (container is Interface) {
			unowned Interface iface = (Interface) container;

			if (sym is Class) {
				iface.add_class ((Class) sym);
			} else if (sym is Constant) {
				iface.add_constant ((Constant) sym);
			} else if (sym is Enum) {
				iface.add_enum ((Enum) sym);
			} else if (sym is Field) {
				iface.add_field ((Field) sym);
			} else if (sym is Method) {
				iface.add_method ((Method) sym);
			} else if (sym is Property) {
				iface.add_property ((Property) sym);
			} else if (sym is Signal) {
				iface.add_signal ((Signal) sym);
			} else if (sym is Struct) {
				iface.add_struct ((Struct) sym);
			}
		} else if (container is Namespace) {
			unowned Namespace ns = (Namespace) container;

			if (sym is Namespace) {
				ns.add_namespace ((Namespace) sym);
			} else if (sym is Class) {
				ns.add_class ((Class) sym);
			} else if (sym is Constant) {
				ns.add_constant ((Constant) sym);
			} else if (sym is Delegate) {
				ns.add_delegate ((Delegate) sym);
			} else if (sym is Enum) {
				ns.add_enum ((Enum) sym);
			} else if (sym is ErrorDomain) {
				ns.add_error_domain ((ErrorDomain) sym);
			} else if (sym is Field) {
				ns.add_field ((Field) sym);
			} else if (sym is Interface) {
				ns.add_interface ((Interface) sym);
			} else if (sym is Method) {
				ns.add_method ((Method) sym);
			} else if (sym is Namespace) {
				ns.add_namespace ((Namespace) sym);
			} else if (sym is Struct) {
				ns.add_struct ((Struct) sym);
			}
		} else if (container is Struct) {
			unowned Struct st = (Struct) container;

			if (sym is Constant) {
				st.add_constant ((Constant) sym);
			} else if (sym is Field) {
				st.add_field ((Field) sym);
			} else if (sym is Method) {
				st.add_method ((Method) sym);
			} else if (sym is Property) {
				st.add_property ((Property) sym);
			}
		} else if (container is ErrorDomain) {
			unowned ErrorDomain ed = (ErrorDomain) container;

			if (sym is ErrorCode) {
				ed.add_code ((ErrorCode) sym);
			} else if (sym is Method) {
				ed.add_method ((Method) sym);
			}
		} else {
			Report.error (sym.source_reference, "impossible to add `%s' to container `%s'".printf (sym.name, container.name));
		}
	}

	static bool is_container (Symbol sym) {
		return sym is ObjectTypeSymbol || sym is Struct || sym is Namespace || sym is ErrorDomain || sym is Enum;
	}

	UnresolvedSymbol? parse_symbol_from_string (string symbol_string, SourceReference? source_reference = null) {
		UnresolvedSymbol? sym = null;
		foreach (unowned string s in symbol_string.split (".")) {
			sym = new UnresolvedSymbol (sym, s, source_reference);
		}
		if (sym == null) {
			Report.error (source_reference, "a symbol must be specified");
		}
		return sym;
	}

	void set_symbol_mapping (UnresolvedSymbol map_from, Symbol map_to) {
		// last mapping is the most up-to-date
		if (map_from is UnresolvedSymbol) {
			unresolved_symbols_map[(UnresolvedSymbol) map_from] = map_to;
		}
	}

	void assume_parameter_names (Signal sig, Symbol sym, bool skip_first) {
		Iterator<Parameter> iter;
		if (sym is Method) {
			iter = ((Method) sym).get_parameters ().iterator ();
		} else {
			iter = ((Delegate) sym).get_parameters ().iterator ();
		}
		bool first = true;
		foreach (var param in sig.get_parameters ()) {
			if (!iter.next ()) {
				// unreachable for valid GIR
				break;
			}
			if (skip_first && first) {
				if (!iter.next ()) {
					// unreachable for valid GIR
					break;
				}
				first = false;
			}
			param.name = iter.get ().name;
		}
	}

	Node? find_invoker (Node node) {
		/* most common use case is invoker has at least the given method prefix
		   and the same parameter names */
		var m = (Method) node.symbol;
		var prefix = "%s_".printf (m.name);
		foreach (var n in node.parent.members) {
			if (!n.name.has_prefix (prefix)) {
				continue;
			}
			Method? invoker = n.symbol as Method;
			if (invoker == null || (m.get_parameters().size != invoker.get_parameters().size)) {
				continue;
			}
			var iter = invoker.get_parameters ().iterator ();
			foreach (var param in m.get_parameters ()) {
				assert (iter.next ());
				if (param.name != iter.get().name)	{
					invoker = null;
					break;
				}
			}
			if (invoker != null) {
				return n;
			}
		}

		return null;
	}

	Metadata get_current_metadata () {
		var selector = reader.name;
		var child_name = reader.get_attribute ("name");
		if (child_name == null) {
			child_name = reader.get_attribute ("aroopp:name");
		}
		if (child_name == null) {
			return Metadata.empty;
		}
		selector = selector.replace ("-", "_");
		child_name = child_name.replace ("-", "_");

		if (selector.has_prefix ("aroopp:")) {
			selector = selector.substring ("aroopp:".length);
		}

		return metadata.match_child (child_name, selector);
	}

	bool push_metadata () {
		var new_metadata = get_current_metadata ();
		// skip ?
		if (new_metadata.has_argument (ArgumentType.SKIP)) {
			if (new_metadata.get_bool (ArgumentType.SKIP)) {
				return false;
			}
		} else if (reader.get_attribute ("introspectable") == "0" || reader.get_attribute ("private") == "1") {
			return false;
		}

		metadata_stack.add (metadata);
		metadata = new_metadata;

		return true;
	}

	void pop_metadata () {
		metadata = metadata_stack[metadata_stack.size - 1];
		metadata_stack.remove_at (metadata_stack.size - 1);
	}

	bool parse_type_arguments_from_string (DataType parent_type, string type_arguments, SourceReference? source_reference = null) {
		int type_arguments_length = (int) type_arguments.length;
		aroopp.StringBuilder current = new aroopp.StringBuilder.sized (type_arguments_length);

		int depth = 0;
		for (var c = 0 ; c < type_arguments_length ; c++) {
			if (type_arguments[c] == '<' || type_arguments[c] == '[') {
				depth++;
				current.append_unichar (type_arguments[c]);
			} else if (type_arguments[c] == '>' || type_arguments[c] == ']') {
				depth--;
				current.append_unichar (type_arguments[c]);
			} else if (type_arguments[c] == ',') {
				if (depth == 0) {
					var dt = parse_type_from_string (current.str, true, source_reference);
					if (dt == null) {
						return false;
					}
					parent_type.add_type_argument (dt);
					current.truncate ();
				} else {
					current.append_unichar (type_arguments[c]);
				}
			} else {
				current.append_unichar (type_arguments[c]);
			}
		}

		var dt = parse_type_from_string (current.str, true, source_reference);
		if (dt == null) {
			return false;
		}
		parent_type.add_type_argument (dt);

		return true;
	}

	DataType? parse_type_from_string (string type_string, bool owned_by_default, SourceReference? source_reference = null) {
		if (type_from_string_regex == null) {
			try {
				type_from_string_regex = new aroopp.Regex ("^(?:(owned|unowned|weak) +)?([0-9a-zA-Z_\\.]+)(?:<(.+)>)?(\\*+)?(\\[,*\\])?(\\?)?$", aroopp.RegexCompileFlags.ANCHORED | aroopp.RegexCompileFlags.DOLLAR_ENDONLY | aroopp.RegexCompileFlags.OPTIMIZE);
			} catch (aroopp.RegexError e) {
				aroopp.error ("Unable to compile regex: %s", e.message);
			}
		}

		aroopp.MatchInfo match;
		if (!type_from_string_regex.match (type_string, 0, out match)) {
			Report.error (source_reference, "unable to parse type");
			return null;
		}

		DataType? type = null;

		var ownership_data = match.fetch (1);
		var type_name = match.fetch (2);
		var type_arguments_data = match.fetch (3);
		var pointers_data = match.fetch (4);
		var array_data = match.fetch (5);
		var nullable_data = match.fetch (6);

		var nullable = nullable_data != null && nullable_data.length > 0;

		if (ownership_data == null && type_name == "void") {
			if (array_data == null && !nullable) {
				type = new VoidType (source_reference);
				if (pointers_data != null) {
					for (int i=0; i < pointers_data.length; i++) {
						type = new PointerType (type);
					}
				}
				return type;
			} else {
				Report.error (source_reference, "invalid void type");
				return null;
			}
		}

		bool value_owned = owned_by_default;

		if (ownership_data == "owned") {
			if (owned_by_default) {
				Report.error (source_reference, "unexpected `owned' keyword");
			} else {
				value_owned = true;
			}
		} else if (ownership_data == "unowned") {
			if (owned_by_default) {
				value_owned = false;
			} else {
				Report.error (source_reference, "unexpected `unowned' keyword");
				return null;
			}
		}

		var sym = parse_symbol_from_string (type_name, source_reference);
		if (sym == null) {
			return null;
		}
		type = new UnresolvedType.from_symbol (sym, source_reference);

		if (type_arguments_data != null && type_arguments_data.length > 0) {
			if (!parse_type_arguments_from_string (type, type_arguments_data, source_reference)) {
				return null;
			}
		}

		if (pointers_data != null) {
			for (int i=0; i < pointers_data.length; i++) {
				type = new PointerType (type);
			}
		}

		if (array_data != null && array_data.length != 0) {
			type = new ArrayType (type, (int) array_data.length - 1, source_reference);
		}

		type.nullable = nullable;
		type.value_owned = value_owned;
		return type;
	}

	string? element_get_string (string attribute_name, ArgumentType arg_type) {
		if (metadata.has_argument (arg_type)) {
			return metadata.get_string (arg_type);
		} else {
			return reader.get_attribute (attribute_name);
		}
	}

	/*
	 * The changed is a faster way to check whether the type has changed and it may affect the C declaration.
	 */
	DataType? element_get_type (DataType orig_type, bool owned_by_default, ref bool no_array_length, out bool changed = null) {
		changed = false;
		var type = orig_type;

		if (metadata.has_argument (ArgumentType.TYPE)) {
			type = parse_type_from_string (metadata.get_string (ArgumentType.TYPE), owned_by_default, metadata.get_source_reference (ArgumentType.TYPE));
			changed = true;
		} else if (!(type is VoidType)) {
			if (metadata.has_argument (ArgumentType.TYPE_ARGUMENTS)) {
				type.remove_all_type_arguments ();
				parse_type_arguments_from_string (type, metadata.get_string (ArgumentType.TYPE_ARGUMENTS), metadata.get_source_reference (ArgumentType.TYPE_ARGUMENTS));
			}

			if (!(type is ArrayType) && metadata.get_bool (ArgumentType.ARRAY)) {
				type = new ArrayType (type, 1, type.source_reference);
				changed = true;
			}

			if (owned_by_default) {
				type.value_owned = !metadata.get_bool (ArgumentType.UNOWNED, !type.value_owned);
			} else {
				type.value_owned = metadata.get_bool (ArgumentType.OWNED, type.value_owned);
			}
			type.nullable = metadata.get_bool (ArgumentType.NULLABLE, type.nullable);
		}

		if (type is ArrayType && !(orig_type is ArrayType)) {
			no_array_length = true;
		}

		return type;
	}

	string? element_get_name (string? gir_name = null) {
		var name = gir_name;
		if (name == null) {
			name = reader.get_attribute ("name");
		}
		var pattern = metadata.get_string (ArgumentType.NAME);
		if (pattern != null) {
			if (pattern.index_of_char ('(') < 0) {
				// shortcut for "(.+)/replacement"
				name = pattern;
			} else {
				try {
					string replacement = "\\1"; // replace the whole name with the match by default
					var split = pattern.split ("/");
					if (split.length > 1) {
						pattern = split[0];
						replacement = split[1];
					}
					var regex = new Regex (pattern, RegexCompileFlags.ANCHORED, RegexMatchFlags.ANCHORED);
					name = regex.replace (name, -1, 0, replacement);
				} catch (Error e) {
					name = pattern;
				}
			}
		} else {
			if (name != null && name.has_suffix ("Enum")) {
				name = name.substring (0, name.length - "Enum".length);
			}
		}

		return name;
	}

	void set_array_ccode (Symbol sym, ParameterInfo info) {
		sym.set_attribute_double ("CCode", "array_length_pos", info.aroopp_idx);
		if (sym is Parameter) {
			sym.set_attribute_string ("CCode", "array_length_cname", info.param.name);
		}
		var type_name = info.param.variable_type.to_qualified_string ();
		if (type_name != "int") {
			var st = root.lookup (type_name);
			if (st != null) {
				if (sym is Method) {
					var m = (Method) sym;
					m.set_attribute_string ("CCode", "array_length_type", st.get_cname ());
				} else {
					var param = (Parameter) sym;
					param.set_attribute_string ("CCode", "array_length_type", st.get_cname ());
				}
			}
		}
	}

	void parse_repository () {
		start_element ("repository");
		if (reader.get_attribute ("version") != GIR_VERSION) {
			Report.error (get_current_src (), "unsupported GIR version %s (supported: %s)".printf (reader.get_attribute ("version"), GIR_VERSION));
			return;
		}
		next ();
		while (current_token == MarkupTokenType.START_ELEMENT) {
			if (reader.name == "namespace") {
				parse_namespace ();
			} else if (reader.name == "include") {
				parse_include ();
			} else if (reader.name == "package") {
				var pkg = parse_package ();
				if (context.has_package (pkg)) {
					// package already provided elsewhere, stop parsing this GIR
					return;
				} else {
					context.add_package (pkg);
				}
			} else if (reader.name == "c:include") {
				parse_c_include ();
			} else {
				// error
				Report.error (get_current_src (), "unknown child element `%s' in `repository'".printf (reader.name));
				skip_element ();
			}
		}
		end_element ("repository");
	}

	void parse_include () {
		start_element ("include");
		var pkg = reader.get_attribute ("name");
		var version = reader.get_attribute ("version");
		if (version != null) {
			pkg = "%s-%s".printf (pkg, version);
		}
		// add the package to the queue
		context.add_external_package (pkg);
		next ();
		end_element ("include");
	}

	string parse_package () {
		start_element ("package");
		var pkg = reader.get_attribute ("name");
		next ();
		end_element ("package");
		return pkg;
	}

	void parse_c_include () {
		start_element ("c:include");
		cheader_filenames += reader.get_attribute ("name");
		next ();
		end_element ("c:include");
	}

	void skip_element () {
		next ();

		int level = 1;
		while (level > 0) {
			if (current_token == MarkupTokenType.START_ELEMENT) {
				level++;
			} else if (current_token == MarkupTokenType.END_ELEMENT) {
				level--;
			} else if (current_token == MarkupTokenType.EOF) {
				Report.error (get_current_src (), "unexpected end of file");
				break;
			}
			next ();
		}
	}

	Node? resolve_node (Node parent_scope, UnresolvedSymbol unresolved_sym, bool create_namespace = false) {
		if (unresolved_sym.inner == null) {
			var scope = parent_scope;
			while (scope != null) {
				var node = scope.lookup (unresolved_sym.name, create_namespace, unresolved_sym.source_reference);
				if (node != null) {
					return node;
				}
				scope = scope.parent;
			}
		} else {
			var inner = resolve_node (parent_scope, unresolved_sym.inner, create_namespace);
			if (inner != null) {
				return inner.lookup (unresolved_sym.name, create_namespace, unresolved_sym.source_reference);
			}
		}
		return null;
	}

	Symbol? resolve_symbol (Node parent_scope, UnresolvedSymbol unresolved_sym) {
		var node = resolve_node (parent_scope, unresolved_sym);
		if (node != null) {
			return node.symbol;
		}
		return null;
	}

	void push_node (string name, bool merge) {
		var parent = current;
		if (metadata.has_argument (ArgumentType.PARENT)) {
			var target = parse_symbol_from_string (metadata.get_string (ArgumentType.PARENT), metadata.get_source_reference (ArgumentType.PARENT));
			parent = resolve_node (root, target, true);
		}

		var node = parent.lookup (name);
		if (node == null || (node.symbol != null && !merge)) {
			node = new Node (name);
			node.new_symbol = true;
			parent.add_member (node);
		} else {
			Node.new_namespaces.remove (node);
		}
		node.element_type = reader.name;
		node.girdata = reader.get_attributes ();
		node.metadata = metadata;
		node.source_reference = get_current_src ();

		var gir_name = node.get_gir_name ();
		if (parent != current || gir_name != name) {
			set_symbol_mapping (new UnresolvedSymbol (null, gir_name), node.get_unresolved_symbol ());
		}

		tree_stack.add (current);
		current = node;
	}

	void pop_node () {
		old_current = current;
		current = tree_stack[tree_stack.size - 1];
		tree_stack.remove_at (tree_stack.size - 1);
	}

	void parse_namespace () {
		start_element ("namespace");

		string? cprefix = reader.get_attribute ("c:identifier-prefixes");
		string? lower_case_cprefix = reader.get_attribute ("c:symbol-prefixes");
		string aroopp_namespace = cprefix;
		string gir_namespace = reader.get_attribute ("name");
		string gir_version = reader.get_attribute ("version");

		if (provided_namespaces.contains ("%s-%s".printf (gir_namespace, gir_version))) {
			skip_element ();
			return;
		}

		// load metadata, first look into metadata directories then in the same directory of the .gir.
		string? metadata_filename = context.get_metadata_path (current_source_file.filename);
		if (metadata_filename != null && FileUtils.test (metadata_filename, FileTest.EXISTS)) {
			var metadata_parser = new MetadataParser ();
			var metadata_file = new SourceFile (context, current_source_file.file_type, metadata_filename);
			context.add_source_file (metadata_file);
			metadata = metadata_parser.parse_metadata (metadata_file);
			metadata_roots.add (metadata);
		}

		var ns_metadata = metadata.match_child (gir_namespace);
		if (ns_metadata.has_argument (ArgumentType.NAME)) {
			aroopp_namespace = ns_metadata.get_string (ArgumentType.NAME);
		}
		if (aroopp_namespace == null) {
			aroopp_namespace = gir_namespace;
		}

		current_source_file.gir_namespace = gir_namespace;
		current_source_file.gir_version = gir_version;

		Namespace ns;
		push_node (aroopp_namespace, true);
		if (current.new_symbol) {
			ns = new Namespace (aroopp_namespace, current.source_reference);
			current.symbol = ns;
		} else {
			ns = (Namespace) current.symbol;
			ns.attributes = null;
			ns.source_reference = current.source_reference;
		}

		current.metadata = ns_metadata;

		if (ns_metadata.has_argument (ArgumentType.CPREFIX)) {
			cprefix = ns_metadata.get_string (ArgumentType.CPREFIX);
		}

		if (ns_metadata.has_argument (ArgumentType.LOWER_CASE_CPREFIX)) {
			lower_case_cprefix = ns_metadata.get_string (ArgumentType.LOWER_CASE_CPREFIX);
		} else if (lower_case_cprefix != null) {
			lower_case_cprefix += "_";
		}

		ns.set_attribute_string ("CCode", "gir_namespace", gir_namespace);
		ns.set_attribute_string ("CCode", "gir_version", gir_version);

		if (cprefix != null) {
			ns.set_attribute_string ("CCode", "cprefix", cprefix);
			if (lower_case_cprefix == null) {
				ns.set_attribute_string ("CCode", "lower_case_cprefix", Symbol.camel_case_to_lower_case (cprefix) + "_");
			}
		}

		if (lower_case_cprefix != null) {
			ns.set_attribute_string ("CCode", "lower_case_cprefix", lower_case_cprefix);
		}

		if (cheader_filenames != null) {
			ns.set_attribute_string ("CCode", "cheader_filename", string.joinv (",", cheader_filenames));
		}

		next ();
		while (current_token == MarkupTokenType.START_ELEMENT) {
			if (!push_metadata ()) {
				skip_element ();
				continue;
			}

			if (reader.name == "alias") {
				parse_alias ();
			} else if (reader.name == "enumeration") {
				if (metadata.has_argument (ArgumentType.ERRORDOMAIN)) {
					if (metadata.get_bool (ArgumentType.ERRORDOMAIN)) {
						parse_error_domain ();
					} else {
						parse_enumeration ();
					}
				} else {
					if ((reader.get_attribute ("aroopp:error-quark") != null) || (reader.get_attribute ("aroopp:error-domain") != null)) {
						parse_error_domain ();
					} else {
						parse_enumeration ();
					}
				}
			} else if (reader.name == "bitfield") {
				parse_bitfield ();
			} else if (reader.name == "function") {
				parse_method ("function");
			} else if (reader.name == "callback") {
				parse_callback ();
			} else if (reader.name == "record") {
				if (metadata.has_argument (ArgumentType.STRUCT)) {
					if (metadata.get_bool (ArgumentType.STRUCT)) {
						parse_record ();
					} else {
						parse_boxed ("record");
					}
				} else if (reader.get_attribute ("aroopp:get-type") != null) {
					parse_boxed ("record");
				} else if (!reader.get_attribute ("name").has_suffix ("Private")) {
					if (reader.get_attribute ("aroopp:is-gtype-struct-for") == null && reader.get_attribute ("disguised") == "1") {
						parse_boxed ("record");
					} else {
						parse_record ();
					}
				} else {
					skip_element ();
				}
			} else if (reader.name == "class") {
				parse_class ();
			} else if (reader.name == "interface") {
				parse_interface ();
			} else if (reader.name == "aroopp:boxed") {
				parse_boxed ("aroopp:boxed");
			} else if (reader.name == "union") {
				if (reader.get_attribute ("aroopp:get-type") != null && !metadata.get_bool (ArgumentType.STRUCT)) {
					parse_boxed ("union");
				} else {
					parse_union ();
				}
			} else if (reader.name == "constant") {
				parse_constant ();
			} else {
				// error
				Report.error (get_current_src (), "unknown child element `%s' in `namespace'".printf (reader.name));
				skip_element ();
			}

			pop_metadata ();
		}
		pop_node ();
		end_element ("namespace");
	}

	void parse_alias () {
		start_element ("alias");
		push_node (element_get_name (), true);
		// not enough information, symbol will be created while processing the tree

		next ();
		bool no_array_length = false;
		current.base_type = element_get_type (parse_type (null, null, true), true, ref no_array_length);

		pop_node ();
		end_element ("alias");
	}

	private void calculate_common_prefix (ref string common_prefix, string cname) {
		if (common_prefix == null) {
			common_prefix = cname;
			while (common_prefix.length > 0 && !common_prefix.has_suffix ("_")) {
				// FIXME: could easily be made faster
				common_prefix = common_prefix.substring (0, common_prefix.length - 1);
			}
		} else {
			while (!cname.has_prefix (common_prefix)) {
				common_prefix = common_prefix.substring (0, common_prefix.length - 1);
			}
		}
		while (common_prefix.length > 0 && (!common_prefix.has_suffix ("_") ||
		       (cname.get_char (common_prefix.length).isdigit ()) && (cname.length - common_prefix.length) <= 1)) {
			// enum values may not consist solely of digits
			common_prefix = common_prefix.substring (0, common_prefix.length - 1);
		}
	}

	void parse_enumeration (string element_name = "enumeration", bool error_domain = false) {
		start_element (element_name);
		push_node (element_get_name (), true);

		Symbol sym;
		if (current.new_symbol) {
			if (error_domain) {
				sym = new ErrorDomain (current.name, current.source_reference);
			} else {
				var en = new Enum (current.name, current.source_reference);
				if (element_name == "bitfield") {
					en.set_attribute ("Flags", true);
				}
				sym = en;
			}
			current.symbol = sym;
		} else {
			sym = current.symbol;
		}
		sym.external = true;
		sym.access = SymbolAccessibility.PUBLIC;

		string common_prefix = null;

		next ();
		
		while (current_token == MarkupTokenType.START_ELEMENT) {
			if (!push_metadata ()) {
				skip_element ();
				continue;
			}

			if (reader.name == "member") {
				if (error_domain) {
					parse_error_member ();
					calculate_common_prefix (ref common_prefix, old_current.get_cname ());
				} else {
					parse_enumeration_member ();
					calculate_common_prefix (ref common_prefix, old_current.get_cname ());
				}
			} else if (reader.name == "function") {
				skip_element ();
			} else {
				// error
				Report.error (get_current_src (), "unknown child element `%s' in `%s'".printf (reader.name, element_name));
				skip_element ();
			}

			pop_metadata ();
		}

		if (common_prefix != null) {
			sym.set_attribute_string ("CCode", "cprefix", common_prefix);
		}

		pop_node ();
		end_element (element_name);
	}

	void parse_error_domain () {
		parse_enumeration ("enumeration", true);
	}

	void parse_bitfield () {
		parse_enumeration ("bitfield");
	}

	void parse_enumeration_member () {
		start_element ("member");
		push_node (element_get_name().up().replace ("-", "_"), false);

		var ev = new EnumValue (current.name, metadata.get_expression (ArgumentType.DEFAULT), current.source_reference);
		current.symbol = ev;
		next ();

		pop_node ();
		end_element ("member");
	}

	void parse_error_member () {
		start_element ("member");
		push_node (element_get_name().up().replace ("-", "_"), false);

		ErrorCode ec;
		string value = reader.get_attribute ("value");
		if (value != null) {
			ec = new ErrorCode.with_value (current.name, new IntegerLiteral (value));
		} else {
			ec = new ErrorCode (current.name);
		}
		current.symbol = ec;
		next ();

		pop_node ();
		end_element ("member");
	}

	DataType parse_return_value (out string? ctype = null, out int array_length_idx = null, out bool no_array_length = null, out bool array_null_terminated = null) {
		start_element ("return-value");

		string transfer = reader.get_attribute ("transfer-ownership");
		string allow_none = reader.get_attribute ("allow-none");
		next ();
		var transfer_elements = transfer != "container";
		var type = parse_type (out ctype, out array_length_idx, transfer_elements, out no_array_length, out array_null_terminated);
		if (transfer == "full" || transfer == "container") {
			type.value_owned = true;
		}
		if (allow_none == "1") {
			type.nullable = true;
		}
		type = element_get_type (type, true, ref no_array_length);
		end_element ("return-value");
		return type;
	}

	Parameter parse_parameter (out int array_length_idx = null, out int closure_idx = null, out int destroy_idx = null, out string? scope = null, string? default_name = null) {
		Parameter param;

		array_length_idx = -1;
		closure_idx = -1;
		destroy_idx = -1;

		start_element ("parameter");
		string name = reader.get_attribute ("name");
		if (name == null) {
			name = default_name;
		}
		string direction = null;
		if (metadata.has_argument (ArgumentType.OUT)) {
			if (metadata.get_bool (ArgumentType.OUT)) {
				direction = "out";
			} // null otherwise
		} else if (metadata.has_argument (ArgumentType.REF)) {
			if (metadata.get_bool (ArgumentType.REF)) {
				direction = "inout";
			} // null otherwise
		} else {
			direction = reader.get_attribute ("direction");
		}
		string transfer = reader.get_attribute ("transfer-ownership");
		string allow_none = reader.get_attribute ("allow-none");

		scope = element_get_string ("scope", ArgumentType.SCOPE);

		string closure = reader.get_attribute ("closure");
		string destroy = reader.get_attribute ("destroy");
		if (closure != null && &closure_idx != null) {
			closure_idx = int.parse (closure);
		}
		if (destroy != null && &destroy_idx != null) {
			destroy_idx = int.parse (destroy);
		}
		if (metadata.has_argument (ArgumentType.CLOSURE)) {
			closure_idx = metadata.get_integer (ArgumentType.CLOSURE);
		}

		next ();
		if (reader.name == "varargs") {
			start_element ("varargs");
			next ();
			param = new Parameter.with_ellipsis (get_current_src ());
			end_element ("varargs");
		} else {
			string ctype;
			bool no_array_length;
			bool array_null_terminated;
			var type = parse_type (out ctype, out array_length_idx, transfer != "container", out no_array_length, out array_null_terminated);
			if (transfer == "full" || transfer == "container" || destroy != null) {
				type.value_owned = true;
			}
			if (allow_none == "1" && direction != "out") {
				type.nullable = true;
			}

			bool changed;
			type = element_get_type (type, direction == "out" || direction == "inout", ref no_array_length, out changed);
			if (!changed) {
				// discard ctype, duplicated information
				ctype = null;
			}

			param = new Parameter (name, type, get_current_src ());
			if (ctype != null) {
				param.set_attribute_string ("CCode", "type", ctype);
			}
			if (direction == "out") {
				param.direction = ParameterDirection.OUT;
			} else if (direction == "inout") {
				param.direction = ParameterDirection.REF;
			}
			if (type is ArrayType) {
				if (metadata.has_argument (ArgumentType.ARRAY_LENGTH_IDX)) {
					array_length_idx = metadata.get_integer (ArgumentType.ARRAY_LENGTH_IDX);
				} else {
					if (no_array_length) {
						param.set_attribute_bool ("CCode", "array_length", false);
					}
					if (array_null_terminated) {
						param.set_attribute_bool ("CCode", "array_null_terminated", array_null_terminated);
					}
				}
			}
			param.initializer = metadata.get_expression (ArgumentType.DEFAULT);
		}
		end_element ("parameter");
		return param;
	}

	DataType parse_type (out string? ctype = null, out int array_length_idx = null, bool transfer_elements = true, out bool no_array_length = null, out bool array_null_terminated = null) {
		bool is_array = false;
		string type_name = reader.get_attribute ("name");
		ctype = null;

		array_length_idx = -1;
		no_array_length = true;
		array_null_terminated = true;

		if (reader.name == "array") {
			is_array = true;
			start_element ("array");

			var src = get_current_src ();

			if (type_name == null) {
				if (reader.get_attribute ("length") != null) {
					array_length_idx = int.parse (reader.get_attribute ("length"));
					no_array_length = false;
					array_null_terminated = false;
				}
				if (reader.get_attribute ("fixed-size") != null) {
					array_null_terminated = false;
				}
				if (reader.get_attribute ("c:type") == "GStrv") {
					no_array_length = true;
					array_null_terminated = true;
				}
				if (reader.get_attribute ("zero-terminated") != null) {
					array_null_terminated = int.parse (reader.get_attribute ("zero-terminated")) != 0;
				}
				next ();
				var element_type = parse_type ();
				end_element ("array");
				return new ArrayType (element_type, 1, src);
			}
		} else if (reader.name == "callback"){
			parse_callback ();
			return new DelegateType ((Delegate) old_current.symbol);
		} else {
			start_element ("type");
		}

		ctype = reader.get_attribute("c:type");

		next ();

		if (type_name == "aroopp.PtrArray"
		    && current_token == MarkupTokenType.START_ELEMENT) {
			type_name = "aroopp.GenericArray";
		}

		DataType type = parse_type_from_gir_name (type_name, out no_array_length, out array_null_terminated, ctype);

		// type arguments / element types
		while (current_token == MarkupTokenType.START_ELEMENT) {
			if (type_name == "aroopp.ByteArray") {
				skip_element ();
				continue;
			}
			var element_type = parse_type ();
			element_type.value_owned = transfer_elements;
			type.add_type_argument (element_type);
		}

		end_element (is_array ? "array" : "type");
		return type;
	}

	DataType parse_type_from_gir_name (string type_name, out bool no_array_length = null, out bool array_null_terminated = null, string? ctype = null) {
		no_array_length = false;
		array_null_terminated = false;

		DataType type;
		if (type_name == "none") {
			type = new VoidType (get_current_src ());
		} else if (type_name == "gpointer") {
			type = new PointerType (new VoidType (get_current_src ()), get_current_src ());
		} else if (type_name == "GObject.Strv") {
			type = new ArrayType (new UnresolvedType.from_symbol (new UnresolvedSymbol (null, "string")), 1, get_current_src ());
			no_array_length = true;
			array_null_terminated = true;
		} else {
			bool known_type = true;
			if (type_name == "utf8") {
				type_name = "string";
			} else if (type_name == "gboolean") {
				type_name = "bool";
			} else if (type_name == "gchar") {
				type_name = "char";
			} else if (type_name == "gshort") {
				type_name = "short";
			} else if (type_name == "gushort") {
				type_name = "ushort";
			} else if (type_name == "gint") {
				type_name = "int";
			} else if (type_name == "guint") {
				type_name = "uint";
			} else if (type_name == "glong") {
				if (ctype != null && ctype.has_prefix ("gssize")) {
					type_name = "ssize_t";
				} else {
					type_name = "long";
				}
			} else if (type_name == "gulong") {
				if (ctype != null && ctype.has_prefix ("gsize")) {
					type_name = "size_t";
				} else {
					type_name = "ulong";
				}
			} else if (type_name == "gint8") {
				type_name = "int8";
			} else if (type_name == "guint8") {
				type_name = "uint8";
			} else if (type_name == "gint16") {
				type_name = "int16";
			} else if (type_name == "guint16") {
				type_name = "uint16";
			} else if (type_name == "gint32") {
				type_name = "int32";
			} else if (type_name == "guint32") {
				type_name = "uint32";
			} else if (type_name == "gint64") {
				type_name = "int64";
			} else if (type_name == "guint64") {
				type_name = "uint64";
			} else if (type_name == "gfloat") {
				type_name = "float";
			} else if (type_name == "gdouble") {
				type_name = "double";
			} else if (type_name == "filename") {
				type_name = "string";
			} else if (type_name == "aroopp.offset") {
				type_name = "int64";
			} else if (type_name == "gsize") {
				type_name = "size_t";
			} else if (type_name == "gssize") {
				type_name = "ssize_t";
			} else if (type_name == "GType") {
				type_name = "aroopp.Type";
			} else if (type_name == "aroopp.String") {
				type_name = "aroopp.StringBuilder";
			} else if (type_name == "GObject.Class") {
				type_name = "aroopp.ObjectClass";
			} else if (type_name == "gunichar") {
				type_name = "unichar";
			} else if (type_name == "aroopp.Data") {
				type_name = "aroopp.Datalist";
			} else if (type_name == "Atk.ImplementorIface") {
				type_name = "Atk.Implementor";
			} else {
				known_type = false;
			}
			var sym = parse_symbol_from_string (type_name, get_current_src ());
			type = new UnresolvedType.from_symbol (sym, get_current_src ());
			if (!known_type) {
				unresolved_gir_symbols.add (sym);
			}
		}

		return type;
	}

	void parse_record () {
		start_element ("record");
		push_node (element_get_name (), true);

		Struct st;
		if (current.new_symbol) {
			st = new Struct (element_get_name (), current.source_reference);
			current.symbol = st;
			var type_id = reader.get_attribute ("aroopp:get-type");
			if (type_id == null) {
				st.set_attribute_bool ("CCode", "has_type_id", false);
			} else {
				st.set_attribute_string ("CCode", "type_id", "%s ()".printf (type_id));
			}
		} else {
			st = (Struct) current.symbol;
		}
		st.external = true;
		st.access = SymbolAccessibility.PUBLIC;

		var gtype_struct_for = reader.get_attribute ("aroopp:is-gtype-struct-for");
		if (gtype_struct_for != null) {
			current.gtype_struct_for = parse_symbol_from_string (gtype_struct_for, current.source_reference);
			unresolved_gir_symbols.add (current.gtype_struct_for);
		}

		bool first_field = true;
		next ();
		while (current_token == MarkupTokenType.START_ELEMENT) {
			if (!push_metadata ()) {
				if (first_field && reader.name == "field") {
					first_field = false;
				}
				skip_element ();
				continue;
			}

			if (reader.name == "field") {
				if (reader.get_attribute ("name") != "priv" && !(first_field && gtype_struct_for != null)) {
					parse_field ();
				} else {
					skip_element ();
				}
				first_field = false;
			} else if (reader.name == "constructor") {
				parse_constructor ();
			} else if (reader.name == "method") {
				parse_method ("method");
			} else if (reader.name == "function") {
				skip_element ();
			} else if (reader.name == "union") {
				parse_union ();
			} else {
				// error
				Report.error (get_current_src (), "unknown child element `%s' in `record'".printf (reader.name));
				skip_element ();
			}

			pop_metadata ();
		}

		pop_node ();
		end_element ("record");
	}

	void parse_class () {
		start_element ("class");
		push_node (element_get_name (), true);

		Class cl;
		var parent = reader.get_attribute ("parent");
		if (current.new_symbol) {
			cl = new Class (current.name, current.source_reference);
			cl.set_attribute_string ("CCode", "type_id", "%s ()".printf (reader.get_attribute ("aroopp:get-type")));
			cl.is_abstract = reader.get_attribute ("abstract") == "1";

			if (parent != null) {
				cl.add_base_type (parse_type_from_gir_name (parent));
			}
			current.symbol = cl;
		} else {
			cl = (Class) current.symbol;
		}
		cl.access = SymbolAccessibility.PUBLIC;
		cl.external = true;

		next ();
		var first_field = true;
		while (current_token == MarkupTokenType.START_ELEMENT) {
			if (!push_metadata ()) {
				if (first_field && reader.name == "field") {
					first_field = false;
				}
				skip_element ();
				continue;
			}

			if (reader.name == "implements") {
				start_element ("implements");
				cl.add_base_type (parse_type_from_gir_name (reader.get_attribute ("name")));
				next ();
				end_element ("implements");
			} else if (reader.name == "constant") {
				parse_constant ();
			} else if (reader.name == "field") {
				if (first_field && parent != null) {
					// first field is guaranteed to be the parent instance
					skip_element ();
				} else {
					if (reader.get_attribute ("name") != "priv") {
						parse_field ();
					} else {
						skip_element ();
					}
				}
				first_field = false;
			} else if (reader.name == "property") {
				parse_property ();
			} else if (reader.name == "constructor") {
				parse_constructor ();
			} else if (reader.name == "function") {
				parse_method ("function");
			} else if (reader.name == "method") {
				parse_method ("method");
			} else if (reader.name == "virtual-method") {
				parse_method ("virtual-method");
			} else if (reader.name == "union") {
				parse_union ();
			} else if (reader.name == "aroopp:signal") {
				parse_signal ();
			} else {
				// error
				Report.error (get_current_src (), "unknown child element `%s' in `class'".printf (reader.name));
				skip_element ();
			}

			pop_metadata ();
		}

		pop_node ();
		end_element ("class");
	}

	void parse_interface () {
		start_element ("interface");
		push_node (element_get_name (), true);

		Interface iface;
		if (current.new_symbol) {
			iface = new Interface (current.name, current.source_reference);
			var typeid = reader.get_attribute ("aroopp:get-type");
			if (typeid != null) {
				iface.set_attribute_string ("CCode", "type_id", "%s ()".printf (typeid));
			}

			current.symbol = iface;
		} else {
			iface = (Interface) current.symbol;
		}

		iface.access = SymbolAccessibility.PUBLIC;
		iface.external = true;


		next ();
		while (current_token == MarkupTokenType.START_ELEMENT) {
			if (!push_metadata ()) {
				skip_element ();
				continue;
			}

			if (reader.name == "prerequisite") {
				start_element ("prerequisite");
				iface.add_prerequisite (parse_type_from_gir_name (reader.get_attribute ("name")));
				next ();
				end_element ("prerequisite");
			} else if (reader.name == "field") {
				parse_field ();
			} else if (reader.name == "property") {
				parse_property ();
			} else if (reader.name == "virtual-method") {
				parse_method ("virtual-method");
			} else if (reader.name == "function") {
				parse_method ("function");
			} else if (reader.name == "method") {
				parse_method ("method");
			} else if (reader.name == "aroopp:signal") {
				parse_signal ();
			} else {
				// error
				Report.error (get_current_src (), "unknown child element `%s' in `interface'".printf (reader.name));
				skip_element ();
			}

			pop_metadata ();
		}

		pop_node ();
		end_element ("interface");
	}

	void parse_field () {
		start_element ("field");
		push_node (element_get_name (), false);

		string allow_none = reader.get_attribute ("allow-none");
		next ();
		var type = parse_type ();
		bool no_array_length = true;
		type = element_get_type (type, true, ref no_array_length);

		var field = new Field (current.name, type, null, current.source_reference);
		field.access = SymbolAccessibility.PUBLIC;
		if (type is ArrayType) {
			if (no_array_length) {
				field.set_attribute_bool ("CCode", "array_length", false);
			}
			field.set_attribute_bool ("CCode", "array_null_terminated", true);
		}
		if (allow_none == "1") {
			type.nullable = true;
		}
		current.symbol = field;

		pop_node ();
		end_element ("field");
	}

	Property parse_property () {
		start_element ("property");
		push_node (element_get_name().replace ("-", "_"), false);

		next ();
		bool no_array_length;
		bool array_null_terminated;
		var type = parse_type (null, null, false, out no_array_length, out array_null_terminated);
		type = element_get_type (type, true, ref no_array_length);
		var prop = new Property (current.name, type, null, null, current.source_reference);
		prop.access = SymbolAccessibility.PUBLIC;
		prop.external = true;
		if (current.parent.symbol is Interface) {
			prop.is_abstract = true;
		}
		if (no_array_length) {
			prop.set_attribute_bool ("CCode", "array_length", false);
		}
		if (array_null_terminated) {
			prop.set_attribute_bool ("CCode", "array_null_terminated", true);
		}
		current.symbol = prop;

		pop_node ();
		end_element ("property");
		return prop;
	}

	void parse_callback () {
		parse_function ("callback");
	}

	void parse_constructor () {
		parse_function ("constructor");
	}

	class ParameterInfo {
		public ParameterInfo (Parameter param, int array_length_idx, int closure_idx, int destroy_idx) {
			this.param = param;
			this.array_length_idx = array_length_idx;
			this.closure_idx = closure_idx;
			this.destroy_idx = destroy_idx;
			this.aroopp_idx = 0.0F;
			this.keep = true;
		}

		public Parameter param;
		public float aroopp_idx;
		public int array_length_idx;
		public int closure_idx;
		public int destroy_idx;
		public bool keep;
	}

	void parse_function (string element_name) {
		start_element (element_name);
		push_node (element_get_name (reader.get_attribute ("invoker")).replace ("-", "_"), false);

		string name = current.name;
		string throws_string = reader.get_attribute ("throws");
		string invoker = reader.get_attribute ("invoker");

		next ();
		DataType return_type;
		string return_ctype = null;
		int return_array_length_idx = -1;
		bool return_no_array_length = false;
		bool return_array_null_terminated = false;
		if (current_token == MarkupTokenType.START_ELEMENT && reader.name == "return-value") {
			return_type = parse_return_value (out return_ctype, out return_array_length_idx, out return_no_array_length, out return_array_null_terminated);
		} else {
			return_type = new VoidType ();
		}

		Symbol s;

		if (element_name == "callback") {
			s = new Delegate (name, return_type, current.source_reference);
			((Delegate) s).has_target = false;
		} else if (element_name == "constructor") {
			if (name == "new") {
				name = null;
			} else if (name.has_prefix ("new_")) {
				name = name.substring ("new_".length);
			}
			var m = new CreationMethod (null, name, current.source_reference);
			m.has_construct_function = false;

			string parent_ctype = null;
			if (current.parent.symbol is Class) {
				parent_ctype = current.parent.get_cname ();
			}
			if (return_ctype != null && (parent_ctype == null || return_ctype != parent_ctype + "*")) {
				m.set_attribute_string ("CCode", "type", return_ctype);
			}
			s = m;
		} else if (element_name == "aroopp:signal") {
			s = new Signal (name, return_type, current.source_reference);
		} else {
			s = new Method (name, return_type, current.source_reference);
		}

		s.access = SymbolAccessibility.PUBLIC;
		s.external = true;

		if (s is Method) {
			var m = (Method) s;
			if (element_name == "virtual-method" || element_name == "callback") {
				if (current.parent.symbol is Interface) {
					m.is_abstract = true;
				} else {
					m.is_virtual = true;
				}
				if (invoker == null && !metadata.has_argument (ArgumentType.VFUNC_NAME)) {
					s.set_attribute ("NoWrapper", true, s.source_reference);
				} else {
					if (current.girdata["name"] != name) {
						m.set_attribute_string ("CCode", "vfunc_name", current.girdata["name"]);
					}
				}
			} else if (element_name == "function") {
				m.binding = MemberBinding.STATIC;
			}
		}

		if (s is Method && !(s is CreationMethod)) {
			var method = (Method) s;
			if (metadata.has_argument (ArgumentType.VIRTUAL)) {
				method.is_virtual = metadata.get_bool (ArgumentType.VIRTUAL);
				method.is_abstract = false;
			} else if (metadata.has_argument (ArgumentType.ABSTRACT)) {
				method.is_abstract = metadata.get_bool (ArgumentType.ABSTRACT);
				method.is_virtual = false;
			}
			if (metadata.has_argument (ArgumentType.VFUNC_NAME)) {
				method.set_attribute_string ("CCode", "vfunc_name", metadata.get_string (ArgumentType.VFUNC_NAME));
				method.is_virtual = true;
			}
		}

		if (!(metadata.get_expression (ArgumentType.THROWS) is NullLiteral)) {
			if (metadata.has_argument (ArgumentType.THROWS)) {
				var error_types = metadata.get_string(ArgumentType.THROWS).split(",");
				foreach (var error_type in error_types) {
					s.add_error_type (parse_type_from_string (error_type, true, metadata.get_source_reference (ArgumentType.THROWS)));
				}
			} else if (throws_string == "1") {
				s.add_error_type (new ErrorType (null, null));
			}
		}

		if (s is Method) {
			var m = (Method) s;
			m.set_attribute ("PrintfFormat", metadata.get_bool (ArgumentType.PRINTF_FORMAT));
			if (metadata.has_argument (ArgumentType.SENTINEL)) {
				m.set_attribute_string ("CCode", "sentinel", metadata.get_string (ArgumentType.SENTINEL));
			}
		}

		if (return_type is ArrayType && metadata.has_argument (ArgumentType.ARRAY_LENGTH_IDX)) {
			return_array_length_idx = metadata.get_integer (ArgumentType.ARRAY_LENGTH_IDX);
		} else {
			if (return_no_array_length) {
				s.set_attribute_bool ("CCode", "array_length", false);
			}
			if (return_array_null_terminated) {
				s.set_attribute_bool ("CCode", "array_null_terminated", true);
			}
		}
		current.return_array_length_idx = return_array_length_idx;

		current.symbol = s;

		var parameters = new ArrayList<ParameterInfo> ();
		current.array_length_parameters = new ArrayList<int> ();
		current.closure_parameters = new ArrayList<int> ();
		current.destroy_parameters = new ArrayList<int> ();
		if (current_token == MarkupTokenType.START_ELEMENT && reader.name == "parameters") {
			start_element ("parameters");
			next ();

			while (current_token == MarkupTokenType.START_ELEMENT) {
				if (!push_metadata ()) {
					skip_element ();
					continue;
				}

				int array_length_idx, closure_idx, destroy_idx;
				string scope;
				string default_param_name = null;
				default_param_name = "arg%d".printf (parameters.size);
				var param = parse_parameter (out array_length_idx, out closure_idx, out destroy_idx, out scope, default_param_name);
				if (array_length_idx != -1) {
					current.array_length_parameters.add (array_length_idx);
				}
				if (closure_idx != -1) {
					current.closure_parameters.add (closure_idx);
				}
				if (destroy_idx != -1) {
					current.destroy_parameters.add (destroy_idx);
				}

				var info = new ParameterInfo (param, array_length_idx, closure_idx, destroy_idx);

				if (s is Method && scope == "async") {
					var unresolved_type = param.variable_type as UnresolvedType;
					if (unresolved_type != null && unresolved_type.unresolved_symbol.name == "AsyncReadyCallback") {
						// GAsync-style method
						((Method) s).coroutine = true;
						info.keep = false;
					}
				}

				parameters.add (info);
				pop_metadata ();
			}
			end_element ("parameters");
		}
		current.parameters = parameters;

		pop_node ();
		end_element (element_name);
	}

	void parse_method (string element_name) {
		parse_function (element_name);
	}

	void parse_signal () {
		parse_function ("aroopp:signal");
	}

	void parse_boxed (string element_name) {
		start_element (element_name);
		string name = reader.get_attribute ("name");
		if (name == null) {
			name = reader.get_attribute ("aroopp:name");
		}
		push_node (element_get_name (name), true);

		Class cl;
		if (current.new_symbol) {
			cl = new Class (current.name, current.source_reference);
			cl.is_compact = true;
			var typeid = reader.get_attribute ("aroopp:get-type");
			if (typeid != null) {
				cl.set_attribute_string ("CCode", "type_id", "%s ()".printf (typeid));
				cl.set_attribute_string ("CCode", "free_function", "g_boxed_free");
				cl.set_attribute_string ("CCode", "copy_function", "g_boxed_copy");
			}

			current.symbol = cl;
		} else {
			cl = (Class) current.symbol;
		}
		cl.access = SymbolAccessibility.PUBLIC;
		cl.external = true;

		next ();
		while (current_token == MarkupTokenType.START_ELEMENT) {
			if (!push_metadata ()) {
				skip_element ();
				continue;
			}

			if (reader.name == "field") {
				parse_field ();
			} else if (reader.name == "constructor") {
				parse_constructor ();
			} else if (reader.name == "method") {
				parse_method ("method");
			} else if (reader.name == "function") {
				skip_element ();
			} else if (reader.name == "union") {
				parse_union ();
			} else {
				// error
				Report.error (get_current_src (), "unknown child element `%s' in `class'".printf (reader.name));
				skip_element ();
			}

			pop_metadata ();
		}

		pop_node ();
		end_element (element_name);
	}

	void parse_union () {
		start_element ("union");
		push_node (element_get_name (), true);

		Struct st;
		if (current.new_symbol) {
			st = new Struct (reader.get_attribute ("name"), current.source_reference);
			current.symbol = st;
		} else {
			st = (Struct) current.symbol;
		}
		st.access = SymbolAccessibility.PUBLIC;
		st.external = true;

		next ();
		while (current_token == MarkupTokenType.START_ELEMENT) {
			if (!push_metadata ()) {
				skip_element ();
				continue;
			}

			if (reader.name == "field") {
				parse_field ();
			} else if (reader.name == "constructor") {
				parse_constructor ();
			} else if (reader.name == "method") {
				parse_method ("method");
			} else if (reader.name == "function") {
				skip_element ();
			} else if (reader.name == "record") {
				parse_record ();
			} else {
				// error
				Report.error (get_current_src (), "unknown child element `%s' in `union'".printf (reader.name));
				skip_element ();
			}

			pop_metadata ();
		}

		pop_node ();
		end_element ("union");
	}

	void parse_constant () {
		start_element ("constant");
		push_node (element_get_name (), false);

		next ();
		var type = parse_type ();
		var c = new Constant (current.name, type, null, current.source_reference);
		current.symbol = c;
		c.access = SymbolAccessibility.PUBLIC;
		c.external = true;

		pop_node ();
		end_element ("constant");
	}

	/* Reporting */
	void report_unused_metadata (Metadata metadata) {
		if (metadata == Metadata.empty) {
			return;
		}

		if (metadata.args.size == 0 && metadata.children.size == 0) {
			Report.warning (metadata.source_reference, "empty metadata");
			return;
		}

		foreach (var arg_type in metadata.args.get_keys ()) {
			var arg = metadata.args[arg_type];
			if (!arg.used) {
				// if metadata is used and argument is not, then it's a unexpected argument
				Report.warning (arg.source_reference, "argument never used");
			}
		}

		foreach (var child in metadata.children) {
			if (!child.used) {
				Report.warning (child.source_reference, "metadata never used");
			} else {
				report_unused_metadata (child);
			}
		}
	}

	/* Post-parsing */

	void resolve_gir_symbols () {
		// gir has simple namespaces, we won't get deeper than 2 levels here, except reparenting
		foreach (var map_from in unresolved_gir_symbols) {
			while (map_from != null) {
				var map_to = unresolved_symbols_map[map_from];
				if (map_to != null) {
					// remap the original symbol to match the target
					map_from.inner = null;
					map_from.name = map_to.name;
					if (map_to is UnresolvedSymbol) {
						var umap_to = (UnresolvedSymbol) map_to;
						while (umap_to.inner != null) {
							umap_to = umap_to.inner;
							map_from.inner = new UnresolvedSymbol (null, umap_to.name);
							map_from = map_from.inner;
						}
					} else {
						while (map_to.parent_symbol != null && map_to.parent_symbol != context.root) {
							map_to = map_to.parent_symbol;
							map_from.inner = new UnresolvedSymbol (null, map_to.name);
							map_from = map_from.inner;
						}
					}
					break;
				}
				map_from = map_from.inner;
			}
		}
	}

	void create_new_namespaces () {
		foreach (var node in Node.new_namespaces) {
			if (node.symbol == null) {
				node.symbol = new Namespace (node.name, node.source_reference);
			}
		}
	}

	void process_interface (Node iface_node) {
		/* Temporarily workaround G-I bug not adding aroopp.Object prerequisite:
		   ensure we have at least one instantiable prerequisite */
		Interface iface = (Interface) iface_node.symbol;
		bool has_instantiable_prereq = false;
		foreach (DataType prereq in iface.get_prerequisites ()) {
			Symbol sym = null;
			if (prereq is UnresolvedType) {
				var unresolved_symbol = ((UnresolvedType) prereq).unresolved_symbol;
				sym = resolve_symbol (iface_node.parent, unresolved_symbol);
			} else {
				sym = prereq.data_type;
			}
			if (sym is Class) {
				has_instantiable_prereq = true;
				break;
			}
		}

		if (!has_instantiable_prereq) {
			iface.add_prerequisite (new ObjectType ((ObjectTypeSymbol) aroopp_ns.scope.lookup ("Object")));
		}
	}

	void process_alias (Node alias) {
		/* this is unfortunate because <alias> tag has no type information, thus we have
		   to guess it from the base type */
		DataType base_type = null;
		Symbol type_sym = null;
		bool simple_type = false;
		if (alias.base_type is UnresolvedType) {
			base_type = alias.base_type;
			type_sym = resolve_symbol (alias.parent, ((UnresolvedType) base_type).unresolved_symbol);
		} else if (alias.base_type is PointerType && ((PointerType) alias.base_type).base_type is VoidType) {
			// gpointer, if it's a struct make it a simpletype
			simple_type = true;
		} else {
			base_type = alias.base_type;
			type_sym = base_type.data_type;
		}

		if (type_sym is Struct && ((Struct) type_sym).is_simple_type ()) {
			simple_type = true;
		}

		if (base_type == null || type_sym == null || type_sym is Struct) {
			var st = new Struct (alias.name, alias.source_reference);
			st.access = SymbolAccessibility.PUBLIC;
			if (base_type != null) {
				// threat target="none" as a new struct
				st.base_type = base_type;
			}
			st.external = true;
			st.set_simple_type (simple_type);
			alias.symbol = st;
		} else if (type_sym is Class) {
			var cl = new Class (alias.name, alias.source_reference);
			cl.access = SymbolAccessibility.PUBLIC;
			if (base_type != null) {
				cl.add_base_type (base_type);
			}
			cl.external = true;
			alias.symbol = cl;
		}
	}

	void process_callable (Node node) {
		var s = node.symbol;
		List<ParameterInfo> parameters = node.parameters;

		DataType return_type = null;
		if (s is Method) {
			return_type = ((Method) s).return_type;
		} else if (s is Delegate) {
			return_type = ((Delegate) s).return_type;
		} else if (s is Signal) {
			return_type = ((Signal) s).return_type;
		}

		if (return_type is ArrayType && node.return_array_length_idx >= 0) {
			if (node.return_array_length_idx >= parameters.size) {
				Report.error (get_current_src (), "invalid array length index");
			} else {
				parameters[node.return_array_length_idx].keep = false;
				node.array_length_parameters.add (node.return_array_length_idx);
			}
		} else if (return_type is VoidType && parameters.size > 0) {
			int n_out_parameters = 0;
			foreach (var info in parameters) {
				if (info.param.direction == ParameterDirection.OUT) {
					n_out_parameters++;
				}
			}

			if (n_out_parameters == 1) {
				ParameterInfo last_param = parameters[parameters.size-1];
				if (last_param.param.direction == ParameterDirection.OUT) {
					// use last out real-non-null-struct parameter as return type
					if (last_param.param.variable_type is UnresolvedType) {
						var st = resolve_symbol (node.parent, ((UnresolvedType) last_param.param.variable_type).unresolved_symbol) as Struct;
						if (st != null && !st.is_simple_type () && !last_param.param.variable_type.nullable) {
							last_param.keep = false;
							return_type = last_param.param.variable_type.copy ();
						}
					}
				}
			}
		}
		if (parameters.size > 1) {
			ParameterInfo last_param = parameters[parameters.size-1];
			if (last_param.param.ellipsis) {
				var first_vararg_param = parameters[parameters.size-2];
				if (first_vararg_param.param.name.has_prefix ("first_")) {
					first_vararg_param.keep = false;
				}
			}
		}

		int i = 0, j=1;

		int last = -1;
		foreach (ParameterInfo info in parameters) {
			if (s is Delegate && info.closure_idx == i) {
				var d = (Delegate) s;
				d.has_target = true;
				d.set_attribute_double ("CCode", "instance_pos", j - 0.1);
				info.keep = false;
			} else if (info.keep
					   && !node.array_length_parameters.contains (i)
					   && !node.closure_parameters.contains (i)
					   && !node.destroy_parameters.contains (i)) {
				info.aroopp_idx = (float) j;
				info.keep = true;

				/* interpolate for aroopp_idx between this and last*/
				float last_idx = 0.0F;
				if (last != -1) {
					last_idx = parameters[last].aroopp_idx;
				}
				for (int k=last+1; k < i; k++) {
					parameters[k].aroopp_idx =  last_idx + (((j - last_idx) / (i-last)) * (k-last));
				}
				last = i;
				j++;
			} else {
				info.keep = false;
				// make sure that aroopp_idx is always set
				// the above if branch does not set aroopp_idx for
				// hidden parameters at the end of the parameter list
				info.aroopp_idx = (j - 1) + (i - last) * 0.1F;
			}
			i++;
		}

		foreach (ParameterInfo info in parameters) {
			if (info.keep) {

				/* add_parameter sets carray_length_parameter_position and cdelegate_target_parameter_position
				   so do it first*/
				if (s is Method) {
					((Method) s).add_parameter (info.param);
				} else if (s is Delegate) {
					((Delegate) s).add_parameter (info.param);
				} else if (s is Signal) {
					((Signal) s).add_parameter (info.param);
				}

				if (info.array_length_idx != -1) {
					if ((info.array_length_idx) >= parameters.size) {
						Report.error (get_current_src (), "invalid array_length index");
						continue;
					}
					set_array_ccode (info.param, parameters[info.array_length_idx]);
				}

				if (info.closure_idx != -1) {
					if ((info.closure_idx) >= parameters.size) {
						Report.error (get_current_src (), "invalid closure index");
						continue;
					}
					if ("%g".printf (parameters[info.closure_idx].aroopp_idx) != "%g".printf (info.aroopp_idx + 0.1)) {
						info.param.set_attribute_double ("CCode", "delegate_target_pos", parameters[info.closure_idx].aroopp_idx);
					}
				}
				if (info.destroy_idx != -1) {
					if (info.destroy_idx >= parameters.size) {
						Report.error (get_current_src (), "invalid destroy index");
						continue;
					}
					if ("%g".printf (parameters[info.destroy_idx].aroopp_idx) != "%g".printf (info.aroopp_idx + 0.2)) {
						info.param.set_attribute_double ("CCode", "destroy_notify_pos", parameters[info.destroy_idx].aroopp_idx);
					}
				}
			}
		}

		if (return_type is ArrayType && node.return_array_length_idx >= 0) {
			set_array_ccode (s, parameters[node.return_array_length_idx]);
		}

		if (s is Method) {
			((Method) s).return_type = return_type;
		} else if (s is Delegate) {
			((Delegate) s).return_type = return_type;
		} else if (s is Signal) {
			((Signal) s).return_type = return_type;
		}
	}

	void find_parent (string cname, Node current, ref Node best, ref int match) {
		var old_best = best;
		if (current.symbol is Namespace) {
			foreach (var child in current.members) {
				// symbol is null only for aliases that aren't yet processed
				if ((child.symbol == null || is_container (child.symbol)) && cname.has_prefix (child.get_lower_case_cprefix ())) {
					find_parent (cname, child, ref best, ref match);
				}
			}
		}
		if (best != old_best) {
			// child is better
			return;
		}

		var current_match = current.get_lower_case_cprefix().length;
		if (current_match > match) {
			match = current_match;
			best = current;
		}
	}

	void process_namespace_method (Node ns, Node node) {
		/* transform static methods into instance methods if possible.
		   In most of cases this is a .gir fault we are going to fix */

		var ns_cprefix = ns.get_lower_case_cprefix ();
		var method = (Method) node.symbol;
		var cname = node.get_cname ();

		Parameter first_param = null;
		if (method.get_parameters ().size > 0) {
			first_param = method.get_parameters()[0];
		}
		if (first_param != null && first_param.variable_type is UnresolvedType) {
			// check if it's a missed instance method (often happens for structs)
			var sym = ((UnresolvedType) first_param.variable_type).unresolved_symbol;
			var parent = resolve_node (ns, sym);
			if (parent != null && parent.parent == ns && is_container (parent.symbol) && cname.has_prefix (parent.get_lower_case_cprefix ())) {
				// instance method
				var new_name = method.name.substring (parent.get_lower_case_cprefix().length - ns_cprefix.length);
				if (parent.lookup (new_name) == null) {
					ns.remove_member (node);
					node.name = new_name;
					method.name = new_name;
					method.get_parameters().remove_at (0);
					method.binding = MemberBinding.INSTANCE;
					parent.add_member (node);
				}
				return;
			}
		}

		int match = 0;
		Node parent = ns;
		find_parent (cname, ns, ref parent, ref match);
		var new_name = method.name.substring (parent.get_lower_case_cprefix().length - ns_cprefix.length);
		if (parent.lookup (new_name) == null) {
			ns.remove_member (node);
			node.name = new_name;
			method.name = new_name;
			parent.add_member (node);
		}
	}

	void process_virtual_method_field (Node node, Delegate d, UnresolvedSymbol gtype_struct_for) {
		var gtype_node = resolve_node (node.parent, gtype_struct_for);
		if (gtype_node == null || !(gtype_node.symbol is ObjectTypeSymbol)) {
			Report.error (gtype_struct_for.source_reference, "Unknown symbol `%s' for virtual method field `%s'".printf (gtype_struct_for.to_string (), node.to_string ()));
		}
		var nodes = gtype_node.lookup_all (d.name);
		if (nodes == null) {
			return;
		}
		foreach (var n in nodes) {
			if (node != n) {
				n.process (this);
			}
		}
		foreach (var n in nodes) {
			if (n.merged) {
				continue;
			}
			var sym = n.symbol;
			if (sym is Signal) {
				var sig = (Signal) sym;
				sig.is_virtual = true;
				assume_parameter_names (sig, d, true);
			} else if (sym is Property) {
				var prop = (Property) sym;
				prop.is_virtual = true;
			}
		}
	}

	void process_async_method (Node node) {
		var m = (Method) node.symbol;
		string finish_method_base;
		if (m.name.has_suffix ("_async")) {
			finish_method_base = m.name.substring (0, m.name.length - "_async".length);
		} else {
			finish_method_base = m.name;
		}
		var finish_method_node = node.parent.lookup (finish_method_base + "_finish");

		// check if the method is using non-standard finish method name
		if (finish_method_node == null) {
			var method_cname = node.get_finish_cname ();
			foreach (var n in node.parent.members) {
				if (n.symbol is Method && n.get_cname () == method_cname) {
					finish_method_node = n;
					break;
				}
			}
		}

		Method method = m;

		if (finish_method_node != null && finish_method_node.symbol is Method) {
			finish_method_node.process (this);
			var finish_method = (Method) finish_method_node.symbol;
			if (finish_method is CreationMethod) {
				method = new CreationMethod (((CreationMethod) finish_method).class_name, null, m.source_reference);
				method.access = m.access;
				method.binding = m.binding;
				method.external = true;
				method.coroutine = true;
				method.has_construct_function = finish_method.has_construct_function;
				method.attributes = m.attributes.copy ();
				method.set_attribute_string ("CCode", "cname", node.get_cname ());
				if (finish_method_base == "new") {
					method.name = null;
				} else if (finish_method_base.has_prefix ("new_")) {
					method.name = m.name.substring ("new_".length);
				}
				foreach (var param in m.get_parameters ()) {
					method.add_parameter (param);
				}
				node.symbol = method;
			} else {
				method.return_type = finish_method.return_type.copy ();
				var a = finish_method.get_attribute ("CCode");
				if (a != null && a.has_argument ("array_length")) {
					method.set_attribute_bool ("CCode", "array_length", a.get_bool ("array_length"));
				}
				if (a != null && a.has_argument ("array_null_terminated")) {
					method.set_attribute_bool ("CCode", "array_null_terminated", a.get_bool ("array_null_terminated"));
				}

				foreach (var param in finish_method.get_parameters ()) {
					if (param.direction == ParameterDirection.OUT) {
						var async_param = param.copy ();
						if (method.scope.lookup (param.name) != null) {
							// parameter name conflict
							async_param.name += "_out";
						}
						method.add_parameter (async_param);
					}
				}

				foreach (DataType error_type in finish_method.get_error_types ()) {
					method.add_error_type (error_type.copy ());
				}
				finish_method_node.processed = true;
				finish_method_node.merged = true;
			}
		}
	}

	/* Hash and equal functions */

	static uint unresolved_symbol_hash (void *ptr) {
		var sym = (UnresolvedSymbol) ptr;
		var builder = new StringBuilder ();
		while (sym != null) {
			builder.append (sym.name);
			sym = sym.inner;
		}
		return builder.str.hash ();
	}

	static bool unresolved_symbol_equal (void *ptr1, void *ptr2) {
		var sym1 = (UnresolvedSymbol) ptr1;
		var sym2 = (UnresolvedSymbol) ptr2;
		while (sym1 != sym2) {
			if (sym1 == null || sym2 == null) {
				return false;
			}
			if (sym1.name != sym2.name) {
				return false;
			}
			sym1 = sym1.inner;
			sym2 = sym2.inner;
		}
		return true;
	}
}
