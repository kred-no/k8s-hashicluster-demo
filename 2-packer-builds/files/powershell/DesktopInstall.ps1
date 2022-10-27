function Log([String]${logtext}) {
  ${timestamp} = (Get-Date -UFormat %T).ToString()
  Write-Host "[${timestamp}] ${logtext}"
}

Log "Installing Firefox .."
${SourceURL} = "https://download.mozilla.org/?product=firefox-msi-latest-ssl&os=win64&lang=en-US";
${Installer} = ${env:TEMP} + "\firefox.exe"; 
Invoke-WebRequest ${SourceURL} -OutFile ${Installer};
Start-Process -FilePath ${Installer} -Args "/s" -Verb RunAs -Wait; 
Remove-Item ${Installer};

