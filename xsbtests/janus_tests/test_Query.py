import sys
sys.path.insert(0,'../../XSB/packages/janus/janus-py')
import janus as jns

orig_output = sys.stdout 
sys.stdout = open('./temp', 'w')

jns.cmd('consult','consult','jns_test')

def test_q():
#    C1 = Query('jns_test','anti_member',[1,2,3])
    for i in jns.Query('jns_test','anti_member',[1,2,3]):
        print('for anti_member: ' + str(i))
    print('--------------------------')
    C1 = jns.Query('jns_test','anti_member',[1,2,3])
    print('anti_member: 1 ' + str(C1.next()))
    print('anti_member: 2 ' + str(C1.next()))
    print('anti_member: 3 ' + str(C1.next()))
    print('anti_member: 4 ' + str(C1.next()))
    print('--------------------------')
    C2 = jns.Query('jns_test','am_3','foobar',[1,2,3])
    print('am_3: 1 ' + str(C2.next()))
    print('am_3: 2 ' + str(C2.next()))
    print('am_3: 3 ' + str(C2.next()))
    print('am_3: 4 ' + str(C2.next()))
    print('--------------------------')
    # need to add vars to do this.
    #    C2 = Query('jns_test:bind_test(A,B,C,D,E,F,G)')
    #    print('bind_test1 - ' + str(C2.next()))
    #    print('bind_test2 - ' + str(C2.next()))
    #    print('bind_test3 - ' + str(C2.next()))
    #    print('bind_test4 - ' + str(C2.next()))
    #    print('bind_test5 - ' + str(C2.next()))
    #    print('bind_test6 - ' + str(C2.next()))
    #    print('bind_test7 - ' + str(C2.next()))
    #    print('bind_test8 - ' + str(C2.next()))

test_q()      

sys.stdout = orig_output
