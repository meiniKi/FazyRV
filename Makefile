
CUR_DIR := $(shell pwd)
SCRIPT := $(CUR_DIR)/script
WORKFLOW_SCRIPT := $(SCRIPT)/workflow

YOSYS := yosys
SVLINT := svlint
SLANG := slang
PYTHON := python3
MAKE := make
BASH := bash
VERILATOR := verilator

NEXTPNR_ICE40 := nextpnr-ice40
NEXTPNR_ECP5 := nextpnr-ecp5
NEXTPNR_GOWIN := nextpnr-gowin
GATEMATE_PR := p_r

TARGET_ARCH ?= ice40

################################
# Synthesis combinations 
#

SYNTH_CHUNKSIZES 	:= 1 2 4 8
SYNTH_CONFS 		:= MIN INT
SYNTH_RF 			:= BRAM BRAM_BP BRAM_DP BRAM_DP_BP

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

WORK_DIR_TOP		:= $(WORK_DIR_MAIN)/work_top
WORK_DIR_CORE		:= $(WORK_DIR_MAIN)/work_core
WORK_DIR_SOC		:= $(WORK_DIR_MAIN)/work_soc
WORK_DIR_EMBENCH	:= $(WORK_DIR_MAIN)/work_rvtests
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
	$(WORKFLOW_SCRIPT)/rvtests_table.sh $(SUMMARY_DIR_RISCVTESTS)


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
	export RISCOF_CHUNKSIZE=$(CHUNKSIZE)
	export RISCOF_CONF=$(CONF)
	export RISCOF_RFTYPE=$(RF)
	riscof testlist --config=dv/config.ini --suite=riscv-arch-test/riscv-test-suite/ --env=riscv-arch-test/riscv-test-suite/env
	riscof run --no-browser --config=dv/config.ini --suite=riscv-arch-test/riscv-test-suite/ --env=riscv-arch-test/riscv-test-suite/env 2>&1 | tee $(SUMMARY_DIR_RISCOF)/tmp.txt
	@ ! grep -q "Failed" $(SUMMARY_DIR_RISCOF)/tmp.txt
	@echo $$? > $(SUMMARY_DIR_RISCOF)/$*.log
	@rm $(SUMMARY_DIR_RISCOF)/tmp.txt
# riscof exit code does not report failures, see Issue #102
# workaround using the tmp.txt file

riscof.all: $(addprefix riscof.run., $(RVTESTS_PARAMS))
	@for log_file in $(wildcard $(SUMMARY_DIR_RISCOF)/*.log); do \
		if [ $$(cat "$$log_file") != "0" ]; then \
			echo "Error: $$log_file RICOF failed"; \
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
fv.rvformal.bmc.insn.%: _fv.rvformal.prepare
	sed -E -i 's/(`define CHUNKSIZE )\S+/\1 $*/' riscv-formal/cores/fazyrv/checks_bmc_insn.cfg
	sed -i -E "s/<INSERT_DEPTH>/$(call get_depth_value, $*)/" riscv-formal/cores/fazyrv/checks_bmc_insn.cfg
	cd riscv-formal/cores/fazyrv && $(PYTHON) ../../checks/genchecks.py checks_bmc_insn
	$(MAKE) -C riscv-formal/cores/fazyrv/checks_bmc_insn
	cd riscv-formal/cores/fazyrv && ./stats.sh checks_bmc_insn
	cd riscv-formal/cores/fazyrv && rm -vrf checks

# param: <CHUNKSIZE>
fv.rvformal.bmc.reg.%: _fv.rvformal.prepare
	sed -E -i 's/(`define CHUNKSIZE )\S+/\1 $*/' riscv-formal/cores/fazyrv/checks_bmc_reg.cfg
	sed -i -E "s/<INSERT_DEPTH>/$(call get_depth_value, $*)/" riscv-formal/cores/fazyrv/checks_bmc_reg.cfg
	cd riscv-formal/cores/fazyrv && $(PYTHON) ../../checks/genchecks.py checks_bmc_reg
	$(MAKE) -C riscv-formal/cores/fazyrv/checks_bmc_reg
	cd riscv-formal/cores/fazyrv && ./stats.sh checks_bmc_reg
	cd riscv-formal/cores/fazyrv && rm -vrf checks

# param: <CHUNKSIZE>
fv.rvformal.cov.insn.%: _fv.rvformal.prepare
	sed -E -i 's/(`define CHUNKSIZE )\S+/\1 $*/' riscv-formal/cores/fazyrv/checks_cov_insn.cfg
	sed -i -E "s/<INSERT_DEPTH>/$(call get_depth_value, $*)/" riscv-formal/cores/fazyrv/checks_cov_insn.cfg
	cd riscv-formal/cores/fazyrv && $(PYTHON) ../../checks/genchecks.py checks_cov_insn
	$(MAKE) -C riscv-formal/cores/fazyrv/checks_cov_insn
	cd riscv-formal/cores/fazyrv && ./stats.sh checks_cov_insn
	cd riscv-formal/cores/fazyrv && rm -vrf checks

# param: <CHUNKSIZE>
fv.rvformal.cov.reg.%: _fv.rvformal.prepare
	sed -E -i 's/(`define CHUNKSIZE )\S+/\1 $*/' riscv-formal/cores/fazyrv/checks_cov_insn.cfg
	sed -i -E "s/<INSERT_DEPTH>/$(call get_depth_value, $*)/" riscv-formal/cores/fazyrv/checks_cov_insn.cfg
	cd riscv-formal/cores/fazyrv && $(PYTHON) ../../checks/genchecks.py checks_cov_insn
	$(MAKE) -C riscv-formal/cores/fazyrv/checks_cov_insn
	cd riscv-formal/cores/fazyrv && ./stats.sh checks_cov_insn
	cd riscv-formal/cores/fazyrv && rm -vrf checks


fv.rvformal.bmc.insn.all: $(addprefix fv.rvformal.bmc.insn.%, $(RVF_CHUNKSIZES))

fv.rvformal.bmc.reg.all: $(addprefix fv.rvformal.bmc.reg.%, $(RVF_CHUNKSIZES))

fv.rvformal.cov.insn.all: $(addprefix fv.rvformal.cov.insn.%, $(RVF_CHUNKSIZES))

fv.rvformal.cov.reg.all: $(addprefix fv.rvformal.cov.reg.%, $(RVF_CHUNKSIZES))

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
# Via fusesoc whenever possible.
_impl.soc.%: $(SRC_DESIGN) $(SRC_SYNTH)
	@echo "${BLUE}Synthesizing for $*...${RESET}"
	$(eval ARCH=$(word 1,$(subst -, ,$*)))
	$(eval CHUNKSIZE=$(word 2,$(subst -, ,$*)))
	$(eval CONF=$(word 3,$(subst -, ,$*)))
	$(eval RF=$(word 4,$(subst -, ,$*)))
	@echo "CHUNKSIZE: $(CHUNKSIZE)"
	@echo "ARCH: $(ARCH)"
	@echo "CONF: $(CONF)"
	@echo "RF: $(RF)"
	mkdir -p $(WORK_DIR_SOC)/$*
	@case ${ARCH} in \
		gatemate) $(YOSYS) -l $(WORK_DIR_SOC)/$*/yosys_$*.log -p "read_verilog -sv -defer $^; chparam -set CHUNKSIZE $(CHUNKSIZE) $(TOP_MODULE_SOC); chparam -set GPOCNT 1 $(TOP_MODULE_SOC); chparam -set MEMDLY1 0 $(TOP_MODULE_SOC); chparam -set CONF \"$(CONF)\" $(TOP_MODULE_SOC); chparam -set RFTYPE \"$(RF)\" $(TOP_MODULE_SOC); synth_$(ARCH) -top $(TOP_MODULE_SOC); synth_$(ARCH) -top $(TOP_MODULE_SOC) -json $(WORK_DIR_SOC)/$*/$*.json -vlog $(WORK_DIR_SOC)/$*/$*.v" && \
					$(GATEMATE_PR) --speed 10 -tm 2 -ccf soc/synth/gatemate_ref.ccf -i $(WORK_DIR_SOC)/$*/$*.v > $(WORK_DIR_SOC)/$*/gm_pr_$*.log ;; \
		gowin) fusesoc run --target=$(ARCH)_ref --build --work-root=$(WORK_DIR_SOC)/$* fsoc --CHUNKSIZE=$(CHUNKSIZE) --CONF=$(CONF) --RFTYPE=$(RF) --GOWIN ;; \
		*) fusesoc run --target=$(ARCH)_ref --build --work-root=$(WORK_DIR_SOC)/$* fsoc --CHUNKSIZE=$(CHUNKSIZE) --CONF=$(CONF) --RFTYPE=$(RF) ;; \
	esac

# param: <ARCH>-<CHUNKSIZE>-<CONF>-<RFTYPE>
# TODO: Use Edalize reporting instead of custom scripts
_report.soc.%: _impl.soc.%
	@echo -e "${GREEN}Report for $*...${RESET}"
	$(eval ARCH=$(word 1,$(subst -, ,$*)))
	mkdir -p $(SUMMARY_DIR_SOC)
	@case ${ARCH} in \
		xilinx) \
			$(WORKFLOW_SCRIPT)/report_vivado_util.sh $(WORK_DIR_SOC)/$*/*.runs/impl_1/fsoc_utilization_placed.rpt > $(SUMMARY_DIR_SOC)/summary_util_$*; \
			$(WORKFLOW_SCRIPT)/report_vivado_timing.sh $(WORK_DIR_SOC)/$*/*.runs/impl_1/fsoc_timing_summary_routed.rpt > $(SUMMARY_DIR_SOC)/summary_wns_$*; \
			$(WORKFLOW_SCRIPT)/report_vivado_timing_to_fmax.sh $(SUMMARY_DIR_SOC) 100 \
			;; \
		gatemate) \
			$(WORKFLOW_SCRIPT)/report_gatemate_util.sh $(WORK_DIR_SOC)/$*/gm_pr_$*.log > $(SUMMARY_DIR_SOC)/summary_util_$*; \
			$(WORKFLOW_SCRIPT)/report_gatemate_timing.sh $(WORK_DIR_SOC)/$*/gm_pr_$*.log  > $(SUMMARY_DIR_SOC)/summary_fmax_$*; \
			;; \
		*) \
			$(WORKFLOW_SCRIPT)/report_yosys_$(ARCH).sh $(WORK_DIR_SOC)/$*/yosys.log > $(SUMMARY_DIR_SOC)/summary_yosys_$*; \
			$(WORKFLOW_SCRIPT)/report_nextpnr_timing.sh $(WORK_DIR_SOC)/$*/next.log > $(SUMMARY_DIR_SOC)/summary_fmax_$*; \
			$(WORKFLOW_SCRIPT)/report_nextpnr_util.sh $(WORK_DIR_SOC)/$*/next.log > $(SUMMARY_DIR_SOC)/summary_util_$*; \
			;; \
	esac

# param: set TARGET_ARCH
report.soc.all: $(addprefix _report.soc.$(TARGET_ARCH)-, $(SYNTH_PARAMS))
	$(PYTHON) $(WORKFLOW_SCRIPT)/summary_table.py $(SUMMARY_DIR_SOC) $(TARGET_ARCH)

report.md:
	$(PYTHON) $(WORKFLOW_SCRIPT)/summary_table_md.py $(SUMMARY_DIR_SOC) $(TARGET_ARCH)

#######################
# Track and plot sizes
#

# param: <ARCH>-<CHUNKSIZE>-<CONF>-<RF>
_track.sizes.synth.%: $(SRC_DESIGN) $(SRC_SYNTH)
	@echo -e "${BLUE}Synthesizing for $*...${RESET}"
	$(eval ARCH=$(word 1,$(subst -, ,$*)))
	$(eval CHUNKSIZE=$(word 2,$(subst -, ,$*)))
	$(eval CONF=$(word 3,$(subst -, ,$*)))
	$(eval RF=$(word 4,$(subst -, ,$*)))
	@echo "CHUNKSIZE: $(CHUNKSIZE)"
	@echo "ARCH: $(ARCH)"
	@echo "CONF: $(CONF)"
	@echo "RF: $(RF)"
	mkdir -p $(WORK_DIR_CORE)/$*
	mkdir -p $(WORK_DIR_SOC)/$*
	$(YOSYS) -q -l $(WORK_DIR_CORE)/$*/yosys_$*.log -p "read_verilog -sv -defer $^; chparam -set CHUNKSIZE $(CHUNKSIZE) $(TOP_MODULE_CORE); chparam -set CONF \"$(CONF)\" $(TOP_MODULE_CORE); chparam -set RFTYPE \"$(RF)\" $(TOP_MODULE_CORE); synth_$(ARCH) -top $(TOP_MODULE_CORE)"
	$(YOSYS) -q -l $(WORK_DIR_SOC)/$*/yosys_$*.log -p "read_verilog -sv -defer $^; chparam -set CHUNKSIZE $(CHUNKSIZE) $(TOP_MODULE_SOC); chparam -set CONF \"$(CONF)\" $(TOP_MODULE_SOC); chparam -set RFTYPE \"$(RF)\" $(TOP_MODULE_SOC); synth_$(ARCH) -top $(TOP_MODULE_SOC)"
	mkdir -p $(SUMMARY_DIR_CORE)
	mkdir -p $(SUMMARY_DIR_SOC)
	$(WORKFLOW_SCRIPT)/report_yosys_$(ARCH).sh $(WORK_DIR_CORE)/$*/yosys_$*.log > $(SUMMARY_DIR_CORE)/summary_yosys_$*
	$(WORKFLOW_SCRIPT)/report_yosys_$(ARCH).sh $(WORK_DIR_SOC)/$*/yosys_$*.log > $(SUMMARY_DIR_SOC)/summary_yosys_$*


track.sizes.synth: $(addprefix _track.sizes.synth.$(TARGET_ARCH)-, $(PLOT_PARAMS))
	$(PYTHON) $(WORKFLOW_SCRIPT)/plot_track_sizes.py $(SUMMARY_DIR_CORE) $(SUMMARY_DIR_SOC) ./doc/area.svg ./doc/area.txt $(COMMIT)

clean:
	rm -vrf $(WORK_DIR_MAIN)
	$(MAKE) -C sim clean 

.PHONY: clean report.riscvtests.all embench.run riscof.all track.sizes.synth


