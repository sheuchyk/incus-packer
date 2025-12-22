.PHONY: init validate build-ubuntu build-ubuntu-salt build-ubuntu-salt-master build-debian build-debian-salt build-debian-salt-master build-alpine build-all clean help

PACKER := packer
TEMPLATES_DIR := templates
VARIABLES_DIR := variables

help:
	@echo "Incus Packer Image Builder"
	@echo ""
	@echo "Usage:"
	@echo "  make init           - Initialize Packer and download plugins"
	@echo "  make validate       - Validate all Packer templates"
	@echo "  make build-ubuntu      - Build Ubuntu image"
	@echo "  make build-ubuntu-salt - Build Ubuntu image with Salt provisioner"
	@echo "  make build-ubuntu-salt-master - Build Ubuntu image with Salt Master installed"
	@echo "  make build-debian   - Build Debian image"
	@echo "  make build-debian-salt - Build Debian image with Salt provisioner"
	@echo "  make build-debian-salt-master - Build Debian image with Salt Master installed"
	@echo "  make build-alpine   - Build Alpine image"
	@echo "  make build-all      - Build all images"
	@echo "  make clean          - Remove build artifacts"
	@echo ""
	@echo "Options:"
	@echo "  VM=true             - Build as virtual machine (e.g., make build-ubuntu VM=true)"
	@echo "  PROFILE=myprofile   - Use specific Incus profile"

init:
	$(PACKER) init .

validate:
	cd $(TEMPLATES_DIR) && $(PACKER) validate ubuntu.pkr.hcl
	cd $(TEMPLATES_DIR) && $(PACKER) validate ubuntu-salt.pkr.hcl
	cd $(TEMPLATES_DIR) && $(PACKER) validate ubuntu-salt-master.pkr.hcl
	cd $(TEMPLATES_DIR) && $(PACKER) validate debian.pkr.hcl
	cd $(TEMPLATES_DIR) && $(PACKER) validate debian-salt.pkr.hcl
	cd $(TEMPLATES_DIR) && $(PACKER) validate debian-salt-master.pkr.hcl
	cd $(TEMPLATES_DIR) && $(PACKER) validate alpine.pkr.hcl

build-ubuntu: init
	cd $(TEMPLATES_DIR) && $(PACKER) build \
		$(if $(VM),-var 'virtual_machine=true',) \
		$(if $(PROFILE),-var 'profile=$(PROFILE)',) \
		ubuntu.pkr.hcl

build-ubuntu-salt: init
	cd $(TEMPLATES_DIR) && $(PACKER) build \
		$(if $(VM),-var 'virtual_machine=true',) \
		$(if $(PROFILE),-var 'profile=$(PROFILE)',) \
		ubuntu-salt.pkr.hcl

build-ubuntu-salt-master: init
	cd $(TEMPLATES_DIR) && $(PACKER) build \
		$(if $(VM),-var 'virtual_machine=true',) \
		$(if $(PROFILE),-var 'profile=$(PROFILE)',) \
		ubuntu-salt-master.pkr.hcl

build-debian: init
	cd $(TEMPLATES_DIR) && $(PACKER) build \
		$(if $(VM),-var 'virtual_machine=true',) \
		$(if $(PROFILE),-var 'profile=$(PROFILE)',) \
		debian.pkr.hcl

build-debian-salt: init
	cd $(TEMPLATES_DIR) && $(PACKER) build \
		$(if $(VM),-var 'virtual_machine=true',) \
		$(if $(PROFILE),-var 'profile=$(PROFILE)',) \
		debian-salt.pkr.hcl

build-debian-salt-master: init
	cd $(TEMPLATES_DIR) && $(PACKER) build \
		$(if $(VM),-var 'virtual_machine=true',) \
		$(if $(PROFILE),-var 'profile=$(PROFILE)',) \
		debian-salt-master.pkr.hcl

build-alpine: init
	cd $(TEMPLATES_DIR) && $(PACKER) build \
		$(if $(VM),-var 'virtual_machine=true',) \
		$(if $(PROFILE),-var 'profile=$(PROFILE)',) \
		alpine.pkr.hcl

build-all: build-ubuntu build-ubuntu-salt build-ubuntu-salt-master build-debian build-debian-salt build-debian-salt-master build-alpine

clean:
	@echo "Cleaning up..."
	rm -rf packer_cache
	@echo "Note: To remove built images, use 'incus image delete <image-name>'"
