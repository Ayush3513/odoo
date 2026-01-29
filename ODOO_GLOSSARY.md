# Odoo Developer Glossary & Cheat Sheet

To master Odoo quickly, you need to recognize these common patterns and variable names instantly. They are used everywhere in the codebase.

## 1. Common Variables & Arguments

*   **`self`**: In Odoo, `self` is a **Recordset**. It is NOT just a single object; it can contain 0, 1, or N records.
    *   *Always* think: "Am I working with one record or many?"
    *   Iterate it: `for record in self:`
*   **`env` (`self.env`)**: The **Environment**. It gives you access to:
    *   The database cursor (`env.cr`).
    *   The current user (`env.user` / `env.uid`).
    *   Other models (`env['sale.order']`).
    *   Context (`env.context`).
*   **`vals`**: Short for "Values". A dictionary `{'field_name': value}` used when creating or writing to records.
    *   Used in `create(vals)` and `write(vals)`.
*   **`cr`**: The Database **Cursor**. Used for executing raw SQL queries (`self.env.cr.execute(...)`). You rarely need this unless doing optimization.
*   **`uid`**: User ID. The integer ID of the user performing the action.
*   **`ids`**: A list of integer IDs representing records in the database.
*   **`context`**: A dictionary carrying "metadata" like the current language (`lang`), timezone, or default values (`default_user_id`).
*   **`domain`**: A list of tuples defining a filter, e.g., `[('field', 'operator', value)]`.
    *   Example: `[('state', '=', 'draft'), ('user_id', '=', self.env.uid)]`.

## 2. Essential ORM Methods (The "Verbs")

*   **`search(domain)`**: Finds records matching the domain. Returns a Recordset.
*   **`browse(ids)`**: Takes a list of IDs and returns a Recordset. Does NOT hit the database immediately (lazy loading).
*   **`create(vals)`**: Creates a new record in the database. Returns the created record.
*   **`write(vals)`**: Updates values on *all* records in the current Recordset. Returns `True`.
*   **`unlink()`**: Deletes the records in the current Recordset.
*   **`search_count(domain)`**: Returns the number of records matching the domain. Faster than `len(search(domain))`.

## 3. Working with Recordsets (The "Tools")

*   **`ensure_one()`**: Checks if `self` contains exactly one record. Raises an error otherwise. Use this at the start of methods that only make sense for a single record.
*   **`filtered(func)`**: Returns a new Recordset containing only records that match the condition.
    *   `paid_orders = orders.filtered(lambda r: r.state == 'paid')`
*   **`mapped(func/field)`**: Returns a list (or Recordset) of values from the records.
    *   `names = orders.mapped('name')` (Returns list of strings)
    *   `partners = orders.mapped('partner_id')` (Returns Recordset of partners)
*   **`sorted(key)`**: Returns a sorted Recordset.

## 4. Key Decorators (The "Config")

*   **`@api.depends('field_A', 'field_B')`**: Used on **Computed Fields**. Tells Odoo: "Recalculate this function if field_A or field_B changes".
*   **`@api.onchange('field_A')`**: Used for UI updates. Tells Odoo: "When the user changes field_A in the form, run this immediately" (before saving).
*   **`@api.constrains('field_A')`**: Used for Validation. Tells Odoo: "Check this logic when field_A is saved". Raises `ValidationError` if failed.
*   **`@api.model`**: Decorates a method that doesn't care about specific records (like a static method). `self` will be empty/generic.
*   **`@api.returns('self')`**: Hint that the method returns a recordset of the same model.

## 5. Field Types & Attributes

*   **`Many2one`**: Link to *one* other record (Foreign Key). e.g., `partner_id`.
*   **`One2many`**: Link to *multiple* records (Reverse of Many2one). e.g., `order_line`. requires `inverse_name`.
*   **`Many2many`**: Link to *multiple* records (Table to Table). e.g., `tag_ids`.
*   **`Selection`**: A drop-down list. Stored as the "key", displayed as the "value".
*   **`compute='_compute_method'`**: Makes the field generic/calculated.
    *   **`store=True`**: The computed value is stored in the database (recomputed only when dependencies change). Good for searching/sorting.
    *   **`store=False`** (Default): Calculated on the fly every time.
*   **`related='field.subfield'`**: A shortcut to grab a value from a related record.

## 6. Common Coding Patterns

**The "Compute" Pattern:**
```python
amount = fields.Float(compute='_compute_amount')

@api.depends('price', 'qty')
def _compute_amount(self):
    for record in self:
        record.amount = record.price * record.qty
```
*Note: Always loop over `self`!*

**The "Override" Pattern:**
```python
def write(self, vals):
    # Logic BEFORE saving
    if 'state' in vals:
        do_something()

    result = super(MyModel, self).write(vals) # Save to DB

    # Logic AFTER saving
    return result
```

**The "Sudo" Pattern:**
*   **`self.sudo()`**: Returns a new Recordset where the current user is "Superuser" (Admin), bypassing access rules. Use carefully!

## 7. Special Files

*   **`__manifest__.py`**: The module configuration (dependencies, loaded views, security files).
*   **`ir.model.access.csv`**: Defines who can Read/Write/Create/Delete models. (Security).
*   **`view.xml`**: Defines the UI (Forms, Trees, Search).
