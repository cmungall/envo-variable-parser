:- use_module(library(tabling)).

cvar( due_to(Effect,Cause) ) --> cvar1(Effect), [due,to], !, cvar1(Cause).
cvar(X) --> cvar0(X).


cvar0( located_in(V, M) ) --> cvar1(V), [in], !, material(M).
cvar0( into(V, M) ) --> cvar1(V), [into], !, material(M).
cvar0(X) --> cvar1(X).

cvar1( inheres_in(A, E) ) --> attribute(A), [of], !, cvar1(E).
cvar1(X) --> cvar2(X).

cvar2(X) --> cvar_np(X).

cvar_np( term(X) ) --> nterm(X).
cvar_np( -(X,Y)) --> cvar_t(X), cvar_np(Y).
cvar_np(X) --> cvar_t(X).

cvar_t( n(X) ) --> [X], {\+ reserved(X)}.

attribute( attribute(A) ) --> cvar2(A).
material( material(M) ) --> cvar_np(M).


reserved(of).


%:- table nterm/3.


%setup :- forall(nterm(_,_,_),true).


show_parse(Term) :-
        format('## ~w~n',[Term]),
        term_toks(Term, Toks),
        forall(cvar(Phrase,Toks,[]),
               format(' PARSE: ~w~n',[Phrase])),
        nl.
xt :-
        show_parse('b').

t :-
        loadvars('data/cf.pro'),
        forall(v(X),
               show_parse(X)).


nterm_1(Term, Toks, []) :- v(Term),term_toks(Term,Toks).

term_toks(S,Toks) :-
        atom_string(A,S),
        concat_atom(Toks,' ',A).


loadvars(F) :-
        consult(F),
        forall(nterm_1(A,B,C),
               assert(nterm(A,B,C))),
        compile_predicates([nterm/3]).


               
