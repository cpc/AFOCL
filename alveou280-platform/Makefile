include config.mk


PFM := $(PLATFORM_REPO_PATHS)/$(PLATFORM)/$(PLATFORM).xpfm

VPPFLAGS := --platform $(PFM) -t hw -s -g
VPPFLAGS_SIM := --platform $(PFM) -t hw_emu -s -g
VPPLFLAGS := --jobs 4

IP_CACHE_DIR ?= ip_cache

OPENASIP_INSTALL_DIR ?= ${HOME}/local

firmwares = vec_add_32x32.img vec_add_16x64.img vec_mul_32x32.img\
			vec_add_32x32_sim.img vec_add_16x64_sim.img vec_mul_32x32_sim.img

rtl_vecadd: tta_vecadd.adf
	[ ! -d $@ ] || rm -r $@
	$(eval $@_adf := $<)
	$(eval $@_tpef := test.tpef)
	generateprocessor --prefer-generation -o $@ -e tta_core --icd-arg-list=debugger:minimal \
		--hdb-list=generate_lsu_32.hdb,generate_rf_iu.hdb,xilinx_series7.hdb,generate_base32.hdb \
		-f onchip -d onchip -g AlmaIFIntegrator -p $($@_tpef) $($@_adf)
	generatebits -x $@ -e tta_core $($@_adf)


vec_add_32x32.img: tta_vecadd.adf firmware_vecadd.c
	$(eval $@_adf := $<)
	$(eval $@_src := $(word 2,$^))
	$(eval $@_tpef := vec_add_32x32.tpef)
	PATH=${OPENASIP_INSTALL_DIR}/bin:${PATH} LD_LIBRARY_PATH=${OPENASIP_INSTALL_DIR}/lib tcecc -DONCHIP_MEM_START=0x4000C000 -DONCHIP_MEM_END=0x40010000 -o3 -v -g -a $($@_adf) -o $($@_tpef) $($@_src)
	generatebits -e tta_core -f bin2n -p $($@_tpef) $($@_adf)
	tcedisasm -n $($@_adf) $($@_tpef)


vec_add_16x64.img: vec_add_32x32.img
	cp $< $@

vec_add_%_sim.img: vec_add_32x32.img
	cp $< $@

vec_mul_32x32.img: vec_add_32x32.img
	cp $< $@

vec_mul_32x32_sim.img: vec_add_32x32.img
	cp $< $@

firmware: $(firmwares)

vec_hls_%.zip: kernels/%/src/*_ip.cpp kernels/%/src/*_ip.h generate_vitis_vec.tcl
	rm -rf vitis_$*
	rm -f vec_hls_$*.zip
	vitis_hls -f generate_vitis_vec.tcl -tclargs $*


.PRECIOUS: vec_%.xo
vec_%.xo: vec_hls_%.zip generate_vec_512_xo.tcl rtl_vecadd
	rm -f vec_$*.xo vec_$*_sim.xo
	rm -rf vivado_$*_xo
	vivado -mode batch -source $(word 2,$^) -tclargs $*


.PRECIOUS: vec_%.xclbin
vec_%.xclbin: vec_%.xo
	$(eval $@_xo := $<)
	v++ -O3 --temp_dir ./_x.$* -R 2 -l $(VPPFLAGS) $(VPPLFLAGS) --config $(word 2,$^) --user_ip_repo_paths vitis_$*/solution1/impl/ --user_ip_repo_paths ip_repo_$* --kernel_frequency 225 -o $@ $($@_xo) --remote_ip_cache ${IP_CACHE_DIR}_$* --connectivity.sp vec_$*_1.m_axi:HBM[0]
	xclbinutil --dump-section EMBEDDED_METADATA:RAW:embeddedMetadata_$*.xml --input $@ --force
	python3 set_xclbin_range.py embeddedMetadata_$*.xml
	xclbinutil --replace-section EMBEDDED_METADATA:RAW:embeddedMetadata_$*.xml --input $@ --output tmp_$*.xclbin
	mv tmp_$*.xclbin $@

overlay_alveou280: vec_add_32x32.xclbin vec_add_16x64.xclbin firmware
	rm -rf $@
	mkdir -p $@/accelerators/vec_add_32x32/firmwares
	mkdir -p $@/accelerators/vec_add_16x64/firmwares
	cp vec_add_32x32.xclbin $@/accelerators/vec_add_32x32/vec_add_32x32.xclbin
	cp vec_add_32x32.xclbin $@/vec_add_32x32.xclbin
	cp vec_add_16x64.xclbin $@/accelerators/vec_add_16x64/vec_add_16x64.xclbin
	cp vec_add_16x64.img $@/accelerators/vec_add_16x64/firmwares/vec_add_16x64.img
	cp vec_add_32x32.img $@/accelerators/vec_add_32x32/firmwares/vec_add_32x32.img
	cp db.json $@/db.json


vec_%_sim.xclbin: vec_%.xo
	$(eval $@_xo := vec_$*_sim.xo)
	v++ -O3 --temp_dir ./_x.$*_sim -R 2 -l $(VPPFLAGS_SIM) $(VPPLFLAGS) --config $(word 2,$^) --user_ip_repo_paths vitis_$*/solution1/impl/ --user_ip_repo_paths ip_repo_$* --kernel_frequency 225 -o $@ $($@_xo) --remote_ip_cache ${IP_CACHE_DIR}_$* --connectivity.sp vec_$*_sim_1.m_axi:HBM[0]
	xclbinutil --dump-section EMBEDDED_METADATA:RAW:embeddedMetadata_$*_sim.xml --input $@ --force
	python3 set_xclbin_range.py embeddedMetadata_$*_sim.xml
	xclbinutil --replace-section EMBEDDED_METADATA:RAW:embeddedMetadata_$*_sim.xml --input $@ --output tmp_$*_sim.xclbin
	mv tmp_$*_sim.xclbin $@
	emconfigutil --platform $(PFM)

