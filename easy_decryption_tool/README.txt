Copyright 2026 Jens Langecker 
Licensed under the GNU Affero General Public License v3.0
see LICENCE.txt of https://www.gnu.org/licenses/agpl-3.0.en.html
SPDX-License-Identifier: AGPL-3.0-or-later

Easy Encryption Tool - Version 0.9.6

Beschreibung

Skript zur einfachen Verschlüsselung zum sicheren und
datenschutzkonformen Upload von Konfigurationsdateien und Datenbanken
zum Support des SchulVerwaltungsProgramms. 


Notwendige Programmdateien

Für die Anwendung des Tools benötigen Sie das Programmpaket:

1. easy_decryption_tool.zip
2. Die Schlüsseldatei im Verzeichnis keys
3. openssl und 7zr im Verzeichnis bin


Installation

Entpacken Sie die Datei "easy_encryption_tool.zip" z.B. in Ihr
HOME-Verzeichnis und wechseln Sie in das entstandene Verzeichnis 
"easy_encryption_tool". Das Programm wird direkt im Verzeichnis
ausgeführt. Die notwendige OpenSSL-Distribution ist im Verzeichnis 
vorhanden, es ist keine zusätzliche Installation notwendig.

Kopieren Sie die Datei "svp-test-system.key" in das entpackte Verzeichnis, 
wo sich auch die Datei "dialog.ps1" befindet.

Die Datei "svp-test-system.key" ist eine Schlüsseldatei, die es ermöglicht, 
die verschlüsselten Dateien zu entschlüsseln. Sie ist deshalb dem 
Programmpaket nicht beigelegt.



Anwendung


Gehen Sie folgendermaßen vor, um eine Datei zu verschlüsseln:
 
1. Rufen Sie das Programm "easy-decrypt.bat" mit einem Doppelklick auf. Es öffnet
sich ein Fenster.

Wenn Sie das Tool zum ersten mal ausführen, so erscheint eine Warnmeldung. 
Klicken Sie auf "Weitere Informationen" und "Trotzdem ausführen". Bei weiteren
Aufrufen erscheint diese Meldung dann nicht mehr.

Sollten keine Schlüsseldateien installiert sein, so bricht das Programm mit einer
Fehlermeldung ab.

2. Klicken Sie auf den Button "..." rechts neben dem Textfeld und wählen Sie
im Dateidialog die zu entschlüsselnde Datei aus.

3. Klicken Sie bei "Zielverzeichnis" auf den Button "..." und wählen Sie das 
gewünschte Zielverzeichnis aus, in das die entschlüsselte Datei geschrieben
werden soll. Beachten Sie, dass aus Datenschutzgründen die Datei nicht auf 
einem Remote- bzw. Cloud-Laufwerk abgespeichert werden darf!

4. Geben Sie im Passwortfeld das Passwort für den Privaten Schlüssel ein.

5. Klicken Sie auf "OK". 


Alternative Schlüssel

Sollten Sie eine Datei entschlüsseln wollen, zu der der zu passende Schlüssel 
nicht als Standard eingerichtet ist, so klicken Sie auf "Alternative Schlüsseldatei"
und wählen Sie den passenden Schlüssel im Filedialog aus. Geben Sie im Passwortfeld 
das zu dieser Datei passende Passwort ein.

Sollte man die alternative Schlüsseldatei doch nicht benötigen, so muss trotz erfolgter
Auswahl einer Schlüsseldatei nur die Checkbox disabled werden.


Schlüsselimport

Führen Sie das Programm schluesselimport.bat aus. Es startet ein Fenster mit einer Eingabemaske für eine
.eda bzw. .edk-Datei.

Erstinstallation: Es liegt noch kein Schlüssel vor. Wählen Sie mit '...' eine .eda-Datei aus. 
	Diese fügt die Schüssel und eine Konfigurationsdatei 'edt.ini' hinzu. Nun können Dateien,
	die mit dem zugehörigen Schlüssel verschlüsselt wurden entschlüsselt werden.

Schlüsselupdate: Die Archive mit der Endung .edk sind verschlüsselt und signiert. Somit können 
	Archive per Email versendet werden, was die Verteilung vereinfacht.
	

(C) 2024/25/26 J. Langecker 

