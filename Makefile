
# ----------------------------------------
# CONSTANTS
# ----------------------------------------
OBO = http://purl.obolibrary.org/obo
CFXML = cf-standard-name-table_v13.xml

# ----------------------------------------
# TOP LEVEL
# ----------------------------------------
all: target/parse.txt

# ----------------------------------------
# DOWNLOAD CF
# ----------------------------------------
data/$(CFXML):
	wget --no-check-certificate https://cdn.earthdata.nasa.gov/conduit/upload/502/cf-standard-name-table_v13.txt -O $@ && touch $@

.PRECIOUS: data/$(CFXML)

# HACK!
data/cf-vars.txt: ont/cf.owl
	pl2sparql -f tsv -i $< -e "label(X,L@en)" "x(L)" > $@

#data/cf.pro: ont/cf.owl
#	perl -npe 's@_@ @g' $< | tbl2p -p v > $@

data/cf.pro: ont/cf.owl
	pl2sparql -f prolog  -i $< -e "label(X,L@en)" "v(L)" > $@

cf-test: data/cf.pro
	swipl -l prolog/grammar -g t,halt.

target/parse.txt: data/cf.pro
	swipl -l prolog/grammar -g t,halt. > $@


cvt: ont/cf.owl

ont/envo.owl:
	curl -L $(OBO)/

ont/cf.owl: data/$(CFXML)
	swipl -l prolog/cfxml2owl -g "convert('$<', '$@.tmp.owl'),halt" && robot convert -i $@.tmp.owl -o $@
