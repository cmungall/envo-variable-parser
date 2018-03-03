:- use_module(library(tabling)).
:- use_module(library(semweb/rdf11)).

case('angstrom exponent of ambient aerosol in air',_).
case('atmosphere cloud liquid water content', _).
case('mass concentration of atomic bromine in air',_).

:- table cvar//1.


cvar( due_to(Effect,Cause) ) --> cvar1(Effect), [due,to], !, cvar1(Cause).
cvar(X) --> cvar0(X).


cvar0( located_in(V, M) ) --> cvar1(V), [in], !, material(M).
cvar0( located_at(V, M) ) --> cvar1(V), [at], !, material(M).
cvar0( into(V, M) ) --> cvar1(V), [into], !, material(M).
cvar0(X) --> cvar1(X).

cvar1( inheres_in(A, E) ) --> attribute(A), [of], !, cvar0(E).
cvar1(X) --> cvar2(X).

cvar2(X) --> cvar_np(X).

%cvar_np( q(X) ) --> nterm(quality, X), !.
cvar_np( inheres_in(Q,E) ) --> material(E), nterm(quality, Q), !.
cvar_np( inheres_in(Q,E) ) --> process(E), nterm(quality, Q), !.  % TODO - check this is a rate
cvar_np(X) --> np(X).


np(X) --> terminal(X).
np( X+Y ) --> terminal(X), np(Y).

terminal( match(X) ) --> nterm(Cat, X),{Cat\=cf},!.
terminal( cf(X) ) --> nterm(cf, X).

terminal( n(X) ) --> [X], {\+ reserved(X)}.

attribute( attribute(A) ) --> cvar2(A).

material( material(M) ) --> nterm(material, M), !.
material( material(M) ) --> np(M).

process( process(M) ) --> nterm(process, M), !.
process( process(M) ) --> np(M).

%fooz(abc) --> [a,b,c].


reserved(of).
reserved(in).
reserved(into).


%tr(Tree,Expr) :-
        

%:- table nterm/3.


%setup :- forall(nterm(_,_,_),true).


show_parse(Term) :-
        format('## ~w~n',[Term]),
        term_toks(Term, _, Toks),
        forall(cvar(Phrase,Toks,[]),
               format(' PARSE: ~w~n',[Phrase])),
        nl.


loadall :-
        consult('data/cf.pro'),
        consult('ont/dict.pl'),
        ix.

t :-
        loadall,
        forall(v(X),
               show_parse(X)).


nterm_1(cf, NTerm, ToksPartial, Rest) :- v(Term),term_toks(Term,NTerm,Toks), append(Toks,Rest,ToksPartial).
nterm_1(Cat, cls(Id,NTerm), ToksPartial, Rest) :- cls(Cat,Id,Term),term_toks(Term,NTerm,Toks), append(Toks,Rest,ToksPartial).

%! term_toks(+Term:Literal,?NormalizedTerm:String,?Toks:list) is det
%
term_toks(S@_,S,Toks) :-
        !,
        term_toks(S,S,Toks).
term_toks(S^^_,S,Toks) :-
        !,
        term_toks(S,S,Toks).

term_toks(S,S,Toks) :-
        atom_string(A,S),
        concat_atom(Toks,' ',A).


ix :-
        forall(nterm_1(Cat, A,B,C),
               assert(nterm(Cat, A,B,C))),
        compile_predicates([nterm/4]),
        tell('target/cache.pro'),
        forall(nterm(Cat,A,B,C),
               format('~q.~n',[nterm(Cat,A,B,C)])),
        told.
               


% TESTS

t1 :-
        loadall,
        show_parse('energy content').

