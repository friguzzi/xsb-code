:- import add_incr_dependency/1 from increval.
:- import incr_directly_depends/2 from increval.
:- import numbervars/1 from num_vars.
:- import xsb_error_get_message/2 from error_handler.

test:- t1(_X,_Y),fail.
test:- incr_directly_depends(t1(X,Y),D),
       Dependency = incr_directly_depends(t1(X,Y),D),
       numbervars(Dependency),
       writeln(Dependency),
       writeln('%---------'),
       fail.
test:- catch(t2(_X,_Y),E,(xsb_error_get_message(E,Msg),
			  writeln(caight_t2(Msg)))),
       writeln('%---------'),
       fail.
test:- catch(t3(_X,_Y),E,(xsb_error_get_message(E,Msg),
			  writeln(caight_t2(Msg)))),
       writeln('%---------'),
       fail.
test:- catch(t4(_X,_Y),E,(xsb_error_get_message(E,Msg),
			  writeln(caight_t2(Msg)))),
       writeln('%---------'),
       fail.
test.

:- dynamic p/1, q/2 as incremental.
:- dynamic r/1.
:- table t1/2,t2/2,t3/2 as incremental.
:- table t4/2.

t1(X,Y):- p(X),!,add_incr_dependency(q(X,f(7,[a],Y))).
t1(X,Y):- q(X,Y).

p(1).
q(2,7).

%-----

t2(X,Y):- q(X,Y),!,add_incr_dependency(r(X)).

%-----

t3(X,Y):- q(X,Y),!,add_incr_dependency(7).

%-----

t4(X,Y):- add_incr_dependency(q(_X,_Y)).

