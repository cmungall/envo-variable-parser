
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
# DOWNLOAD AND PROCESS CF
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


ont/cf.owl: data/$(CFXML)
	swipl -l prolog/cfxml2owl -g "convert('$<', '$@.tmp.owl'),halt" && robot convert -i $@.tmp.owl -o $@

cvt: ont/cf.owl

# ----------------------------------------
# ONTOLOGY PROCESSING
# ----------------------------------------

DICTS = envo_material envo_process pato_quality

ont/envo.owl:
	curl -L $(OBO)/envo.owl > $@.tmp && mv $@.tmp $@
.PRECIOUS: envo.owl

ont/pato.owl:
	curl -L $(OBO)/pato.owl > $@.tmp && mv $@.tmp $@
.PRECIOUS: pato.owl

ont/envo_material.pl: ont/envo.owl
	pl2sparql -f prolog -i $< -e "rdfs_subclass_of(X, '$(OBO)/ENVO_00010483'),label(X,L)" "cls(material,X,L)" > $@

ont/envo_process.pl: ont/envo.owl
	pl2sparql -f prolog -i $< -e "rdfs_subclass_of(X, '$(OBO)/ENVO_02500000'),label(X,L)" "cls(process,X,L)" > $@

ont/pato_quality.pl: ont/pato.owl
	pl2sparql -f prolog -i $< -e "rdfs_subclass_of(X, '$(OBO)/PATO_0000001'),label(X,L)" "cls(quality,X,L)" > $@

ont/dict.pl: $(patsubst %, ont/%.pl, $(DICTS))
	cat $^ > $@

# ----------------------------------------
# PARSE AND TRANSLATE
# ----------------------------------------

target/parse.txt: data/cf.pro ont/dict.pl prolog/grammar.pl
	swipl -l prolog/grammar -g t,halt. > $@
