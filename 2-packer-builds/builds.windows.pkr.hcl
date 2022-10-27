//////////////////////////////////
// Packer Builds | Windows
//////////////////////////////////

build {
  sources = [
    "source.azure-arm.win2k22",
  ]

  provisioner "powershell" {
    elevated_user     = build.User
    elevated_password = build.Password

    scripts = [
      "./files/powershell/consul.ps1",
      "./files/powershell/nomad.ps1",
      "./files/powershell/consul-template.ps1",
    ]
  }

  // deprovision (SysPrep)
  provisioner "powershell" {
    script = "./files/powershell/deprovision.ps1"
  }
}
