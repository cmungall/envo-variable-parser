all: cf-test

CFXML = cf-standard-name-table_v13.xml

data/$(CFXML):
	wget --no-check-certificate https://cdn.earthdata.nasa.gov/conduit/upload/502/cf-standard-name-table_v13.txt -O $@ && touch $@

.PRECIOUS: data/$(CFXML)

# HACK!
data/cf-vars.txt: data/$(CFXML)
	perl -ne 'print "$$1\n" if m@<entry id="(\S+)">@' $< > $@

data/cf.pro: data/cf-vars.txt
	perl -npe 's@_@ @g' $< | tbl2p -p v > $@

cf-test: data/cf.pro
	swipl -l prolog/grammar -g t,halt.

cvt: ont/cf.owl

ont/cf.owl: data/$(CFXML)
	swipl -l prolog/cfxml2owl -g "convert('$<', '$@.tmp.owl'),halt" && robot convert -i $@.tmp.owl -o $@
