import sys
sys.path.insert(0,'../../XSB/packages/janus/janus-py')
#from janus import *
import janus as jns

orig_output = sys.stdout 
sys.stdout = open('./temp', 'w')

jns.consult('jns_unicode')
jns.consult('px_callbacks')
print('xp_unicode:unicode_upper: '
      + str(jns.qdet('jns_unicode','unicode_upper','Η Google μου το μετέφρασε')))
print('px_callbacks:test_json: ' + str(jns.qdet('px_callbacks','test_json')))
NewClass,TV = jns.qdet('px_callbacks','test_class','joe')
print('px_callbacks','test_class: ' + str(NewClass.name))

sys.stdout = orig_output
