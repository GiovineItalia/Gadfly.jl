
gadfly=`julia -e 'print(julia_pkgdir())'`/Gadfly/bin/gadfly

html : overview.html

%.html : %.md
	$(gadfly) $< > $@

clean :
	rm -f *.html

