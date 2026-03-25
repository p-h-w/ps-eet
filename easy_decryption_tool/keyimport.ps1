########################################################
#
# Installer script for importing new keys
#
# Copyright 2026 Jens Langecker 
# Licensed under the GNU Affero General Public License v3.0
# see LICENCE.txt of https://www.gnu.org/licenses/agpl-3.0.en.html
# SPDX-License-Identifier: AGPL-3.0-or-later
#
########################################################

#
# loading gui elements
#
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$version = [string]'0.2.1'
$author = [string]'J. Langecker'
$years = [string]'2025/26'



#
# Setting installation directory
#
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

# For debugging Purpose
# Write-Host "Install-Dir: $scriptPath"

#
# testing, if config file exists. 
# config file edt.ini is only parsed
# if we're already have a key and
# are able to open the encrypted
# .edk files.
# otherwise the key must be 
# imported via zip file.
if (! (Test-Path $scriptPath"\edt.ini")){

	Write-Host -ForegroundColor red "Configfile $scriptPath\edt.ini not found!"
	[System.Windows.Forms.MessageBox]::Show("Konfigurationsdatei edt.ini nicht gefunden!", "Error", 0, [System.Windows.Forms.MessageBoxIcon]::Error)
	Exit 1

}

# reading the parameters of edt.ini
# to variables used in thie script
Get-Content edt.ini | Foreach-Object{
	$var = $_.Split('=')
	New-Variable -Name $var[0] -Value $var[1]
}

#if ( $private_key -eq "" -or $certificate_file -eq "" -or $private_key -eq $null -or $certificate_file -eq $null ){
	
	$selFileExtensions = "Edt-Archiv (*.eda)|*.eda|Alle Dateien (*.*)|*.*"
	
#} else {
	
#	$selFileExtensions = "Verschlüsseltes Edt-Archiv (*.edk)|*.edk|Edt-Archiv (*.eda)|*.eda|Alle Dateien (*.*)|*.*"
	
#}

write-Host "File extensions: $selFileExtensions"

#########################################
#
# Function to hide or show passphrase
#
#########################################
Function showPW_function () {
	 if ( $pw_viewCB.Checked ){
	    $pw_textBox.PasswordChar = $null
	 }

	 else {
	    $pw_textBox.PasswordChar = "*"	  
	 }
}


#
# File selection dialog
#
Function File ($InitialDirectory, $FileExtensions){
    
    Add-Type -AssemblyName System.Windows.Forms
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.Title = "Wählen Sie eine Datei aus"
    $OpenFileDialog.InitialDirectory = $InitialDirectory
    $OpenFileDialog.Filter = $FileExtensions
    $OpenFileDialog.ShowHelp = $true
    
    if ($OpenFileDialog.ShowDialog() -eq "Cancel")
       {
			[System.Windows.Forms.MessageBox]::Show("Keine Datei ausgewählt!", "Error", 0, [System.Windows.Forms.MessageBoxIcon]::Exclamation)
	   
       }
	   
       $Global:SelectedFile = $OpenFileDialog.FileName
       Return $SelectedFile
}

#
# passphrase window Function
#
Function EnterPassphrase ($opensslPath){
	
	Add-Type -AssemblyName System.Windows.Forms
	Add-Type -AssemblyName System.Drawing

	$cmd = '"'+$opensslPath+'" '
	$cmd += 'x509 -enddate -dateopt iso_8601 -noout '
	$cmd += '-in "'+$keydir+"\"+$certificate_file+'"'
	#Write-Host $cmd

	$expiryDate= iex "& $cmd"
	$expiryDate = $expiryDate.Replace("notAfter=", "")
	$expiryDate = $expiryDate.Remove(10,10)
	#Write-Host $expiryDate

	$pw_form = New-Object System.Windows.Forms.form
	$pw_form.Text = 'Passworteingabe'
	$pw_form.Size = New-Object System.Drawing.Size(320,180)
	$pw_form.StartPosition = 'CenterScreen'
	
	$keyno = New-Object System.Windows.Forms.Label
	$keyno.Location = New-Object System.Drawing.Point(10,10)
	$keyno.Size = New-Object System.Drawing.Size(180,23)
	$keyno.Text = "Schlüsselnummer: "+$expiryDate
	$pw_form.Controls.Add($keyno)

	$pw_textBox = New-Object System.Windows.Forms.MaskedTextBox
	$pw_textBox.PasswordChar = "*"
	$pw_textBox.Location = New-Object System.Drawing.Point(10,35)
	$pw_textBox.Size = New-Object System.Drawing.Size(280,23)
	$pw_form.Controls.Add($pw_textBox)
	
	$pw_viewCB = New-Object System.Windows.Forms.CheckBox
	$pw_viewCB.Text = "Passwort anzeigen"
	$pw_viewCB.AutoSize = $true
	$pw_viewCB.Location = New-Object System.Drawing.Point(10,65)
	$pw_viewCB.add_CheckedChanged({ showPW_function })
	$pw_form.Controls.Add($pw_viewCB)
	
	$pw_button_ypos = 100
	$pw_okButton = New-Object System.Windows.Forms.Button
	$pw_okButton.Location = New-Object System.Drawing.Point(130,$pw_button_ypos)
	$pw_okButton.Size = New-Object System.Drawing.Size(75,23)
	$pw_okButton.Text = 'OK'
	$pw_okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
	$pw_form.AcceptButton = $pw_okButton
	$pw_form.Controls.Add($pw_okButton)

	$pw_cancelButton = New-Object System.Windows.Forms.Button
	$pw_cancelButton.Location = New-Object System.Drawing.Point(215,$pw_button_ypos)
	$pw_cancelButton.Size = New-Object System.Drawing.Size(75,23)
	$pw_cancelButton.Text = 'Cancel'
	$pw_cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
	$pw_form.CancelButton = $pw_cancelButton
	$pw_form.Controls.Add($pw_cancelButton)
	
	$pw_result = $pw_form.ShowDialog()
	
	if ($pw_result -eq [System.Windows.Forms.DialogResult]::OK){
		
		Return $pw_textBox.Text
		
	} else {
		
		Return [System.Windows.Forms.DialogResult]::Cancel
		
	}
	
}

#
# UnCompress Function
#
Function UnCompress ($FileName){
	
	# for debugging purpose
	#Write-Host "Uncompressing: $FileName"
	if ( (Test-Path $FileName )){
		
		Expand-Archive -Force -Path $FileName -DestinationPath $scriptPath
		Return 0
	}
	
	Return 1
}


# UpdateIniFile Function to 
# parse and write update
# information into edt.ini
Function UpdateIniFile ( $location ){

	# For debugging Purpose
	Write-Host $location
	
	$iniFile = $location+"\edt.ini"
	$oldIni = $location+"\edt_ini.old"
	$updateFile = $location+"\update.ini"
	
	# Moving edt.ini to backup file
	Move-Item $iniFile $oldIni -Force
	
	# Reading contents of update file and ini File
	$update_content = Get-Content -Path $updateFile
	$ini_file = Get-Content -Path $oldIni
	
	# Iterating through all entries of update-File
	foreach ( $line in $update_content ){
		
		# Splitting parameter line into variable-value array
		$parameter = $line.Split("=")
		
		# does config-file contain the requested parameter?
		if ( $ini_file -match "$([regex]::Escape($parameter[0])).*" ){
			
			# Yes? Then replace the line with the new varibale=value pair
			$ini_file = $ini_file -replace "$([regex]::Escape($parameter[0])).*", $line
			
		} else {
			
			# No? Then add the new parameter to the end of the File
			$ini_file += $line
			
		}
		
	} # finish with all new parameters
	
	# Now: write the config array to the new config File
	Write-Output $ini_file | Out-File -FilePath $iniFile
	
	Remove-Item $updateFile
	
}


# For debugging purpose
# Write-Host "Tempdir: $env:TEMP"

################################################################
#
# GUI starts here
#
################################################################

#####################################
#
# initializing main window
#
#####################################
$form = New-Object System.Windows.Forms.form
$form.Text = 'EDT key importer'+$version
$form.Size = New-Object System.Drawing.Size(650,180)
$form.StartPosition = 'CenterScreen'

#
# Description
#
$FileDescriptionText = New-Object System.Windows.Forms.Label
$FileDescriptionText.Location = New-Object System.Drawing.Point(10,20)
$FileDescriptionText.Size = New-Object System.Drawing.Size(600,20)
$FileDescriptionText.Text = "Schlüsselimporttool für Easy Decryption Tool ($version)"
$form.Controls.Add($FileDescriptionText)

#
# File Selection Elements
#
# Label

# Options for all 
$fileSelYpos = 60

$FileSelLabel = New-Object System.Windows.Forms.Label
$FileSelLabel.Location = New-Object System.Drawing.Point(10,$fileSelYpos)
$FileSelLabel.Size = New-Object System.Drawing.Size(120,23)
$FileSelLabel.Text = 'Schlüsselarchiv'
$form.Controls.Add($FileSelLabel)

# Box
$FileSelBox = New-Object System.Windows.Forms.TextBox
$FileSelBox.Location = New-Object System.Drawing.Point(140,$fileSelYpos)
$FileSelBox.Size = New-Object System.Drawing.Size(400,90)
$form.Controls.Add($FileSelBox)

# Button
$FileSelButton = New-Object System.Windows.Forms.Button
$FileSelButton.Location = New-Object System.Drawing.Point(550,$fileSelYpos)
$FileSelButton.Size = New-Object System.Drawing.Size(50,20)
$FileSelButton.Text = '...'
$FileSelButton.add_click({$file = File $env:USERPROFILE $selFileExtensions; $FileSelBox.Text = $file})
$form.Controls.Add($FileSelButton)

#
# OK & Cancel Buttons
#

# Options for all Buttons
$buttonYpos = 100

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(380,$buttonYpos)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.add($okButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(465,$buttonYpos)
$cancelButton.Size = New-Object System.Drawing.Size(75,23)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)

$form.Add_Shown({$FileSelBox.Select()})

$form.TopMost = $true

$result = $form.ShowDialog()

######################################################
#
# Start working here, when OK-Button is pressed.
#
######################################################

if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
	
	# checking if a import file name is given
	if ( $FileSelBox.Text -eq "" ){
	
		[System.Windows.Forms.MessageBox]::Show("Keine Datei ausgewählt!", "Error", 0, [System.Windows.Forms.MessageBoxIcon]::Error)	
		Exit 1
	
	}	
	
	

	
	# keydir, ca_file and issuer_email are mandatory for this part. 
	# If they aren't defined exit.
	if ( $keydir -eq "" -or $ca_file -eq "" -or $issuer_email -eq "" ){
		
		[System.Windows.Forms.MessageBox]::Show("Keine Zertifikate installiert!", "Error", 0, [System.Windows.Forms.MessageBoxIcon]::Error)
		Exit 1
	
	}
	
	# Setting path to CAfile
	$authorithyfile = $scriptPath+"\"+$keydir+"\"+$ca_file
			
	# Testing, if file is eda or edk
	switch ((Get-Item $FileSelBox.Text).Extension)
	{
		
		# eda file
		# .eda files (Easy-Decryption-tool-Archive) is 
		# a signed but unencrypted zip file to avoid 
		# import of malicous data
		".eda" {
			
			# First: copy file to Temp-Path with correct zip file Extension
			# Calling UnCompress function
			$srcFile =  $FileSelBox.Text
			$outFile = $env:TEMP+'\'+(Get-Item $FileSelBox.Text).Basename+'.zip'
			
			$cmd = '"'+$scriptPath+'\'+$openssl_binary+'" cms -verify -binary -inform DER '
			$cmd += '-in "'+$srcFile+'" '
			$cmd += '-verify_email "'+$issuer_email+'" '
			$cmd += '-CAfile "'+$authorithyfile+'" '
			$cmd += '-out "'+$outFile+'"'
			
			# For debugging Purpose
			# Write-Host $cmd
			
			iex "& $cmd"
			
			# Unpacking and		
			# checking exit code	
			if ( (UnCompress $outFile) -eq 0 ){
			
				UpdateIniFile $scriptPath
			
				[System.Windows.Forms.MessageBox]::Show("Die Schüssel wurden erfolgreich importiert.","Status",0,[System.Windows.Forms.MessageBoxIcon]::Information)
			
			}
			else {
			
				[System.Windows.Forms.MessageBox]::Show("Fehler beim Schüsselimport!","Error",0,[System.Windows.Forms.MessageBoxIcon]::Error)
			
			}
			
			# Removing zip-File
			
			Remove-Item $outFile
		}
		
		# edt-own archive 
		".edk" {
			
			# variables private_key and certificate_file are mandatory in this part#
			# if not defined: Exit
			if ( $private_key -eq "" -or $certificate_file -eq "" -or $private_key -eq $null -or $certificate_file -eq $null ){
				
				[System.Windows.Forms.MessageBox]::Show("Keine Schlüssel installiert!`nBitte installieren Sie zuerst eine .eda-Datei.", "Error", 0, [System.Windows.Forms.MessageBoxIcon]::Error)
				Exit 1
				
			}

			# 
			if (! (Test-Path ($scriptPath+"\"+$keydir)) -or ! (Test-Path ($scriptPath+"\"+$keydir+"\"+$ca_file)) -or ! (Test-Path ($scriptPath+"\"+$keydir+"\"+$private_key))) {
	
				Write-Host -NoNewline "Looking for "$scriptPath"\"$keydir": "
				Write-Host -ForegroundColor red "Not Found!"
				[System.Windows.Forms.MessageBox]::Show("Keine Schlüssel installiert!", "Error", 0, [System.Windows.Forms.MessageBoxIcon]::Error)
				Exit 1
	
			}

			$inFileFull = (Get-Item $FileSelBox.Text).FullName
			$inFileBase = (Get-Item $FileSelBox.Text).Basename
			$key = $scriptPath+"\"+$keydir+"\"+$private_key
			$outFile = $env:TEMP+"\"+$inFileBase+".zip"
			$tempout = $env:TEMP+"\"+$infileBase+".p7m"
			
			# command for Decryption
			$cmd = '"'+$scriptPath+'\'+$openssl_binary+'" cms -decrypt -binary -outform DER '
			$cmd += '-in "'+$inFileFull+'" '
			$cmd += '-inkey "'+$key+'" '
			$cmd += '-out "'+$tempout+'" -passin env:pWord'
			#command for verification
			#$cmd += ' | '+'"'+$scriptPath+'\'+$openssl_binary+'" cms -verify -binary -inform DER'
			#$cmd += ' -CAfile "'+$authorithyfile+'" -out "'+$outfile+'"'
			
			# setting looper variable to ensure 
			# loop will be left only after 
			# correct password or cancel
			$looper  = $true
			
			# do while loop to give more chances to enter correct password
			do {
				
				
				# Getting passphrase from input window
				$env:pWord = EnterPassphrase($scriptPath+"\"+$openssl_binary)
				
				# For debugging purpose only
				# Write-Host $env:pWord
			
				# exit, if cancel is pressed
				if ( $env:pWord -eq [System.Windows.Forms.DialogResult]::Cancel ) {
					
					Exit 0
					
				}

				# for debugging purpose
				# Write-Host $cmd
			
				iex "& $cmd"
				
				if ( $LastExitCode -ne 0 ){
					
					[System.Windows.Forms.MessageBox]::Show("Falsches Passwort!", "Error", 0, [System.Windows.Forms.MessageBoxIcon]::Exclamation)
					
				} else {
					
					$looper = $false
					
				}
			
			} while ( $looper )
			
			$cmd = '"'+$scriptPath+'\'+$openssl_binary+'" cms -verify -binary -inform DER '
			$cmd += '-in "'+$tempout+'" '
			$cmd += '-verify_email "'+$issuer_email+'" '
			$cmd += '-CAfile "'+$authorithyfile+'" '
			$cmd += '-out "'+$outFile+'"'
			
			# Write-Host $cmd
			
			iex "& $cmd"
			
			
			
			# extract archive into tool installation directory
			
			switch ( $LastExitCode ){
				
				# if update package verification was successful
				0 {
					# for debug purpose
					#Write-Host $scriptPath
					
					# unpack the update package into installation dir
					UnCompress $outFile
					
					# writing config-updates to ini-file
					UpdateIniFile $scriptPath
					
				}
				
				#
				# Wrongly signed packet
				#
				4 {
				
					[System.Windows.Forms.MessageBox]::Show("Falsch unterschriebenes Updatepaket!", "Error", 0, [System.Windows.Forms.MessageBoxIcon]::Error)
				
				}
				
				#
				# all other errors
				#
				Default {
					
					[System.Windows.Forms.MessageBox]::Show("Fehler beim Installieren des Paketes!", "Error", 0, [System.Windows.Forms.MessageBoxIcon]::Error)
					
				}
				
			}
			
			# message for successful Import-Alias
			[System.Windows.Forms.MessageBox]::Show("Die Datei wurde erfolgreich importiert.","Status",0,[System.Windows.Forms.MessageBoxIcon]::Information)	
			
			Remove-Item $outFile
			Remove-Item $tempout
			
		}
		
		Default {
			
			[System.Windows.Forms.MessageBox]::Show("Falscher Dateityp","Error",0,[System.Windows.Forms.MessageBoxIcon]::Error)
			Exit 1
		}
	}	

	
}
