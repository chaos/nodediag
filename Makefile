all:
	@echo Nothing to do

clean:
	rm -f nodediag-*.tar.gz

dist:
	@scripts/mkdist

check:
	cd test && ../scripts/runtests
