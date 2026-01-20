# Incus containers configuration
# Define your containers here

incus:
  containers:
    # Example web server
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

    # Example database server
    db1:
      image: debian-salt
      profiles:
        - default
      network:
        static_ip: 10.0.0.20
        gateway: 10.0.0.1
        netmask: 24
      salt_minion: true
      config:
        limits.cpu: "4"
        limits.memory: 4GB

    # Example app server without static IP (DHCP)
    # app1:
    #   image: ubuntu-salt
    #   profiles:
    #     - default
    #   salt_minion: true
