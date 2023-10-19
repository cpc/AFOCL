

db: db/overlay_arria10 db/overlay_alveou280


db/overlay_alveou280:
	$(MAKE) -C alveou280-platform overlay_alveou280
	rm -rf $@
	mkdir -p $@
	cp -r alveou280-platform/overlay_alveou280/* $@


db/overlay_arria10:
	$(MAKE) -C a10-ocl-platform overlay_arria10
	rm -rf $@
	mkdir -p $@
	cp -r a10-ocl-platform/overlay_arria10/* $@
