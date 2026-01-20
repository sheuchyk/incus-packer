# Destroy Incus containers defined in pillar
# Usage: salt-run state.orchestrate incus.destroy

{% set containers = salt['pillar.get']('incus:containers', {}) %}

{% for name, config in containers.items() %}

{{ name }}_container_absent:
  lxd_container.absent:
    - name: {{ name }}
    - stop: True

{% endfor %}
