Easy Encryption Tool

The Easy Encryption Tool is a windows tool to encrypt (sensitive) data before transfer to a support server, 
which is often a simple cloud space in today's times. 

The tool is a simple wrapper for openssl to encrypt data with a public key. OpenSSL is not included in the 
package and must be obtained from other resources. Most easy is to use a standalone openssl.exe and put it 
into the script path. Every internal file will be called relatively to the package path.

Easy Decryption Tool

The Easy Decryption Tool is a Windows GUI tool written in PowerShell as a wrapper for openssl binary and 7zr
to decrypt sensitive data uploaded to a simple cloud space. The tool need the private key to the corresponding 
public key of the easy encryption tool. To forward the decrypted data, 7zip compression with encryption is
achieved via the 7zr util, which has to be downloaded from 7z.org website.
