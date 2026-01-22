# Incus containers configuration
# Define your containers here

incus:
  containers:
    # salt-master server
    salt-master:
      image: debian-salt-master
      profiles:
        - default
      network:
        static_ip: 172.16.0.4
        gateway: 172.16.0.2
        netmask: 24
        dns: "172.16.0.241, 172.16.0.242"
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
        static_ip: 172.16.0.5
        gateway: 172.16.0.2
        netmask: 24
        dns: "172.16.0.241, 172.16.0.242"
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
