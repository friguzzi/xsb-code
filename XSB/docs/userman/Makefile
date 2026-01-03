# File: XSB/docs/userman/Makefile
#
# $Id: Makefile,v 1.7 2010-08-19 15:03:36 spyrosh Exp $

.PHONY: all manual1 manual2 manual1-md manual2-md

all: manual1 manual2

manual1:
	latex manual1	
	bibtex manual1
	makeindex manual1
	latex manual1
	latex manual1
	dvips manual1.dvi -o manual1.ps
	dvipdf manual1.dvi
	$(MAKE) manual1-md

manual2:
	latex manual2	
	bibtex manual2
	makeindex manual1
	latex manual2
	latex manual2
	dvips manual2.dvi -o manual2.ps
	dvipdf manual2.dvi
	$(MAKE) manual2-md

manual1-md:
	@if command -v pandoc >/dev/null 2>&1; then \
		pandoc manual1.tex -o manual1.md; \
	else \
		echo "pandoc not found; skipping manual1.md"; \
	fi

manual2-md:
	@if command -v pandoc >/dev/null 2>&1; then \
		pandoc manual2.tex -o manual2.md; \
	else \
		echo "pandoc not found; skipping manual2.md"; \
	fi
