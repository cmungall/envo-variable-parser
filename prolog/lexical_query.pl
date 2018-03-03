:- use_module(library(semweb/rdf11)).

:- rdf_register_prefix(obo, 'http://purl.obolibrary.org/obo/').
:- rdf_register_prefix(oio, 'http://www.geneontology.org/formats/oboInOwl#').

q(Root, Cls, Label, Score) :-
        rdf_global_id(obo:Root,URI),
        rdfs_subclass_of(Cls, URI),
        cls_label_score(Cls,Label,Score).

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

