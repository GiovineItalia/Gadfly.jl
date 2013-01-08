
gadfly=`julia -e 'print(julia_pkgdir())'`/Gadfly/bin/gadfly

all : html

html : overview.html

%.html : %.md
	$(gadfly) --self-contained $< > $@

clean :
	rm -f *.html

