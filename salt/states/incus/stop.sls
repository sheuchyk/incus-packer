# Stop Incus containers defined in pillar
# Usage: salt-run state.orchestrate incus.stop

{% set containers = salt['pillar.get']('incus:containers', {}) %}

{% for name, config in containers.items() %}

{{ name }}_container_stopped:
  lxd_container.stopped:
    - name: {{ name }}

{% endfor %}
