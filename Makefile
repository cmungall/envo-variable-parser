
# ----------------------------------------
# CONSTANTS
# ----------------------------------------
OBO = http://purl.obolibrary.org/obo
CFXML = cf-standard-name-table_v13.xml
SWIPL = swipl -L0 -G0 -T0  -p library=prolog

# ----------------------------------------
# TOP LEVEL
# ----------------------------------------
all: target/parse.txt


# ----------------------------------------
# TESTS
# ----------------------------------------
test:   
	$(SWIPL) -l prolog/grammar -g run_tests,halt

# ----------------------------------------
# DOWNLOAD AND PROCESS CF
# ----------------------------------------
data/$(CFXML):
	wget --no-check-certificate https://cdn.earthdata.nasa.gov/conduit/upload/502/cf-standard-name-table_v13.txt -O $@ && touch $@

.PRECIOUS: data/$(CFXML)

data/cf-vars.txt: ont/cf.owl
	pl2sparql -f tsv -i $< -e "label(X,L@en)" "x(L)" > $@

data/cf-defs.txt: ont/cf.owl
	pl2sparql  -f tsv -i $< -e "label(X,L@en),rdf(X,'http://purl.obolibrary.org/obo/IAO_0000115', D@en)" "x(L,D)" > $@

#data/cf.pro: ont/cf.owl
#	perl -npe 's@_@ @g' $< | tbl2p -p v > $@

data/cf.pro: ont/cf.owl
	pl2sparql -f prolog  -i $< -e "label(X,L@en)" "v(L)" > $@


ont/cf.owl: data/$(CFXML)
	swipl -l prolog/cfxml2owl -g "convert('$<', '$@.tmp.owl'),halt" && robot convert -i $@.tmp.owl -o $@

cvt: ont/cf.owl

# ----------------------------------------
# 
# ----------------------------------------

# ----------------------------------------
# ONTOLOGY PROCESSING
# ----------------------------------------

ONTS = envo pato chebi

ont/envo.owl:
	curl -L $(OBO)/envo.owl > $@.tmp && mv $@.tmp $@
.PRECIOUS: envo.owl

ont/pato.owl:
	curl -L $(OBO)/pato.owl > $@.tmp && mv $@.tmp $@
.PRECIOUS: pato.owl

ont/chebi.owl:
	curl -L $(OBO)/chebi.owl > $@.tmp && mv $@.tmp $@
.PRECIOUS: chebi.owl

ont/dictionary.pl: $(patsubst %, ont/%.owl, $(ONTS))
	pl2sparql -f prolog $(patsubst %, -i %, $^) -c data/cf.pro -c prolog/lexical_query -e cls_label > $@.tmp && mv $@.tmp $@

# ----------------------------------------
# PARSE AND TRANSLATE
# ----------------------------------------

target/parse.txt: data/cf.pro ont/dictionary.pl prolog/grammar.pl
	$(SWIPL) -l prolog/grammar -g parse_all,halt. > $@

target/parse-detail.txt: data/cf.pro ont/dictionary.pl prolog/grammar.pl
	swipl -l prolog/grammar -g parse_all(true),halt. > $@

target/usage.txt: data/cf.pro ont/dictionary.pl prolog/grammar.pl
	swipl -l prolog/grammar -g usage_report,halt. > $@.tmp && sort -u $@.tmp > $@

target/summary.txt: data/cf.pro ont/dictionary.pl prolog/grammar.pl
	swipl -l prolog/grammar -g usage_summary,halt. > $@.tmp && mv $@.tmp $@
