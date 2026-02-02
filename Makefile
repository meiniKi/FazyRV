
CUR_DIR := $(shell pwd)
SCRIPT := $(CUR_DIR)/script

YOSYS := yosys
SVLINT := svlint
SLANG := slang
PYTHON := python
MAKE := make
BASH := bash
VERILATOR := verilator

TARGET_ARCH ?= ice40
COMMIT ?= n/a

################################
# Synthesis combinations 
#

SYNTH_CHUNKSIZES 	:= 1 2 4 8
SYNTH_CONFS 		:= MIN
SYNTH_RF 			:= LOGIC BRAM BRAM_BP BRAM_DP BRAM_DP_BP

# Synth param:  <CHUNKSIZE>-<CONF>-<RFTYPE>
SYNTH_PARAMS := $(foreach bdwidth,$(SYNTH_CHUNKSIZES),\
				$(foreach conf,$(SYNTH_CONFS),\
				$(foreach rf,$(SYNTH_RF),$(bdwidth)-$(conf)-$(rf))))


################################
# Plot combinations 
#

PLOT_CHUNKSIZES := 1 2 4 8
PLOT_CONFS 		:= MIN
PLOT_RF 		:= BRAM BRAM_DP_BP

# Plot param:  <CHUNKSIZE>-<CONF>-<RFTYPE>
PLOT_PARAMS := $(foreach bdwidth,$(PLOT_CHUNKSIZES),\
				$(foreach conf,$(PLOT_CONFS),\
				$(foreach rf,$(PLOT_RF),$(bdwidth)-$(conf)-$(rf))))


################################
# Formal chuck sizes to verify 
#

RVF_CHUNKSIZES := 8 4 2 1


################################
# Simulation combinations 
#

RVTESTS_CHUNKSIZES := 8 4 2 1
RVTESTS_CONF_RF := MIN-LOGIC MIN-BRAM MIN-BRAM_BP MIN-BRAM_DP MIN-BRAM_DP_BP

RVTESTS_PARAMS	:= 	$(foreach bdwidth,$(RVTESTS_CHUNKSIZES),\
					$(foreach con_rf,$(RVTESTS_CONF_RF),$(bdwidth)-$(con_rf)))


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
RESET='\033[0m'

SRC_DESIGN := $(wildcard rtl/*.v rtl/*.sv)
SRC_SYNTH := $(wildcard soc/rtl/*.v soc/rtl/*.sv)

TOP_MODULE_SOC := fsoc
TOP_MODULE_CORE := fazyrv_core
TOP_MODULE_TOP := fazyrv_top

WORK_DIR_MAIN		:= work

WORK_DIR_CORE		:= $(WORK_DIR_MAIN)/work_core
WORK_DIR_SOC		:= $(WORK_DIR_MAIN)/work_soc
WORK_DIR_RISCOF		:= $(WORK_DIR_MAIN)/work_riscof

SUMMARY_DIR_SOC			:= $(WORK_DIR_MAIN)/summary_fsoc_soc
SUMMARY_DIR_CORE		:= $(WORK_DIR_MAIN)/summary_fazyrv
SUMMARY_DIR_RISCOF 		:= $(WORK_DIR_MAIN)/summary_riscof
SUMMARY_DIR_RISCVTESTS 	:= $(WORK_DIR_MAIN)/summary_riscvtests

get_depth_value = $(if $(filter $(1),8),21,\
					$(if $(filter $(1),4),33,\
					$(if $(filter $(1),2),57,\
					$(if $(filter $(1),1),105,\
					<THROW_ERROR>))))

################################
################################
################################

################
# lint
#

lint.svlint: $(SRC_DESIGN)
	$(SVLINT) $^

lint.slang: $(SRC_DESIGN)
	$(SLANG) --lint-only $^

lint.verilator: $(SRC_DESIGN)
	$(VERILATOR) --lint-only -Wall -Wno-GENUNNAMED -Wno-WIDTHEXPAND -Wno-UNUSEDPARAM -Wno-UNUSEDSIGNAL -Wno-WIDTHTRUNC -Wno-CASEOVERLAP $^

################
# RISCV-TESTS 
#

# param: <CHUNKSIZE>-<CONF>-<RFTYPE>
sim.riscvtests.%: $(SRC_DESIGN) $(SRC_SYNTH)
	@echo "${BLUE}Simulating riscvtests for $*...${RESET}"
	$(eval CHUNKSIZE=$(word 1,$(subst -, ,$*)))
	$(eval CONF=$(word 2,$(subst -, ,$*)))
	$(eval RF=$(word 3,$(subst -, ,$*)))
	@echo "CHUNKSIZE: $(CHUNKSIZE)"
	@echo "CONF: $(CONF)"
	@echo "RF: $(RF)"
	mkdir -p $(SUMMARY_DIR_RISCVTESTS)
	@if [ "$(RF)" = "LOGIC" ] || [ "$(CONF)" = "MIN" ]; then \
		$(MAKE) -C sim test CHUNKSIZE=$(CHUNKSIZE) RFTYPE=$(RF) CONF=$(CONF) WITH_CSR=0; \
	else \
		$(MAKE) -C sim test CHUNKSIZE=$(CHUNKSIZE) RFYPE=$(RF) CONF=$(CONF) WITH_CSR=1; \
	fi
	@echo $$? > $(SUMMARY_DIR_RISCVTESTS)/$*.log
	$(MAKE) -C sim clean

report.riscvtests.all: $(addprefix sim.riscvtests., $(RVTESTS_PARAMS))
	@echo "${BLUE}Generating riscvtests table for all combinations${RESET}"
	$(SCRIPT)/rvtests_table.sh $(SUMMARY_DIR_RISCVTESTS)


################
# RISCOF 
#

riscof.prepare: dv/config.ini
	fusesoc library add fsoc .
	riscof arch-test --clone
	riscof validateyaml --config=dv/config.ini

# param: <CHUNKSIZE>-<CONF>-<RFTYPE>
riscof.run.%: $(SRC_DESIGN) $(SRC_SYNTH)
	@echo "${BLUE}Simulating riscvtests for $*...${RESET}"
	$(eval CHUNKSIZE=$(word 1,$(subst -, ,$*)))
	$(eval CONF=$(word 2,$(subst -, ,$*)))
	$(eval RF=$(word 3,$(subst -, ,$*)))
	@echo "CHUNKSIZE: $(CHUNKSIZE)"
	@echo "CONF: $(CONF)"
	@echo "RF: $(RF)"
	mkdir -p $(WORK_DIR_RISCOF)
	mkdir -p $(SUMMARY_DIR_RISCOF)
	riscof testlist --config=dv/config.ini --suite=riscv-arch-test/riscv-test-suite/ --env=riscv-arch-test/riscv-test-suite/env
	RISCOF_CHUNKSIZE=$(CHUNKSIZE) RISCOF_CONF=$(CONF) RISCOF_RFTYPE=$(RF) \
		riscof run --no-browser --config=dv/config.ini --suite=riscv-arch-test/riscv-test-suite/ --env=riscv-arch-test/riscv-test-suite/env 2>&1 | tee $(SUMMARY_DIR_RISCOF)/tmp.txt
	@ ! grep -q -e "Failed" -e "ERROR" $(SUMMARY_DIR_RISCOF)/tmp.txt
	@echo $$? > $(SUMMARY_DIR_RISCOF)/$*.log
	@rm $(SUMMARY_DIR_RISCOF)/tmp.txt
# riscof exit code does not report failures, see Issue #102
# workaround using the tmp.txt file

riscof.all: $(addprefix riscof.run., $(RVTESTS_PARAMS))
	@if [ -z "$$(find $(SUMMARY_DIR_RISCOF) -name '*.log')" ]; then \
		echo "Error: No *.log files found"; \
		exit 1; \
	fi

	@for log_file in $$(find $(SUMMARY_DIR_RISCOF) -name '*.log'); do \
		if [ "$$(cat $$log_file)" != "0" ]; then \
			echo "Error: $$log_file RISCOF failed"; \
			exit 1; \
		fi; \
	done


################
# Formal 
#

_fv.rvformal.prepare:
	if [ ! -d riscv-formal ]; then \
		echo "[Error] riscv-formal does not exist. Are submodules initialized?"; \
		exit 1; \
	fi
	mkdir -p riscv-formal/cores/fazyrv/rtl
	cp rtl/* riscv-formal/cores/fazyrv/rtl
	cp rvf/* riscv-formal/cores/fazyrv/


# param: <CHUNKSIZE>
fv.rvformal.bmc.insn.%:
	make _fv.rvformal.prepare
	sed -E -i 's/(`define CHUNKSIZE )\S+/\1 $*/' riscv-formal/cores/fazyrv/checks_bmc_insn.cfg
	sed -i -E "s/<INSERT_DEPTH>/$(call get_depth_value, $*)/" riscv-formal/cores/fazyrv/checks_bmc_insn.cfg
	cd riscv-formal/cores/fazyrv && $(PYTHON) ../../checks/genchecks.py checks_bmc_insn
	$(MAKE) -C riscv-formal/cores/fazyrv/checks_bmc_insn
	cd riscv-formal/cores/fazyrv && ./stats.sh checks_bmc_insn
	cd riscv-formal/cores/fazyrv && rm -vrf checks

# param: <CHUNKSIZE>
fv.rvformal.bmc.reg.%:
	make _fv.rvformal.prepare
	sed -E -i 's/(`define CHUNKSIZE )\S+/\1 $*/' riscv-formal/cores/fazyrv/checks_bmc_reg.cfg
	sed -i -E "s/<INSERT_DEPTH>/$(call get_depth_value, $*)/" riscv-formal/cores/fazyrv/checks_bmc_reg.cfg
	cd riscv-formal/cores/fazyrv && $(PYTHON) ../../checks/genchecks.py checks_bmc_reg
	$(MAKE) -C riscv-formal/cores/fazyrv/checks_bmc_reg
	cd riscv-formal/cores/fazyrv && ./stats.sh checks_bmc_reg
	cd riscv-formal/cores/fazyrv && rm -vrf checks

# param: <CHUNKSIZE>
fv.rvformal.cov.insn.%:
	make _fv.rvformal.prepare
	sed -E -i 's/(`define CHUNKSIZE )\S+/\1 $*/' riscv-formal/cores/fazyrv/checks_cov_insn.cfg
	sed -i -E "s/<INSERT_DEPTH>/$(call get_depth_value, $*)/" riscv-formal/cores/fazyrv/checks_cov_insn.cfg
	cd riscv-formal/cores/fazyrv && $(PYTHON) ../../checks/genchecks.py checks_cov_insn
	$(MAKE) -C riscv-formal/cores/fazyrv/checks_cov_insn
	cd riscv-formal/cores/fazyrv && ./stats.sh checks_cov_insn
	cd riscv-formal/cores/fazyrv && rm -vrf checks

# param: <CHUNKSIZE>
fv.rvformal.cov.reg.%:
	make _fv.rvformal.prepare
	sed -E -i 's/(`define CHUNKSIZE )\S+/\1 $*/' riscv-formal/cores/fazyrv/checks_cov_reg.cfg
	sed -i -E "s/<INSERT_DEPTH>/$(call get_depth_value, $*)/" riscv-formal/cores/fazyrv/checks_cov_reg.cfg
	cd riscv-formal/cores/fazyrv && $(PYTHON) ../../checks/genchecks.py checks_cov_reg
	$(MAKE) -C riscv-formal/cores/fazyrv/checks_cov_reg
	cd riscv-formal/cores/fazyrv && ./stats.sh checks_cov_reg
	cd riscv-formal/cores/fazyrv && rm -vrf checks


fv.rvformal.all.bmc.insn: $(addprefix fv.rvformal.bmc.insn., $(RVF_CHUNKSIZES))

fv.rvformal.all.bmc.reg: $(addprefix fv.rvformal.bmc.reg., $(RVF_CHUNKSIZES))

fv.rvformal.all.cov.insn: $(addprefix fv.rvformal.cov.insn., $(RVF_CHUNKSIZES))

fv.rvformal.all.cov.reg: $(addprefix fv.rvformal.cov.reg., $(RVF_CHUNKSIZES))

################
# Embench 
#

embench.prepare:
	@if [ ! -d embench-iot ]; then \
		echo "[Error] embench-iot does not exist. Are submodules initialized?" \
		exit 1; \
	fi
	rm embench-iot/benchmark_speed.py
	ln -sf ../soc/embench/benchmark_speed.py embench-iot/benchmark_speed.py
	ln -sf ../../../../soc/embench/verilator embench-iot/config/riscv32/boards/
	ln -sf ../../soc/embench/fsoc_verilator.py embench-iot/pylib/fsoc_verilator.py

embench.run: embench.prepare
	@echo "${BLUE}Running embench...${RESET}"
	$(SCRIPT)/benchmark_run_embench_all.sh

################
# SoC implement
#

# param: <ARCH>-<CHUNKSIZE>-<CONF>-<RFTYPE>
impl.soc.%:
	@echo "${BLUE}Synthesizing for $*...${RESET}"
	$(eval ARCH=$(word 1,$(subst -, ,$*)))
	$(eval CHUNKSIZE=$(word 2,$(subst -, ,$*)))
	$(eval CONF=$(word 3,$(subst -, ,$*)))
	$(eval RF=$(word 4,$(subst -, ,$*)))
	@echo "CHUNKSIZE: $(CHUNKSIZE)"
	@echo "ARCH: $(ARCH)"
	@echo "CONF: $(CONF)"
	@echo "RF: $(RF)"
	fusesoc run --target=$(ARCH)_ref --build --work-root=$(WORK_DIR_SOC)/$* fsoc --CHUNKSIZE=$(CHUNKSIZE) --CONF=$(CONF) --RFTYPE=$(RF)

# param: <ARCH>-<CHUNKSIZE>-<CONF>-<RFTYPE>
report.soc.%: impl.soc.%
	@echo -e "${GREEN}Report for $*...${RESET}"
	$(eval ARCH=$(word 1,$(subst -, ,$*)))
	$(PYTHON) $(SCRIPT)/reporting.py $(ARCH) $(WORK_DIR_SOC)/$* -o $(SUMMARY_DIR_SOC)/$*.json

# param: set TARGET_ARCH
summary.soc.all: $(addprefix report.soc.$(TARGET_ARCH)-, $(SYNTH_PARAMS))
	$(PYTHON) $(SCRIPT)/summary.py $(SUMMARY_DIR_SOC) -o $(WORK_DIR_MAIN)/soc_$(TARGET_ARCH).md


#######################
# Track and plot sizes
#

# param: <ARCH>-<CHUNKSIZE>-<CONF>-<RF>
_track.sizes.impl.%:
	@echo -e "${BLUE}Synthesizing for $*...${RESET}"
	$(eval ARCH=$(word 1,$(subst -, ,$*)))
	$(eval CHUNKSIZE=$(word 2,$(subst -, ,$*)))
	$(eval CONF=$(word 3,$(subst -, ,$*)))
	$(eval RF=$(word 4,$(subst -, ,$*)))
	fusesoc run --target=$(ARCH)_ref --build --work-root=$(WORK_DIR_CORE)/$* fazyrv --CHUNKSIZE=$(CHUNKSIZE) --CONF=$(CONF) --RFTYPE=$(RF)
	$(PYTHON) $(SCRIPT)/reporting.py $(ARCH) $(WORK_DIR_CORE)/$* -o $(SUMMARY_DIR_CORE)/$*.json
	$(PYTHON) $(SCRIPT)/summary.py $(SUMMARY_DIR_CORE) -o $(SUMMARY_DIR_CORE)/core_ice40.md
	make report.soc.$(ARCH)-$(CHUNKSIZE)-$(CONF)-$(RF)	

track.sizes: $(addprefix _track.sizes.impl.ice40-, $(PLOT_PARAMS))
	$(PYTHON) $(SCRIPT)/plot_track_sizes.py ice40 $(SUMMARY_DIR_CORE) $(SUMMARY_DIR_SOC) --svg ./doc/area.svg --ascii ./doc/area.txt --commit_hash $(COMMIT)

clean:
	rm -vrf $(WORK_DIR_MAIN)
	$(MAKE) -C sim clean 

.PHONY: clean report.riscvtests.all embench.run riscof.all track.sizes.synth


