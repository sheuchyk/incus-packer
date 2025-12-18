# Common system configuration

timezone_setup:
  timezone.system:
    - name: UTC

locale_setup:
  locale.present:
    - name: en_US.UTF-8
