#Set-ExecutionPolicy -ExecutionPolicy Bypass

${VERSION} = '0.29.5'
${NAME} = 'consul-template'
${NAME_C} = (Get-Culture).TextInfo.ToTitleCase(${NAME}.ToLower())
${BASE_URL} = 'https://releases.hashicorp.com'
${INSTALL_DIR} = "${env:SystemDrive}\\HashiCorp\\${NAME_C}"

# Create Folder
if (!(Test-Path ${INSTALL_DIR})){
  New-Item -ItemType Directory ${INSTALL_DIR}
}
Set-Location ${INSTALL_DIR}

# Download & Validate
Invoke-WebRequest -Uri "${BASE_URL}/${NAME}/${VERSION}/${NAME}_${VERSION}_windows_amd64.zip" -Outfile "${INSTALL_DIR}\${NAME}_${VERSION}_windows_amd64.zip"
Invoke-WebRequest -Uri "${BASE_URL}/${NAME}/${VERSION}/${NAME}_${VERSION}_SHA256SUMS" -Outfile "${INSTALL_DIR}\${NAME}_${VERSION}_SHA256SUMS"
Invoke-WebRequest -Uri "${BASE_URL}/${NAME}/${VERSION}/${NAME}_${VERSION}_SHA256SUMS.sig" -Outfile "${INSTALL_DIR}\${NAME}_${VERSION}_SHA256SUMS.sig"
Get-Content "${INSTALL_DIR}/*SHA256SUMS"| Select-String  (Get-Filehash -algorithm SHA256 "${INSTALL_DIR}/${NAME}_${VERSION}_windows_amd64.zip").hash.toLower()

# Extract
Expand-Archive "${INSTALL_DIR}/${NAME}_${VERSION}_windows_amd64.zip" "${INSTALL_DIR}/bin" -Force

# Add to Path (current shell & registry)
${env:path} += ";${INSTALL_DIR}/bin"
[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", "Machine") + ";${INSTALL_DIR}/bin", "Machine")

# Cleanup
"${INSTALL_DIR}\${NAME}_${VERSION}_windows_amd64.zip"
"${INSTALL_DIR}\${NAME}_${VERSION}_SHA256SUMS"
"${INSTALL_DIR}\${NAME}_${VERSION}_SHA256SUMS.sig"
