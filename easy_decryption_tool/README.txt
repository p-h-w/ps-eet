Copyright 2026 Jens Langecker
Licensed under the GNU Affero General Public License v3.0
see LICENCE.txt or https://www.gnu.org/licenses/agpl-3.0.en.html
SPDX-License-Identifier: AGPL-3.0-or-later

Easy Encryption Tool - Version 0.9.6

Description

Script for simple encryption for the secure and privacy-compliant upload of configuration files 
and databases to support the School Management Program.

Required program files

To use the tool you need the program package:

    easy_decryption_tool.zip
    The key file in the keys directory
    openssl and 7zr in the bin directory

Installation

Extract the file "easy_encryption_tool.zip", e.g., into your HOME directory, and change into the 
resulting "easy_encryption_tool" directory. The program runs directly from that directory. The 
required OpenSSL distribution is included in the directory; no additional installation is necessary.

Copy the file "svp-test-system.key" into the extracted directory where "dialog.ps1" is located.

The file "svp-test-system.key" is a key file that allows decryption of the encrypted files. It 
is therefore not included in the program package.

Usage

Follow these steps to decrypt a file:

    Launch the program "easy-decrypt.bat" by double-clicking it. A window will open.

If you run the tool for the first time, a warning dialog will appear. Click "More info" and "Run anyway". 
This message will not appear on subsequent runs.

If no key files are installed, the program will exit with an error message.

    Click the "..." button to the right of the text field and select the .enc file to decrypt in the 
	file dialog.

    Click the "..." button for "Destination directory" and choose the target directory where the decrypted 
	file should be written. Note that for data protection reasons the file must not be saved on a remote 
	or cloud drive!

    Enter the password for the private key in the password field.

    Click "OK".

Alternative key

If you need to decrypt a file whose corresponding key is not configured as the default, click "Alternative 
key file" and select the matching key in the file dialog. Enter the password for that key in the password field.

If you decide you do not need the alternative key after selecting it, simply uncheck the checkbox.

Key import

Run schluesselimport.bat. A window with an input form for a .eda or .edk file will open.

First installation: No key is present yet. Use the '...' button to select a .eda file. This will add the key 
and a configuration file 'edt.ini'. You can then decrypt files that were encrypted with the corresponding key.

Key update: Archives with the .edk extension are encrypted and signed. They can be sent by email, which 
simplifies distribution.

(C) 2024/25/26 J. Langecker
