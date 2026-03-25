############################################################
#
# Easy decrypt Tool
#
# Copyright 2026 Jens Langecker 
# Licensed under the GNU Affero General Public License v3.0
# see LICENCE.txt of https://www.gnu.org/licenses/agpl-3.0.en.html
# SPDX-License-Identifier: AGPL-3.0-or-later
#
############################################################




Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# some hardwired preferences

$version = [string]'0.9.6'
$author = [string]'J. Langecker'
$years = [string]'2024/25/26'

#
# number of digits in filename
$digits = '0000'

#
# separator for splitting file names into parts
#
$separator = "__"

#
# ySize of main window
#
$ySize = 350

#
# multi file suffix
$suffixMultiFile = "eetp"

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Easy Decryption Tool - Version '+$version
#$form.Size = New-Object System.Drawing.Size(650,$ySize)
$form.StartPosition = 'CenterScreen'

#
# File Extensions
#
$encFileExtensions = "Verschlüsselte Dateien (*.enc)|*.enc|Alle Dateien (*.*)|*.*"
$keyFileExtensions = "Schlüsseldateien (*.key)|*.key|Alle Dateien (*.*)|*.*"

###################################################
#
# scriptPath
#
###################################################
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

################################################
#
# test on existence of edt.ini and $keydir
# to see, whether key is installed
#	
################################################


if (! (Test-Path $scriptPath"\edt.ini") ){
	
	Write-Host -ForegroundColor red "Configfile $scriptPath\edt.ini not found!"
	[System.Windows.Forms.MessageBox]::Show("Konfigurationsdatei edt.ini nicht gefunden!", "Error", 0, [System.Windows.Forms.MessageBoxIcon]::Error)
	Exit 1
	
}

Get-Content edt.ini | Foreach-Object{
    $var = $_.Split('=')
    New-Variable -Name $var[0] -Value $var[1]
}

if ( $certificate_file -eq "" -or $private_key -eq "" -or $certificate_file -eq $null -or $private_key -eq $null ){
	
	Write-Host -ForegroundColor red "No Certificate or Private Key found!"
	[System.Windows.Forms.MessageBox]::Show("Keine Zertifikate installiert!", "Error", 0, [System.Windows.Forms.MessageBoxIcon]::Error)
	Exit 1
	
}

if (! (Test-Path ($scriptPath+"\"+$keydir)) -or ! (Test-Path ($scriptPath+"\"+$keydir+"\"+$certificate_file)) -or ! (Test-Path ($scriptPath+"\"+$keydir+"\"+$private_key))) {
	
	Write-Host -NoNewline "Looking for "$scriptPath"\"$keydir": "
	Write-Host -ForegroundColor red "Not Found!"
	[System.Windows.Forms.MessageBox]::Show("Keine Schlüssel installiert!", "Error", 0, [System.Windows.Forms.MessageBoxIcon]::Error)
	Exit 1
	
}

# after checking for config file and keys
# setting path for opensslPath
$opensslPath = $scriptPath+"\"+$openssl_binary


# setting ySize of main window according to parameters
if ( $forward_7zip -eq "true" ){
	
	$ySize = 370
	
}

$form.Size = New-Object System.Drawing.Size(650,$ySize)


############################################################
#
# Directory selection dialog
#
############################################################
Function Directory ([string]$InitialDirectory, [string]$encFileExtensions) {
    Add-Type -AssemblyName System.Windows.Forms
    $OpenFolderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    #	 $OpenFolderDialog.RootFolder = 'MyComputer'
    if ($InitialDirectory) {
	$OpenFolderDialog.SelectedPath = $InitialDirectory
    }

    if ($OpenFolderDialog.ShowDialog() -eq "Cancel"){
	[System.Windows.Forms.MessageBox]::Show("Kein Verzeichnis ausgewählt", "Error", 0, [System.Windows.Forms.MessageBoxIcon]::Exclamation)
    }
    return $OpenFolderDialog.SelectedPath
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

#########################################
#
# sticher function to combine all
# parts to one file
#
#########################################

Function Combine ( $inFile ){

    $infileBase = (Get-Item $inFile).Basename -Split $separator
    $infileDirectory = (Get-Item $inFile).DirectoryName

    $chunkNum = 0

    $inFile = $infileDirectory+"\"+$infileBase[0]+$separator+$infileBase[1]+"."+$suffixMultiFile+$chunkNum.ToString($digits)

    $outFile = $infileDirectory+"\"+$infileBase[0]+"."+$infileBase[1]
    
    $outStream = [System.IO.File]::OpenWrite($outFile)

    # Write-Host $infile

    while ( Test-Path $inFile ){

	Write-Host "Stiching: $inFile"
	$bytes = [System.IO.File]::ReadAllBytes($inFile)
	$outStream.Write($bytes, 0, $bytes.Count)

	$chunkNum += 1
	$inFile = $infileDirectory+"\"+$infileBase[0]+$separator+$infileBase[1]+"."+$suffixMultiFile+$chunkNum.ToString($digits)


    }
    
    $outStream.Close();
	
	Return $outFile
}


#########################################
#
# Function to hide or show passphrase
#

Function showPW_function ( $element_to_enable, $check_box ) {
	 if ( $check_box.Checked ){
	    $element_to_enable.PasswordChar = $null
	 }

	 else {
	    $element_to_enable.PasswordChar = "*"	  
	 }
}



#
# test if checkbox checked
#
Function checkboxTest(){
	 if ( $altKeyEnable_CB.Checked ){
	    $altKeytextBox1.enabled = $true
	    $altKeyselButton1.enabled = $true	    
	 }
	 else {
	    $altKeytextBox1.enabled = $false
	    $altKeyselButton1.enabled = $else	      
	 }
	 
}


#################################################
#
# include extension for 7zip forwarding
#
#################################################
#if ( $forward_7zip -eq "true" ){
#	
#	Write-Host $scriptPath"\"$7ZipExtension
#	if ( ( Test-Path $scriptPath"\"$7ZipExtension ) -and ( $7ZipExtension -ne "" ) ){
#		
#		. $scriptPath"\"$7ZipExtension
#		
#	} else {
#		
#		[System.Windows.Forms.MessageBox]::Show("Erweiterungsdatei kann nicht geladen werden!","Fehler",0,[System.Windows.Forms.MessageBoxIcon]::Error)
#		Exit 1
#		
#	}
#	
#}

Get-ChildItem $scriptPath"\"$extensions_dir -Filter *.ps1 | 
Foreach-Object {
	
	. $_.FullName
	
}

#################################################
#
# Primary description text
#
#################################################
$text1 = New-Object System.Windows.Forms.Label
$text1.Location = New-Object System.Drawing.Point(10,20)
$text1.Size = New-Object System.Drawing.Size(600,80)
$text1.Text = "Easy Decryption Tool - Version $version`n`nEinfache Entschlüsselung von Konfigurationsdateien und Datenbanken nach Upload an den Support`nAchten Sie darauf, dass die entschlüsselte Datei ausschließlich auf einem lokalen Datenträger abgespeichert wird.`nDie Dateien dürfen sich nicht in einem Ziparchiv befinden."
$form.Controls.Add($text1)

#
# File selection elements
#
$label2 = New-Object System.Windows.Forms.Label
$label2.Location = New-Object System.Drawing.Point(10,100)
$label2.Size = New-Object System.Drawing.Size(120,23)
$label2.Text = 'Verschlüsselte Datei:'
$form.Controls.Add($label2)

$textBox2 = New-Object System.Windows.Forms.TextBox
$textBox2.Location = New-Object System.Drawing.Point(140,100)
$textBox2.Size = New-Object System.Drawing.Size(400,90)
$form.Controls.Add($textBox2)

$fileselButton2 = New-Object System.Windows.Forms.Button
$fileselButton2.Location = New-Object System.Drawing.Point(550,100)
$fileselButton2.Size = New-Object System.Drawing.Size(40,20)
$fileselButton2.Text = '...'
$fileselButton2.add_click({$file = File $env:USERPROFILE $encFileExtensions; $textBox2.Text = $file})
$form.Controls.Add($fileselButton2)

#
# Target directory elements
#
$label3 = New-Object System.Windows.Forms.Label
$label3.Location = New-Object System.Drawing.Point(10,130)
$label3.Size = New-Object System.Drawing.Size(120,23)
$label3.Text = 'Zielverzeichnis:'
$form.Controls.Add($label3)

$textBox3 = New-Object System.Windows.Forms.TextBox
$textBox3.Location = New-Object System.Drawing.Point(140,130)
$textBox3.Size = New-Object System.Drawing.Size(400,90)
$form.Controls.Add($textBox3)

$dirselButton3 = New-Object System.Windows.Forms.Button
$dirselButton3.Location = New-Object System.Drawing.Point(550,130)
$dirselButton3.Size = New-Object System.Drawing.Size(40,20)
$dirselButton3.Text = '...'
$dirselButton3.add_click({$directory = Directory; $textBox3.Text = $directory})
$form.Controls.Add($dirselButton3)

#
# Password dialog - uses * to keep passphrase secret
#
$label1 = New-Object System.Windows.Forms.Label
$label1.Location = New-Object System.Drawing.Point(10,160)
$label1.Size = New-Object System.Drawing.Size(100,23)
$label1.Text = 'Passwort:'
$form.Controls.Add($label1)

$textBox1 = New-Object System.Windows.Forms.MaskedTextBox
$textBox1.PasswordChar = "*"
$textBox1.Location = New-Object System.Drawing.Point(140,160)
$textBox1.Size = New-Object System.Drawing.Size(200,90)
$form.Controls.Add($textBox1)

$showPW_CB = New-Object System.Windows.Forms.CheckBox
$showPW_CB.Text = "Passwort anzeigen"
$showPW_CB.AutoSize = $true
$showPW_CB.Location = New-Object System.Drawing.Point(350,160)
$showPW_CB.add_CheckedChanged({ showPW_function $textBox1 $showPW_CB  })
$form.Controls.Add($showPW_CB) 

#
# getting end date of certificate 
#
$cmd = '"'+$opensslPath+'" '
$cmd += 'x509 -enddate -dateopt iso_8601 -noout '
$cmd += '-in "'+$keydir+"\"+$certificate_file+'"'
#Write-Host $cmd

$expiryDate= iex "& $cmd"
$expiryDate = $expiryDate.Replace("notAfter=", "")
$expiryDate = $expiryDate.Remove(10,10)
#$expiryDate



$label2 = New-Object System.Windows.Forms.Label
$label2.Location = New-Object System.Drawing.Point(140,190)
$label2.Size = New-Object System.Drawing.Size(180,23)
$label2.Text = "Schlüsselnummer:"+$expiryDate
$form.Controls.Add($label2)

$altKeyEnable_CB = New-Object System.Windows.Forms.CheckBox
$altKeyEnable_CB.Text = "Alternativer Schlüssel"
$altKeyEnable_CB.AutoSize = $true
$altKeyEnable_CB.Location = New-Object System.Drawing.Point(350,190)
$altKeyEnable_CB.add_CheckedChanged( { checkboxTest } )
$form.Controls.Add($altKeyEnable_CB)

$altKeyselButton1 = New-Object System.Windows.Forms.Button
$altKeyselButton1.Location = New-Object System.Drawing.Point(490,190)
$altKeyselButton1.Size = New-Object System.Drawing.Size(100,20)
$altKeyselButton1.Text = 'Schlüsseldatei'
$altKeyselButton1.enabled = $false
$altKeyselButton1.add_click({$file = File $scriptPath'\'$keydir $keyFileExtensions; $altKeytextBox1.Text = $file})
$form.Controls.Add($altKeyselButton1)

$altKeytextBox1 = New-Object System.Windows.Forms.TextBox
$altKeytextBox1.Location = New-Object System.Drawing.Point(140,220)
$altKeytextBox1.Size = New-Object System.Drawing.Size(400,23)
$altKeytextBox1.enabled = $false
$form.Controls.Add( $altKeytextBox1 )

# 
# forward 7Zip-Button
#
if ( $forward_7zip -eq "true" ){
	$forwardSevenZip_CB = New-Object System.Windows.Forms.CheckBox
	$forwardSevenZip_CB.Text = "Verschlüsselte 7-Zip-Archivierung"
	$forwardSevenZip_CB.AutoSize = $true
	$forwardSevenZip_CB.Location = New-Object System.Drawing.Size(140,250)
	$form.Controls.Add( $forwardSevenZip_CB )
}

# Lower Border Elements
#
# defining yposition of info and buttons combined
$buttons_yPos = $ySize-90
$buttonsXPos = 350
$buttons_relXPos = $buttonsXPos+80

$text2 = New-Object System.Windows.Forms.Label
$text2.Location = New-Object System.Drawing.Point(10,$buttons_yPos)
$text2.Size = New-Object System.Drawing.Size(200,23)
$text2.Text = "(C) $years $author" 
$form.Controls.Add($text2)


$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point($buttonsXPos,$buttons_yPos)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $ok
$form.Controls.add($okButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point($buttons_relXPos,$buttons_yPos)
$cancelButton.Size = New-Object System.Drawing.Size(75,23)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)



$form.Add_Shown({$textBox2.Select()})
$form.Add_Shown({$textBox3.Select()})
$form.Add_Shown({$altKeytextBox1.Select()})


$form.TopMost = $true


$result = $form.ShowDialog()


if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{

	# Error checking
	if ( $textBox2.Text -eq "" -or $textBox3.Text -eq "" ){
		
		[System.Windows.Forms.MessageBox]::Show("Keine Dateien zum Entschlüsseln ausgewählt`noder kein Zielverzeichnis angegeben!","Fehler",0,[System.Windows.Forms.MessageBoxIcon]::Error)	
		Exit 2
		
	}

    # writing Passphrase into environment variable
    # for not to be seen within task list
    $env:pWord = $textBox1.Text


    # splitting the outfile name into parts
    $infileBase = (Get-Item $textBox2.Text).Basename -Split $separator    
    $infileExtension = (Get-Item $textBox2.Text).Extension
    $infileDirectory = (Get-Item $textBox2.Text).DirectoryName
    
    # alternate key enabled?
    if ( $altKeyEnable_CB.Checked ){
		$keyPath = $altKeytextBox1.Text
    }
    else {
		$keyPath = $scriptPath+"\"+$keydir+"\"+$private_key
    }
    
    # $cmd = '"'+$opensslPath+'"'+' cms -decrypt -binary -in "'+$textBox2.Text+'" -out "'+$textBox3.Text+'\'+$outfile[0]+'.'+$outfile[1]+'" -inform DER -inkey "'+$keyPath+'" -passin env:pWord'

    # testing file, if it's a part of a multi file archive
    #
    if ( $infileBase[2].substring(0, 4) -eq $suffixMultiFile ){

		$chunkNum = 0

		$infile = $infileDirectory+"\"+$infileBase[0]+"__"+$infileBase[1]+"__"+$suffixMultiFile+$chunkNum.ToString($digits)+"__"+$infileBase[3]+$infileExtension
	
		$outFile = $textBox3.Text+"\"+$infileBase[0]+"__"+$infileBase[1]+"."+$suffixMultiFile+$chunkNum.ToString($digits)

		# Write-Host $infile
	
		while ( Test-Path $infile ) {

			Write-Host "Decrypting: $infile"
	    
			$cmd = '"'+$opensslPath+'"'+' cms -decrypt -binary -in "'+$infile+'" -out "'+$outFile+'" -inform DER -inkey "'+$keyPath+'" -passin env:pWord'

			iex "& $cmd"

			$chunkNum += 1

			$infile = $infileDirectory+"\"+$infileBase[0]+"__"+$infileBase[1]+"__"+$suffixMultiFile+$chunkNum.ToString($digits)+"__"+$infileBase[3]+$infileExtension

			$outFile = $textBox3.Text+"\"+$infileBase[0]+"__"+$infileBase[1]+"."+$suffixMultiFile+$chunkNum.ToString($digits)
	    
		}

		$outFile = $textBox3.Text+"\"+$infileBase[0]+"__"+$infileBase[1]+"."+$suffixMultiFile+$digits

		$outFile = Combine $outFile
	
    }
    else {

		$infile = $infileDirectory+"\"+$infileBase[0]+"__"+$infileBase[1]+"__"+$infileBase[2]+$infileExtension

		$outFile = $textBox3.Text+"\"+$infileBase[0]+"."+$infileBase[1]

		$cmd = '"'+$opensslPath+'"'+' cms -decrypt -binary -in "'+$infile+'" -out "'+$outFile+'" -inform DER -inkey "'+$keyPath+'" -passin env:pWord'

		# Write-Host "Infile: $infile"
		# Write-Host "Outfile: $outFile"
		# Write-Host "$cmd"
		iex "& $cmd"
	
    }

    
    if ($LastExitCode -eq 2) {
		[System.Windows.Forms.MessageBox]::Show("Passwort falsch oder Datei nicht gefunden!","Fehler",0,[System.Windows.Forms.MessageBoxIcon]::Error)	
		Exit 2
    }
    
    if ($LastExitCode -eq 6) {
		[System.Windows.Forms.MessageBox]::Show("Fehler beim Schreiben der Zieldatei!","Fehler",0,[System.Windows.Forms.MessageBoxIcon]::Error)	
		Exit 6
    }	
    
    if ($LastExitCode -eq 0) {
		[System.Windows.Forms.MessageBox]::Show("Die Datei wurde erfolgreich entschlüsselt.","Status",0,[System.Windows.Forms.MessageBoxIcon]::Information)	   
    }
	
	#
	# If 7Zip-forwarding is active, continue with 7Zip-forwarding
	#
	if ( $forwardSevenZip_CB.Checked ){

	Write-Host "7Zip-forwarding enabled"
		Write-Host "file to forward: "$outFile		
		szipexport ( $outFile )
		
	} else {
		
		# Write-Host "No 7Zip-forwarding"
		
	}
	
	# End
}


