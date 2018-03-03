:- use_module(library(tabling)).
:- use_module(library(semweb/rdf11)).

case('angstrom exponent of ambient aerosol in air',_).
case('atmosphere cloud liquid water content', _).
case('mass concentration of atomic bromine in air',_).

:- table cvar//1.

% EXAMPLE: "tendency of upward air velocity due to advection"
cvar( due_to(Effect,Cause) ) --> cvar(Effect), [due,to], !, cause(Cause).

% EXAMPLE: "tendency of upward air velocity due to advection"
cvar( assuming(V,Assumption) ) --> cvar(V), [assuming], !, assumption(Assumption).

% EXAMPLE: "upward heat flux in air"
cvar( located_in(V, M) ) --> cvar(V), [in], !, location(M).

% EXAMPLE: "air pressure at cloud base"
cvar( located_at(V, M) ) --> cvar(V), [at], !, location(M).

% EXAMPLE: "virtual salt flux into sea water"
cvar( into(V, M) ) --> cvar(V), [into], !, location(M).

% EXAMPLE: "volume fraction of clay in soil")
% TODO: fractions
cvar( inheres_in(A, E) ) --> attribute(A), [of], !, cvar(E).

cvar(X) --> cvar_np(X).

%cvar_np( q(X) ) --> nterm(quality, X), !.
cvar_np( inheres_in(Q,E) ) --> material(E), nterm(quality, Q), !.
cvar_np( inheres_in(Q,E) ) --> process(E), nterm(quality, Q), !.  % TODO - check this is a rate
cvar_np(X) --> np(X).


cause(X) --> process(X), !.
cause(X) --> np(X).

location(X) --> material(X), !.
location(X) --> np(X).

assumption(X) --> np(X).


np(X) --> terminal(X).
np( X+Y ) --> terminal(X), np(Y).

terminal( match(X) ) --> nterm(Cat, X),{Cat\=cf},!.
terminal( cf(X) ) --> nterm(cf, X).

terminal( n(X) ) --> [X], {\+ reserved(X)}.

attribute( attribute(A) ) --> cvar(A).

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

