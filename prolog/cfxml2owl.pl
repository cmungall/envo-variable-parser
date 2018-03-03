:- use_module(library(sgml)).
:- use_module(library(semweb/rdf11)).

:- rdf_register_prefix(cf, 'http://purl.obolibrary.org/obo/envo/vars/cf/').
:- rdf_register_prefix(oio, 'http://www.geneontology.org/formats/oboInOwl#').
:- rdf_register_prefix(def, 'http://purl.obolibrary.org/obo/IAO_0000115').
:- rdf_register_prefix(quality, 'http://purl.obolibrary.org/obo/PATO_0000001').

convert(File,Out) :-
        load_xml(File,[Term],[]),
        tf(Term),
        rdf_save(Out).

frag_label(ID,NLabel) :-
        concat_atom(Toks,'_',ID),
        concat_atom(Toks,' ',Label),
        nlabel(Label,NLabel).

        

tf(element(_,_,Elts)) :-
        rdf_assert(cf:'cf.owl',rdf:type,owl:'Ontology'),
        forall(member(E,Elts),
               tf_top(E)).

tf_top( element(entry, [id=ID], Elts) ) :-
        !,
        rdf_global_id(cf:ID,URI),
        rdf_assert(URI, rdf:type, owl:'Class'),
        rdf_assert(URI, rdfs:subClassOf, quality:''),
        frag_label(ID,Label),
        rdf_assert(URI, rdfs:label, Label@en),
        forall(member(E,Elts),
               tf_prop(URI,E)).

tf_top( element(alias, [id=ID], Elts) ) :-
        !,
        member(element(entry_id,_,[AltID]), Elts),
        rdf_global_id(cf:ID,URI),
        frag_label(AltID,Label),
        rdf_assert(URI,oio:hasExactSynonym,Label@en).



tf_top(E) :- debug(info,'noparse ~w',[E]).

tf_prop(URI,element(canonical_units,_,[U])) :-
        !,
        rdf_assert(URI,oio:hasUnitLabel,U@en).
tf_prop(URI,element(grib,_,[U])) :-
        !,
        rdf_assert(URI,oio:grib,U@en).
tf_prop(URI,element(amip,_,[U])) :-
        !,
        rdf_assert(URI,oio:amip,U@en).
tf_prop(URI,element(description,_,[D])) :-
        !,
        rdf_assert(URI,def:'',D@en).
tf_prop(_URI,E) :-
        E = element(_,_,_),
        !,
        writeln(noparse(E)).
tf_prop(_,_).

nlabel(Label,NLabel) :-
        atom_concat(' ',X,Label),
        !,
        nlabel(X,NLabel).
nlabel(Label,NLabel) :-
        atom_concat(X,' ',Label),
        !,
        nlabel(X,NLabel).
nlabel(Label,Label) :- !.




