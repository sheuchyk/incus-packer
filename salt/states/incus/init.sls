# Incus container orchestration state
# Manages containers defined in pillar data

{% set containers = salt['pillar.get']('incus:containers', {}) %}

{% for name, config in containers.items() %}

{{ name }}_container:
  lxd_container.present:
    - name: {{ name }}
    - image: {{ config.get('image', 'ubuntu-salt') }}
    - running: {{ config.get('running', True) }}
    - profiles:
      {% for profile in config.get('profiles', ['default']) %}
      - {{ profile }}
      {% endfor %}
    {% if config.get('config') %}
    - config:
      {% for key, value in config.get('config', {}).items() %}
        {{ key }}: "{{ value }}"
      {% endfor %}
    {% endif %}
    {% if config.get('devices') %}
    - devices:
      {% for dev_name, dev_config in config.get('devices', {}).items() %}
        {{ dev_name }}:
          {% for key, value in dev_config.items() %}
          {{ key }}: "{{ value }}"
          {% endfor %}
      {% endfor %}
    {% endif %}

{% if config.get('network') and config.get('network').get('static_ip') %}
{{ name }}_static_ip:
  cmd.run:
    - name: |
        cat > /tmp/{{ name }}_netplan.yaml << 'EOF'
        network:
          version: 2
          ethernets:
            eth0:
              addresses:
                - {{ config.network.static_ip }}/{{ config.network.get('netmask', '24') }}
              routes:
                - to: default
                  via: {{ config.network.gateway }}
              nameservers:
                addresses: [{{ config.network.get('dns', '8.8.8.8, 8.8.4.4') }}]
        EOF
        incus file push /tmp/{{ name }}_netplan.yaml {{ name }}/etc/netplan/50-static.yaml
        incus exec {{ name }} -- chmod 600 /etc/netplan/50-static.yaml
        incus exec {{ name }} -- rm -f /etc/netplan/10-incus.yaml 2>/dev/null || true
        incus exec {{ name }} -- netplan apply
        incus config device override {{ name }} eth0 ipv4.address="{{ config.network.static_ip }}"
        rm /tmp/{{ name }}_netplan.yaml
    - require:
      - lxd_container: {{ name }}_container
    - onchanges:
      - lxd_container: {{ name }}_container
{% endif %}

{% if config.get('salt_minion', True) %}
{{ name }}_salt_minion:
  cmd.run:
    - name: |
        incus exec {{ name }} -- systemctl enable salt-minion
        incus exec {{ name }} -- systemctl restart salt-minion
    - require:
      - lxd_container: {{ name }}_container
    {% if config.get('network') and config.get('network').get('static_ip') %}
      - cmd: {{ name }}_static_ip
    {% endif %}
    - onchanges:
      - lxd_container: {{ name }}_container
{% endif %}

{% endfor %}
