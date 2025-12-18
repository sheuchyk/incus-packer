# Package management

{% set packages = salt['pillar.get']('packages:install', ['curl', 'wget', 'vim']) %}

install_packages:
  pkg.installed:
    - pkgs:
      {% for pkg in packages %}
      - {{ pkg }}
      {% endfor %}
    - refresh: True
