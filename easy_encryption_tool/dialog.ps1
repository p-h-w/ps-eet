# Copyright 2026 Jens Langecker 
# Licensed under the GNU Affero General Public License v3.0
# see LICENCE.txt of https://www.gnu.org/licenses/agpl-3.0.en.html
# SPDX-License-Identifier: AGPL-3.0-or-later
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$version = [string]'0.9.13'
$author = [String]'J. Langecker'
$years = [String]'2024, 2025, 2026'
$ScriptName = 'Easy-Encrypter'
$logoFile = "Logo.png"

#
# number of digits
$digits = '0000'

# setting expiration date
# sets how much days in future
# the certificate must be valid
# Configured in edt.ini file
#
$default_exp_date = 0

#
# Bit length for symmetric cipher
# will be defined in edt.ini
#
$default_bitLength = [String]'128'

#
# Chunksize parameter is the
# maximal file size when srcfile
# is split. Cloud systems often Support
# 1GiB maximum, due to encryption overhead
# a bit less than 1GiB for each chunk 
# is recommended
# 
$default_chunksize = [Math]::Pow(1000,3)/10

#
# reading config file eet.ini
# and setting variables defined there
#
Get-Content eet.ini | Foreach-Object{
	
	# skip empty lines
	if ( $_ -ne "" ) {
		
		# Using # as comment symbol
		if ( $_.Substring(0,1) -ne "#" ){
			
			# split lines on "=" and skip "#" and " " at the end
			# to make comments at the end possible
			$var = ( $_.Split('#') ).Split('=')
			New-Variable -Name $var[0].Trim() -Value $var[1].Trim()
			
		}

	}
}

# Setting up paths 
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$opensslPath = $scriptPath+"\"+$openssl_binary
$logoImagePath = $scriptPath+"\"+$logoFile

#########################################
#
# Error Handling
#
#########################################

# Testing on validity of variables
if (  ! ( Test-Path -Path $opensslPath ) -or ( $openssl_binary -eq $null ) -or ( $openssl_binary -eq "" ) ){
	
	[System.Windows.Forms.MessageBox]::Show("OpenSSL-Executable nicht gefunden`r`noder Konfigurationsfehler!", "Fehler", 0, [System.Windows.Forms.MessageBoxIcon]::Stop)
	exit 1
}

if ( ( $bitlength -eq $null ) ){
	
	# set minimum bitlength as fallback
	Write-Host -ForegroundColor DarkRed "No bitlength set for symmetric cipher! Setting to 128 bit!"
	$bitlength = 128
	
}

switch( $bitLength ) {
	
	128 {}
	192 {}
	256 {}
	Default {
		
		Write-Host -ForegroundColor DarkRed "No valid keylength for symmetric cipher! Setting to $default_bitLength bit!"
		$bitlength = $default_bitLength
		
	}
	
}

Write-Host "Symmetric Key Length: "$bitlength


if ( ($chunksize -eq $null) -or ($chunksize -eq "") -or !($chunksize -match '^\d+$') ){

	Write-Host -ForegroundColor DarkRed "Split-File Size is configured wrongly! Setting to default."
	$chunksize=$default_chunksize
	
} else {
	
	$chunksize = [Math]::Pow( $chunksize, 3)
	
}

Write-Host "Split-File Length: "$chunksize


if ( [int]$chunksize -gt 1070000000 ){

	[System.Windows.Forms.MessageBox]::Show("Split-Dateigröße ist eventuell zu groß für den Upload!", "Fehler", 0, [System.Windows.Forms.MessageBoxIcon]::Exclamation)

}

$form = New-Object System.Windows.Forms.Form
$form.Text = $ScriptName+" - "+$version
$form.Size = New-Object System.Drawing.Size(850,300)
$form.StartPosition = 'CenterScreen'

if ( ($exp_date -eq $null) -or ($exp_date -eq "" )){
	
	$exp_date = $default_exp_date
	
}

if ( !($certificate_file) -or ($certificate_file -eq "") ){
	
	Write-Host -ForegroundColor DarkRed "No certificate file given!"
	exit 1
	
} 
elseif ( !(Test-Path $certificate_file) ){
	
	Write-Host -ForegroundColor DarkRed "Certificate File not found!"
	exit 1
	
}


#############################################
#
# Folder functions
#
#############################################

#####################################
#
# Folder selection dialog
#
#####################################
Function Directory ($InitialDirectory) {
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

#################################
#
# file selection dialog
#
#################################
Function File ($InitialDirectory){
    Add-Type -AssemblyName System.Windows.Forms
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.Title = "Wählen Sie eine Datei aus"
    $OpenFileDialog.InitialDirectory = $InitialDirectory
    $OpenFileDialog.Filter = "Alle Dateien (*.*)| *.*"
    $OpenFileDialog.ShowHelp = $true

    if ($OpenFileDialog.ShowDialog() -eq "Cancel")
    {
		[System.Windows.Forms.MessageBox]::Show("Keine Datei ausgewählt!", "Error", 0, [System.Windows.Forms.MessageBoxIcon]::Exclamation)
	   
    }

    $Global:SelectedFile = $OpenFileDialog.FileName
	   
	  # Reject Multiple Archive Files
	# Selected by People who don't know to RTFM
	if ( $SelectedFile -ne "" ){
	   $SelectedBaseArray = (( Get-Item $SelectedFile ).Name ).Split(".")
	   
	   if ( $SelectedBaseArray[$SelectedBaseArray.count-1] -match '[0-9]{3}' -and $SelectedBaseArray[$SelectedBaseArray.count-2] -eq "7z" ){
		   [System.Windows.Forms.MessageBox]::Show("7zip-Multidateiarchive sind unzulässig!`nBitte lesen Sie die Anleitung.", "Error", 0, [System.Windows.Forms.MessageBoxIcon]::Exclamation)
		   Return $null
	   }

	   if ( $SelectedBaseArray[$SelectedBaseArray.count-2] -match '[A-Z,0-9]+-?\d' -and $SelectedBaseArray[$SelectedBaseArray.count-1] -eq "rar" ){
		   [System.Windows.Forms.MessageBox]::Show("rar-Multidateiarchive sind unzulässig!`nBitte lesen Sie die Anleitung.", "Error", 0, [System.Windows.Forms.MessageBoxIcon]::Exclamation)
		   Return $null
	   }
	   if ( $SelectedBaseArray.count -gt 2 ){
	   
		   [System.Windows.Forms.MessageBox]::Show("Der Dateiname enthält zu viele Punkte`nund folgt nicht dem Schema Name.Erweiterung!`nBitte lesen Sie die Anleitung.", "Error", 0, [System.Windows.Forms.MessageBoxIcon]::Exclamation)
		   Return $null
	   }

		if ( ($SelectedFile -Split "__").count -gt 1 ){
			
			[System.Windows.Forms.MessageBox]::Show("Der Dateiname enthält unzulässige Zeichenfolgen.`nBitte lesen Sie die Anleitung.", "Error", 0, [System.Windows.Forms.MessageBoxIcon]::Exclamation)	
			Return $null	
		}
		
	} 
	
	Return $SelectedFile
}

##########################################
#
# Function to encrypt
#
#########################################
Function Encrypt ( $infile, $outfileDirectory ){

    # Write-Host "$outfileDirectory"
    #$infile = "$infile"+"\"+"$outDirectory"
    
    #
    # extracting expire date from certificate
    #
    $cmd = '"'+$opensslPath+'" '
    $cmd += 'x509 -enddate -dateopt iso_8601 -noout '
    $cmd += '-in "'+$certificate_file+'"'
    
	# for debug purpose
    # Write-Host $cmd
	
    $expiryDate = iex "& $cmd"
    $expiryDate = $expiryDate.Replace("notAfter=", "")
    $expiryDate = $expiryDate.Remove(10, 10)
    # Write-Host $expiryDate
    
    # setting outfile name and extension
    $outfile_name = [System.IO.Path]::GetFileNameWithoutExtension($infile)
    #$outfileDirectory = [System.IO.Path]::GetDirectoryName($infile)
    $outfile_ext = [System.IO.Path]::GetExtension($infile)
    $outfile_ext = $outfile_ext.Replace(".", "")
    #
    
    $encOutfile = "$outfileDirectory"+"\"+"$outfile_name"+"__"+"$outfile_ext"+"__"+"$expiryDate"+".enc"

    #
    # Creating command variable for encryption
    # of given file
    #
    $cmd = '"'+$opensslPath+'" '
    $cmd += 'cms -encrypt -binary -aes-'+$bitLength+'-cbc '
    $cmd += '-in "'+$infile+'" '
    $cmd += '-out "'+$encOutfile+'" '
    $cmd += '-outform DER '
    $cmd += '"'+$scriptPath+"\"+$certificate_file+'"'

    # for debugging purpose
    # Write-Host $cmd

    #
    # status message
    Write-Host "Encrypting to File: $encOutfile"

    #
    # executing command string
    #
    iex "& $cmd"

    switch ($LastExitCode){

    	   2 {
	     [System.Windows.Forms.MessageBox]::Show("Quelldatei konnte nicht gelesen werden!","Fehler",0,[System.Windows.Forms.MessageBoxIcon]::Stop)
	     exit 1
	   }

	   6 {
	     [System.Windows.Forms.MessageBox]::Show("Verschlüsselte Datei konnte nicht geschrieben werden!","Fehler",0,[System.Windows.Forms.MessageBoxIcon]::Stop)

	     exit 1
	   }

	   Default {}

    }

    return $encOutfile

}


##########################################
#
# Function to split overlarge files into
# parts of <=1GB
#
##########################################
Function Split ( $inFile, $outDirectory, $explorerCheckBox ){

    $prefixName = [System.IO.Path]::GetFileNameWithoutExtension($inFile)
    $inDirectory = [System.IO.Path]::GetDirectoryName($inFile)
    $extension = [System.IO.Path]::GetExtension($inFile)
    $extension_nodot = $extension.Replace(".","")
    $extensionPrefixSplit = "eetp"
    
    # For debugging purpose
    # Write-Host

    $outPrefix = "$outDirectory"+"\"
    $outPrefix = "$outPrefix"+"$prefixName"+"__"+"$extension_nodot"

    # for debugging purpose
    # Write-Host "Output Prefix: $outPrefix"
    # Write-Host "Input File: $inFile"
    # Write-Host "ChunkSize: $chunksize"


    $instream = [System.IO.File]::OpenRead($infile)
    $chunkNum = 0
    $buffer = New-Object byte[] $chunksize

    #
    # Splitting Files into parts of 1GB (correctly $chunksize)
    #
    while ( $bytesRead = $instream.Read( $buffer, 0, $chunksize ) ){

    	$outfile = "$outPrefix"+"."+"$extensionPrefixSplit"+$chunkNum.ToString($digits)
	
	  # For debugging purpose
	  Write-Host "Splitting to File: $outfile"

	  $outstream = [System.IO.File]::OpenWrite($outfile)
	  $outstream.Write($buffer, 0, $bytesRead);
	  $outstream.Close();

	  $encOutfile = Encrypt $outfile $outDirectory

	  # for debugging purpose
	  # Write-Host "Return Value: $encOutfile"

	  Remove-Item -Path $outfile
	  $chunkNum += 1

    }

    $instream.Close();    

    # for debugging purpose
    # Write-Host "Return of Split: $encOutfile"
    return $encOutfile 
    
}

#########################################################
#
# First, test, if used certificate is expired
#
#########################################################
#
# setting up command calling 
#
#########################################################         
$cmd = '"'+$opensslPath+'"'+' x509 -checkend $exp_date -noout '
$cmd += '-in "'+$scriptPath+"\"+$certificate_file+'"'


# display command string for debugging purpose
#
#$cmd

#executing command
#
iex "& $cmd"

# if certificate is expired, quit the program
#
if ($LastExitCode -eq 1) {
   [System.Windows.Forms.MessageBox]::Show("Das Zertifikat zur Verschlüsselung ist abgelaufen!`nBitte installieren Sie ein gültiges Zertifikat oder laden`nSie sich die neuste Version dieses Programms herunter.","Fehler",0,[System.Windows.Forms.MessageBoxIcon]::Stop)

   exit
}


#####################################
#
# GUI interface starts here
#
#####################################

#####################################
#
# label
#
#####################################
$text1 = New-Object System.Windows.Forms.Label
$text1.Location = New-Object System.Drawing.Point(10,20)
$text1.Size = New-Object System.Drawing.Size(600,50)
$text1.Text = $ScriptName+"`n`nEinfache und sichere Verschlüsselung von Konfigurations- und Datenbankdateien zum Upload an den Support."
$form.Controls.Add($text1)



#################################
#
# File selection elements
#
#################################
$srcLabel = New-Object System.Windows.Forms.Label
$srcLabel.Location = New-Object System.Drawing.Point(10,80)
$srcLabel.Size = New-Object System.Drawing.Size(300,20)
$srcLabel.Text = 'Zu verschlüsselnde Datei (*.backup, *.sql, *.zip, *.log. u.a.):'
$form.Controls.Add($srcLabel)

$srcFile = New-Object System.Windows.Forms.TextBox
$srcFile.Location = New-Object System.Drawing.Point(10,100)
$srcFile.Size = New-Object System.Drawing.Size(530,90)
$form.Controls.Add($srcFile)

$fileselButton = New-Object System.Windows.Forms.Button
$fileselButton.Location = New-Object System.Drawing.Point(550,100)
$fileselButton.Size = New-Object System.Drawing.Size(40,20)
$fileselButton.Text = '...'
$fileselButton.add_click({$file = File; $srcFile.Text = $file})
$form.Controls.Add($fileselButton)

##################################
#
# Target directory elements
#
##################################
$targetLabel = New-Object System.Windows.Forms.Label
$targetLabel.Location = New-Object System.Drawing.Point(10,130)
$targetLabel.Size = New-Object System.Drawing.Size(100,20)
$targetLabel.Text = 'Zielverzeichnis:'
$form.Controls.Add($targetLabel)

$targetBox = New-Object System.Windows.Forms.TextBox
$targetBox.Location = New-Object System.Drawing.Point(10,150)
$targetBox.Size = New-Object System.Drawing.Size(530,90)
$form.Controls.Add($targetBox)

$dirselButton = New-Object System.Windows.Forms.Button
$dirselButton.Location = New-Object System.Drawing.Point(550,150)
$dirselButton.Size = New-Object System.Drawing.Size(40,20)
$dirselButton.Text = '...'
$dirselButton.add_click({$directory = Directory; $targetBox.Text = $directory})
$form.Controls.Add($dirselButton)

###############################################
#
# selection to open file in file explorer
#
###############################################
$explorerCheckBox = New-Object System.Windows.Forms.CheckBox
$explorerCheckBox.Text = "Dateibrowser öffnen und ENC-Datei anzeigen (Optional). "
$explorerCheckBox.AutoSize = $true
$explorerCheckBox.Location = New-Object System.Drawing.Point(10,180)
$form.Controls.Add($explorerCheckBox)

##############################################
#
# Copyright and Author's information
#
##############################################
$authorsInfo = New-Object System.Windows.Forms.Label
$authorsInfo.Location = New-Object System.Drawing.Point(10,220)
$authorsInfo.Size = New-Object System.Drawing.Size(200,23)
$authorsInfo.Text = '(C) '+$years+' '+$author
$form.Controls.Add($authorsInfo)


################################################
#
# Logo
#
################################################

if ( (Test-Path -Path $logoImagePath) ){
	$logoPictureBox = New-Object Windows.Forms.PictureBox
	$logoPicture = [System.Drawing.Image]::FromFile($logoImagePath)
	$logoPictureBox.Width = $logoPicture.Width
	$logoPictureBox.Height = $logoPicture.Height
	$logoPictureBox.Location = New-Object System.Drawing.Size(620,20)
	$logoPictureBox.Image = $logoPicture

	$form.Controls.Add($logoPictureBox)
	
}


####################################
#
# OK and Cancel buttons
#
####################################
$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(350,220)
$okButton.Size = New-Object System.Drawing.Size(100,23)
$okButton.Text = 'Verschlüsseln'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $ok
$form.Controls.add($okButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(460,220)
$cancelButton.Size = New-Object System.Drawing.Size(100,23)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)



$form.TopMost = $true


$result = $form.ShowDialog()

# Starting if 'ok' button is pressed
if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
	
	#
	# Checking on valid file names and target directories
	#
	if ( ( $srcFile.Text -eq "" ) ) {
		
		[System.Windows.Forms.MessageBox]::Show("Keine Datei zum Verschlüsseln ausgesucht!", "Fehler", 0, [System.Windows.Forms.MessageBoxIcon]::Stop)
		exit 1
		
	}
	elseif ( !(Test-Path -Path $srcFile.Text) ){
		
		[System.Windows.Forms.MessageBox]::Show("Der angegebene Dateinamen existiert nicht!", "Fehler", 0, [System.Windows.Forms.MessageBoxIcon]::Stop)
		exit 1
			
	}
    
	#
	# Checking on valid target directory
	#
	if ( ( $targetBox.Text -eq "" ) ){
		
		[System.Windows.Forms.MessageBox]::Show("Kein Zielverzeichnis angegeben!", "Fehler", 0, [System.Windows.Forms.MessageBoxIcon]::Stop)
		exit 1
		
	}
	elseif ( !(Test-Path -Path $targetBox.Text) ) {
		
		[System.Windows.Forms.MessageBox]::Show("Das angegebene Zielverzeichnis existiert nicht!", "Fehler", 0, [System.Windows.Forms.MessageBoxIcon]::Stop)
		exit 1
		
	} 
	
	#
	# testing, if selected file size is larger than chunksize
	# if yes: split file, if no: encrypt as is.
	#
    if ( (Get-Item $srcFile.Text).length -igt $chunksize ) {
	
		$encOutfile = Split $srcFile.Text $targetBox.Text
	
    }
    else {
	
		$encOutfile = Encrypt $srcFile.Text $targetBox.Text
	
    }

	#
	# System Message on successful encryption 
	#
    [System.Windows.Forms.MessageBox]::Show("Die Datei wurde erfolgreich verschlüsselt.`nBitte laden sie die ENC-Datei(en) zum Support hoch.","Status",0,[System.Windows.Forms.MessageBoxIcon]::Information)
    
    # if checkbox requests File Explorer
    # open file browser and mark file
    if ( $explorerCheckBox.Checked ) {
	
		# Write-Host "Returned Value: $encOutfile"
		Start-Process -FilePath "C:\Windows\explorer" -ArgumentList "/select, ""$encOutfile"""
    }
    
    
}

#
# End of dialog.ps1
#
