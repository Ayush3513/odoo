# Advanced Odoo Coding Concepts (The "Senior Developer" Path)

This guide bridges the gap between a Junior/Intern and a Senior Developer. We explain complex topics using simple mechanical analogies and show you the real code used in Odoo.

---

## 1. Context Manipulation (`with_context`)
**Analogy:** Imagine you are a worker (Method). You usually wear a standard uniform (Environment). Sometimes, you need to wear a "High Visibility Vest" (Context) to enter a specific zone. The worker is the same, but the rules around them change.

**What it does:** It passes "invisible" metadata to methods. It doesn't change the data in the database, but it changes *how* the code behaves (e.g., translating text, setting default values).

**Real Code (`sale/models/sale_order.py`):**
```python
# The order changes its 'language' context temporarily
order = order.with_context(lang=order.partner_id.lang)
# Now, any field read from 'order' will be translated to the Partner's language
```

**Senior Tip:** Use this to bypass default behaviors without rewriting code. Common keys: `tracking_disable=True`, `active_test=False` (include archived records).

---

## 2. Privilege Escalation (`sudo`)
**Analogy:** You are a regular mechanic, but you need to open the Manager's Safe. You borrow the "Master Key" for just one task.

**What it does:** It creates a new Environment where the user is the **Superuser (Admin)**. This bypasses ALL Access Rights and Record Rules.

**Real Code (`sale/models/sale_order.py`):**
```python
# A regular salesperson might not have rights to read Transaction IDs directly
txs = self.sudo().transaction_ids.filtered(...)
```

**Senior Tip:** **DANGER!** Never use `sudo()` blindly. It creates security holes. Only use it when a user *needs* to do something technically allowed by the system but forbidden by their user level (e.g., a customer confirming an order via portal).

---

## 3. Delegation Inheritance (`_inherits`)
**Analogy:** A "Car" object and an "Engine" object. The Car *contains* the Engine. If you ask the Car for its "Horsepower", it automatically asks the Engine. You don't see the Engine; you just interact with the Car.

**What it does:** It embeds another model inside your model transparently.

**Real Code (`addons/product/models/product_product.py`):**
```python
class ProductProduct(models.Model):
    _name = "product.product"
    # The Product Variant 'contains' a Product Template
    _inherits = {'product.template': 'product_tmpl_id'}
```
**Translation:** Every `product.product` (Variant) has a hidden link to a `product.template`. If you read `product.name`, Odoo automatically grabs it from the Template.

---

## 4. Batch Processing (`@api.model_create_multi`)
**Analogy:** Moving bricks.
*   **Junior:** Pick up 1 brick. Walk to wall. Place brick. Repeat 1000 times.
*   **Senior:** Put 1000 bricks on a pallet. Move pallet with forklift. Place all at once.

**What it does:** Optimizes the `create` method to handle a **list** of dictionaries instead of one by one. This reduces Database calls from 1000 to 1.

**Real Code (`sale/models/sale_order.py`):**
```python
@api.model_create_multi
def create(self, vals_list):
    # vals_list is a LIST of dictionaries: [{'name': 'A'}, {'name': 'B'}]
    for vals in vals_list:
        # Pre-process data in python (fast)
        if vals.get('name', _("New")) == _("New"):
             vals['name'] = ...

    # Call SQL INSERT once for all records
    return super().create(vals_list)
```

---

## 5. Transient Models (Wizards)
**Analogy:** A Scratchpad. You write notes on it, do a calculation, and then throw the paper in the trash. It doesn't go into the permanent filing cabinet.

**What it does:** These are database tables that are temporary. They are used for **Pop-up Windows** (Wizards) where users input data that isn't saved permanently but triggers an action.

**Real Code (`sale/wizard/sale_make_invoice_advance.py`):**
```python
class SaleAdvancePaymentInv(models.TransientModel): # <--- Note the difference
    _name = "sale.advance.payment.inv"

    advance_payment_method = fields.Selection(...)

    def create_invoices(self):
        # Use the data from the popup to do the real work
        sale_orders = self.env['sale.order'].browse(self._context.get('active_ids', []))
        sale_orders._create_invoices(...)
```

---

## 6. Abstract Models (Mixins)
**Analogy:** A "Skill" or "Trait".
*   "Can Fly" is a trait. A Bird has it. A Plane has it. But "Can Fly" is not an animal or machine itself.

**What it does:** A model meant *only* to be inherited. It gives features to other models. It has no table in the database.

**Real Code (`sale/models/sale_order.py`):**
```python
class SaleOrder(models.Model):
    # 'mail.thread' adds the Messaging/Chatter feature
    # 'mail.activity.mixin' adds the To-Do Activity feature
    _inherit = ['mail.thread', 'mail.activity.mixin', ...]
```

---

## 7. SQL Constraints (`_sql_constraints`)
**Analogy:** A physical barrier. A square peg cannot fit in a round hole, no matter how hard you push.

**What it does:** Adds a constraint directly to the **PostgreSQL** database. It is much faster and safer than Python checks (`@api.constrains`).

**Real Code Example:**
```python
_sql_constraints = [
    ('name_unique', 'UNIQUE(name)', 'The Order Reference must be unique!'),
    ('qty_positive', 'CHECK(quantity >= 0)', 'Quantity must be positive.'),
]
```
**Translation:** The Database itself will throw an error if you try to save a duplicate name or negative quantity. Odoo catches this error and shows a nice message.

---

## 8. Computed Fields: Stored vs Non-Stored
**Analogy:**
*   **Non-Stored (Default):** Calculating `2 + 2` in your head every time someone asks. (Good for values that change constantly, like "Days until Delivery").
*   **Stored (`store=True`):** Calculating `2 + 2`, writing `4` on a sticky note, and just reading the note next time. (Good for Sorting, Grouping, or heavy calculations).

**Real Code (`sale/models/sale_order.py`):**
```python
# Stored: We need to search/sort by 'amount_total', so we save it to the DB.
amount_total = fields.Monetary(string="Total", store=True, compute='_compute_amounts')

# Non-Stored: 'is_expired' changes depending on Today's date.
# Saving it would be wrong because tomorrow it might change without us touching the record.
is_expired = fields.Boolean(compute='_compute_is_expired')
```
