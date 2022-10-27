//////////////////////////////////
// Packer Builds | Linux
//////////////////////////////////

build {
  sources = [
    "source.azure-arm.debian-11",
  ]

  // provision
  provisioner "file" {
    sources = [
      "./files/templates/consul.service",
      "./files/templates/nomad.service",
    ]
    #destination = "/etc/systemd/system/"
    destination = "/tmp/"
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
    skip_clean      = true

    inline = [
      "mv /tmp/consul.service /etc/systemd/system/",
      "mv /tmp/nomad.service /etc/systemd/system/",
    ]
  }

  provisioner "shell" {
    script          = "./files/shell/hashinetes-install.sh"
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
    skip_clean      = true
  }

  // pre-install ansible
  /*provisioner "shell" {
    script = "./files/shell/ansible-install.apt.sh"
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
    skip_clean = true
  } 
  
  // provision
  provisioner "ansible-local" {
    command = join(" ", [
      "ANSIBLE_FORCE_COLOR=1",
      "PYTHONUNBUFFERED=1",
      "ANSIBLE_LOCAL_TEMP=/tmp/ansible",
      "ANSIBLE_REMOTE_TEMP=/tmp/ansible-managed",
      "ANSIBLE_ROLES_PATH=/tmp/packer-provisioner-ansible-local/galaxy_roles:/etc/ansible/roles",
      "ansible-playbook",
    ])

    playbook_files = [
      "./files/ansible-local/nomad.yaml",
      "./files/ansible-local/consul.yaml",
      "./files/ansible-local/cni-plugins.yaml",
    ]
  }*/

  // deprovision
  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
    script          = "./files/shell/deprovision.sh"
    skip_clean      = true
  }
}
