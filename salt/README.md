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
