

db: db/overlay_alveou280


db/overlay_alveou280:
	$(MAKE) -C alveou280-platform overlay_alveou280
	rm -rf $@
	mkdir -p $@
	cp -r alveou280-platform/overlay_alveou280/* $@

