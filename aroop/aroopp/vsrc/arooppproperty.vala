/* arooppproperty.aroopp
 *
 * Copyright (C) 2006-2010  Jürg Billeter
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
 *	Raffaele Sandrini <raffaele@sandrini.ch>
 */

using aroopp;

/**
 * Represents a property declaration in the source code.
 */
public class aroopp.Property : Symbol, Lockable {
	/**
	 * The property type.
	 */
	public DataType? property_type {
		get { return _data_type; }
		set {
			_data_type = value;
			if (value != null) {
				_data_type.parent_node = this;
			}
		}
	}
	
	/**
	 * The get accessor of this property if available.
	 */
	public PropertyAccessor? get_accessor {
		get { return _get_accessor; }
		set {
			_get_accessor = value;
			if (value != null) {
				value.owner = scope;
			}
		}
	}
	
	/**
	 * The set/construct accessor of this property if available.
	 */
	public PropertyAccessor? set_accessor {
		get { return _set_accessor; }
		set {
			_set_accessor = value;
			if (value != null) {
				value.owner = scope;
			}
		}
	}
	
	/**
	 * Represents the generated `this` parameter in this property.
	 */
	public Parameter this_parameter { get; set; }

	/**
	 * Specifies whether automatic accessor code generation should be
	 * disabled.
	 */
	public bool interface_only { get; set; }
	
	/**
	 * Specifies whether this property is abstract. Abstract properties have
	 * no accessor bodies, may only be specified within abstract classes and
	 * interfaces, and must be overriden by derived non-abstract classes.
	 */
	public bool is_abstract { get; set; }
	
	/**
	 * Specifies whether this property is virtual. Virtual properties may be
	 * overridden by derived classes.
	 */
	public bool is_virtual { get; set; }
	
	/**
	 * Specifies whether this property overrides a virtual or abstract
	 * property of a base type.
	 */
	public bool overrides { get; set; }

	/**
	 * Reference the the Field that holds this property
	 */
	public Field field { get; set; }

	/**
	 * Specifies whether this field may only be accessed with an instance of
	 * the contained type.
	 */
	public MemberBinding binding { get; set; default = MemberBinding.INSTANCE; }

	/**
	 * Specifies the virtual or abstract property this property overrides.
	 * Reference must be weak as virtual properties set base_property to
	 * themselves.
	 */
	public Property base_property {
		get {
			find_base_properties ();
			return _base_property;
		}
	}
	
	/**
	 * Specifies the abstract interface property this property implements.
	 */
	public Property base_interface_property {
		get {
			find_base_properties ();
			return _base_interface_property;
		}
	}

	/**
	 * Specifies the default value of this property.
	 */
	public Expression initializer { get; set; }

	private bool lock_used = false;

	private DataType _data_type;

	private weak Property _base_property;
	private Property _base_interface_property;
	private bool base_properties_valid;
	PropertyAccessor? _get_accessor;
	PropertyAccessor? _set_accessor;

	/**
	 * Creates a new property.
	 *
	 * @param name         property name
	 * @param type         property type
	 * @param get_accessor get accessor
	 * @param set_accessor set/construct accessor
	 * @param source       reference to source code
	 * @return             newly created property
	 */
	public Property (string name, DataType? property_type, PropertyAccessor? get_accessor, PropertyAccessor? set_accessor, SourceReference? source_reference = null, Comment? comment = null) {
		base (name, source_reference, comment);
		this.property_type = property_type;
		this.get_accessor = get_accessor;
		this.set_accessor = set_accessor;
	}

	public override void accept (CodeVisitor visitor) {
		visitor.visit_property (this);
	}

	public override void accept_children (CodeVisitor visitor) {
		property_type.accept (visitor);
		
		if (get_accessor != null) {
			get_accessor.accept (visitor);
		}
		if (set_accessor != null) {
			set_accessor.accept (visitor);
		}

		if (initializer != null) {
			initializer.accept (visitor);
		}
	}

	public bool get_lock_used () {
		return lock_used;
	}
	
	public void set_lock_used (bool used) {
		lock_used = used;
	}
	
	/**
	 * Checks whether the accessors and type of the specified property
	 * matches this property.
	 *
	 * @param prop a property
	 * @return     true if the specified property is compatible to this
	 *             property
	 */
	public bool equals (Property prop2) {
		if ((get_accessor == null && prop2.get_accessor != null) ||
		    (get_accessor != null && prop2.get_accessor == null)) {
			return false;
		}

		if ((set_accessor == null && prop2.set_accessor != null) ||
		    (set_accessor != null && prop2.set_accessor == null)) {
			return false;
		}

		if (get_accessor != null) {
			// check accessor value_type instead of property_type
			// due to possible ownership differences
			if (!prop2.get_accessor.value_type.equals (get_accessor.value_type)) {
				return false;
			}
		}

		if (set_accessor != null) {
			// check accessor value_type instead of property_type
			// due to possible ownership differences
			if (!prop2.set_accessor.value_type.equals (set_accessor.value_type)) {
				return false;
			}

			if (set_accessor.writable != prop2.set_accessor.writable) {
				return false;
			}
			if (set_accessor.construction != prop2.set_accessor.construction) {
				return false;
			}
		}

		return true;
	}

	public override void replace_type (DataType old_type, DataType new_type) {
		if (property_type == old_type) {
			property_type = new_type;
		}
	}

	private void find_base_properties () {
		if (base_properties_valid) {
			return;
		}

		if (parent_symbol is Class) {
			find_base_interface_property ((Class) parent_symbol);
			if (is_virtual || overrides) {
				find_base_class_property ((Class) parent_symbol);
			}
		} else if (parent_symbol is Interface) {
			if (is_virtual || is_abstract) {
				_base_interface_property = this;
			}
		}

		base_properties_valid = true;
	}

	private void find_base_class_property (Class cl) {
		var sym = cl.scope.lookup (name);
		if (sym is Property) {
			var base_property = (Property) sym;
			if (base_property.is_abstract || base_property.is_virtual) {
				if (!equals (base_property)) {
					error = true;
					Report.error (source_reference, "Type and/or accessors of overriding property `%s' do not match overridden property `%s'.".printf (get_full_name (), base_property.get_full_name ()));
					return;
				}

				_base_property = base_property;
				return;
			}
		}

		if (cl.base_class != null) {
			find_base_class_property (cl.base_class);
		}
	}

	private void find_base_interface_property (Class cl) {
		// FIXME report error if multiple possible base properties are found
		foreach (DataType type in cl.get_base_types ()) {
			if (type.data_type is Interface) {
				var sym = type.data_type.scope.lookup (name);
				if (sym is Property) {
					var base_property = (Property) sym;
					if (base_property.is_abstract) {
						if (!equals (base_property)) {
							error = true;
							Report.error (source_reference, "Type and/or accessors of overriding property `%s' do not match overridden property `%s'.".printf (get_full_name (), base_property.get_full_name ()));
							return;
						}

						_base_interface_property = base_property;
						return;
					}
				}
			}
		}
	}

	public override bool check (CodeContext context) {
		if (checked) {
			return !error;
		}

		checked = true;

		if (is_abstract) {
			if (parent_symbol is Class) {
				var cl = (Class) parent_symbol;
				if (!cl.is_abstract) {
					error = true;
					Report.error (source_reference, "Abstract properties may not be declared in non-abstract classes");
					return false;
				}
			} else if (!(parent_symbol is Interface)) {
				error = true;
				Report.error (source_reference, "Abstract properties may not be declared outside of classes and interfaces");
				return false;
			}
		} else if (is_virtual) {
			if (!(parent_symbol is Class) && !(parent_symbol is Interface)) {
				error = true;
				Report.error (source_reference, "Virtual properties may not be declared outside of classes and interfaces");
				return false;
			}

			if (parent_symbol is Class) {
				var cl = (Class) parent_symbol;
				if (cl.is_compact) {
					error = true;
					Report.error (source_reference, "Virtual properties may not be declared in compact classes");
					return false;
				}
			}
		} else if (overrides) {
			if (!(parent_symbol is Class)) {
				error = true;
				Report.error (source_reference, "Properties may not be overridden outside of classes");
				return false;
			}
		} else if (access == SymbolAccessibility.PROTECTED) {
			if (!(parent_symbol is Class) && !(parent_symbol is Interface)) {
				error = true;
				Report.error (source_reference, "Protected properties may not be declared outside of classes and interfaces");
				return false;
			}
		}

		var old_source_file = context.analyzer.current_source_file;
		var old_symbol = context.analyzer.current_symbol;

		if (source_reference != null) {
			context.analyzer.current_source_file = source_reference.file;
		}
		context.analyzer.current_symbol = this;

		if (property_type is VoidType) {
			error = true;
			Report.error (source_reference, "'void' not supported as property type");
			return false;
		}

		property_type.check (context);

		if (get_accessor != null) {
			get_accessor.check (context);
		}
		if (set_accessor != null) {
			set_accessor.check (context);
		}

		if (initializer != null) {
			initializer.check (context);
		}

		// check whether property type is at least as accessible as the property
		if (!context.analyzer.is_type_accessible (this, property_type)) {
			error = true;
			Report.error (source_reference, "property type `%s` is less accessible than property `%s`".printf (property_type.to_string (), get_full_name ()));
		}

		if (overrides && base_property == null) {
			Report.error (source_reference, "%s: no suitable property found to override".printf (get_full_name ()));
		}

		if (!external_package && !overrides && !hides && get_hidden_member () != null) {
			Report.warning (source_reference, "%s hides inherited property `%s'. Use the `new' keyword if hiding was intentional".printf (get_full_name (), get_hidden_member ().get_full_name ()));
		}

		/* construct properties must be public */
		if (set_accessor != null && set_accessor.construction) {
			if (access != SymbolAccessibility.PUBLIC) {
				error = true;
				Report.error (source_reference, "%s: construct properties must be public".printf (get_full_name ()));
			}
		}

		if (initializer != null && !initializer.error && initializer.value_type != null && !(initializer.value_type.compatible (property_type))) {
			error = true;
			Report.error (initializer.source_reference, "Expected initializer of type `%s' but got `%s'".printf (property_type.to_string (), initializer.value_type.to_string ()));
		}

		context.analyzer.current_source_file = old_source_file;
		context.analyzer.current_symbol = old_symbol;

		return !error;
	}
}
