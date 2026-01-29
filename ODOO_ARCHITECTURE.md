# Odoo Architecture Analysis for New Developers

Welcome to the Odoo team! As an experienced developer, I've outlined the core concepts you need to understand to work effectively with this codebase.

## 1. Overall Architecture

Odoo follows a **multi-tier architecture**:

1.  **Database Tier**: **PostgreSQL**. This is the only supported database. It stores all data, including application configuration and view definitions.
2.  **Server Tier**: **Odoo Server** (Python). This handles the business logic, ORM (Object-Relational Mapping), and HTTP serving.
    -   **Core (`odoo/`)**: This directory contains the framework itself.
        -   `odoo/http.py`: The web server layer (handling requests).
        -   `odoo/orm/`: The heart of Odoo. It maps Python classes to Postgres tables (`models.py`, `fields.py`).
        -   `odoo/api.py`: The API used to interact with the database (Environment, cursor, etc.).
    -   **Addons (`addons/`)**: This is where the actual business applications live. Odoo is modular; everything from "Accounting" to "Sales" is an addon.
3.  **Client Tier**: **Web Client** (JavaScript/OWL). The interface you see in the browser is a Single Page Application (SPA) built with Odoo's own UI framework called **OWL** (Odoo Web Library). It communicates with the server via **JSON-RPC**.

## 2. Key Modules and Interaction

Modules (Addons) are the building blocks. They interact via **dependencies**.

*   **`base`**: The "kernel" of the business logic. It defines `res.partner` (Contacts), `res.users` (Users), `res.company` (Multi-company support). Almost every module depends on `base`.
*   **`web`**: The technical module that provides the web client (the backend UI). It contains the JavaScript framework (OWL) and generic widgets.
*   **`sale`** (Example): A functional module. It extends the system to handle Sales Orders.
    -   It depends on `product` and `payment`.
    -   It uses `res.partner` to link orders to customers.

**How they interact:**
Modules interact by **extending** each other's models and views. For example, `sale` might add a "Sales Count" field to the `res.partner` model defined in `base`. This is done without modifying the original `base` code, using Odoo's inheritance mechanism.

## 3. Important Design Patterns

### A. MVC (Model-View-Controller)
*   **Model (`models.py`)**: Python classes inheriting from `models.Model`. They define the data structure and business methods.
*   **View (XML)**: Stored in the database. Views (Forms, Lists, Kanbans) describe *how* to display the data. They are rendered by the Web Client.
*   **Controller (`controllers/main.py`)**: Python classes used mainly for custom routes (e.g., `/shop/checkout` or specific JSON-RPC endpoints). *Note: Standard backend CRUD operations are handled automatically by the framework's generic controller, so you often don't write controllers for standard backend views.*

### B. ORM & Active Record
Odoo uses a custom ORM.
*   **Active Record Pattern**: A recordset (e.g., `sale.order(1, 2)`) allows you to call methods directly on data.
    ```python
    orders = env['sale.order'].search([('state', '=', 'draft')])
    orders.action_confirm() # Calls business logic on these records
    ```

### C. Inheritance (The "Odoo Way")
This is crucial. You rarely "change" code; you "extend" it.
1.  **Class Inheritance (`_inherit`)**: Modifies an existing model in-place.
    ```python
    class SaleOrder(models.Model):
        _inherit = 'sale.order'

        new_field = fields.Char("My New Field") # Adds a column to sale_order table
    ```
2.  **Prototype Inheritance (`_name` + `_inherit`)**: Copies attributes to a new model.
3.  **Mixins**: Using multiple inheritance to add generic behavior (e.g., `mail.thread` adds the chatter/messaging feature to any model).

## 4. Request -> ORM -> Business Logic -> UI Flow

Let's trace what happens when a user clicks "Confirm" on a Sales Order.

### Step 1: The Request (Client to Server)
The User clicks the button in the browser (Web Client).
*   The **JavaScript** client sends a **JSON-RPC** request via HTTP POST.
*   **URL**: `/web/dataset/call_button` (or similar generic endpoint).
*   **Payload**: Contains the model (`sale.order`), method (`action_confirm`), and the Record IDs (e.g., `[10]`).

### Step 2: HTTP Layer (`odoo/http.py`)
*   The Odoo server receives the request in `odoo/http.py`.
*   The **Dispatcher** determines this is a call to a model method.
*   It initializes the **Environment** (`request.env`), setting up the database cursor and the current user (`request.uid`).

### Step 3: The ORM (`odoo/orm/models.py`)
*   The framework locates the `sale.order` model in the **Registry**.
*   It creates a **Recordset** for the requested IDs.
*   It checks **Access Rights** (ACLs) to ensure the user can write/execute on this model.

### Step 4: Business Logic (`addons/sale/models/sale_order.py`)
The `action_confirm` method is executed.
```python
def action_confirm(self):
    # 1. Validation
    if any(order.state != 'draft' for order in self):
        raise UserError(...)

    # 2. Update State
    self.write({'state': 'sale', 'date_order': fields.Datetime.now()})

    # 3. Trigger generic behavior (e.g. lock)
    self.filtered(lambda so: so._should_be_locked()).action_lock()

    return True
```
*   `self.write(...)` triggers the ORM's `write` method, executing an SQL `UPDATE`.

### Step 5: The Response (Server to Client)
*   The method returns `True` (or sometimes an Action dictionary to open a new view).
*   `odoo/http.py` wraps this result in a JSON response.
*   The **Web Client** receives the response. If it's `True`, it usually reloads the form view to show the new state ("Sales Order" instead of "Quotation").

---

**Summary for an Intern:**
Start by understanding `odoo/orm/models.py` (how to define data) and `addons/sale/` (how real business logic is implemented). The framework handles the heavy lifting of converting HTTP requests into Python method calls. Your job is mostly defining the data model and the business rules in Python, and the UI layout in XML.
