# Start Incus containers defined in pillar
# Usage: salt-run state.orchestrate incus.start

{% set containers = salt['pillar.get']('incus:containers', {}) %}

{% for name, config in containers.items() %}

{{ name }}_container_running:
  lxd_container.running:
    - name: {{ name }}

{% endfor %}
