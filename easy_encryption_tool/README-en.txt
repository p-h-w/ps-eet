Script for simple encryption to securely and privacy-compliantly 
upload configuration files and databases to support department.

# Copyright 2026 Jens Langecker 
# Licensed under the GNU Affero General Public License v3.0
# see LICENCE.txt of https://www.gnu.org/licenses/agpl-3.0.en.html
# SPDX-License-Identifier: AGPL-3.0-or-later


Required program files

You need the following archive to use the tool:

    easy_encryption_tool.exe

Installation

No installation is required.

Usage

Follow these steps to encrypt a file:

Launch the program "svp-encrypter.exe" by double-clicking it. 
After a short delay a window will open.

Click the button to the right of the text field and select the 
file to encrypt in the file dialog. Note: the filename must 
not contain "__" and must not be a multi-file 7z or rar archive.

Choose a destination directory. For clarity it is recommended to 
create a new, empty folder for the output file(s).

Click "OK".

If the file is larger than 1 GB, it will be split into multiple 
parts, which will then be encrypted.

Progress can be monitored in the console window. A dialog box 
confirms successful completion of the encryption.

Upload the ENC file(s) to the upload link provided by the 
support team. In addition to the original filename, the file(s) 
include a numeric sequence that allows key association. Please 
leave the filename as generated.

WARNING: You CANNOT DECRYPT the encrypted ENC file(s) yourself! 
Only delete the unencrypted original files when you are certain 
they are no longer needed.
