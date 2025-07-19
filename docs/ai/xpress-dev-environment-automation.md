Looking at the xpress repository and the pain points in the current development setup, I can see several opportunities to streamline the developer experience. Let me propose a plan to extend the build and deployment scripts to automate the dev environment setup.

## Development Environment Automation Plan

### Current State Analysis
The current dev setup requires:
- Manual cloning of frappe_docker
- Copying devcontainer configs
- Manual bench initialization
- Multiple commands for site creation
- Manual app installation
- Separate steps for starting services

### Proposed Enhancement: `dev_mmp_stack.sh`

Create a new script that mirrors the simplicity of your deployment scripts but for development environments.

### Epic: Automated Development Environment Setup

**Goal**: Enable developers to go from zero to a fully functional MMP development environment with a single command.

### User Stories

#### 1. **One-Command Dev Setup**
```bash
./dev_mmp_stack.sh init --name my-mmp-dev
```
- Automatically clone and configure frappe_docker
- Set up devcontainer configurations
- Initialize bench with correct versions
- Create a development site
- Install specified apps (frappe, erpnext, mmp-core)
- Configure VSCode settings

#### 2. **Smart App Management**
```bash
./dev_mmp_stack.sh add-app --repo github.com/org/custom-app --branch develop
```
- Fetch and install apps into existing bench
- Handle dependencies automatically
- Update site with new app
- Rebuild assets if needed

#### 3. **Development Profile System**
```yaml
# profiles/mmp-full.yaml
name: mmp-full
frappe_version: version-15
apps:
  - name: erpnext
    branch: version-15
  - name: mmp-core
    repo: github.com/your-org/mmp-core
    branch: main
site:
  name: mmp-dev.localhost
  admin_password: auto
  developer_mode: true
services:
  thingsboard: true
  grafana: true
```

Usage:
```bash
./dev_mmp_stack.sh init --profile mmp-full
```

#### 4. **Integrated Service Management**
```bash
# Start everything including ThingsBoard and Grafana
./dev_mmp_stack.sh start --full-stack

# Start only Frappe/ERPNext
./dev_mmp_stack.sh start --core

# Add monitoring
./dev_mmp_stack.sh add-service grafana
```

#### 5. **Development Utilities**
```bash
# Quick database reset with fixtures
./dev_mmp_stack.sh reset-db --with-demo-data

# Sync with production schema
./dev_mmp_stack.sh sync-from --source prod-backup.sql

# Quick debugging setup
./dev_mmp_stack.sh debug --app erpnext --module manufacturing
```

### Technical Implementation Plan

#### Phase 1: Core Script Structure
```bash
dev_mmp_stack.sh
├── init          # Initialize new dev environment
├── start         # Start services
├── stop          # Stop services
├── add-app       # Add new app to bench
├── reset-db      # Database management
├── show-info     # Display access URLs and credentials
└── destroy       # Clean up environment
```

#### Phase 2: Integration Points
1. **Docker Compose Extension**
   - Extend the existing devcontainer setup
   - Add ThingsBoard and Grafana services
   - Configure networking for full stack

2. **Bench Automation**
   - Wrapper around bench commands
   - Error handling and recovery
   - Progress indicators

3. **VSCode Integration**
   - Auto-configure debugging
   - Set up recommended extensions
   - Configure workspace settings

#### Phase 3: Developer Experience Features
1. **Health Checks**
   ```bash
   ./dev_mmp_stack.sh doctor
   # Checks: Docker memory, ports, dependencies, etc.
   ```

2. **Quick Switching**
   ```bash
   ./dev_mmp_stack.sh switch --env client-a
   # Switch between different development environments
   ```

3. **Backup/Restore**
   ```bash
   ./dev_mmp_stack.sh backup --name before-upgrade
   ./dev_mmp_stack.sh restore --name before-upgrade
   ```

### Directory Structure Enhancement
```
xpress/
├── deploy/
│   ├── build_mmp_stack.sh
│   ├── deploy_mmp_local.sh
│   └── dev_mmp_stack.sh        # NEW
├── dev/                         # NEW
│   ├── profiles/               # Development profiles
│   ├── templates/              # Docker compose templates
│   └── scripts/                # Helper scripts
```

### Benefits
1. **Reduced Time to First Commit**: From hours to minutes
2. **Consistency**: Every developer gets the same environment
3. **MMP-Specific**: Pre-configured for MMP development needs
4. **Full Stack**: Includes ThingsBoard and Grafana out of the box
5. **Flexibility**: Easy to customize via profiles

### Next Steps
1. Create the base `dev_mmp_stack.sh` script
2. Implement the init command with basic functionality
3. Add profile support
4. Integrate ThingsBoard and Grafana
5. Add developer utilities
6. Documentation and examples

This approach maintains the philosophy of your existing scripts - smart defaults with flexibility when needed, while dramatically simplifying the developer onboarding experience for the MMP project.