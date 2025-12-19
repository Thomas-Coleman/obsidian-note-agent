# Local Production Setup Guide

This guide walks you through setting up and running the Obsidian Note Agent in production mode on your local MacBook using Docker Compose.

**Monorepo Structure:** This project uses a monorepo organization:
- `note-agent-app/` - Rails API application
- `chrome-extension/` - Chrome extension for web capture (in development)
- Root directory - Docker orchestration and management scripts

## Quick Start

**Already have Docker installed?** Here's the fastest path to running:

```bash
# 1. Configure environment (edit .env.production)
#    - Add your ANTHROPIC_API_KEY
#    - Set OBSIDIAN_VAULT_PATH (no quotes, even with spaces/apostrophes)

# 2. Start everything
bin/production start

# 3. Create a user (after containers are healthy)
docker exec obsidian_note_agent_app bin/rails runner "
user = User.create!(email: 'you@example.com')
puts 'API Token: ' + user.api_token
"

# 4. Test it
curl -X POST http://localhost/api/v1/captures \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content": "Test note", "content_type": "conversation"}'

# Check your Obsidian vault's Captures folder!
```

Need more details? Read on!

## Table of Contents
- [Quick Start](#quick-start)
- [Prerequisites](#prerequisites)
- [Initial Setup](#initial-setup)
- [Starting the Production Environment](#starting-the-production-environment)
- [Stopping the Production Environment](#stopping-the-production-environment)
- [Creating Your First User](#creating-your-first-user)
- [Daily Usage](#daily-usage)
- [Troubleshooting](#troubleshooting)
- [Understanding the Setup](#understanding-the-setup)

## Prerequisites

1. **Docker Desktop** - Download from [docker.com](https://www.docker.com/products/docker-desktop/)
   - Install and ensure it's running (you'll see the Docker icon in your menu bar)
   - Requires at least 4GB of RAM allocated to Docker (check in Docker Desktop settings)

2. **Obsidian Vault** - Know the full path to your Obsidian vault directory
   - Example: `/Users/tomcoleman/Documents/MyVault`

3. **Anthropic API Key** - Get from [console.anthropic.com](https://console.anthropic.com/)
   - You'll need an active account with credits

## Initial Setup

### Step 1: Configure Environment Variables

1. Open `.env.production` in your text editor
2. Update the following values:

```bash
# Add your Anthropic API key (required)
ANTHROPIC_API_KEY=sk-ant-api03-...your-key-here

# Set your Obsidian vault path (required)
# Use absolute path - NO quotes needed, even with spaces or apostrophes
OBSIDIAN_VAULT_PATH=/Users/yourusername/Documents/MyVault
```

**Important Notes:**
- Use the **absolute path** to your Obsidian vault, not a relative path
- **Do NOT use quotes** around the path, even if it contains spaces or apostrophes
- Example with special characters: `OBSIDIAN_VAULT_PATH=/Users/tom/Documents/Tom's Notes`
- Docker Compose reads the value literally - quotes would be included in the path

### Step 2: Verify Docker is Running

1. Open Docker Desktop
2. Make sure the Docker engine is running (green whale icon in your menu bar)
3. Ensure you have at least 4GB RAM allocated in Docker Desktop preferences

## Starting the Production Environment

### First Time Start

The first time you start, Docker will build your application image (takes 5-10 minutes):

```bash
bin/production start
```

This command will:
1. Validate your `.env.production` configuration
2. Pull the MySQL 8 Docker image (if not already present)
3. Build your Rails application Docker image
4. Create and start both MySQL and Rails containers
5. Run database migrations automatically
6. Start Puma web server and Solid Queue background processor

**Expected output:**
```
Starting production environment...
Production environment started!
App available at: http://localhost
View logs: bin/production logs
```

### Subsequent Starts

After the first build, starting is much faster (just seconds):

```bash
bin/production start
```

### Checking Status

Verify both containers are running and healthy:

```bash
bin/production status
```

You should see:
```
NAME                      STATUS
obsidian_note_agent_app   Up X minutes (healthy)
obsidian_note_agent_db    Up X minutes (healthy)
```

### Viewing Logs

Watch application logs in real-time:

```bash
# Follow app logs
bin/production logs app

# Follow database logs
bin/production logs db

# View last 50 lines only
bin/production logs app | tail -50
```

Press `Ctrl+C` to stop following logs.

## Stopping the Production Environment

### Standard Stop

Stop all containers (data persists in volumes):

```bash
bin/production stop
```

This gracefully stops both containers but **preserves**:
- All database data
- User accounts
- Captures
- Configuration

### Restart

Restart without rebuilding:

```bash
bin/production restart
```

### Rebuild After Code Changes

If you modify Rails code or update gems, rebuild the Docker image:

```bash
bin/production rebuild
```

This rebuilds the image and restarts containers while preserving data.

## Creating Your First User

After the production environment is started, create a user account to access the API.

### Using Rails Runner (Recommended)

```bash
docker exec obsidian_note_agent_app bin/rails runner "
user = User.create!(email: 'your@email.com')
puts '================================'
puts 'User created successfully!'
puts '================================'
puts 'Email: ' + user.email
puts 'API Token: ' + user.api_token
puts 'Obsidian Vault Path: ' + user.obsidian_vault_path
puts '================================'
puts 'SAVE THIS API TOKEN!'
puts '================================'
"
```

**Important:**
- The `obsidian_vault_path` is automatically set to `/rails/obsidian_vault` (the container path)
- **Save the API token** - you'll need it for all API requests
- The vault path is the container's path, not your Mac's path - the volume mount handles the translation

### Using Rails Console

Alternatively, open Rails console:

```bash
bin/production console
```

Then create a user interactively:

```ruby
user = User.create!(email: "your@email.com")
puts user.api_token
# Save this token!
```

**Note:** In production, `obsidian_vault_path` defaults to `/rails/obsidian_vault` automatically.

### Testing Your Setup

Test the API with a capture:

```bash
curl -X POST http://localhost/api/v1/captures \
  -H "Authorization: Bearer YOUR_API_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "This is a test capture to verify everything works",
    "content_type": "conversation"
  }'
```

Wait 5-10 seconds, then check your Obsidian vault's `Captures` folder - you should see a new markdown file!

## Daily Usage

All daily operations use the `bin/production` script for convenience.

### Available Commands

```bash
bin/production start     # Start production environment
bin/production stop      # Stop production environment (data persists)
bin/production restart   # Restart without rebuilding
bin/production rebuild   # Rebuild Docker image and restart
bin/production logs      # View application logs
bin/production console   # Open Rails console
bin/production bash      # Open bash shell in app container
bin/production db        # Open MySQL console
bin/production status    # Show status of all services
bin/production clean     # Remove all containers and volumes (DESTRUCTIVE!)
bin/production help      # Show help message
```

### Common Workflows

**Daily startup:**
```bash
bin/production start
```

**Check if running:**
```bash
bin/production status
```

**View real-time logs:**
```bash
bin/production logs app
# Press Ctrl+C to stop
```

**Access Rails console:**
```bash
bin/production console
```

**Shutdown for the day:**
```bash
bin/production stop
```

**After updating code:**
```bash
bin/production rebuild
```

## Troubleshooting

### Common Issues and Solutions

#### Port 3306 Already in Use (MySQL Conflict)

**Symptom:**
```
Error: bind: address already in use (port 3306)
```

**Cause:** You have MySQL running locally on your Mac (common with Homebrew MySQL).

**Solution:** The `docker-compose.yml` is configured to use port 3307 on your Mac to avoid conflicts. If you still see this error, check:

```bash
lsof -i :3307  # See what's using port 3307
```

To temporarily stop local MySQL:
```bash
brew services stop mysql
```

#### Port 80 Already in Use

**Symptom:**
```
Error: bind: address already in use (port 80)
```

**Cause:** Apache or another web server is using port 80.

**Solutions:**

**Option 1:** Stop the conflicting service
```bash
sudo lsof -i :80  # Find what's using port 80
sudo apachectl stop  # If it's Apache
```

**Option 2:** Change the app port in `docker-compose.yml`:
```yaml
ports:
  - "8080:80"  # Use port 8080 instead
```
Then access via `http://localhost:8080`

#### Container Keeps Restarting

**Symptom:**
```bash
bin/production status
# Shows: Restarting (1) X seconds ago
```

**Diagnosis:**
```bash
docker logs obsidian_note_agent_app --tail 50
```

**Common causes:**

1. **Missing databases:** If you see "Access denied for database 'obsidian_note_agent_production_cache'":
   ```bash
   docker exec obsidian_note_agent_db mysql -u root -p[PASSWORD] -e "
   CREATE DATABASE IF NOT EXISTS obsidian_note_agent_production_cache;
   CREATE DATABASE IF NOT EXISTS obsidian_note_agent_production_queue;
   CREATE DATABASE IF NOT EXISTS obsidian_note_agent_production_cable;
   GRANT ALL PRIVILEGES ON obsidian_note_agent_production_cache.* TO 'obsidian_note_agent'@'%';
   GRANT ALL PRIVILEGES ON obsidian_note_agent_production_queue.* TO 'obsidian_note_agent'@'%';
   GRANT ALL PRIVILEGES ON obsidian_note_agent_production_cable.* TO 'obsidian_note_agent'@'%';
   FLUSH PRIVILEGES;
   "
   docker restart obsidian_note_agent_app
   ```

2. **Invalid RAILS_MASTER_KEY:** Verify the key in `.env.production` matches `config/master.key`

3. **Missing ANTHROPIC_API_KEY:** Check `.env.production` has a valid API key

#### Notes Not Appearing in Obsidian Vault

**Symptom:** Captures are processed (status: "published") but files don't appear on your Mac.

**Diagnosis:**
```bash
# Check if files exist inside container
docker exec obsidian_note_agent_app ls -la /rails/obsidian_vault/Captures/

# Check the actual volume mount
docker inspect obsidian_note_agent_app | grep -A5 "obsidian_vault"
```

**Common causes:**

1. **Incorrect volume mount path:**
   - Check `.env.production` has the **full** path without quotes:
   ```bash
   OBSIDIAN_VAULT_PATH=/Users/tom/Documents/Tom's Obsidian Notes
   ```
   - Even with apostrophes, do NOT use quotes
   - Verify the mount: `docker inspect` should show the complete path

2. **Wrong user vault path:**
   ```bash
   bin/production console
   User.first.obsidian_vault_path
   # Should return: "/rails/obsidian_vault"
   ```

3. **Permission issues:**
   - Container runs as user ID 1000
   - Check your vault directory permissions allow writing

4. **Obsidian vault path with special characters:**
   - If your path has apostrophes, spaces, or special characters, ensure no quotes in `.env.production`
   - Docker Compose reads values literally

**Fix for incorrect volume mount:**
```bash
# 1. Stop containers
bin/production stop

# 2. Fix OBSIDIAN_VAULT_PATH in .env.production (no quotes!)

# 3. Restart
bin/production start

# 4. Verify mount
docker inspect obsidian_note_agent_app | grep -A5 "obsidian_vault"
```

#### Database Connection Errors

**Symptom:**
```
ActiveRecord::DatabaseConnectionError
```

**Diagnosis:**
```bash
bin/production status  # Check if DB is healthy
bin/production logs db  # Check DB logs
```

**Solutions:**

1. Verify database is running and healthy:
   ```bash
   bin/production status
   # Both should show (healthy)
   ```

2. Check databases exist:
   ```bash
   bin/production db
   # In MySQL console:
   SHOW DATABASES;
   # Should see: obsidian_note_agent_production, _cache, _queue, _cable
   ```

3. Verify credentials in `.env.production` match docker-compose.yml

#### .env.production Parsing Errors

**Symptom:**
```
unexpected EOF while looking for matching quote
```

**Cause:** Apostrophe or special character in environment variable value.

**Solution:** The `bin/production` script doesn't need quotes for paths. Remove any quotes from `.env.production`:

```bash
# WRONG (with quotes)
OBSIDIAN_VAULT_PATH="/Users/tom/Tom's Notes"

# CORRECT (no quotes)
OBSIDIAN_VAULT_PATH=/Users/tom/Tom's Notes
```

#### Out of Memory

**Symptom:**
- Containers crash unexpectedly
- Logs show "Killed" messages
- Poor performance

**Solution:**

1. Open Docker Desktop
2. Go to Settings → Resources
3. Increase Memory to at least 4GB (8GB recommended)
4. Click "Apply & Restart"
5. Rebuild: `bin/production rebuild`

#### Debugging Tips

**View all logs together:**
```bash
docker-compose --env-file .env.production logs -f
```

**Check container resource usage:**
```bash
docker stats obsidian_note_agent_app obsidian_note_agent_db
```

**Inspect a specific capture:**
```bash
bin/production console
# Then in console:
capture = Capture.find(1)
puts "Status: #{capture.status}"
puts "Error: #{capture.error_message}"
puts "File: #{capture.obsidian_file_path}"
```

**Access container shell for debugging:**
```bash
bin/production bash
# Now you're inside the container
ls -la /rails/obsidian_vault/
cat /rails/log/production.log | tail -100
```

#### Clean Slate (Nuclear Option)

If something is really broken and you want to start completely fresh:

```bash
bin/production clean
```

**WARNING:** This command:
- Stops and removes all containers
- Deletes all volumes (including database data)
- **You will lose ALL data:** users, captures, configuration

You'll need to start from scratch:
```bash
bin/production start
# Then recreate users
```

Use this only as a last resort!

## Understanding the Setup

### Architecture

```
┌─────────────────────────────────────────┐
│         Your MacBook                     │
│                                          │
│  ┌────────────┐      ┌────────────┐    │
│  │   MySQL    │◄─────┤   Rails    │    │
│  │ Container  │      │  Container │    │
│  │            │      │            │    │
│  │  Port 3306 │      │  Port 80   │    │
│  └────────────┘      └────┬───────┘    │
│        │                   │            │
│   mysql_data          Obsidian Vault   │
│     Volume            Mount             │
│        │                   │            │
│  ┌─────▼──────┐      ┌────▼──────┐    │
│  │ Persistent │      │   Your    │    │
│  │  Database  │      │ Obsidian  │    │
│  │    Data    │      │   Vault   │    │
│  └────────────┘      └───────────┘    │
│                                         │
└─────────────────────────────────────────┘
```

### What Happens When You Run `bin/production start`

1. **Docker Compose reads** `docker-compose.yml` and `.env.production`
2. **MySQL container starts** first
   - Creates databases on first run
   - Data persists in `mysql_data` volume
3. **Health check waits** until MySQL is ready
4. **Rails container starts**
   - Builds from your Dockerfile
   - Runs `bin/docker-entrypoint` which migrates databases
   - Starts Puma web server with Thruster proxy
   - Starts Solid Queue for background jobs
5. **Volumes mount**:
   - Your Obsidian vault → `/rails/obsidian_vault` in container
   - Rails storage → persistent volume
6. **Port 80 exposes** your app to `http://localhost`

### Data Persistence

**Persistent (survives container restart):**
- MySQL database data (`mysql_data` volume)
- Rails storage files (`rails_storage` volume)
- Obsidian vault (directly on your Mac)

**Non-persistent (reset on container rebuild):**
- Application code (rebuilt from Dockerfile)
- Installed gems (rebuilt from Gemfile)
- Logs (unless you mount `/rails/log`)

### Security Considerations

**For Local Use:**
- Default passwords are okay since only accessible from your Mac
- Port 3306 exposed only to localhost
- API accessible only on localhost

**If Exposing to Network:**
1. Change all passwords in `.env.production`
2. Use stronger `MYSQL_ROOT_PASSWORD`
3. Consider adding SSL proxy (update `docker-compose.yml`)
4. Add firewall rules
5. Use environment-specific secrets

### Updating the Application

When you pull new code:

```bash
git pull
bin/production rebuild
```

This:
1. Rebuilds Docker image with new code
2. Runs new migrations automatically
3. Restarts the app

Your database data is preserved.

## Advanced Usage

### Customizing MySQL Configuration

Create `note-agent-app/config/mysql/production.cnf`:

```ini
[mysqld]
max_connections = 200
innodb_buffer_pool_size = 1G
```

Uncomment in `docker-compose.yml`:
```yaml
volumes:
  - ./note-agent-app/config/mysql/production.cnf:/etc/mysql/conf.d/custom.cnf
```

### Running Multiple Environments

Create separate compose files:
- `docker-compose.staging.yml`
- `docker-compose.production.yml`

Use with:
```bash
docker-compose -f docker-compose.staging.yml up -d
```

### Backing Up Data

**Database backup:**
```bash
docker-compose exec db mysqldump \
  -u root -p"${MYSQL_ROOT_PASSWORD}" \
  obsidian_note_agent_production > backup.sql
```

**Restore:**
```bash
docker-compose exec -T db mysql \
  -u root -p"${MYSQL_ROOT_PASSWORD}" \
  obsidian_note_agent_production < backup.sql
```

## Support

For issues specific to Docker Compose setup, check:
1. This guide's troubleshooting section
2. Docker Desktop logs
3. `bin/production logs` output

For application issues:
1. See main project README
2. Check Rails logs
3. Use Rails console to debug
