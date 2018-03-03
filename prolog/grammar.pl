:- use_module(library(tabling)).
:- use_module(library(semweb/rdf11)).

case('angstrom exponent of ambient aerosol in air',_).
case('atmosphere cloud liquid water content', _).
case('mass concentration of atomic bromine in air',_).

:- table variable//1.

% EXAMPLE: "tendency of upward air velocity due to advection"
variable( due_to(Effect,Cause) ) --> variable(Effect), [due,to], cause(Cause).

% EXAMPLE: "tendency of upward air velocity due to advection"
variable( assuming(V,Assumption) ) --> variable(V), [assuming], assumption(Assumption).

% EXAMPLE: "upward heat flux in air"
variable( located_in(V, M) ) --> variable(V), [in], !, location(M).

% EXAMPLE: "air pressure at cloud base"
variable( located_at(V, M) ) --> variable(V), [at], !, location(M).

% EXAMPLE: "virtual salt flux into sea water"
variable( into(V, M) ) --> variable(V), [into], !, location(M).

% EXAMPLE: "volume fraction of clay in soil")
% TODO: fractions
variable( inheres_in(A, E) ) --> attribute(A), [of], !, variable(E).

variable(X) --> variable_np(X).

%variable_np( q(X) ) --> nterm(quality, X), !.
variable_np( inheres_in(Q,E) ) --> material(E), nterm(quality, Q), !.
variable_np( inheres_in(Q,E) ) --> process(E), nterm(quality, Q), !.  % TODO - check this is a rate
variable_np(X) --> np(X).


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

attribute( attribute(A) ) --> variable(A).

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
        forall(variable(Phrase,Toks,[]),
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


:- begin_tests(parse_test, [setup(loadall)]).

test_parse(Term, Expected) :-
        nl,
        format('## ~w~n',[Term]),
        term_toks(Term, _, Toks),
        forall(variable(Phrase,Toks,[]),
               format(' PARSE: ~q~n',[Phrase])),
        assertion( \+ \+ (variable(Phrase,Toks,[]), Phrase=Expected)).


test(p1) :-
        test_parse('energy content', _).        

:- end_tests(parse_test).
