/*
  
http://www.met.reading.ac.uk/~jonathan/CF_metadata/14.1/lexicon
  
  */

:- use_module(library(tabling)).
:- use_module(library(semweb/rdf11)).
:- rdf_register_prefix(dbr,'http://dbpedia.org/resource/').

:- op(200,xfy,and).
:- op(150,xfy,some).
:- op(150,xfy,only).

:- table variable//1.

% From: http://cfconventions.org/Data/cf-standard-names/docs/guidelines.html
variable( intersectionOf([Std,
                          Surface,
                          Component,
                          At,
                          Medium,
                          Process,
                          Condition])
        ) -->
        surface(Surface),
        component(Component),
        std(Std),
        at_surface(At),
        in_medium(Medium),
        due_to_process(Process),
        assuming_condition(Condition).

% A surface is defined as a function of horizontal position
:- table surface//1.
surface( on(X) ) --> np(X).

opt_surface(X) --> surface(X).
opt_surface($none) --> [].

at_surface( X ) --> [at], surface(X).
at_surface( $none ) --> [].


% The direction of the spatial component of a vector is indicated by one of the words upward, downward, northward, southward, eastward, westward, x, y. The last two indicate directions along the horizontal grid being used when they are not true longitude and latitude (if there is a rotated pole, for instance)
% EXAMPLE: geostrophic eastward
:- table component//1.
component( component(X) ) --> np(X).
component($none) --> [].

:- table medium//1.
medium( medium(X) ) --> physical(X).

:- table in_medium//1.
in_medium( X ) --> [in], medium(X).
in_medium( $none ) --> [].

:- table due_to_process//1.
due_to_process(X) --> [due,to], !, process(X).
due_to_process($none) --> [].

:- table assuming_condition//1.
assuming_condition(X) --> [assuming], !, assumption(X).
assuming_condition($none) --> [].

% standard name
:- table std//1.
std( tendency_of(X) ) --> [tendency,of], !, std(X).
std( square_of(X) ) --> [square,of], !, std(X).
std( ratio_of(X,Y) ) --> [ratio,of], !, std(X), [to], std(Y).

% variant case
% E.g. sea surface temperature
std( intersectionOf([Q,
                     inheres_in(E),
                     surface(S)]) ) --> physical(E), surface(S),object_quality(Q).
std( intersectionOf([Q,
                     inheres_in(E)]) ) --> physical(E), object_quality(Q).


% TODO rest
std( std(X) ) --> quality(X).



% EXAMPLE: "ratio of x derivative of ocean rigid lid pressure to sea surface density"
xxvariable( ratio(V1,V2) ) --> [ratio],[of],xxvariable(V1), [to], xxvariable(V2).

% EXAMPLE: "mass fraction of alkanes in air"
% Mass fraction is used in the construction mass_fraction_of_X_in_Y, where X is a material constituent of Y. It means the ratio of the mass of X to the mass of Y (including X)
xxvariable( fraction(Q,M1,M2) ) --> quality(Q),[fraction],[of],physical(M1), [in], physical(M2).

% EXAMPLE: "product of air temperature and specific humidity"
xxvariable( product(V1,V2) ) --> [product],[of],xxvariable(V1), [and], xxvariable(V2).

% EXAMPLE: "tendency of upward air velocity due to advection"
xxvariable( due_to(Effect,Phenomenom) ) --> xxvariable(Effect), [due,to], phenomenom(Phenomenom).

% EXAMPLE: "tendency of upward air velocity due to advection"
xxvariable( assuming(V,Assumption) ) --> xxvariable(V), [assuming], assumption(Assumption).

% EXAMPLE: "upward heat flux in air"
xxvariable( measured_in(V, M) ) --> xxvariable(V), [in], location(M).

% EXAMPLE: "air pressure at cloud base"
xxvariable( measured_at(V, M) ) --> xxvariable(V), [at], location(M).

% EXAMPLE: "virtual salt flux into sea water"
xxvariable( into(V, M) ) --> xxvariable(V), [into], location(M).

% EXAMPLE: "volume fraction of clay in soil")
xxvariable( inheres_in(A, E) ) --> attribute(A), [of], xxvariable(E).

%%%%xxvariable_np( q(X) ) --> nterm(quality, X), !.
xxvariable( inheres_in(Q,E) ) --> physical(E), object_quality(Q).
xxvariable( inheres_in(Q,E) ) --> process(E), process_quality(Q).  % TODO - check this is a rate

:- table phenomenom//1.

% 'phenomenom' terms succeed 'due to'
phenomenom(X) --> process(X).
phenomenom(X) --> np(X), \+ process(X).

% TODO
location(X) --> material(X).
location(X) --> np(X), \+ material(X).

assumption(X) --> np(X).

% arbitrary noun-phrase
np(X) --> terminal(X).
np( X+Y ) --> terminal(X), np(Y).

% terminals
terminal( induce(X) ) --> nterm(Cats, X),{Cats\=[cf]}.
%terminal( cf(X) ) --> nterm([cf], X).
terminal( n(X) ) --> [X], \+nterm(_,X), {\+ reserved(X)}.
%terminal( n(X) ) --> [X], {\+ reserved(X)}.

xxattribute( attribute(A) ) --> xxvariable(A).

:- table physical//1.

% EXAMPLE: sea surface
physical( qualified(Qual, M) ) --> physical(M),qualifier(Qual).
physical( physical(M) ) --> cat_nterm(physical, M).
physical( physical(M) ) --> np(M), \+ cat_nterm(physical, M).


qualifier(Qual) --> np(Qual).


material( material(M) ) --> cat_nterm(material, M), !.
material( material(M) ) --> np(M).

process( process(M) ) --> cat_nterm(process, M), !.
process( process(M) ) --> np(M).

quality( quality(Q) ) --> cat_nterm(quality, Q), !.
quality( quality(Q) ) --> np(Q).

object_quality( object_quality(Q) ) --> cat_nterm(object_quality, Q), !.
object_quality( object_quality(Q) ) --> terminal(Q).

process_quality( process_quality(Q) ) --> cat_nterm(process_quality, Q), !.
process_quality( process_quality(Q) ) --> terminal(Q).

%fooz(abc) --> [a,b,c].

cat_nterm(Cat,X) --> nterm(Cats,X),{member(Cat,Cats)}.


reserved(due).
reserved(to).
reserved(of).
reserved(at).
reserved(in).
reserved(into).

% ----------------------------------------
% UTIL
% ----------------------------------------

%! show_parse(+Term:string, IsShowAll:bool) is det
%
% given term, show the best parse - and optionally all parses
show_parse(Term,IsShowAll) :-
        format('## ~w~n',[Term]),
        term_toks(Term, _, Toks),
        Goal = variable(Phrase,Toks,[]),
        (   goal_ranked(Goal, Phrase, [Score-Best|_])
        ->  format('  BEST: ~w  // PENALTY=~w~n',[Best,Score]),
            (   tree_expression(Best,Expr)
            ->  format('  EQUIVALENT_TO: ~w ~n',[Expr])
            ;   format('  **NO_OWL**~n'))
        ;   format('  **NO_PARSE**~n')),
        forall((IsShowAll,Goal),
               format(' PARSE: ~w~n',[Phrase])),
        nl.

% load dictionary and terms to parse
loadall :-
        consult('data/cf.pro'), % v/1
        consult('ont/dictionary.pl'), % cls_label/4
        compile_dcg_terms.

% parse all v/1 terms and show results
parse_all :-
        parse_all(false).
parse_all(IsShowAll) :-
        loadall,
        forall(v(X),
               show_parse(X,IsShowAll)),
        tell('target/slim-generated.pro'),
        forall(found(X),
               format('~q.~n',[slim(X)])),
        told.

% Tok is a token in NTerm
token_usage(Tok,NTerm) :-
        v(Term),
        term_toks(Term,NTerm,Toks),
        member(Tok,Toks).

% show every usage of a token, write report
usage_report :-
        loadall,
        forall(token_usage(Tok,Term),
               format('~w\t~w~n',[Tok,Term])).

% count every usage of a token, write report
usage_summary :-
        loadall,
        setof(Num-Tok,aggregate(sum(1),Term,token_usage(Tok,Term),Num),Pairs),
        reverse(Pairs,Rev),
        forall(member(Num-Tok,Rev),
               format('~w\t~w~n',[Num,Tok])).

% ----------------------------------------
% COMPILING TO GRAMMAR
% ----------------------------------------


%! term_toks(+Term:Literal,?NormalizedTerm:String,?Toks:list) is det
%
% term is tokenized as a list of tokens
term_toks(S@_,S,Toks) :-
        !,
        term_toks(S,S,Toks).
term_toks(S^^_,S,Toks) :-
        !,
        term_toks(S,S,Toks).

term_toks(S,S,Toks) :-
        atom_string(A,S),
        concat_atom(Toks,' ',A).

% intermediate goal used in compilation of DCG goals
nterm_1([cf], NTerm, ToksPartial, Rest) :- v(Term),term_toks(Term,NTerm,Toks), append(Toks,Rest,ToksPartial).
nterm_1(Cats, cls(Id,NTerm), ToksPartial, Rest) :- cls_label(Id,Term,Cats,_Score),term_toks(Term,NTerm,Toks), append(Toks,Rest,ToksPartial).


% compiles the existing vocabulary (loaded by loadall/1) into DCG terminals
compile_dcg_terms :-
        forall(nterm_1(Cat, A,B,C),
               assert(nterm(Cat, A,B,C))),
        compile_predicates([nterm/4]),
        tell('target/cache.pro'),
        forall(nterm(Cat,A,B,C),
               format('~q.~n',[nterm(Cat,A,B,C)])),
        told.

% ----------------------------------------
% TRANSLATION TO OWL
% ----------------------------------------
tree_expression(cls(URI,_), URI) :- !.
tree_expression(n(Word), dbr:Word) :- !.
tree_expression(A+B, and(AX,some(relatedTo,BX))) :- !, tree_expression(A,AX), tree_expression(B,BX).
tree_expression(T,AX) :-
        % unary predicates are informative and do not affect the class expression
        T =.. [_,A],
        !,
        tree_expression(A,AX).
tree_expression(T,and(AX,some(R,BX))) :-
        % binary predicates
        T =.. [Pred,A,B],
        !,
        tree_expression(A,AX),
        tree_expression(B,BX),
        R=Pred.                 % TODO

tree_expression(T,and(Genus,some(of,AX),some(upper,BX),some(lower,CX))) :-
        % binary predicates
        T =.. [Pred,A,B,C],
        !,
        tree_expression(A,AX),
        tree_expression(B,BX),
        tree_expression(C,CX),
        Genus=Pred.                 % TODO
tree_expression(X,huh(X)).



               


% ----------------------------------------
% SCORING
% ----------------------------------------
% A term can product multiple parses; each parse tree
% is penalized by the presence of certain characteristics; e.g use of unknown vocab terms

:- dynamic found/1.

tree_penalty(intersectionOf(L), Sum) :-
        !,
        maplist(tree_penalty,L,Scores),
        sumlist(Scores,Sum).


% terminal is unknown word
tree_penalty(n(_),2) :- !.

% arbitrary noun-phrase
tree_penalty(A+B,S) :-
        !,
        tree_penalty(A,S1),
        tree_penalty(B,S2),
        S is S1 + S2 + 4.

tree_penalty(Cls,0) :-
        Cls = cls(_,_),
        !,
        assert(found(Cls)).


tree_penalty(induce(A),S) :-
        !,
        tree_penalty(A,S1),
        S is S1 + 6.
tree_penalty(T,S) :-
        T =.. [_Pred,A],
        !,
        tree_penalty(A,S).

% minor penalty incurred for depth
tree_penalty(T,S) :-
        T =.. [_Pred,A,B],
        !,
        tree_penalty(A,S1),
        tree_penalty(B,S2),
        S is S1 + S2 + 1.

% as above, n-ary; e.g. fraction
tree_penalty(T,S) :-
        T =.. [_Pred,A,B,C],
        !,
        tree_penalty(A,S1),
        tree_penalty(B,S2),
        tree_penalty(C,S3),
        S is S1 + S2 + S3 + 1.

% TODO: score classes based on synonym                   
tree_penalty(_,0) :- !.


%! rank_trees(+Trees:list, Pairs:list) is det
%
% given a list of parse trees, returns a list of Penalty-Tree pairs
% ordered by lowest penalty first
rank_trees(Trees,Pairs) :-
        setof(S-T,(member(T,Trees),tree_penalty(T,S)),Pairs).

% goal is assumed to be a DCG phrase goal that binds Template to a possible parse tree
goal_ranked(Goal,Template,Pairs) :-
        setof(Template,Goal,Trees),
        rank_trees(Trees,Pairs).



% ----------------------------------------
% TESTS
% ----------------------------------------


:- begin_tests(parse_test, [setup(loadall)]).

test_parse(Term, ExpectedTree, ExpectedScore) :-
        test_parse(Term, ExpectedTree, ExpectedScore, variable).
test_parse(Term, ExpectedTree, ExpectedScore, Pred) :-
        nl,
        format('## ~w~n',[Term]),
        term_toks(Term, _, Toks),
        % DEFAULT: variable(Phrase,Toks,[]),
        Goal =.. [Pred, Phrase, Toks, []],
        goal_ranked(Goal, Phrase, [Score-Best|_]),
        format('  BEST: ~q  // SCORE=~w~n',[Best,Score]),
        nl,
        tree_expression(Best,Expr),
        format('  EQUIVALENT_TO: ~w ~n',[Expr]),        
        forall((Goal,tree_penalty(Phrase,Penalty)),
               format(' PARSE: ~q // PENALTY=~w~n',[Phrase,Penalty])),
        nl,
        assertion( \+ \+ (Goal, Phrase=ExpectedTree)),
        assertion( Score = ExpectedScore).



xxxtest(preexisting) :-
        test_parse('angle of emergence', cf("angle of emergence"), 0, terminal).
test(ee) :-
        test_parse('sea surface', _, _, physical).

test(eq1) :-
        test_parse('energy content', _, _).
test(eq2) :-
        test_parse('air density', _, _).
test(eeq1) :-
        test_parse('sea surface density', _, _).
test(t3) :-
        test_parse('ratio of x derivative of ocean rigid lid pressure to sea surface density', _, _).
test(frac1) :-
        test_parse('mass fraction of alkanes in air',_,_).


:- end_tests(parse_test).
