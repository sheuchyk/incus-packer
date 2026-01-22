# Salt Configuration

This directory contains Salt states and pillars for provisioning images with Packer.

## Structure

```
salt/
├── minion              # Salt minion config (masterless mode)
├── pillar/             # Pillar data (configuration values)
│   ├── top.sls         # Pillar targeting
│   ├── common.sls      # Common configuration
│   └── packages.sls    # Package list
└── states/             # Salt states
    ├── top.sls         # State targeting
    ├── common/         # Common state module
    │   └── init.sls
    └── packages/       # Package installation state
        └── init.sls
```

## Usage with Packer

Use the `templates/ubuntu-salt.pkr.hcl` template:

```bash
cd templates
packer build ubuntu-salt.pkr.hcl
```

## Adding New States

1. Create a new directory in `states/` (e.g., `states/nginx/`)
2. Add `init.sls` with your state definition
3. Include the state in `states/top.sls`
4. Add any pillar data to `pillar/`

## Example: Adding nginx

```yaml
# states/nginx/init.sls
nginx:
  pkg.installed: []
  service.running:
    - enable: True
```

## Container Orchestration

Salt states for managing Incus containers are in `states/incus/`.

### Defining Containers

Edit `pillar/incus.sls` to define your containers:

```yaml
incus:
  containers:
    web1:
      image: ubuntu-salt
      profiles:
        - default
      network:
        static_ip: 10.0.0.10
        gateway: 10.0.0.1
        netmask: 24
        dns: "8.8.8.8, 8.8.4.4"
      salt_minion: true
      config:
        limits.cpu: "2"
        limits.memory: 2GB
```

### Available States

```bash
# Create/update all containers
salt 'salt-master' state.apply incus
salt 's-0-2' state.apply incus

# Stop all containers
salt 'salt-master' state.apply incus.stop

# Start all containers
salt 'salt-master' state.apply incus.start

# Destroy all containers
salt 'salt-master' state.apply incus.destroy
```

### Container Options

| Option | Description | Default |
|--------|-------------|---------|
| `image` | Incus image name | `ubuntu-salt` |
| `profiles` | List of Incus profiles | `['default']` |
| `running` | Start container after creation | `true` |
| `salt_minion` | Enable and start salt-minion | `true` |
| `network.static_ip` | Static IP address | - |
| `network.gateway` | Gateway address | - |
| `network.netmask` | Network mask | `24` |
| `network.dns` | DNS servers | `8.8.8.8, 8.8.4.4` |
| `config` | Incus config options | - |
| `devices` | Incus device config | - |
