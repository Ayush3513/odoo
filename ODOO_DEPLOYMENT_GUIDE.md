# Freelancer's Guide: Cost-Effective Odoo Deployment

This guide explains how to deploy Odoo for your client for **$5 - $10 / month**.

## The Architecture (The "Budget Stack")

Instead of paying for expensive Managed Hosting (Odoo.sh) or PaaS (Heroku/Render), we will use a **Virtual Private Server (VPS)** and **Docker**.

1.  **VPS Provider**: Use **Hetzner** (cheapest, reliable), **DigitalOcean**, or **Linode**.
    *   **Spec**: 2 vCPU, 4GB RAM (Minimum for stable Odoo). Cost: ~$6-10/month.
2.  **Containerization**: **Docker & Docker Compose**. This keeps Odoo and Postgres separate and clean.
3.  **Reverse Proxy**: **Nginx**. To handle SSL (HTTPS) and your client's domain.

---

## Step 1: Get the Server

1.  Create an account on DigitalOcean or Hetzner.
2.  Create a "Droplet" / "Cloud Server".
3.  **OS**: Ubuntu 24.04 LTS (or Debian 12).
4.  **Region**: Closest to your client.

## Step 2: Install Docker

SSH into your new server (`ssh root@your-server-ip`) and run:

```bash
# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose plugin (usually included, but just in case)
apt install docker-compose-plugin
```

## Step 3: Configure Security (Crucial!)

Before running anything, you MUST change the passwords.

1.  **Clone this Repository** onto the server:
    ```bash
    git clone https://github.com/your-repo/odoo-project.git /opt/odoo-project
    cd /opt/odoo-project
    ```

2.  **Edit Configuration**:
    Open `odoo.conf` and `docker-compose.yml`.
    ```bash
    nano odoo.conf
    nano docker-compose.yml
    ```
    *   Replace `CHANGE_ME_MASTER_PASSWORD` with a strong password. You will need this to create the database.
    *   Replace `CHANGE_ME_DB_PASSWORD` in **BOTH** files with a strong password. They must match.

## Step 4: Deploy the Code

1.  **Start the Stack**:
    ```bash
    docker compose up -d --build
    ```
    *   `-d`: Detached mode (runs in background).
    *   `--build`: Builds the custom image from the Dockerfile.

2.  **Check logs**:
    ```bash
    docker compose logs -f
    ```
    Wait until you see "HTTP service running".

At this point, Odoo is running on `http://your-server-ip:8069`.

## Step 5: Set up Domain & HTTPS (The "Pro" Touch)

Your client needs `https://erp.client.com`, not an IP address.

1.  **DNS**: Point `erp.client.com` to your server's IP (A Record).
2.  **Nginx Proxy Manager** (The easiest way for freelancers):
    Instead of writing complex Nginx configs, deploy Nginx Proxy Manager (NPM).

    Create a `docker-compose.npm.yml`:
    ```yaml
    services:
      app:
        image: 'jc21/nginx-proxy-manager:latest'
        ports:
          - '80:80'
          - '81:81'
          - '443:443'
        volumes:
          - ./data:/data
          - ./letsencrypt:/etc/letsencrypt
    ```
    Run it: `docker compose -f docker-compose.npm.yml up -d`

3.  **Configure**:
    *   Go to `http://your-server-ip:81`
    *   Login (Email: `admin@example.com`, Password: `changeme`).
    *   Click "Proxy Hosts" -> "Add Proxy Host".
    *   **Domain Names**: `erp.client.com`
    *   **Forward Hostname / IP**: `odoo-web` (or your server IP).
    *   **Forward Port**: `8069`.
    *   **SSL Tab**: Select "Request a new SSL Certificate" (Let's Encrypt). Check "Force SSL".
    *   Save.

## Step 6: Backups (Crucial!)

As a freelancer, **you are responsible if data is lost**.

1.  **Database Backup**:
    Set up a daily cron job on the host:
    ```bash
    # Dump the DB from the container
    docker exec -t odoo-project-db-1 pg_dumpall -c -U odoo > /root/backups/dump_$(date +%F).sql
    ```
2.  **Filestore Backup**:
    The volume `odoo-web-data` contains images/attachments. Backup `/var/lib/docker/volumes/...`.

**Recommendation**: Write a script to upload these to AWS S3 or Backblaze B2 (free tier exists).

## Cost Breakdown

*   **VPS**: $6/month
*   **Domain**: $10/year
*   **SSL**: Free (Let's Encrypt)
*   **Backups**: Free (S3 Free Tier) or pennies.
*   **Total**: **~$7/month**
