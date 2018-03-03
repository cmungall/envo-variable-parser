:- use_module(library(semweb/rdf11)).

:- rdf_register_prefix(obo, 'http://purl.obolibrary.org/obo/').
:- rdf_register_prefix(oio, 'http://www.geneontology.org/formats/oboInOwl#').

exclude_prefix('UBERON').
exclude_prefix('CARO').

exclude(Cls) :-
        rdf_global_id(obo:Id,Cls),
        concat_atom([Prefix,_],'_',Id),
        exclude_prefix(Prefix).

cls_category(Cls, Cat) :-
        category_id(Cat,Id),
        rdf_global_id(obo:Id,CatCls),
        \+ \+ rdfs_subclass_of(Cls, CatCls).

cls_label(Cls, NLabel, Cats, Score) :-
        cls_label_score(Cls,Label,Score),
        \+ exclude(Cls),
        nlabel(Label, NLabel),
        setof(Cat,cls_category(Cls,Cat),Cats).

nlabel(Label@_, Label) :- !.
nlabel(Label^^_, Label) :- !.
nlabel(Label, Label) :- !.

cls_label_score(URI,Label,5) :-
        label(URI,Label).

cls_label_score(URI,Label,4) :-
        rdf(URI,oio:hasExactSynonym,Label).

cls_label_score(URI,Label,1) :-
        rdf(URI,oio:hasRelatedSynonym,Label).
cls_label_score(URI,Label,1) :-
        rdf(URI,oio:hasBroadSynonym,Label).
cls_label_score(URI,Label,1) :-
        rdf(URI,oio:hasNarrowSynonym,Label).

category_id(chemical, 'CHEBI_24431').
category_id(quality, 'PATO_0000001').
category_id(process_quality, 'PATO_0001236').
category_id(object_quality, 'PATO_0001241').
category_id(material, 'ENVO_00010483').
category_id(feature, 'ENVO_00002297').
category_id(process, 'ENVO_02500000').
category_id(physical, 'BFO_0000040').
category_id(unit, 'UO_0000000').
