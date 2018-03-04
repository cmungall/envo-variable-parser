:- use_module(library(semweb/rdf11)).
:- use_module(library(tabling)).
:- use_module(bitset).

:- rdf_register_prefix(obo, 'http://purl.obolibrary.org/obo/').
:- rdf_register_prefix(oio, 'http://www.geneontology.org/formats/oboInOwl#').

exclude_prefix('UBERON').
exclude_prefix('CARO').

exclude(Cls) :-
        rdf_global_id(obo:Id,Cls),
        concat_atom([Prefix,_],'_',Id),
        exclude_prefix(Prefix).


%! term_toks(+Term:Literal,?NormalizedTerm:String,?Toks:list) is det
%
% term is tokenized as a list of tokens
:- table term_toks/3.
term_toks(S@_,S,Toks) :-
        !,
        term_toks(S,S,Toks).
term_toks(S^^_,S,Toks) :-
        !,
        term_toks(S,S,Toks).

term_toks(S,S,Toks) :-
        atom_string(A,S),
        concat_atom(Toks1,' ',A),
        sort(Toks1,Toks).



:- table var_vector/1.
var_vector(V) :-
        v(Label),
        term_toks(Label,_,Toks),
        set_to_bitset(Toks,V).

        
is_used(Label) :-
        term_toks(Label,_,Toks),
        set_to_bitset(Toks,V),
        N is popcount(V),
        var_vector(V2),
        I is V /\ V2,
        NI is popcount(I),
        N == NI.
        
        
:- debug(lex).

cls_category(Cls, Cat) :-
        category_id(Cat,Id),
        rdf_global_id(obo:Id,CatCls),
        \+ \+ rdfs_subclass_of(Cls, CatCls).

cls_label(Cls, NLabel, Cats, Score) :-
        cls_label_score(Cls,Label,Score),
        \+ exclude(Cls),
        nlabel(Label, NLabel),
        %debug(lex,'Checking if label is found: ~w',[Label]),
        \+ \+ is_used(NLabel),
        debug(lex,' * Keeping: ~w',[Label]),
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

