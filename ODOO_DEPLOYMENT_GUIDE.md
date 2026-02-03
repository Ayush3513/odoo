# Freelancer's Guide: Cost-Effective Odoo Deployment

This guide explains how to deploy Odoo. You have two main options:

1.  **Low-Cost VPS** (~$5/mo): Best for production/clients.
2.  **Render.com** (Free): Best for **learning/demo** purposes.

---

## Option 1: VPS Deployment (Recommended for Clients)

**Cost**: ~$6-10/month.
**Pros**: Production-ready, persistent, fast.
**Cons**: Requires manual setup.

### Step 1: Get the Server
1.  Create an account on **Hetzner** or **DigitalOcean**.
2.  Create a standard VPS (Ubuntu 24.04, 2 vCPU, 4GB RAM).

### Step 2: Install Docker
SSH into your server (`ssh root@ip`) and run:
```bash
apt update && apt upgrade -y
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```

### Step 3: Configure & Run
1.  Clone this repository: `git clone https://github.com/your-repo/odoo-project.git /opt/odoo`
2.  Edit passwords:
    *   `nano odoo.conf`: Set `admin_passwd` and `db_password`.
    *   `nano docker-compose.yml`: Set `POSTGRES_PASSWORD` (must match `db_password`).
3.  Run: `docker compose up -d --build`

---

## Option 2: Free Cloud Deployment (Render.com)

**Cost**: $0/month.
**Pros**: No server management, instant setup via Blueprint.
**Cons**:
*   **Sleeps**: Web service spins down after inactivity (takes 50s to wake up).
*   **Database**: Postgres Free Tier expires after 90 days.
*   **RAM**: Limited to 512MB (Odoo might crash if you install too many apps).

### Step 1: Push to GitHub
Make sure this code is in a GitHub (or GitLab) repository.

### Step 2: Create Blueprint on Render
1.  Sign up at [render.com](https://render.com).
2.  Click **New +** -> **Blueprint**.
3.  Connect your GitHub account and select this repository.
4.  Render will detect the `render.yaml` file automatically.
5.  Click **Apply**.

### Step 3: Deployment
Render will:
1.  Create a PostgreSQL database.
2.  Build your Docker image.
3.  Deploy Odoo and link it to the database automatically.

Once finished, you will get a URL like `https://odoo-server-xxxx.onrender.com`.

### Important Note on Passwords
On Render, the `admin_passwd` is randomly generated. To find it:
1.  Go to your Dashboard -> **odoo-server** (Web Service).
2.  Click **Environment**.
3.  Reveal the `ADMIN_PASSWD` variable. Use this to create/restore databases.

---

## Security Checklist (For ANY Deployment)

1.  **Change Default Passwords**: Never leave `admin` or `odoo` as passwords.
2.  **HTTPS**: Render handles this automatically. For VPS, use Nginx Proxy Manager.
3.  **Backups**:
    *   **VPS**: Cron job to `pg_dump`.
    *   **Render**: Manual backups required for free tier.
