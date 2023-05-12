all: index.md

%.md: %.cbmd Makefile
	(awk -f until.awk '\+\+\+' 2 $<; \
	CODEBRAID_ANSI=false codebraid pandoc --ascii --from markdown --to markdown $< \
	| awk -f after.awk '\+\+\+' 2 | sed -r 's/^``` {\.([a-z]+).*}/```\1/; s/``` ?std(out|err)/```txt/;') > $@

%.rawmd: %.cbmd Makefile
	CODEBRAID_ANSI=false codebraid pandoc --ascii --from markdown --to markdown $< > $@


%.html: %.cbmd Makefile
	CODEBRAID_ANSI=false codebraid pandoc -s --ascii --from markdown --to html --css pandoc.css --css style.css $< > $@ || true

open: README.html
	open README.html

watch:
	fswatch -o index.cbmd | xargs -n1 -I{} $(MAKE) all
