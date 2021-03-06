default_target: all

.PHONY: update_all clone_all coqutil riscv-coq bedrock2 compiler kami processor end2end all clean_coqutil clean_riscv-coq clean_bedrock2 clean_compiler clean_kami clean_processor clean_end2end clean_manglenames clean install_bedrock2 install_compiler install_processor install_end2end install

clone_all:
	git submodule update --init --recursive

update_all:
	git submodule update --recursive

REL_PATH_OF_THIS_MAKEFILE:=$(lastword $(MAKEFILE_LIST))
ABS_ROOT_DIR:=$(abspath $(dir $(REL_PATH_OF_THIS_MAKEFILE)))
# use cygpath -m because Coq on Windows cannot handle cygwin paths
ABS_ROOT_DIR:=$(shell cygpath -m '$(ABS_ROOT_DIR)' 2>/dev/null || echo '$(ABS_ROOT_DIR)')

DEPS_DIR ?= $(ABS_ROOT_DIR)/deps
export DEPS_DIR

ifeq ($(TRY_MANGLE_NAMES),1)
COQC := $(ABS_ROOT_DIR)/coqc-try-mangle-names.sh
export COQC
endif

EXTERNAL_DEPENDENCIES?=

ifneq ($(EXTERNAL_DEPENDENCIES),1)

bedrock2: coqutil
riscv-coq: coqutil
kami: riscv-coq
compiler: riscv-coq bedrock2
processor: riscv-coq kami
end2end: compiler bedrock2 processor
all: bedrock2 compiler processor end2end
clean: clean_coqutil clean_riscv-coq clean_kami

endif


clean_manglenames:
	find . -type f -name '*.manglenames' -delete

coqutil:
	$(MAKE) -C $(DEPS_DIR)/coqutil

clean_coqutil:
	$(MAKE) -C $(DEPS_DIR)/coqutil clean

kami:
	$(MAKE) -C $(DEPS_DIR)/kami

clean_kami:
	$(MAKE) -C $(DEPS_DIR)/kami clean

riscv-coq:
	$(MAKE) -C $(DEPS_DIR)/riscv-coq all

clean_riscv-coq:
	$(MAKE) -C $(DEPS_DIR)/riscv-coq clean

bedrock2:
	$(MAKE) -C $(ABS_ROOT_DIR)/bedrock2

clean_bedrock2:
	$(MAKE) -C $(ABS_ROOT_DIR)/bedrock2 clean

install_bedrock2:
	$(MAKE) -C $(ABS_ROOT_DIR)/bedrock2 install

compiler:
	$(MAKE) -C $(ABS_ROOT_DIR)/compiler

clean_compiler:
	$(MAKE) -C $(ABS_ROOT_DIR)/compiler clean

install_compiler:
	$(MAKE) -C $(ABS_ROOT_DIR)/compiler install

processor:
	$(MAKE) -C $(ABS_ROOT_DIR)/processor

clean_processor:
	$(MAKE) -C $(ABS_ROOT_DIR)/processor clean

install_processor:
	$(MAKE) -C $(ABS_ROOT_DIR)/processor install

end2end:
	$(MAKE) -C $(ABS_ROOT_DIR)/end2end

clean_end2end:
	$(MAKE) -C $(ABS_ROOT_DIR)/end2end clean

install_end2end:
	$(MAKE) -C $(ABS_ROOT_DIR)/end2end install

all: bedrock2 compiler processor end2end

clean: clean_bedrock2 clean_compiler clean_processor clean_end2end

install: install_bedrock2 install_compiler install_processor install_end2end
