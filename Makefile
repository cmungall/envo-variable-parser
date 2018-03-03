all: cf-test

data/cf-standard-name-table_v13.xml:
	wget --no-check-certificate https://cdn.earthdata.nasa.gov/conduit/upload/502/cf-standard-name-table_v13.txt -O $@ && touch $@

.PRECIOUS: data/cf-standard-name-table_v13.xml

# HACK!
data/cf-vars.txt: data/cf-standard-name-table_v13.xml
	perl -ne 'print "$$1\n" if m@<entry id="(\S+)">@' $< > $@

data/cf.pro: data/cf-vars.txt
	perl -npe 's@_@ @g' $< | tbl2p -p v > $@

cf-test: data/cf.pro
	swipl -l prolog/grammar -g t,halt.
