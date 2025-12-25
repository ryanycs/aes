INCDIR = +incdir+vsrc
DEF    = +define+FSDB

test_aes:
	mkdir -p output
	vcs -R -full64 -sverilog tests/test_aes/tb.sv \
	$(INCDIR) $(DEF) \
	-debug_access+all \
	+notimingcheck

test_mix_columns:
	mkdir -p output
	vcs -R -full64 -sverilog tests/test_mix_columns/tb.sv \
	$(INCDIR) $(DEF) \
	-debug_access+all \
	+notimingcheck
