# Incus Packer Image Builder

Проект для сборки Incus образов с использованием HashiCorp Packer.

## Требования

- [Packer](https://www.packer.io/downloads) >= 1.7.0
- [Incus](https://linuxcontainers.org/incus/) установлен и настроен
- Linux система с поддержкой контейнеров

## Установка и настройка incus

```
sudo apt update
sudo apt install -y git build-essential
```

## Установка и настройка packer

```
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install packer
```

### Установка ZFS

```bash
sudo apt update
sudo apt install -y zfsutils-linux
```

### Создание ZFS пула

```bash
# Создание RAIDZ1 пула из трёх NVMe дисков
sudo zpool create -f incus-pool raidz1 /dev/nvme1n1 /dev/nvme2n1 /dev/nvme3n1

# Проверка пула
sudo zpool status incus-pool

# Включение сжатия
sudo zfs set compression=lz4 incus-pool
```

### Добавление пользователя в группу incus

```bash
sudo gpasswd --add $USER incus-admin
sudo usermod -aG incus-admin $(whoami)
newgrp incus-admin
```

### Инициализация Incus с ZFS

```bash
incus admin init
```

При инициализации выберите:

- Storage backend: **zfs**
- Create a new ZFS pool: **no**
- Name of the existing ZFS pool: **incus-pool**

## Структура проекта

```
.
├── plugins.pkr.hcl          # Конфигурация плагинов Packer
├── Makefile                 # Автоматизация сборки
├── README.md
├── templates/               # Шаблоны образов
│   ├── ubuntu.pkr.hcl       # Ubuntu образ
│   ├── ubuntu-salt.pkr.hcl  # Ubuntu образ с Salt provisioner
│   ├── ubuntu-salt-master.pkr.hcl  # Ubuntu образ с Salt Master
│   ├── debian.pkr.hcl       # Debian образ
│   └── alpine.pkr.hcl       # Alpine образ
├── salt/                    # Salt конфигурация
│   ├── master               # Конфиг Salt Master
│   ├── minion.build         # Конфиг для masterless сборки
│   ├── minion.production    # Конфиг для подключения к master
│   ├── states/              # Salt states
│   └── pillar/              # Pillar данные
├── scripts/                 # Provisioning скрипты
│   ├── common.sh            # Общие настройки
│   ├── security.sh          # Настройки безопасности
│   └── cleanup.sh           # Очистка образа
└── variables/               # Файлы переменных
    └── common.pkrvars.hcl
```

## Быстрый старт

### 1. Инициализация

```bash
make init
```

### 2. Валидация шаблонов

```bash
make validate
```

### 3. Сборка образов

```bash
# Сборка Ubuntu образа (контейнер)
make build-ubuntu

# Сборка Debian образа
make build-debian

# Сборка Alpine образа
make build-alpine

# Сборка Ubuntu с Salt provisioner
make build-ubuntu-salt

# Сборка Ubuntu с Salt Master
make build-ubuntu-salt-master

# Сборка всех образов
make build-all
```

### 4. Сборка виртуальных машин

```bash
# Ubuntu VM
make build-ubuntu VM=true

# С указанием профиля
make build-ubuntu VM=true PROFILE=myprofile
```

## Ручная сборка

```bash
# Инициализация плагинов
packer init .

# Сборка Ubuntu
cd templates
packer build ubuntu.pkr.hcl

# Сборка с переменными
packer build -var 'image_name=my-ubuntu' -var 'virtual_machine=true' ubuntu.pkr.hcl
```

## Переменные

| Переменная          | Описание             | По умолчанию                                                      |
| ------------------- | -------------------- | ----------------------------------------------------------------- |
| `image_name`        | Имя выходного образа | `ubuntu-custom` / `debian-custom` / `alpine-custom`               |
| `image_description` | Описание образа      | `Custom <distro> image built with Packer`                         |
| `source_image`      | Исходный образ       | `images:ubuntu/24.04` / `images:debian/12` / `images:alpine/3.20` |
| `install_packages`  | Пакеты для установки | `["curl", "wget", "vim"]`                                         |
| `virtual_machine`   | Сборка как VM        | `false`                                                           |
| `profile`           | Профиль Incus        | `default`                                                         |

## Использование собранных образов

```bash
# Просмотр образов
incus image list

# Создание контейнера из образа
incus launch ubuntu-custom my-container

# Создание VM из образа
incus launch ubuntu-custom my-vm --vm
```

## Добавление своих скриптов

Добавьте скрипты в папку `scripts/` и подключите их в шаблоне:

```hcl
provisioner "shell" {
  scripts = [
    "../scripts/common.sh",
    "../scripts/your-script.sh"
  ]
}
```

## Использование Salt

Проект поддерживает provisioning с помощью Salt в masterless режиме. Salt конфигурация находится в папке `salt/`.

### Структура Salt

```
salt/
├── master              # Конфиг Salt Master
├── minion.build        # Конфиг для masterless сборки образа
├── minion.production   # Конфиг для подключения к master (10.39.46.91)
├── pillar/             # Pillar данные (переменные)
│   ├── top.sls
│   ├── common.sls
│   └── packages.sls
└── states/             # Salt states
    ├── top.sls
    ├── common/init.sls
    └── packages/init.sls
```

### Сборка образа с Salt

При сборке образа используется `minion.build` для masterless провижининга. Конфиг удаляется после применения states — образ не содержит настроек подключения к master.

```bash
# Сборка образа с Salt minion
make build-ubuntu-salt

# Сборка образа с Salt Master
make build-debian-salt-master
```

### Запуск контейнера с подключением к Master

После сборки образа контейнер не содержит конфигурации minion. Для запуска с подключением к master используйте скрипт:

```bash
./scripts/deploy-minion.sh <container-name> [image-name]

# Пример
./scripts/deploy-minion.sh web-server ubuntu-salt
```

Скрипт:
1. Создаёт контейнер из образа
2. Копирует `minion.production` в `/etc/salt/minion`
3. Запускает `salt-minion` сервис

После запуска примите ключ на master:
```bash
salt-key -a <container-name>
```

### Изменение адреса Master

Отредактируйте `salt/minion.production`:
```yaml
master: <новый-ip-или-hostname>
```

### Добавление нового state

1. Создайте директорию в `salt/states/` (например, `nginx/`)
2. Добавьте `init.sls` с описанием state
3. Включите state в `salt/states/top.sls`
4. При необходимости добавьте pillar данные в `salt/pillar/`

Пример `salt/states/nginx/init.sls`:

```yaml
nginx:
  pkg.installed: []
  service.running:
    - enable: True
```

## Доступные исходные образы

Список доступных образов можно получить командой:

```bash
incus image list images:
```

Популярные образы:

- `images:ubuntu/24.04` - Ubuntu 24.04 LTS
- `images:ubuntu/22.04` - Ubuntu 22.04 LTS
- `images:debian/12` - Debian 12 (Bookworm)
- `images:debian/11` - Debian 11 (Bullseye)
- `images:alpine/3.20` - Alpine 3.20
- `images:centos/9-Stream` - CentOS Stream 9
- `images:rockylinux/9` - Rocky Linux 9

## Лицензия

MIT
