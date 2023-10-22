import sys
sys.path.insert(0,'../../XSB/packages/janus/janus-py')

import janus as jns

orig_output = sys.stdout 
sys.stdout = open('./temp', 'w')

jns.cmd('consult','consult','jns_test')

jns.cmd('consult','consult','jns_test')
#jns_cmd('consult','consult','basics')

def test_query_once(): 
    X = jns.query_once('jns_test:anti_member([1,2,3],X)')
    print('am: ' + str(X))
    X = jns.query_once('jns_test:bind_test(A,B,C,D,E,F,G)')
    print('bind_test: ' + str(X))
    X = jns.query_once('jns_test:one_ary_fail(X)')
    print('one_ary_fail: ' + str(X))
    X = jns.query_once('jns_test:anti_member(X,Y)',Dict={'X':[1,2,3]})
    print('am input input dict: ' + str(X))
    X = jns.query_once('jns_test:anti_member([1,2,3],Y)',Dict={})
    print('am input empty dict: ' + str(X))
    X = jns.query_once('one_ary_undef(X)')
    print('one_ary_undef: ' + str(X))
                 
    X = jns.query_once('jns_test:anti_member([1,2,3],X)',truth_vals=jns.NO_TRUTHVALS)
    print('am-ntv: ' + str(X))
    X = jns.query_once('jns_test:bind_test(A,B,C,D,E,F,G)',truth_vals=jns.NO_TRUTHVALS)
    print('bind_test-ntv: ' + str(X))
    X = jns.query_once('jns_test:one_ary_fail(X)',truth_vals=jns.NO_TRUTHVALS)
    print('one_ary_fail-ntv: ' + str(X))
    X = jns.query_once('jns_test:anti_member(X,Y)',Dict={'X':[1,2,3]},truth_vals=jns.NO_TRUTHVALS)
    print('am input input dict-ntv: ' + str(X))
    X = jns.query_once('jns_test:anti_member([1,2,3],Y)',Dict={},truth_vals=jns.NO_TRUTHVALS)
    print('am input empty dict-ntv: ' + str(X))
    X = jns.query_once('one_ary_undef(X)',truth_vals=jns.NO_TRUTHVALS)
    print('one_ary_undef-ntv: ' + str(X))

    X = jns.query_once('one_ary_undef(X)',truth_vals=jns.DELAY_LISTS)
    print('one_ary_undef-dl: ' + str(X))
    X = jns.query_once('jns_test:anti_member([1,2,3],Y)',Dict={},truth_vals=jns.DELAY_LISTS)
    print('am input empty dict-dl: ' + str(X))
    X = jns.query_once('jns_test:win((a,b,c))',Dict={},truth_vals=jns.DELAY_LISTS)
    print('am input empty dict-dl: ' + str(X))

test_query_once()

sys.stdout = orig_output
