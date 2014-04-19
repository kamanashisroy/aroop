/* arooppsetliteral.aroopp
 *
 * Copyright (C) 2009-2010  Jürg Billeter
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

using aroop;
using aroopp;

public class aroopp.SetLiteral : Literal {
	private Set<Expression> expression_list = Set<Expression> ();

	public DataType element_type { get; private set; }

	public SetLiteral (SourceReference? source_reference = null) {
		this.source_reference = source_reference;
	}

	public override void accept_children (CodeVisitor visitor) {
		foreach (Expression expr in expression_list) {
			expr.accept (visitor);
		}
	}

	public override void accept (CodeVisitor visitor) {
		visitor.visit_set_literal (this);

		visitor.visit_expression (this);
	}

	public void add_expression (Expression expr) {
		expression_list.add (expr);
		expr.parent_node = this;
	}

	public Set<Expression> get_expressions () {
		return expression_list;
	}

	public override bool is_pure () {
		return false;
	}

	public override void replace_expression (Expression old_node, Expression new_node) {
		for (int i = 0; i < expression_list.size; i++) {
			if (expression_list[i] == old_node) {
				expression_list[i] = new_node;
			}
		}
	}

	public override bool check (CodeContext context) {
		if (checked) {
			return !error;
		}

		checked = true;

		var set_type = new ObjectType ((Class) context.root.scope.lookup ("Dova").scope.lookup ("Set"));
		set_type.value_owned = true;

		bool fixed_element_type = false;
		if (target_type != null && target_type.data_type == set_type.data_type && target_type.get_type_arguments ().size == 1) {
			element_type = target_type.get_type_arguments ().get (0).copy ();
			element_type.value_owned = false;
			fixed_element_type = true;
		}

		for (int i = 0; i < expression_list.size; i++) {
			var expr = expression_list[i];

			if (fixed_element_type) {
				expr.target_type = element_type;
			}
			if (!expr.check (context)) {
				return false;
			}

			// expression might have been replaced in the list
			expr = expression_list[i];

			if (element_type == null) {
				element_type = expr.value_type.copy ();
				element_type.value_owned = false;
			}
		}

		if (element_type == null) {
			error = true;
			Report.error (source_reference, "cannot infer element type for set literal");
			return false;
		}

		element_type = element_type.copy ();
		element_type.value_owned = true;
		set_type.add_type_argument (element_type);
		value_type = set_type;

		return !error;
	}

	public override void emit (CodeGenerator codegen) {
		foreach (Expression expr in expression_list) {
			expr.emit (codegen);
		}

		codegen.visit_set_literal (this);

		codegen.visit_expression (this);
	}
}
