:- module(bitset,
          [
           set_to_bitset/2,
           bitset_to_set/2,
           bs_intersection/3,
           bs_intersection_cardinality/3,
           bs_union/3,
           bs_union_cardinality/3
           ]).

:- use_module(library(tabling)).
:- use_module(library(yall)).

:- dynamic element_ix_cache/2.

element_ix(E,N) :-
        element_ix_cache(E,N),
        !.
element_ix(E,N) :-
        (   nb_current(ix,N_last)
        ->  true
        ;   N_last = -1),
        N is N_last + 1,
        nb_setval(ix,N),
        assert(element_ix_cache(E,N)),
        !.

:- dynamic compiled.
compile_set(S) :-
        set_to_bitset(S,_),
        % this paradoxially slows things down...
        %compile_predicates([element_ix_cache/2]),
        assert(compiled).


set_to_bitset(S,V) :-
        (   \+ compiled
        ->  setof(Exp,E^N^(member(E,S),element_ix(E,N),Exp is 2**N),Exps)
        ;   setof(Exp,E^N^(member(E,S),element_ix_cache(E,N),Exp is 2**N),Exps)),
        sumlist(Exps,V).

%% bitset_to_set(+V:int,?AL:list)
% True if V is an integer bit vector with the attributes in AL set
bitset_to_set(V,S) :-
        bitset_to_set(V,S,0).
bitset_to_set(0,[],_) :- !.
bitset_to_set(V,[E|S],Pos) :-
        Bit is lsb(V),
        V2 is V >> (Bit+1),
        BitPos is Pos+Bit,
        element_ix_cache(E,BitPos),
        Pos2 is Pos+(Bit+1),
        bitset_to_set(V2,S,Pos2).

        


old_bitset_to_set(V,AL) :-
        bitset_to_set(V,AL,16).

old_bitset_to_set(V,AL,Window) :-
        Mask is 2**Window -1,
        bitset_to_set(V,ALx,0,Window,Mask),
        flatten(ALx,AL).

%% bitset_to_set(+V:int,?AL:list,+Pos,+Window,+Mask) is det
% Mask must = Window^2 -1 (not checked)
% shifts V down Window bits at a time. If there are any bits in the window,
% use bitset_to_set_lo/2 to get the attribute list from this window.
% note resulting list must be flattened.
% todo: difference list impl?
bitset_to_set(0,[],_,_,_) :- !.
bitset_to_set(V,AL,Pos,Window,Mask) :-
        !,
        NextBits is V /\ Mask,
        VShift is V >> Window,
        NextPos is Pos+Window,
        (   NextBits=0
        ->  bitset_to_set(VShift,AL,NextPos,Window,Mask)
        ;   bitset_to_set_lo(NextBits,ALNew,Pos),
            AL=[ALNew|AL2],
            bitset_to_set(VShift,AL2,NextPos,Window,Mask)).

% as bitset_to_set/2, but checks one bit at a time
bitset_to_set_lo(AV,AL) :-
        bitset_to_set_lo(AV,AL,0).

bitset_to_set_lo(0,[],_) :- !.
bitset_to_set_lo(AV,AL,Pos) :-
        NextBit is AV /\ 1,
        AVShift is AV >> 1,
        NextPos is Pos+1,
        (   NextBit=1
        ->  element_ix_cache(Att,Pos),
            AL=[Att|AL2]
        ;   AL=AL2),
        !,
        bitset_to_set_lo(AVShift,AL2,NextPos).

% ----------------------------------------
% OPERATIONS
% ----------------------------------------

bs_intersection(S1,S2,R) :-
        set_to_bitset(S1,V1),
        set_to_bitset(S2,V2),
        V is V1 /\ V2,
        bitset_to_set(V,R1),
        sort(R1,R).


bs_intersection_cardinality(S1,S2,N) :-
        set_to_bitset(S1,V1),
        set_to_bitset(S2,V2),
        N is popcount(V1 /\ V2).

bs_union(S1,S2,R) :-
        set_to_bitset(S1,V1),
        set_to_bitset(S2,V2),
        V is V1 \/ V2,
        bitset_to_set(V,R1),
        sort(R1,R).

bs_union_cardinality(S1,S2,N) :-
        set_to_bitset(S1,V1),
        set_to_bitset(S2,V2),
        N is popcount(V1 \/ V2).

        
:- begin_tests(ops).


ord_intersection_wrap(L1,L2,I) :-
        sort(L1,S1),
        sort(L2,S2),
        ord_intersection(S1,S2,I).
ord_union_wrap(L1,L2,I) :-
        sort(L1,S1),
        sort(L2,S2),
        ord_union(S1,S2,I).


test(encode) :-
        S = [a,b,c,d],
        set_to_bitset(S,V),
        writeln(v=V),
        bitset_to_set(V,S1),
        assertion(S1=S).

test(and) :-
        S1 = [d,c,z],
        S2 = [a,b,d,c],
        forall(permutation(S1,S1p),
               forall(permutation(S2,S2p),
                      (   assertion(bs_intersection(S1p,S2p,[c,d])),
                          assertion(bs_intersection_cardinality(S1p,S2p,2))))).

test(random) :-
        forall(between(1,10,N),
               (   randseq(N,N,List1),
                   randseq(N,N,List2),
                   ord_intersection_wrap(List1,List2,SI),
                   ord_union_wrap(List1,List2,SU),
                   assertion(bs_intersection(List1,List2,SI)),
                   assertion(bs_union(List1,List2,SU)))).


test(or) :-
        S1 = [b,a,c,d],
        S2 = [d,c,z],
        forall(permutation(S1,S1p),
               forall(permutation(S2,S2p),
                      (   assertion(bs_union(S1p,S2p,[a,b,c,d,z])),
                          assertion(bs_union_cardinality(S1p,S2p,5))))).


random_atom(Len,A) :-
        randseq(Len,26,Seq),
        maplist([Num,Code]>>(Code is Num+96),Seq,Chars),
        atom_chars(A,Chars).

random_atoms(N,Len,As) :-
        findall(A,(between(1,N,_),
                   random_atom(Len,A)),
                As).

random_subset(N,S1,S2) :-
        findall(A,(between(1,N,_),
                   random_select(A,S1,_)),
                As),
        sort(As,S2).

% hmm, turns out this is much slower than ord_intersection
test(bench) :-
        random_atoms(9999,20,As),
        %compile_set(As),
        random_subset(2000,As,S1),
        random_subset(2000,As,S2),
        set_to_bitset(S1,V1),
        set_to_bitset(S2,V2),
        time(_ is V1 /\ V2),
        time(ord_intersection(S1,S2,X)),
        time(bs_intersection(S1,S2,Y)),
        assertion(X=Y).


        
        

:- end_tests(ops).
