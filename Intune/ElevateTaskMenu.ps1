$Applications = "ComputerManagement","Explorer","Powershell","ProgramsAndFeatures","Services","TaskScheduler"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Application Elevation'
$form.Size = New-Object System.Drawing.Size(400,250)
$form.StartPosition = 'CenterScreen'

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(165,180)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(250,180)
$cancelButton.Size = New-Object System.Drawing.Size(75,23)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(360,40)
$label.Text = 'Choose Application to Elevate'
$form.Controls.Add($label)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10,60)
$listBox.Size = New-Object System.Drawing.Size(360,20)
$listBox.Height = 80

foreach ($Application in $Applications){
    [void] $listBox.Items.Add($Application)

}

$form.Controls.Add($listBox)

$form.Topmost = $true

$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    switch ($listBox.SelectedItem){

        ComputerManagement {
            $startWithElevatedRights = "compmgmt.msc"
            $Credential = Get-Credential
            Start-Process -PassThru -FilePath powershell -Credential $credential -windowstyle hidden -ArgumentList '-noprofile -command &{Start-Process ',  $startWithElevatedRights, '-Wait -verb runas}'
        }
        Explorer{
            $startWithElevatedRights = "Explorer.exe"
            $Credential = Get-Credential
            Start-Process -PassThru -FilePath powershell -Credential $credential -windowstyle hidden -ArgumentList '-noprofile -command &{Start-Process ',  $startWithElevatedRights, '-Wait -verb runas}'
        }
        Powershell{
            $startWithElevatedRights = "Powershell.exe"
            $Credential = Get-Credential
            Start-Process -PassThru -FilePath powershell -Credential $credential -windowstyle hidden -ArgumentList '-noprofile -command &{Start-Process ',  $startWithElevatedRights, '-Wait -verb runas}'
        }
        ProgramsAndFeatures{
            $startWithElevatedRights = "appwiz.cpl"
            $Credential = Get-Credential
            Start-Process -PassThru -FilePath powershell -Credential $credential -windowstyle hidden -ArgumentList '-noprofile -command &{Start-Process ',  $startWithElevatedRights, '-Wait -verb runas}'
        }
        Services{
            $startWithElevatedRights = "services.msc"
            $Credential = Get-Credential
            Start-Process -PassThru -FilePath powershell -Credential $credential -windowstyle hidden -ArgumentList '-noprofile -command &{Start-Process ',  $startWithElevatedRights, '-Wait -verb runas}'
        }
        TaskScheduler{
            $startWithElevatedRights = "taskschd.msc"
            $Credential = Get-Credential
            Start-Process -PassThru -FilePath powershell -Credential $credential -windowstyle hidden -ArgumentList '-noprofile -command &{Start-Process ',  $startWithElevatedRights, '-Wait -verb runas}'
        }
        Default {
            Write-Host "No Application Selected"
        }
    }

}