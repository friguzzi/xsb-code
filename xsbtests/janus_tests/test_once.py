import sys
sys.path.insert(0,'../../XSB/packages/janus/janus-py')
from janus import *

orig_output = sys.stdout 
sys.stdout = open('./temp', 'w')

jns_cmd('consult','consult','jns_test')

from janus import *

jns_cmd('consult','consult','jns_test')
#jns_cmd('consult','consult','basics')

def test_once(): 
    X = jns_once('jns_test:anti_member([1,2,3],X)')
    print('am: ' + str(X))

    X = jns_once('jns_test:bind_test(A,B,C,D,E,F,G)')
    print('bind_test: ' + str(X))


test_once()

sys.stdout = orig_output
