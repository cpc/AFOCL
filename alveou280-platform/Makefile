include config.mk


PFM := $(PLATFORM_REPO_PATHS)/$(PLATFORM)/$(PLATFORM).xpfm

VPPFLAGS := --platform $(PFM) -t hw -s -g
VPPFLAGS_SIM := --platform $(PFM) -t hw_emu -s -g
VPPLFLAGS := --jobs 4

IP_CACHE_DIR ?= ip_cache

OPENASIP_INSTALL_DIR ?= ${HOME}/local

firmwares = vec_add_32x32.img vec_add_16x64.img vec_mul_32x32.img\
			vec_add_32x32_sim.img vec_add_16x64_sim.img vec_mul_32x32_sim.img\
			vec_canny1_sim.img vec_canny2_sim.img vec_canny3_sim.img


rtl_vecadd: tta_vecadd.adf
	[ ! -d $@ ] || rm -r $@
	$(eval $@_adf := $<)
	$(eval $@_tpef := test.tpef)
	generateprocessor --prefer-generation -o $@ -e tta_core --icd-arg-list=debugger:minimal \
		--hdb-list=generate_lsu_32.hdb,generate_rf_iu.hdb,xilinx_series7.hdb,generate_base32.hdb \
		-f onchip -d onchip -g AlmaIFIntegrator -p $($@_tpef) $($@_adf)
	generatebits -x $@ -e tta_core $($@_adf)

sim_bitstreams: vec_add_32x32_sim.xclbin vec_add_16x64_sim.xclbin vec_mul_32x32_sim.xclbin\
	vec_canny1_sim.xclbin vec_canny2_sim.xclbin vec_canny3_sim.xclbin

canny_bitstreams: vec_canny1.xclbin vec_canny2.xclbin vec_canny3.xclbin

vec_sobel3x3_sim.img: vec_sobel3x3.img
	cp $< $@

vec_sobel3x3.img: tta_vecadd.adf firmware_canny.c
	$(eval $@_adf := $<)
	$(eval $@_src := $(word 2,$^))
	$(eval $@_tpef := vec_sobel3x3.tpef)
	#PATH=${OPENASIP_INSTALL_DIR}/bin:${PATH} LD_LIBRARY_PATH=${OPENASIP_INSTALL_DIR}/lib tcecc -DONCHIP_MEM_START=0x4000C000 -DONCHIP_MEM_END=0x40010000 -o3 -v -g -a $($@_adf) -o $($@_tpef) $($@_src)
	PATH=${OPENASIP_INSTALL_DIR}/bin:${PATH} LD_LIBRARY_PATH=${OPENASIP_INSTALL_DIR}/lib tcecc \
		 -DDISABLE_VECTOR_PRINTF=1 -DPRINTF_BUFFER_AS_ID=1 \
		 -D__CBUILD__=1 -DPOCL_DEVICE_ADDRESS_BITS=32 \
		 -D__OPENCL_VERSION__=120 \
		 -DONCHIP_MEM_START=0x4000C000 -DONCHIP_MEM_END=0x40010000 \
		 -I/home/topi/pocl_wd/os/include/ \
		 -I/home/topi/pocl_wd/os/lib/kernel/ \
		 -o3 -v -g -a $($@_adf) -o $($@_tpef) $($@_src) \
		 /home/topi/pocl_wd/os/lib/kernel/printf_base.c /home/topi/pocl_wd/os/lib/kernel/printf.c
	generatebits -e tta_core -f bin2n -p $($@_tpef) $($@_adf)
	tcedisasm -n $($@_adf) $($@_tpef)

vec_canny1_sim.img: vec_canny1.img
	cp $< $@

vec_canny1.img: tta_vecadd.adf firmware_canny1.c
	$(eval $@_adf := $<)
	$(eval $@_src := $(word 2,$^))
	$(eval $@_tpef := vec_canny1.tpef)
	PATH=${OPENASIP_INSTALL_DIR}/bin:${PATH} LD_LIBRARY_PATH=${OPENASIP_INSTALL_DIR}/lib tcecc \
		 -DDISABLE_VECTOR_PRINTF=1 -DPRINTF_BUFFER_AS_ID=1 \
		 -D__CBUILD__=1 -DPOCL_DEVICE_ADDRESS_BITS=32 \
		 -D__OPENCL_VERSION__=120 \
		 -DONCHIP_MEM_START=0x4000C000 -DONCHIP_MEM_END=0x40010000 \
		 -I/home/topi/pocl_wd/os/include/ \
		 -I/home/topi/pocl_wd/os/lib/kernel/ \
		 -o3 -v -g -a $($@_adf) -o $($@_tpef) $($@_src) \
		 /home/topi/pocl_wd/os/lib/kernel/printf_base.c
	generatebits -e tta_core -f bin2n -p $($@_tpef) $($@_adf)
	tcedisasm -n $($@_adf) $($@_tpef)

vec_canny2_sim.img: vec_canny2.img
	cp $< $@
	cp $< vec_sobel3x3_sim.img
	cp $< vec_phase_sim.img
	cp $< vec_magnitude_sim.img
	cp $< vec_nonmax_sim.img

vec_canny2.img: tta_vecadd.adf firmware_canny2.c
	$(eval $@_adf := $<)
	$(eval $@_src := $(word 2,$^))
	$(eval $@_tpef := vec_canny2.tpef)
	PATH=${OPENASIP_INSTALL_DIR}/bin:${PATH} LD_LIBRARY_PATH=${OPENASIP_INSTALL_DIR}/lib tcecc \
		 -DDISABLE_VECTOR_PRINTF=1 -DPRINTF_BUFFER_AS_ID=1 \
		 -D__CBUILD__=1 -DPOCL_DEVICE_ADDRESS_BITS=32 \
		 -D__OPENCL_VERSION__=120 \
		 -DONCHIP_MEM_START=0x4000C000 -DONCHIP_MEM_END=0x40040000 \
		 -I/home/topi/pocl_wd/os/include/ \
		 -I/home/topi/pocl_wd/os/lib/kernel/ \
		 -o3 -v -g -a $($@_adf) -o $($@_tpef) $($@_src) \
		 /home/topi/pocl_wd/os/lib/kernel/printf_base.c
	generatebits -e tta_core -f bin2n -p $($@_tpef) $($@_adf)
	tcedisasm -n $($@_adf) $($@_tpef)

vec_canny3_sim.img: vec_canny3.img
	cp $< $@

vec_canny3.img: tta_vecadd.adf firmware_canny3.c
	$(eval $@_adf := $<)
	$(eval $@_src := $(word 2,$^))
	$(eval $@_tpef := vec_canny3.tpef)
	PATH=${OPENASIP_INSTALL_DIR}/bin:${PATH} LD_LIBRARY_PATH=${OPENASIP_INSTALL_DIR}/lib tcecc \
		 -DDISABLE_VECTOR_PRINTF=1 -DPRINTF_BUFFER_AS_ID=1 \
		 -D__CBUILD__=1 -DPOCL_DEVICE_ADDRESS_BITS=32 \
		 -D__OPENCL_VERSION__=120 \
		 -DONCHIP_MEM_START=0x4000C000 -DONCHIP_MEM_END=0x40010000 \
		 -I/home/topi/pocl_wd/os/include/ \
		 -I/home/topi/pocl_wd/os/lib/kernel/ \
		 -o3 -v -g -a $($@_adf) -o $($@_tpef) $($@_src) \
		 /home/topi/pocl_wd/os/lib/kernel/printf_base.c
	generatebits -e tta_core -f bin2n -p $($@_tpef) $($@_adf)
	tcedisasm -n $($@_adf) $($@_tpef)


vec_canny4_sim.img: vec_canny4.img
	cp $< $@

vec_canny4.img: tta_vecadd.adf firmware_canny4.c
	$(eval $@_adf := $<)
	$(eval $@_src := $(word 2,$^))
	$(eval $@_tpef := vec_canny4.tpef)
	PATH=${OPENASIP_INSTALL_DIR}/bin:${PATH} LD_LIBRARY_PATH=${OPENASIP_INSTALL_DIR}/lib tcecc \
		 -DDISABLE_VECTOR_PRINTF=1 -DPRINTF_BUFFER_AS_ID=1 \
		 -D__CBUILD__=1 -DPOCL_DEVICE_ADDRESS_BITS=32 \
		 -D__OPENCL_VERSION__=120 \
		 -DONCHIP_MEM_START=0x4000C000 -DONCHIP_MEM_END=0x40010000 \
		 -I/home/topi/pocl_wd/os/include/ \
		 -I/home/topi/pocl_wd/os/lib/kernel/ \
		 -o3 -v -g -a $($@_adf) -o $($@_tpef) $($@_src) \
		 /home/topi/pocl_wd/os/lib/kernel/printf_base.c
	generatebits -e tta_core -f bin2n -p $($@_tpef) $($@_adf)
	tcedisasm -n $($@_adf) $($@_tpef)


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

.PRECIOUS: vec_canny1.xo
vec_canny1.xo: vec_hls_sobel3x3.zip generate_canny1_xo.tcl rtl_vecadd vec_hls_phase.zip vec_hls_magnitude.zip vec_hls_nonmax.zip
	rm -f vec_canny1.xo vec_canny1_sim.xo
	rm -rf vivado_canny1_xo
	vivado -mode batch -source $(word 2,$^) -tclargs canny1

.PRECIOUS: vec_canny3.xo
vec_canny3.xo: vec_hls_sobel3x3.zip generate_canny3_xo.tcl rtl_vecadd vec_hls_phase.zip vec_hls_magnitude.zip vec_hls_nonmax.zip
	rm -f vec_canny3.xo vec_canny3_sim.xo
	rm -rf vivado_canny3_xo
	vivado -mode batch -source $(word 2,$^) -tclargs canny3

.PRECIOUS: vec_canny4.xo
vec_canny4.xo: vec_hls_sobel3x3_ctrl.zip generate_canny4_xo.tcl rtl_vecadd vec_hls_phase_ctrl.zip vec_hls_magnitude_ctrl.zip vec_hls_nonmax_ctrl.zip axis_stall_counter/axis_stall_counter.vhdl axi_constant_vhdl/axi_constant.vhdl
	rm -f vec_canny4.xo vec_canny4_sim.xo
	rm -rf vivado_canny4_xo
	vivado -mode batch -source $(word 2,$^) -tclargs canny4

.PRECIOUS: vec_sobel3x3.xo
vec_sobel3x3.xo: vec_hls_sobel3x3.zip generate_sobel3x3_xo.tcl rtl_vecadd
	rm -f vec_sobel3x3.xo vec_sobel3x3_sim.xo
	rm -rf vivado_sobel3x3_xo
	vivado -mode batch -source $(word 2,$^) -tclargs sobel3x3


.PRECIOUS: vec_%.xo
vec_%.xo: vec_hls_%.zip generate_vec_512_xo.tcl rtl_vecadd
	rm -f vec_$*.xo vec_$*_sim.xo
	rm -rf vivado_$*_xo
	vivado -mode batch -source $(word 2,$^) -tclargs $*


.PRECIOUS: vec_canny2_nonmax.xo
vec_canny2_nonmax.xo : vec_hls_nonmax.zip generate_canny2_xo.tcl rtl_vecadd
	rm -f vec_canny2_nonmax.xo vec_canny2_nonmax_sim.xo
	rm -rf vivado_canny2_nonmax_xo
	vivado -mode batch -source $(word 2,$^) -tclargs nonmax    1073938432 2 1 1

.PRECIOUS: vec_canny2_magnitude.xo
vec_canny2_magnitude.xo : vec_hls_magnitude.zip generate_canny2_xo.tcl rtl_vecadd
	rm -f vec_canny2_magnitude.xo vec_canny2_magnitude_sim.xo
	rm -rf vivado_canny2_magnitude_xo
	vivado -mode batch -source $(word 2,$^) -tclargs magnitude 1073872896 2 1 0

.PRECIOUS: vec_canny2_phase.xo
vec_canny2_phase.xo : vec_hls_phase.zip generate_canny2_xo.tcl rtl_vecadd
	rm -f vec_canny2_phase.xo vec_canny2_phase_sim.xo
	rm -rf vivado_canny2_phase_xo
	vivado -mode batch -source $(word 2,$^) -tclargs phase     1073807360 2 1 0

.PRECIOUS: vec_canny2_sobel3x3.xo
vec_canny2_sobel3x3.xo : vec_hls_sobel3x3.zip generate_canny2_xo.tcl rtl_vecadd
	rm -f vec_canny2_sobel3x3.xo vec_canny2_sobel3x3_sim.xo
	rm -rf vivado_canny2_sobel3x3_xo
	vivado -mode batch -source $(word 2,$^) -tclargs sobel3x3 1073741824 1 2 1

.PRECIOUS: vec_canny2_sim.xclbin
vec_canny2_sim.xclbin: vec_canny2_nonmax.xo vec_canny2_magnitude.xo vec_canny2_phase.xo vec_canny2_sobel3x3.xo
	v++ -O3 --temp_dir ./_x.canny2_sim -R 2 -l $(VPPFLAGS_SIM) $(VPPLFLAGS) \
		--user_ip_repo_paths vitis_sobel3x3/solution1/impl/ \
		--user_ip_repo_paths vitis_phase/solution1/impl/ \
		--user_ip_repo_paths vitis_magnitude/solution1/impl/ \
		--user_ip_repo_paths vitis_nonmax/solution1/impl/ \
		--user_ip_repo_paths ip_repo_canny2 \
		--kernel_frequency 400 -o $@ \
		--remote_ip_cache ${IP_CACHE_DIR}_canny2_sim \
		--connectivity.sp vec_sobel3x3_sim_1.m_axi:HBM[0] \
		--connectivity.sp vec_phase_sim_1.m_axi:HBM[0] \
		--connectivity.sp vec_magnitude_sim_1.m_axi:HBM[0] \
		--connectivity.sp vec_nonmax_sim_1.m_axi:HBM[0] \
		vec_canny2_nonmax_sim.xo vec_canny2_phase_sim.xo vec_canny2_magnitude_sim.xo vec_canny2_sobel3x3_sim.xo
	xclbinutil --dump-section EMBEDDED_METADATA:RAW:embeddedMetadata_canny2_sim.xml --input $@ --force
	python3 set_xclbin_range.py embeddedMetadata_canny2_sim.xml
	xclbinutil --replace-section EMBEDDED_METADATA:RAW:embeddedMetadata_canny2_sim.xml --input $@ --output tmp_canny2_sim.xclbin
	mv tmp_canny2_sim.xclbin $@
	cp $@ vec_sobel3x3_sim.xclbin

.PRECIOUS: vec_canny2.xclbin
vec_canny2.xclbin: vec_canny2_nonmax.xo vec_canny2_magnitude.xo vec_canny2_phase.xo vec_canny2_sobel3x3.xo
	v++ -O3 --temp_dir ./_x.canny2 -R 2 -l $(VPPFLAGS) $(VPPLFLAGS) \
		--user_ip_repo_paths vitis_sobel3x3/solution1/impl/ \
		--user_ip_repo_paths vitis_phase/solution1/impl/ \
		--user_ip_repo_paths vitis_magnitude/solution1/impl/ \
		--user_ip_repo_paths vitis_nonmax/solution1/impl/ \
		--user_ip_repo_paths ip_repo_canny2 \
		--kernel_frequency 300 -o $@ \
		--remote_ip_cache ${IP_CACHE_DIR}_canny2 \
		--connectivity.sp vec_sobel3x3_1.m_axi:HBM[0] \
		--connectivity.sp vec_phase_1.m_axi:HBM[0] \
		--connectivity.sp vec_magnitude_1.m_axi:HBM[0] \
		--connectivity.sp vec_nonmax_1.m_axi:HBM[0] \
		vec_canny2_nonmax.xo vec_canny2_phase.xo vec_canny2_magnitude.xo vec_canny2_sobel3x3.xo
	xclbinutil --dump-section EMBEDDED_METADATA:RAW:embeddedMetadata_canny2.xml --input $@ --force
	python3 set_xclbin_range.py embeddedMetadata_canny2.xml
	xclbinutil --replace-section EMBEDDED_METADATA:RAW:embeddedMetadata_canny2.xml --input $@ --output tmp_canny2.xclbin
	mv tmp_canny2.xclbin $@



.PRECIOUS: vec_%.xclbin
vec_%.xclbin: vec_%.xo
	$(eval $@_xo := $<)
	v++ -O3 --temp_dir ./_x.$* -R 2 -l $(VPPFLAGS) $(VPPLFLAGS) \
		--user_ip_repo_paths vitis_$*/solution1/impl/ \
		--user_ip_repo_paths ip_repo_$* --kernel_frequency 400 \
		-o $@ $($@_xo) --remote_ip_cache ${IP_CACHE_DIR}_$* \
		--connectivity.sp vec_$*_1.m_axi:HBM[0]
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

.PRECIOUS: vec_canny1.xclbin
vec_canny1.xclbin: vec_canny1.xo
	$(eval $@_xo := $<)
	v++ -O3 --temp_dir ./_x.canny1 -R 2 -l $(VPPFLAGS) $(VPPLFLAGS) \
		--user_ip_repo_paths vitis_sobel3x3/solution1/impl/ \
		--user_ip_repo_paths vitis_phase/solution1/impl/ \
		--user_ip_repo_paths vitis_magnitude/solution1/impl/ \
		--user_ip_repo_paths vitis_nonmax/solution1/impl/ \
		--user_ip_repo_paths ip_repo_canny1 \
		--kernel_frequency 160 -o $@ $($@_xo) --remote_ip_cache ${IP_CACHE_DIR}_canny1 \
		--connectivity.sp vec_canny1_1.m_axi_0:HBM[0:7] \
		--connectivity.sp vec_canny1_1.m_axi_1:HBM[0:7] \
		--connectivity.sp vec_canny1_1.m_axi_2:HBM[0:7] \
		--connectivity.sp vec_canny1_1.m_axi_3:HBM[0:7] \
		--connectivity.sp vec_canny1_1.m_axi_4:HBM[0:7] \
		--connectivity.sp vec_canny1_1.m_axi_5:HBM[0:7] \
		--connectivity.sp vec_canny1_1.m_axi_6:HBM[0:7] \
		--connectivity.sp vec_canny1_1.m_axi_7:HBM[0:7] \
		--connectivity.sp vec_canny1_1.m_axi_8:HBM[0:7] \
		--connectivity.sp vec_canny1_1.m_axi_9:HBM[0:7] \
		--connectivity.sp vec_canny1_1.m_axi_10:HBM[0:7] \
		--connectivity.sp vec_canny1_1.m_axi_11:HBM[0:7] \
		--connectivity.sp vec_canny1_1.m_axi_12:HBM[0:7]
	xclbinutil --dump-section EMBEDDED_METADATA:RAW:embeddedMetadata_canny1.xml --input $@ --force
	python3 set_xclbin_range.py embeddedMetadata_canny1.xml
	xclbinutil --replace-section EMBEDDED_METADATA:RAW:embeddedMetadata_canny1.xml --input $@ --output tmp_canny1.xclbin
	mv tmp_canny1.xclbin $@


vec_canny1_sim.xclbin: vec_canny1.xo
	$(eval $@_xo := vec_canny1_sim.xo)
	v++ -O3 --temp_dir ./_x.canny1_sim -R 2 -l $(VPPFLAGS_SIM) $(VPPLFLAGS) \
		--user_ip_repo_paths vitis_sobel3x3/solution1/impl/ \
		--user_ip_repo_paths vitis_phase/solution1/impl/ \
		--user_ip_repo_paths vitis_magnitude/solution1/impl/ \
		--user_ip_repo_paths vitis_nonmax/solution1/impl/ \
		--user_ip_repo_paths ip_repo_canny1 --kernel_frequency 400 -o $@ $($@_xo) --remote_ip_cache ${IP_CACHE_DIR}_canny1 \
		--connectivity.sp vec_canny1_sim_1.m_axi_0:HBM[0:7] \
		--connectivity.sp vec_canny1_sim_1.m_axi_1:HBM[0:7] \
		--connectivity.sp vec_canny1_sim_1.m_axi_2:HBM[0:7] \
		--connectivity.sp vec_canny1_sim_1.m_axi_3:HBM[0:7] \
		--connectivity.sp vec_canny1_sim_1.m_axi_4:HBM[0:7] \
		--connectivity.sp vec_canny1_sim_1.m_axi_5:HBM[0:7] \
		--connectivity.sp vec_canny1_sim_1.m_axi_6:HBM[0:7] \
		--connectivity.sp vec_canny1_sim_1.m_axi_7:HBM[0:7] \
		--connectivity.sp vec_canny1_sim_1.m_axi_8:HBM[0:7] \
		--connectivity.sp vec_canny1_sim_1.m_axi_9:HBM[0:7] \
		--connectivity.sp vec_canny1_sim_1.m_axi_10:HBM[0:7] \
		--connectivity.sp vec_canny1_sim_1.m_axi_11:HBM[0:7] \
		--connectivity.sp vec_canny1_sim_1.m_axi_12:HBM[0:7]
	xclbinutil --dump-section EMBEDDED_METADATA:RAW:embeddedMetadata_canny1_sim.xml --input $@ --force
	python3 set_xclbin_range.py embeddedMetadata_canny1_sim.xml
	xclbinutil --replace-section EMBEDDED_METADATA:RAW:embeddedMetadata_canny1_sim.xml --input $@ --output tmp_canny1_sim.xclbin
	mv tmp_canny1_sim.xclbin $@
	emconfigutil --platform $(PFM)


.PRECIOUS: vec_canny3.xclbin
vec_canny3.xclbin: vec_canny3.xo
	$(eval $@_xo := $<)
	v++ -O3 --temp_dir ./_x.canny3 -R 2 -l $(VPPFLAGS) $(VPPLFLAGS) \
		--user_ip_repo_paths vitis_sobel3x3/solution1/impl/ \
		--user_ip_repo_paths vitis_phase/solution1/impl/ \
		--user_ip_repo_paths vitis_magnitude/solution1/impl/ \
		--user_ip_repo_paths vitis_nonmax/solution1/impl/ \
		--user_ip_repo_paths ip_repo_canny3 \
		--kernel_frequency 280 -o $@ $($@_xo) --remote_ip_cache ${IP_CACHE_DIR}_canny3 \
		--connectivity.sp vec_canny3_1.m_axi_0:HBM[0:7] \
		--connectivity.sp vec_canny3_1.m_axi_1:HBM[0:7] \
		--connectivity.sp vec_canny3_1.m_axi_2:HBM[0:7]
	xclbinutil --dump-section EMBEDDED_METADATA:RAW:embeddedMetadata_canny3.xml --input $@ --force
	python3 set_xclbin_range.py embeddedMetadata_canny3.xml
	xclbinutil --replace-section EMBEDDED_METADATA:RAW:embeddedMetadata_canny3.xml --input $@ --output tmp_canny3.xclbin
	mv tmp_canny3.xclbin $@


vec_canny3_sim.xclbin: vec_canny3.xo
	$(eval $@_xo := vec_canny3_sim.xo)
	v++ -O3 --temp_dir ./_x.canny3_sim -R 2 -l $(VPPFLAGS_SIM) $(VPPLFLAGS) \
		--user_ip_repo_paths vitis_sobel3x3/solution1/impl/ \
		--user_ip_repo_paths vitis_phase/solution1/impl/ \
		--user_ip_repo_paths vitis_magnitude/solution1/impl/ \
		--user_ip_repo_paths vitis_nonmax/solution1/impl/ \
		--user_ip_repo_paths ip_repo_canny3 \
		--kernel_frequency 200 -o $@ $($@_xo) --remote_ip_cache ${IP_CACHE_DIR}_canny3 \
		--connectivity.sp vec_canny3_sim_1.m_axi_0:HBM[0:7] \
		--connectivity.sp vec_canny3_sim_1.m_axi_1:HBM[0:7] \
		--connectivity.sp vec_canny3_sim_1.m_axi_2:HBM[0:7]
	xclbinutil --dump-section EMBEDDED_METADATA:RAW:embeddedMetadata_canny3_sim.xml --input $@ --force
	python3 set_xclbin_range.py embeddedMetadata_canny3_sim.xml
	xclbinutil --replace-section EMBEDDED_METADATA:RAW:embeddedMetadata_canny3_sim.xml --input $@ --output tmp_canny3_sim.xclbin
	mv tmp_canny3_sim.xclbin $@
	emconfigutil --platform $(PFM)


.PRECIOUS: vec_canny4.xclbin
vec_canny4.xclbin: vec_canny4.xo
	rm -rf _x.canny4
	$(eval $@_xo := $<)
	v++ -O3 --temp_dir ./_x.canny4 -R 2 -l $(VPPFLAGS) $(VPPLFLAGS) \
		--user_ip_repo_paths vitis_sobel3x3_ctrl/solution1/impl/ \
		--user_ip_repo_paths vitis_phase_ctrl/solution1/impl/ \
		--user_ip_repo_paths vitis_magnitude_ctrl/solution1/impl/ \
		--user_ip_repo_paths vitis_nonmax_ctrl/solution1/impl/ \
		--user_ip_repo_paths ip_repo_canny4 \
		--kernel_frequency 220 -o $@ $($@_xo) --remote_ip_cache ${IP_CACHE_DIR}_canny4 \
		--vivado.impl.strategies Congestion_SpreadLogic_high \
		--connectivity.sp vec_canny4_1.m_axi_0:HBM[0-7] \
		--connectivity.sp vec_canny4_1.m_axi_1:HBM[0-7]
	xclbinutil --dump-section EMBEDDED_METADATA:RAW:embeddedMetadata_canny4.xml --input $@ --force
	python3 set_xclbin_range.py embeddedMetadata_canny4.xml
	xclbinutil --replace-section EMBEDDED_METADATA:RAW:embeddedMetadata_canny4.xml --input $@ --output tmp_canny4.xclbin
	mv tmp_canny4.xclbin $@


vec_canny4_sim.xclbin: vec_canny4.xo
	$(eval $@_xo := vec_canny4_sim.xo)
	v++ -O3 --temp_dir ./_x.canny4_sim -R 2 -l $(VPPFLAGS_SIM) $(VPPLFLAGS) \
		--user_ip_repo_paths vitis_sobel3x3_ctrl/solution1/impl/ \
		--user_ip_repo_paths vitis_phase_ctrl/solution1/impl/ \
		--user_ip_repo_paths vitis_magnitude_ctrl/solution1/impl/ \
		--user_ip_repo_paths vitis_nonmax_ctrl/solution1/impl/ \
		--user_ip_repo_paths ip_repo_canny4 --kernel_frequency 400 -o $@ $($@_xo) --remote_ip_cache ${IP_CACHE_DIR}_canny4 --connectivity.sp vec_canny4_sim_1.m_axi:HBM[0]
	xclbinutil --dump-section EMBEDDED_METADATA:RAW:embeddedMetadata_canny4_sim.xml --input $@ --force
	python3 set_xclbin_range.py embeddedMetadata_canny4_sim.xml
	xclbinutil --replace-section EMBEDDED_METADATA:RAW:embeddedMetadata_canny4_sim.xml --input $@ --output tmp_canny4_sim.xclbin
	mv tmp_canny4_sim.xclbin $@
	emconfigutil --platform $(PFM)

vec_%_sim.xclbin: vec_%.xo
	$(eval $@_xo := vec_$*_sim.xo)
	v++ -O3 --temp_dir ./_x.$*_sim -R 2 -l $(VPPFLAGS_SIM) $(VPPLFLAGS) \
		--user_ip_repo_paths vitis_$*/solution1/impl/ \
		--user_ip_repo_paths ip_repo_$* \
		--kernel_frequency 400 -o $@ $($@_xo) --remote_ip_cache ${IP_CACHE_DIR}_$* \
		--connectivity.sp vec_$*_sim_1.m_axi:HBM[0]
	xclbinutil --dump-section EMBEDDED_METADATA:RAW:embeddedMetadata_$*_sim.xml --input $@ --force
	python3 set_xclbin_range.py embeddedMetadata_$*_sim.xml
	xclbinutil --replace-section EMBEDDED_METADATA:RAW:embeddedMetadata_$*_sim.xml --input $@ --output tmp_$*_sim.xclbin
	mv tmp_$*_sim.xclbin $@
	emconfigutil --platform $(PFM)

