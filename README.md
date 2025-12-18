# Incus Packer Image Builder

Проект для сборки Incus образов с использованием HashiCorp Packer.

## Требования

- [Packer](https://www.packer.io/downloads) >= 1.7.0
- [Incus](https://linuxcontainers.org/incus/) установлен и настроен
- Linux система с поддержкой контейнеров

## Структура проекта

```
.
├── plugins.pkr.hcl          # Конфигурация плагинов Packer
├── Makefile                 # Автоматизация сборки
├── README.md
├── templates/               # Шаблоны образов
│   ├── ubuntu.pkr.hcl       # Ubuntu образ
│   ├── ubuntu-salt.pkr.hcl  # Ubuntu образ с Salt provisioner
│   ├── debian.pkr.hcl       # Debian образ
│   └── alpine.pkr.hcl       # Alpine образ
├── salt/                    # Salt конфигурация
│   ├── minion               # Конфиг для masterless режима
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

| Переменная | Описание | По умолчанию |
|------------|----------|--------------|
| `image_name` | Имя выходного образа | `ubuntu-custom` / `debian-custom` / `alpine-custom` |
| `image_description` | Описание образа | `Custom <distro> image built with Packer` |
| `source_image` | Исходный образ | `images:ubuntu/24.04` / `images:debian/12` / `images:alpine/3.20` |
| `install_packages` | Пакеты для установки | `["curl", "wget", "vim"]` |
| `virtual_machine` | Сборка как VM | `false` |
| `profile` | Профиль Incus | `default` |

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
├── minion              # Конфиг Salt minion
├── pillar/             # Pillar данные (переменные)
│   ├── top.sls
│   ├── common.sls
│   └── packages.sls
└── states/             # Salt states
    ├── top.sls
    ├── common/init.sls
    └── packages/init.sls
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
