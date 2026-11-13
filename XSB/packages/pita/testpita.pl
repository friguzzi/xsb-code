


:- import permutation/2 from lists.

:- import maplist/2, maplist/3 from swi.

:- import concat_atom/2 from string.
:- import format/2 from format.

:- import prob/2, parse/2 from pita.


:- [pita].

test_pita_xsb:-
	run_tests([coin,
%    coinmsw,
    dice,
    epidemic,
    earthquake,
    sneezing,
    trigger,
    light,
    threesideddice,
    bloodtype,
    mendel,
    coin2,
  %  simpson,
  %  viral,
    uwcse,
    path,
    pathdb,
    multiple_paths_simple,
    multiple_paths,
    % abd1,
    % abd2,
    % abd3,
    % map1,
    % map_es3,
    % map_es21,
    % map_es2,
    % map_es2map,
    % map_es2map1,
    % pitavit_win,
    % pitavit_hmm,
    % pitavit_coin,
    % pitavit_mendel,
    meta,
    pcfg,
    % var_objdb,
    card
    ]).

perm(_A,_B).

% perm(A,B):-
%   permutation(A,B).

bar(_,_).
bar1(_,_).

is_dict(_).

run(H):-
    M=usermod,
	copy_term(H,NH),
	numbervars(NH,1,_),
%	NH=(_Query,close_to('P',_Prob)),
	format("~w.~n",[NH]),
	(H=(G,R)),
	call(M:G),!,
	format("\t~w.~n~n",[G]),
	call(R).

epsilon(0.09).

close_to(V,T):-
	epsilon(E),
	TLow is T-E,
	THigh is T+E,
	TLow=<V,
	V=<THigh.

close_to(V,T,E):-
	TLow is T-E,
	THigh is T+E,
	TLow=<V,
	V=<THigh.

relative_epsilon(0.1).

relatively_close_to(V,T):-
	relative_epsilon(E),
	TLow is T*(1-E),
	THigh is T*(1+E),
	TLow=<V,
	V=<THigh.

relatively_close_to(V,T,E):-
	TLow is T*(1-E),
	THigh is T*(1+E),
	TLow=<V,
	V=<THigh.


run_tests([]).

run_tests([H|T]):-
  run_test(H),
  run_tests(T).

run_test(E):-
  concat_atom(['examples/',E,'.pl'],FilePl),
%  concat_atom(['examples/',E,'.P'],FileP),
  pita:load(FilePl),
%	[FileP],
  findall(usermod:test(E,T),test_couple(E,T),L),
  maplist(call,L).


term_expansion_test((:- module(_,_)),[]):-!.

term_expansion_test((:- use_module(_)),[]):-!.

term_expansion_test((:- begin_tests(_, _)),[]):-!.

term_expansion_test((:- end_tests(_)),[]):-!,
  retract(example(E)),
  assert(ex(E)).

term_expansion_test( (:- ensure_loaded(library(examples/E))),[]):-!,
	%writeln((:- ensure_loaded(library(examples/E)))),
  assert(example(E)).


term_expansion_test((test(T):-run(Body)),[test_couple(E,T),(test(E,T):-run(Body1))]):-!,
	%writeln((test(T):-Body)),
  example(E),
%	trace,
	process_body(Body,E,Body1),
	assert(test_couple(E,T)),
	assert((test(E,T):-run(Body1))).
	%writeln((test(E,T):-run(Body1))).
	
term_expansion_test(C,[]):-
	assert(C).


%process_at(prob(H,Ev,P),E,prob(E:H,Ev,P)):-!.
% process_at(prob(H,Ev,P),E,_):-!,
% writeln(process_at(prob(H,Ev,P),E,_)).

% process_at(H,_,H).
%	writeln(process_at(H,E,H)).

process_body((A,B),E,(A1,B1)):-!,
	process_at(A,E,A1),
	%writeln(process_body((A,B),E,(A1,B1))),
	process_body(B,E,B1).

process_body(A,E,A1):-
	process_at(A,E,A1).

 process_at((A,B),E,(A1,B1)):-!,
 	process_body((A,B),E,(A1,B1)).


process_at(At,E,B):-
At=..[prob,H|T],!,
B=..[prob,(E:H)|T].

process_at(At,_,At).

% :-[test_pita].
term_expansion_test_pita([]).

term_expansion_test_pita([H|T]):-
	%writeln(term_expansion_test(H)),
	term_expansion_test(H,_),
	%writeln(term_expansion_test(H1)),
	term_expansion_test_pita(T).

load_test_pita:-
	open('test_pita.pl',read,SI),
	read_clauses(SI,C),
	close(SI),
	% writeln('test_pita.pl loaded'),
	% maplist(writeln,C),
	term_expansion_test_pita(C).
%	maplist(term_expansion_test_pita,C,_).

:- load_test_pita.
