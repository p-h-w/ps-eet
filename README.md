Easy Encryption Tool

The Easy Encryption Tool is a windows tool to encrypt (sensitive) data before transfer to a support server, 
which is often a simple cloud space in today's times. 

The tool is a simple wrapper for openssl, which is not included in the package and must be obtained from 
other resources. Most easy is to use a standalone openssl.exe and put it into the script path. Every internal
file will be called relatively to the package path.
