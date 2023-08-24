:- compiler_options([xpp_on,spec_off]).
:- ensure_loaded(janus).
#include "../../XSB/packages/janus/janus_defs.h"
:-  set_prolog_flag(character_set, utf_8) . 

:- import pyfunc/3, pydot/3, pyfunc/4,pyfunc/5,janus_python_version/1 from janus.
:- import concat_atom/2 from string.
:- import length/2 from basics.
:- import xsb_error_get_message/2 from error_handler.
:- import lazy_writeln/1 from standard.

test:-
    func_tests, 
    dataConversionTests,
%    callback_test,
    json_tests,
    kwargs_tests,
    error_tests,
    meth_tests,
    variadic_tests,
    pyc_tests,
    py_iter_tests,
    pyfunc(gc,collect(),Collect),
    writeln(collect(Collect)).

%--------------------------------

func_tests :- 
    check_call(pyfunc(test_janus_plg, sumlist3(5,[1,2,3]),_Res1),[6,7,8]),
    check_call(pyfunc(builtins,float('+1E6'),_Res2),1000000.0).

%--------------------------------

py_iter_tests:-
    check_call(setof(Ret,py_iter(test_janus_plg,makelist(),Ret),_List),[1,2,3,4]),
    fail.
py_iter_tests:-
    check_call(setof(Ret,py_iter(test_janus_plg,squares(1,5),Ret),_List),[1,4,9,16]),
    fail.
py_iter_tests:-
    check_call(setof(Ret,py_iter(builtins,range(1,6),Ret),_List),[1,2,3,4,5]),
    fail.
py_iter_tests.
    
pyObj_GetIterTest :- 
	pyfunc(test_janus_plg, sumlist3(5,[1,2,3]), R),
	pyObj_GetIter(R, R1), pyObj_Next(R1, 6).

pyObj_NextTest :- 
	pyfunc(test_janus_plg, sumlist3(5,[1,2,3]), R),
	pyObj_GetIter(R, R1), pyObj_Next(R1, 6), not(pyObj_Next(R, 6)).

%--------------------------------

dataConversionTests :- 
    (intConvTest->
	 write('int conversion tests successful\n')
     ;   write('!!!int conversion tests failed\n')), 
    (floatConvTest->
	 write('float conversion tests successful\n')
     ;   write('!!!float conversion tests failed\n')),
    (stringConvTest->
	 write('string conversion tests successful\n')
     ;   write('!!!string conversion tests failed\n')),
    (listConvTest->
	 write('list conversion tests successful\n')
     ;   write('!!!list conversion tests failed\n')),
    (setConvTest->
	 write('set conversion tests successful\n')
     ;   write('!!!set conversion tests failed\n')),
    (tupleConvTest->
	 write('tuple conversion tests successful\n')
    ;    write('!!!tuple conversion tests failed\n')),
    fail.
dataConversionTests :- 
    (dictConvTest->
	 write('dict conversion tests successful\n')
    ;    write('!!!dict conversion tests failed\n')),
    fail.
dataConversionTests :- 
    pyfunc(test_janus_plg,return_None(),PYNONE_PROLOG),
    writeln('return_None_succeeded'),
    fail.
dataConversionTests :- 
    pyfunc(test_janus_plg,return_True(),1),
    writeln('return_True_succeeded'),
    fail.
dataConversionTests :- 
    pyfunc(test_janus_plg,return_False(),0),
    writeln('return_False_succeeded'),
    fail.
dataConversionTests :- 
    (intConvTest_sizecheck->
	 write('int conversion_sizecheck tests successful\n')
     ;   write('!!!int conversion_sizecheck tests failed\n')), 
    (floatConvTest_sizecheck->
	 write('float conversion_sizecheck tests successful\n')
     ;   write('!!!float conversion_sizecheck tests failed\n')),
    (stringConvTest_sizecheck->
	 write('string conversion_sizecheck tests successful\n')
     ;   write('!!!string conversion_sizecheck tests failed\n')),
    (listConvTest_sizecheck->
	 write('list conversion_sizecheck tests successful\n')
     ;   write('!!!list conversion_sizecheck tests failed\n')),
    (setConvTest_sizecheck->
	 write('set conversion_sizecheck tests successful\n')
     ;   write('!!!set conversion_sizecheck tests failed\n')),
    (tupleConvTest_sizecheck->
	 write('tuple conversion_sizecheck tests successful\n')
    ;   write('!!!tuple conversion_sizecheck tests failed\n')),
    fail.
dataConversionTests:- 
    (dictConvTest_sizecheck->
	 write('dict conversion_sizecheck tests successful\n')
    ;    write('!!!dict conversion_sizecheck tests failed\n')),
    fail.
dataConversionTests.

pyfunc_sc(Mod,Func,Reg):-
    pyfunc(Mod,Func,[],[sizecheck(true)],Reg).

intConvTest :-
    current_prolog_flag(min_integer, MinValue), 
    not(var(MinValue)), 
    current_prolog_flag(max_integer, MaxValue), 
    not(var(MaxValue)),
    pyfunc(test_janus_plg, returnVal(MinValue), MinValue), 
    pyfunc(test_janus_plg, returnVal(MaxValue), MaxValue).

intConvTest_sizecheck :-
    current_prolog_flag(min_integer, MinValue), 
    not(var(MinValue)), 
    current_prolog_flag(max_integer, MaxValue), 
    not(var(MaxValue)),
    pyfunc_sc(test_janus_plg, returnVal(MinValue), MinValue), 
    pyfunc_sc(test_janus_plg, returnVal(MaxValue), MaxValue).

floatConvTest :- 
    pyfunc(test_janus_plg, returnVal(3.54), 3.54),
    pyfunc(test_janus_plg, returnVal(3.5535252352), 3.5535252352).

floatConvTest_sizecheck :- 
    pyfunc_sc(test_janus_plg, returnVal(3.54), 3.54),
    pyfunc_sc(test_janus_plg, returnVal(3.5535252352), 3.5535252352).

stringConvTest :-
    pyfunc(test_janus_plg, returnVal(helloworld), helloworld),
    pyfunc(test_janus_plg, returnVal('helloworld'), helloworld),
    pyfunc(test_janus_plg, returnVal('Санкт-Петербург'),R3),R3 == 'Санкт-Петербург'.
				  
stringConvTest_sizecheck :-
    pyfunc_sc(test_janus_plg, returnVal(helloworld), helloworld),
    pyfunc_sc(test_janus_plg, returnVal('helloworld'), helloworld),
    pyfunc_sc(test_janus_plg, returnVal('Санкт-Петербург'),R3),R3 == 'Санкт-Петербург'.
				  
listConvTest:-
    pyfunc(test_janus_plg, returnVal([a,b,c]), R1),R1 = [a,b,c],
    pyfunc(test_janus_plg, returnVal([]), R2), R2 == [],
    pyfunc(test_janus_plg, returnVal([1,[2,3,4],[hello,155]]), R3),
    R3 ==  [1, [2, 3, 4], ['hello', 155]],
    pyfunc(test_janus_plg, func(), R4), R4 == [1,2,3, PYTUP_PROLOG(5, 6), 'hello', [11,17]],
    !.
listConvTest_sizecheck:-
    pyfunc_sc(test_janus_plg, returnVal([a,b,c]), R1),R1 = [a,b,c],
    pyfunc_sc(test_janus_plg, returnVal([]), R2), R2 == [],
    pyfunc_sc(test_janus_plg, returnVal([1,[2,3,4],[hello,155]]), R3),
    R3 ==  [1, [2, 3, 4], ['hello', 155]],
    pyfunc_sc(test_janus_plg, func(), R4), R4 == [1,2,3, PYTUP_PROLOG(5, 6), 'hello', [11,17]],
    !.

setConvTest:- 
    check_sort_call(pyfunc(test_janus_plg,returnSet( ),_Ret1),
		      ['"foo"','''bar''',PYSET_PROLOG([1,-(a,b,7),hello])]).

setConvTest_sizecheck:- 
    pyfunc_sc(test_janus_plg,returnSet( ) ,F ),
    F = ['"foo"','''bar''',PYSET_PROLOG(S)],
    length(S,3),
    pyfunc_sc(test_janus_plg, returnVal(PYSET_PROLOG([a,b,c])), R1 ),
    arg(1,R1,A), length(A,3),!.

tupleConvTest:-
    pyfunc(test_janus_plg, returnVal(PYTUP_PROLOG(a,b,c)), R1),R1 = PYTUP_PROLOG(a,b,c),
    pyfunc(test_janus_plg,tupletest_func(),R2),
    R2 = PYTUP_PROLOG(5,PYTUP_PROLOG(),hello,PYTUP_PROLOG(5,6,7)),
    !.

tupleConvTest_sizecheck:-
    pyfunc_sc(test_janus_plg, returnVal(PYTUP_PROLOG(a,b,c)), R1),R1 = PYTUP_PROLOG(a,b,c),
    pyfunc_sc(test_janus_plg,tupletest_func(),R2), R2 = PYTUP_PROLOG(5,PYTUP_PROLOG(),hello,PYTUP_PROLOG(5,6,7)),
    !.

dictConvTest_sizecheck:-
    pyfunc(returnVal,return_dictionary(),[],[sizecheck(true)],Ret),
    Ret =  {('Name' : 'Geeks',1 : [1,2,3,4])}.

dictConvTest:-
    pyfunc(returnVal,return_dictionary(),Ret),
    Ret =  {('Name' : 'Geeks',1 : [1,2,3,4])}.

%--------------------------------

% TES: probably the wrong way to do this, but keeping it in for now.
% it *might* be responsible for uninitialized stack frame problem.

callback_test:- 
    pyfunc('test/testc', tester(),  X),
    X = [['Санкт-Петербург', '2']],
    writeln('callback test successful'),
    !.
callback_test:-
    writeln('!!!callback test failed').

% used in callback
p('Санкт-Петербург').
p(3).
q(2).

%--------------------------------

% numpy
pyc_tests:- 
    pyfunc(test_janus_plg,go(),X),X == 2,!,
    writeln('pyc_tests successful').
pyc_tests:- 
    writeln('!!!pyc_tests failed').

json_tests:-
    Jstring = '{"name": "Bob", "languages": ["English", "Fench","GERMAN"]}',
     pyfunc(test_janus_plg,prolog_loads(Jstring),F),
     (F = {(name : 'Bob',languages : ['English','Fench','GERMAN'])} -> 
	  writeln('json_loads_test successful')
        ; writeln('!!!json_loads_test_failed') ),
     fail.
%json_tests:-
%    Jstring = '{"name": "Bob", "languages": ["English", "French","GERMAN"]}',
%      atom_chars(Jgood,Jgch),write(Jgch),nl,
%  pyfunc('janus_json',prolog_loads(Jstring),Jdict),
%    pyfunc('janus_json',prolog_dumps(Jdict),[indent=2],Jindent),
%    (Jindent = Jgood -> 
%      writeln('json_dumps_test successful')
%    ; write('!!!json_dumps_test_failed'),nl,
%      writeq(Jgood),nl,writeq(Jindent),nl,
%      atom_chars(Jgood,Jgch),write(Jgch),nl,
%      writeln('----------------'),
%      atom_chars(Jindent,Jich),writeq(Jich),nl ),
%    fail.
json_tests:- 
    pyfunc(test_janus_plg,prolog_load('sample.json'),Json),
    writeln(json_2(Json)),
    fail.
json_tests.    

  kwargs_tests:-
    pyfunc(test_janus_plg,kwargs_append(foo),[bar=1,baz=2],Ret),
    writeln(kwargs(Ret)).

error_tests:-
    error_tests_1(no_module,foo(1),
		 
		  [' Python Error;',_,'Type: <class ''ModuleNotFoundError''>',_,
		   'Value: ModuleNotFoundError("No module named ''no_module''")',_]),
    fail.
error_tests:-
%    catch(pyfunc(kwargs,foo(1),_X),E,(xsb_error_get_message(E,M),writeln(M))),
    error_tests_1(test_janus_plg,foo(1),
		  [' ++Error[janus]: foo/1 is not a callable function in the Python module \'test_janus_plg\' (arg 2 of pyfunc/3)']),
    fail.
error_tests:-
    error_tests_1(test_janus_plg,7,[' ++Error[janus]: ',_,' is not a callable function (in arg 2 of pyfunc/3)']),
    fail.
% returns obj
%error_tests:-
%    catch(pyfunc(test_err,raise_err_3(),_X),E,(xsb_error_get_message(E,M),writeln(M))),
%    fail.
error_tests:-
    \+ janus_python_version('python3.11'),
   error_tests_1(test_err,raise_err_1(),
		  [' Python Error;',_,'Type: <class ''Exception''>',_, 
		   'Value: Exception(''spam'', ''eggs'')',_,
		   'Python traceback (most recent call last):',_,
		   'File ',_,', line 3, in raise_err_1',_]),
    fail.
error_tests:-
    janus_python_version('python3.11'),
    error_tests_1(test_err,raise_err_1(),
		  [' Python Error;',_,'Type: <class ''Exception''>',_,
		   'Value: Exception(''spam'', ''eggs'')',_]),
    fail.
error_tests.

error_tests_1(Mod,Goal,Message):-
    catch(pyfunc(Mod,Goal,_X),E,xsb_error_get_message(E,Mess)),
    (concat_atom(Message,Mess) ->
	 true
    ;  writeln('!!!failed'(error_tests_1(Mod,Goal))),
       writeln(Mess),
       writeln(Message)).
    
meth_tests:- 
    check_call(pyfunc('Person','Person'(john,35),Obj),pyObj(_)),
    check_call(pydot(Obj,func0(),_Ret1),'Hello my name is john'),
    check_call(pydot(Obj,func1(doofus),_Ret2),'Hello my name is john and I''m a doofus'),
    check_call(pydot(Obj,favorite_ice_cream,_Ret3),chocolate),
    check_call(pydot(Obj,func2(real,doofus),_Ret4),
	       'Hello my name is john and I''m a real doofus'),
    check_call(pydot(Obj,func3(real,big,doofus),_Ret5),
	       'Hello my name is john and I''m a real big doofus'),
    fail.
meth_tests:-
    check_call(pydot(sys,flags,_Res),
	       -(0,0,0,0,0,0,0,0,0,0,0,1,0,@('False'),0,0,@('False'),-1)),
    check_call(pydot(sys,exc_info(),_Res1),-(@('None'),@('None'),@('None'))),
    fail.
meth_tests:- 
    catch(pydot(1,favorite_ice_cream,_Ret4),E2,xsb_error_get_message(E2,Msg2)),
    writeln(personErr1(Msg2)),
    pyfunc('Person','Person'(john,35),Obj),
    catch(pydot(Obj,1,_Ret5),E3,xsb_error_get_message(E3,Msg3)),
    writeln(personErr2(Msg3)).

variadic_tests:-
    testit(pyfunc(variadic,variadic_print('a','b','c'),A),A,'a|b|c|'),
    testit(pyfunc(variadic,variadic_print('a','b','c','d'),B),B,'a|b|c|d|'),
    testit(pyfunc(variadic,opt_print('a'),C),C,'a|1'),
    testit(pyfunc(variadic,opt_print('b','c'),D),D,'b|c'),
    writeln('variadic tests succeeded'),!.
variadic_tests:-
    writeln('!!!variadic test failed').

testit(Call,Var,Answer):-
    call(Call),
    (Var = Answer -> 
       true
    ; writeln('!!!wrong_answer'(Call,Var,Answer)),
      fail).

check_call(pydot(Obj,MA,Res),Atom):-
    pydot(Obj,MA,Res),
    (Res = Atom ->
      (Res = pyObj(_) -> ResOut = pyObj ; ResOut = Res),
      (Obj = pyObj(_) -> ObjOut = pyObj ; ObjOut = Obj),
      lazy_writeln([pydot(ObjOut,MA,ResOut),' succeeded.'])
    ; lazy_writeln(['!!! ',pydot(pyObj,MA,ResOut),' failed.  Did not match ',Atom])).
check_call(pyfunc(Mod,MA,Res),Atom):-
    pyfunc(Mod,MA,Res),
    (Res = Atom ->
      (Res = pyObj(_) -> ResOut = pyObj ; ResOut = Res),
      lazy_writeln([pyfunc(Mod,MA,ResOut),' succeeded.'])
    ; lazy_writeln(['!!! ',pyfunc(Mod,MA,Res),' failed.  Did not match ',Atom])).
% specific to a single test...
check_call(setof(Res,py_iter(Mod,MA,Res),List),GoodList):- 
    setof(Res,py_iter(Mod,MA,Res),List),
    (List = GoodList ->
      lazy_writeln([py_iter(Mod,MA,List),' succeeded.'])
    ; lazy_writeln(['!!! ',py_iter(Mod,MA,List),' failed.  Did not match ',GoodList])).
check_sort_call(pyfunc(Mod,MA,Res),Atom):-
    pyfunc(Mod,MA,Res),
    (Res = ['"foo"','''bar''',pySet(Set)] ->
       true
    ; lazy_writeln(['!!!-1 ',pyfunc(Mod,MA,Res),' failed. Did not match ',['"foo"','bar',pySet(Set)]])),
    sort(Set,SetSort),
    (SetSort = [1,hello,-(a,b,7)] -> 
      lazy_writeln([pyfunc(Mod,MA,SetSort),' succeeded.'])
    ; lazy_writeln(['!!! ',pyfunc(Mod,MA,SetSort),' failed.  Did not match ',Atom])).

end_of_file.

%pytXSB :- pyfunc('test/testc', tester(),  X), pyList2prList(X, []).
%pythonXSBTests :- (pytXSB->write('python to XSB tests successful\n'); write('python to XSB tests %failed\n')).


%object_tests:- 
%    meth_tests,
%    fail.
%object_tests.

%meth_tests:-
%    Ret2 = 'Hello my name is john and I''m a doofus',
%    Ret3 = chocolate,
%    Ret4 = 'Hello my name is john and I''m a real doofus',
%    Ret5 = 'Hello my name is john and I''m a real big doofus',
%    M1 = ' ++Error[janus]: arg 1 of pydot/4 is not a Python Object: 1',
%    M2 = ' ++Error[janus]: arg 2 of pydot/4 is not a Python function or attribute: 1',
%    writeln('Person test succeeded'),!.
%meth_tests:- 
%    writeln('!!!Person test failed').

<
