# Development Environment: my-project

## Quick Start

1. **Open in VSCode**:
   ```bash
   code ../development/my-project/frappe_docker/
   ```

2. **Reopen in Container**:
   - Press `Ctrl+Shift+P` (Cmd+Shift+P on macOS)
   - Type: "Dev Containers: Reopen in Container"
   - Wait for container to build (first time takes 5-10 minutes)
   - **Note**: VSCode Explorer will be empty initially - this is normal!

3. **Automated Setup** (inside container terminal):
   ```bash
   cd development/
   ./setup-bench.sh
   ```
   
   **OR Manual Setup** (if you prefer step-by-step):
   ```bash
   cd development/
   bench init --skip-redis-config-generation --frappe-branch version-15 frappe-bench
   cd frappe-bench
   
   # Configure hosts
   bench set-config -g db_host mariadb
   bench set-config -g redis_cache redis://redis-cache:6379
   bench set-config -g redis_queue redis://redis-queue:6379
   bench set-config -g redis_socketio redis://redis-queue:6379
   
   # Edit Procfile for Redis containers
   sed -i '/redis/d' ./Procfile
   
   # Install ERPNext
   bench get-app --branch version-15 erpnext
   
   # Install MMP Core
   bench get-app --branch develop https://github.com/christophdanger/mmp_core.git
   
   # Create site
   bench new-site --no-mariadb-socket --admin-password admin development.localhost
   bench --site development.localhost install-app erpnext
   bench --site development.localhost install-app mmp_core
   
   # Enable developer mode
   bench --site development.localhost set-config developer_mode 1
   bench --site development.localhost clear-cache
   ```

4. **Start Development**:
   ```bash
   bench start
   ```
   
   Access: [http://development.localhost:8000](http://development.localhost:8000)
   Login: Administrator / admin

## Development Workflow

### Creating Custom Apps
```bash
# Inside the container
bench new-app my_custom_app
bench --site development.localhost install-app my_custom_app
```

### Building Production Image
When ready to deploy your custom app:

1. **Push to GitHub**:
   ```bash
   cd apps/my_custom_app
   git init && git add . && git commit -m "Initial commit"
   git remote add origin https://github.com/username/my_custom_app.git
   git push -u origin main
   ```

2. **Build Docker Image**:
   ```bash
   # From xpress/deploy/ directory
   ./build_mmp_stack.sh build --app github.com/username/my_custom_app:main --push
   ```

3. **Deploy for Testing**:
   ```bash
   ./deploy_mmp_local.sh deploy --ssl
   ```

## Environment Management

- **List environments**: `./dev_mmp_stack.sh list`
- **Environment info**: `./dev_mmp_stack.sh info my-project`
- **Clean up**: `./dev_mmp_stack.sh clean my-project`

## Prerequisites

- VSCode with "Dev Containers" extension
- Docker with at least 4GB memory allocation
- Git configured

