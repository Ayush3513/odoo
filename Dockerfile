FROM python:3.12-slim-bookworm

# Install system dependencies
# Odoo needs:
# - build-essential, python3-dev, libldap2-dev, libsasl2-dev (for python-ldap)
# - postgresql-client (for db operations)
# - libxml2-dev, libxslt1-dev, zlib1g-dev (for lxml)
# - libjpeg-dev, libfreetype6-dev, liblcms2-dev, libopenjp2-7-dev, libtiff5-dev (for Pillow)
# - wkhtmltopdf (for PDF reports) - tricky on Debian, we use a standalone install or package if available
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    python3-dev \
    libldap2-dev \
    libsasl2-dev \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
    libjpeg-dev \
    libfreetype6-dev \
    liblcms2-dev \
    libopenjp2-7-dev \
    libtiff5-dev \
    libpq-dev \
    curl \
    gnupg2 \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install wkhtmltopdf
RUN curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.bookworm_amd64.deb \
    && apt-get update \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# Create odoo user
RUN useradd -ms /bin/bash odoo

# Work directory
WORKDIR /opt/odoo

# Copy requirements
COPY requirements.txt /opt/odoo/
RUN pip install --upgrade pip \
    && pip install -r requirements.txt

# Copy Entrypoint
COPY entrypoint.sh /opt/odoo/
RUN chmod +x /opt/odoo/entrypoint.sh

# Copy Application Code
COPY . /opt/odoo/

# Change ownership
RUN chown -R odoo:odoo /opt/odoo

# Switch to odoo user
USER odoo

# Expose Odoo services
EXPOSE 8069 8072

# Set Entrypoint
ENTRYPOINT ["/opt/odoo/entrypoint.sh"]

# Default command
CMD ["python3", "odoo-bin", "-c", "/opt/odoo/odoo.conf"]
