ROOT_DIR := $(shell pwd)
INC_DIR := +incdir+include

TESTCASES := tests/testcases.txt

# VCS
VCS := vcs
VCS_FLAGS := -debug_access+all +notimingcheck +define+FSDB

# ModelSim
VLOG := vlog.exe
VSIM := vsim.exe
VSIM_FLAGS := -do "run -all; quit"

list_tests:
	@cat $(TESTCASES)

%.vsim:
	@if [ ! -f "tests/$*/tb.sv" ]; then \
		echo "[Error] Test not found: $*"; \
		exit 1; \
	fi
	$(VLOG) tests/$*/tb.sv -f filelist.f $(INC_DIR)
	$(VSIM) -c work.tb $(VSIM_FLAGS)

%.vcs:
	@if [ ! -f "tests/$*/tb.sv" ]; then \
		echo "[Error] Test not found: $*"; \
		exit 1; \
	fi
	$(VCS) -R -full64 -sverilog tests/$*/tb.sv -f filelist.f $(INC_DIR) $(VCS_FLAGS)
