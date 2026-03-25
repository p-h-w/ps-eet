###############################################
#
# Copyright 2026 Jens Langecker 
# Licensed under the GNU Affero General Public License v3.0
# see LICENCE.txt of https://www.gnu.org/licenses/agpl-3.0.en.html
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# 7zip extension to forward decompressed files
# directly to 7z and encrypt it
# necessary extensions:
# forward_7zip=true
# 7zip_path=executable binary
# 7zip_chunksize=size of chunk if too big
# 7ZipExtension=extensions\szipexport.ps1
#
###############################################

[bool] $global:setpw = $False

Function 7zip_checkFileSize ( $File, $chunksize, $multiplier ){
	
	if ( (Get-Item $File).length -igt ([int]$chunksize.Remove( ($chunksize.length-1),1)*$multiplier) ) {
		
		Return "-v$chunksize"
		
	} else {
		
		Return ""
		
	}
	
}

Function genString ( $length ){
	
	# if $length is not set, use default value as fallback
	if ( $length -eq $null ){
		
		$length = 12
		
	}
	
	# For debug purpose
	# Write-Host "Password-Length: "$length
	
	#return value as string
	return -join ( (48..57) + (65..90) + (97..122) | Get-Random -Count $length | %{[char]$_} )
	
}



Function szipexport ( $inFile ){
	
	do {
		
		
		# Loading Gui modules for Powershell
		Add-Type -AssemblyName System.Windows.Forms
		Add-Type -AssemblyName System.Drawing
	
		$xSize = 380
		$ySize = 280

		$7z_form = New-Object System.Windows.Forms.Form
		$7z_form.Text = "7zip-Exporter"
		$7z_form.StartPosition = 'CenterScreen'
		$7z_form.Size = New-Object System.Drawing.Size($xSize,$ySize)



		$yPos_fileselector = 5
		$pw_label1 = New-Object System.Windows.Forms.Label
		$pw_label1.Location = New-Object System.Drawing.Point( 10, $yPos_fileselector )
		$pw_label1.Size = New-Object System.Drawing.Size(200,20)
		$pw_label1.Text = "Zielverzeichnis"
		$7z_form.Controls.Add($pw_label1)


		$7z_filebox = New-Object System.Windows.Forms.TextBox
		$7z_filebox.Location = New-Object System.Drawing.Point(10,($yPos_fileselector+20))
		$7z_filebox.Size = New-Object System.Drawing.Size(280,23)
		$7z_form.Controls.Add($7z_fileBox)
		
		$7z_FileSelButton = New-Object System.Windows.Forms.Button
		$7z_FileSelButton.Location = New-Object System.Drawing.Point(($xSize-70),($yPos_fileselector+20))
		$7z_FileSelButton.Size = New-Object System.Drawing.Size(50,20)
		$7z_FileSelButton.Text = '...'
		$7z_FileSelButton.add_click({$7z_directory = Directory; $7z_filebox.Text = $7z_directory})
		$7z_form.Controls.Add($7z_FileSelButton)
	
		$pw_ySize = 60
	
		$pw_label1 = New-Object System.Windows.Forms.Label
		$pw_label1.Location = New-Object System.Drawing.Point(10, $pw_ySize )
		$pw_label1.Size = New-Object System.Drawing.Size(200,20)
		$pw_label1.Text = "Passwort"
		$7z_form.Controls.Add($pw_label1)
		
		$pw_textBox = New-Object System.Windows.Forms.MaskedTextBox
		$pw_textBox.PasswordChar = "*"
		$pw_textBox.Location = New-Object System.Drawing.Point(10,($pw_ySize+20))
		$pw_textBox.Size = New-Object System.Drawing.Size(280,23)
		$7z_form.Controls.Add($pw_textBox)
		
		$pw_label2 = New-Object System.Windows.Forms.Label
		$pw_label2.Location = New-Object System.Drawing.Point(10, ($pw_ySize+50) )
		$pw_label2.Size = New-Object System.Drawing.Size(200,20)
		$pw_label2.Text = "Passwort wiederholen"
		$7z_form.Controls.Add($pw_label2)
		
		$pw_textBox2 = New-Object System.Windows.Forms.MaskedTextBox
		$pw_textBox2.PasswordChar = "*"
		$pw_textBox2.Location = New-Object System.Drawing.Point(10,($pw_ySize+70))
		$pw_textBox2.Size = New-Object System.Drawing.Size(280,23)
		$7z_form.Controls.Add($pw_textBox2)
	
		$pw_viewCB = New-Object System.Windows.Forms.CheckBox
		$pw_viewCB.Text = "Passwort anzeigen"
		$pw_viewCB.AutoSize = $true
		$pw_viewCB.Location = New-Object System.Drawing.Point(10,($pw_ySize+95))
		$pw_viewCB.add_CheckedChanged({ showPW_function $pw_textBox $pw_viewCB })
		$pw_viewCB.add_CheckedChanged({ showPW_function $pw_textBox2 $pw_viewCB })
		$7z_form.Controls.Add($pw_viewCB)
		
		$pw_genButton = New-Object  System.Windows.Forms.Button
		$pw_genButton.Location = New-Object System.Drawing.Point(($7z_button_xpos+150), ($pw_ySize+95))
		$pw_genButton.Size = New-Object system.Drawing.Size(130,23)
		$pw_genButton.Text = "Passwort generieren"
		$pw_genButton.add_click({$gen_password = genString $pw_length; $pw_textBox.Text = $gen_password; $pw_textBox2.Text = $gen_password; $global:setpw = $True})
		$7z_form.Controls.Add($pw_genButton)
	
		$7z_button_xpos = 130
		$7z_button_ypos = ($ySize-80)
		$7z_okButton = New-Object System.Windows.Forms.Button
		$7z_okButton.Location = New-Object System.Drawing.Point($7z_button_xpos,$7z_button_ypos)
		$7z_okButton.Size = New-Object System.Drawing.Size(75,23)
		$7z_okButton.Text = 'OK'
		$7z_okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
		$7z_form.AcceptButton = $7z_okButton
		$7z_form.Controls.Add($7z_okButton)

		$7z_cancelButton = New-Object System.Windows.Forms.Button
		$7z_cancelButton.Location = New-Object System.Drawing.Point(($7z_button_xpos+85),$7z_button_ypos)
		$7z_cancelButton.Size = New-Object System.Drawing.Size(75,23)
		$7z_cancelButton.Text = 'Cancel'
		$7z_cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
		$7z_form.CancelButton = $7z_cancelButton
		$7z_form.Controls.Add($7z_cancelButton)
		
		$result = $7z_form.ShowDialog()
		
		if ( $pw_textBox.Text -ne $pw_textBox2.Text ){
			
			[System.Windows.Forms.MessageBox]::Show("Passwörter nicht identisch!","Fehler",0,[System.Windows.Forms.MessageBoxIcon]::Error)
			
		}

	} while ( $pw_textBox.Text -ne $pw_textBox2.Text )
	
	# Write-Host $inFile
	
	switch ( $7zip_chunksize.Remove(0,1) ){
		
		"b" {
			
			$multiplier = 1
			
		}
		
		"k" {
			
			$multiplier = 1024
			
		}
		
		"m" {
			
			$multiplier = 1024*1024
		}
		
		"g" {
			
			$multiplier = 1024*1024*1024
			
		}
		
		
	} # End switch
	
	#
	# check filesize if greater then chunksize
	#
	$v_options = 7zip_checkFileSize $inFile $7zip_chunksize $multiplier
	
	$7zip_cmd = "`""+$scriptPath+"\"+$7zip_path+"`""+" a -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on -mhe=on "
	$7zip_cmd += $v_options+" -p'"+$pw_textBox.Text+"' "
	$7zip_cmd += '"'+$7z_filebox.Text+"\"+(Get-Item $inFile).Basename+".7z"+'" "'+$inFile+'"'
	
	# write password, if password was generated
	# by password generator
	
	# Write-Host "Passwd: "$pw_textBox.Text

	# Write-Host "random-PW: "$setpw

	if ( $setpw ){
		
		# put the password containing file 
		# one directory upwards to avoid 
		# copying it onto remote server
		# accidentally.
		$7z_PwFile = $7z_filebox.Text+"\..\"+(Get-Item $inFile).Basename+".txt"
		# Write-Host "PW-File: "$7z_PwFile
		Write-Output $pw_textBox.Text | Out-File -FilePath $7z_PwFile
		
	}
	
	# for debug purpose
	# Write-Host "$7zip_cmd"
	iex "& $7zip_cmd"
	
}	
