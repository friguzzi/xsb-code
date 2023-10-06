import sys
sys.path.insert(0,'../../XSB/packages/janus/janus-py')
import janus as jns

orig_output = sys.stdout 
sys.stdout = open('./temp', 'w')

jns.cmd('consult','consult','jns_test')

def test_qs():
    for i in jns.QueryString('jns_test:one_ary_fail(FX)'):
        print('for one_ary_fail: ' + str(i))
    print('--------------------------')
    for i in jns.QueryString('jns_test:anti_member([1,2,3],FX)'):
        print('for anti_member: ' + str(i))
    print('--------------------------')
    C1 = jns.QueryString('jns_test:anti_member([1,2,3],X)')
    print('anti_member 1: ' + str(C1.next()))
    print('anti_member 2: ' + str(C1.next()))
    print('anti_member 3: ' + str(C1.next()))
    print('anti_member 4: ' + str(C1.next()))
    print('--------------------------')
    C2 = jns.QueryString('jns_test:am_3(foobar,[1,2,3],X)')
    print('am_3 1: ' + str(C2.next()))
    print('am_3 2: ' + str(C2.next()))
    print('am_3 3: ' + str(C2.next()))
    print('am_3 4: ' + str(C2.next()))
    print('--------------------------')
    for i in jns.QueryString('jns_test:bind_test(A,B,C,D,E,F,G)'):
        print('bind_test ' + str(i))
    print('--------------------------')
    for i in jns.QueryString('jns_test:anti_member(X,Y)',Dict={'X':[1,2,3]}):
        print('anti_member input_dict 1: ' + str(i))
    print('--------------------------')

test_qs()

sys.stdout = orig_output
