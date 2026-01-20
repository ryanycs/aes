KEY_LENGTH ?= 128

INC_DIR := +incdir+include

TESTCASES := tests/testcases.txt

GREEN := \033[0;32m
NC := \033[0m

# VCS
VCS := vcs
VCS_FLAGS := -debug_access+all +notimingcheck +define+FSDB +define+AES$(KEY_LENGTH)

# ModelSim
VLOG := vlog.exe
VLOG_FLAGS := +define+AES$(KEY_LENGTH)
VSIM := vsim.exe
VSIM_FLAGS := -do "run -all; quit"

list_tests:
	@cat $(TESTCASES)

%.vsim:
	@if [ ! -f "tests/$*/tb.sv" ]; then \
		echo "[Error] Test not found: $*"; \
		exit 1; \
	fi
	@if [ ! -d "work" ]; then \
		mkdir work; \
	fi
	@if [ ! -d "output" ]; then \
		mkdir output; \
	fi
	@echo "[Info] AES Key Length: $(GREEN)$(KEY_LENGTH)$(NC) bits"
	$(VLOG) tests/$*/tb.sv -f filelist.f $(INC_DIR) $(VLOG_FLAGS)
	$(VSIM) -c work.tb $(VSIM_FLAGS)

%.vcs:
	@if [ ! -f "tests/$*/tb.sv" ]; then \
		echo "[Error] Test not found: $*"; \
		exit 1; \
	fi
	@if [ ! -d "output" ]; then \
		mkdir output; \
	fi
	@echo "[Info] AES Key Length: $(GREEN)$(KEY_LENGTH)$(NC) bits"
	$(VCS) -R -full64 -sverilog tests/$*/tb.sv -f filelist.f $(INC_DIR) $(VCS_FLAGS)
