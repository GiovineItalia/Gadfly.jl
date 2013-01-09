
gadfly=`julia -e 'print(julia_pkgdir())'`/Gadfly/bin/gadfly

all : html

html : overview.html

markdown: overview.weaved.md

%.html : %.md
	$(gadfly) --to=html $< > $@

%.weaved.md : %.md
	$(gadfly) --to=markdown $< > $@

clean :
	rm -f *.html

