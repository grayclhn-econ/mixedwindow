.PHONY: all clean burn zip

TeXFLAGS := -p -b -q -c
R := R
Rscript := Rscript
RFLAGS := --vanilla
sqlite := sqlite3
sqliteFLAGS := $(empty)

all: Paper.pdf # zip Online

Paper.pdf: Paper.tex mc.tex empirics.tex
	texi2dvi $< $(TeXFLAGS)
mc.tex: floats db/dgp1.done db/dgp2.done db/dgp3.done
empirics.tex: floats empirics.RData

floats: 
	mkdir -p $@

empirics.RData: R/empirics.R
	$(Rscript) $(RSCRIPTFLAGS) $< &> R/empirics.Rout

%.pdf: %.tex
	$(R) CMD texi2dvi $< $(TeXFLAGS)
%.tex: %.Rnw
	$(R) CMD Sweave $<


# Automatically create an archive file
archfile = calhoun-2011-ClWcomment.tar.gz
zip: $(archfile)
$(archfile): $(filter-out .bzrignore, $(shell bzr ls -R -V --kind=file)) Paper.pdf AllRefs.bib
	tar chzf $@ $^

# Put the archive file on my website
Online: $(archfile)
	scp $? gcalhoun@econ22.econ.iastate.edu:public_html/software
	touch $@

# I use the makefile to parallelize the simulations (this is kind of
# ghetto, but effective and easy).  Basically, I create several
# different temporary databases and store simulation results in each
# one, then insert the values into a table in the main database -- the
# reason is to get around problems that SQLite has with concurrent
# write access (in the future, I'll probably use a different DBM).
# All of the dependencies that manage that process are contained in
# MakeScript.mk, which is automatically generated by MakeScript.R.
# MakeScript.R has the parameters that control the number of
# simulations, number of jobs to use, etc.
MakeScript.mk: MakeScript.R
	$(Rscript) $(RFLAGS) $< > $@
include MakeScript.mk