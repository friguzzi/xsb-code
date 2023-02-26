
The Python libraries used by these files can be installed via

$JANUS_PYTHON -m pip -r requirements.txt

where $JANUS_PYTHON is the Python with which Janus was installed.

An exception is faiss, which is built differently depending on whether
your computer has an available GPU or not (see the online
documentation for faiss).