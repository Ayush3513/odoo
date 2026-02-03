#!/bin/bash
set -e

# If ODOO_CONF_FILE is not present (or empty), generate it from Environment Variables
ODOO_CONF=${ODOO_CONF:-/etc/odoo.conf}

if [ ! -f "$ODOO_CONF" ] || [ ! -s "$ODOO_CONF" ]; then
    echo "Generating $ODOO_CONF from environment variables..."

    # Set defaults
    DB_PORT=${DB_PORT:-5432}
    DB_USER=${DB_USER:-odoo}
    DB_PASSWORD=${DB_PASSWORD:-odoo}
    ADMIN_PASSWD=${ADMIN_PASSWD:-admin}
    ADDONS_PATH=${ADDONS_PATH:-/opt/odoo/addons}

    # Write config file
    cat <<EOF > "$ODOO_CONF"
[options]
admin_passwd = $ADMIN_PASSWD
db_host = $DB_HOST
db_port = $DB_PORT
db_user = $DB_USER
db_password = $DB_PASSWORD
addons_path = $ADDONS_PATH
default_productivity_apps = True
EOF
fi

# Execute the CMD passed to docker run
exec "$@"
