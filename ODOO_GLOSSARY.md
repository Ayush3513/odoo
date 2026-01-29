# Odoo Developer Glossary & Cheat Sheet (Intern Edition)

Welcome! This guide is designed for new coders. It breaks down the "scary" Odoo terms into simple concepts and shows you real code from the `sale` module so you can see them in action.

---

## 1. The "Big Three" Variables
You will see these in almost every function.

### `self`
*   **What is it?** It's the "Current Selection" of records. Think of it like a **List of Rows** in Excel that you are currently working on.
*   **Catch:** It might have 1 row, 100 rows, or 0 rows.
*   **Real Code Example:**
    ```python
    # From sale_order.py
    for order in self:
        # We loop through each 'row' (order) in the list
        order.require_signature = order.company_id.portal_confirmation_sign
    ```
*   **Translation:** "For every order in my current list, set the signature requirement based on the company's setting."

### `env` (Environment)
*   **What is it?** Your "Toolbox". It gives you access to everything else in Odoo: other tables, the current user, the database.
*   **How to access:** `self.env`
*   **Real Code Example:**
    ```python
    # searching for a pricelist in the 'product.pricelist' table
    is_active = self.env['product.pricelist'].search([('active', '=', True)])
    ```
*   **Translation:** "Go into my toolbox, grab the Pricelist table, and search for active ones."

### `vals` (Values)
*   **What is it?** A "Dictionary" (Key-Value pairs) containing data to Save.
*   **Format:** `{'column_name': new_value, 'other_column': 123}`
*   **Real Code Example:**
    ```python
    # In the create method
    vals['name'] = "New Order 001"
    super().create(vals)
    ```
*   **Translation:** "In the box of data we are about to save (`vals`), set the Name to 'New Order 001'."

---

## 2. The Actions (ORM Methods)
These are the verbs you use to interact with the database.

### `search(domain)`
*   **What is it?** "Find me records". Equivalent to SQL `SELECT * FROM table WHERE ...`.
*   **Real Code Example:**
    ```python
    # Find orders that have a pending email template
    pending_orders = self.search([('pending_email_template_id', '!=', False)])
    ```
*   **Translation:** "Search this table for any order where 'pending_email_template_id' is NOT empty."

### `create(vals)`
*   **What is it?** "Insert a new row".
*   **Real Code Example:**
    ```python
    # Creating a new activity for a user
    self.env['mail.activity'].create({
        'res_id': order.id,
        'user_id': order.user_id.id,
        'note': 'Please check this order',
    })
    ```
*   **Translation:** "Create a new row in the Activity table with these specific values."

### `write(vals)`
*   **What is it?** "Update existing rows".
*   **Real Code Example:**
    ```python
    # Changing the state of an order to 'sent'
    self.write({'state': 'sent'})
    ```
*   **Translation:** "Update ALL records in `self` (my current list) and change their state to 'sent'."

### `unlink()`
*   **What is it?** "Delete rows".
*   **Real Code Example:**
    ```python
    # Delete lines that are just section headers
    section_lines = self.order_line.filtered(lambda l: l.display_type == 'line_section')
    section_lines.unlink()
    ```
*   **Translation:** "Take the section lines I found and delete them from the database."

---

## 3. The "List" Tools (Recordset Operations)
Since `self` is a list of records, Odoo gives you tools to filter and sort them without writing SQL.

### `filtered(lambda ...)`
*   **What is it?** "Keep only these". Like an Excel Filter.
*   **Real Code Example:**
    ```python
    # Get only the orders that are currently in 'sale' state
    confirmed_orders = self.filtered(lambda so: so.state == 'sale')
    ```
*   **Translation:** "Look at `self`, and give me a new list containing ONLY the orders where state is 'sale'."

### `mapped('field')`
*   **What is it?** "Extract a column". Like selecting a column in Excel and copying it.
*   **Real Code Example:**
    ```python
    # Get a list of all names of partners in these orders
    partner_names = self.mapped('partner_id.name')
    ```
*   **Translation:** "From every order in my list, grab the Partner's Name and give me a plain list of them."

### `ensure_one()`
*   **What is it?** "Panic if there's more than one!". It's a safety check.
*   **Real Code Example:**
    ```python
    def action_confirm(self):
        self.ensure_one()
        # ... logic that only works for a SINGLE order ...
    ```
*   **Translation:** "Stop everything if `self` contains 0 records or 2+ records. I can only handle exactly one right now."

---

## 4. The Decorators (Magic Tags)
These sit above your functions (`@...`) and tell Odoo *when* to run them.

### `@api.depends('field')`
*   **What is it?** "Auto-Calculate this". Used for fields that compute their own value.
*   **Real Code Example:**
    ```python
    @api.depends('price', 'qty')
    def _compute_total(self):
        for record in self:
            record.total = record.price * record.qty
    ```
*   **Translation:** "Watch the 'price' and 'qty' fields. If either changes, re-run this function to update 'total'."

### `@api.onchange('field')`
*   **What is it?** "Update the UI immediately". Runs when the user is typing in a form, *before* they save.
*   **Real Code Example:**
    ```python
    @api.onchange('partner_id')
    def _onchange_partner(self):
        # When user selects a customer, auto-fill their address
        self.shipping_address = self.partner_id.address
    ```
*   **Translation:** "As soon as the user picks a Partner in the dropdown, verify/update the shipping address field on the screen."

### `@api.constrains('field')`
*   **What is it?** "Validation Rule". Runs when saving.
*   **Real Code Example:**
    ```python
    @api.constrains('percent')
    def _check_percent(self):
        if self.percent > 100:
            raise ValidationError("You cannot give 110%!")
    ```
*   **Translation:** "When saving, check the 'percent' field. If it's bad, block the save and show this error."

---

## 5. Field Types
How we define columns in the database table.

*   **`fields.Char`**: A small text box (e.g., Name).
*   **`fields.Float`**: A decimal number (e.g., Price).
*   **`fields.Many2one`**: A link to **one** parent (e.g., `partner_id` links to one Customer).
*   **`fields.One2many`**: A link to **many** children (e.g., `order_line` links to many items).
*   **`fields.Selection`**: A static dropdown list (e.g., `state`: Draft, Sent, Done).
