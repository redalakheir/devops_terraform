terraform {
  required_providers {
    scaleway = {
      source = "scaleway/scaleway"
    }
  }
  required_version = ">= 0.13"
}


provider "scaleway" {
    access_key     = "SCW21DQD0P0GGCH5PKD7"
    secret_key     = "e88941e6-6146-4d09-b6df-a3fda6a51ad5"
    project_id     = "76e75232-44f3-4460-9f78-a3a8e73ad87e"
}

resource "scaleway_rdb_instance" "main" {
    name           = "test-rdb"
    node_type      = "db-dev-s"
    engine         = "PostgreSQL-12"
    is_ha_cluster  = false
    user_name      = "Admin"
    password       = "Admin!123"
}

resource "scaleway_instance_ip" "public_ip" {
  count = 2
}


resource "scaleway_instance_server" "web" {
  count = 2
    type = "DEV1-S"
    image = "ubuntu_focal"
    ip_id = scaleway_instance_ip.public_ip[count.index].id
    user_data = {
        DATABASE_URI = "postgres://${scaleway_rdb_instance.main.user_name}:${scaleway_rdb_instance.main.password}@${scaleway_rdb_instance.main.endpoint_ip}:${scaleway_rdb_instance.main.endpoint_port}/rdb"
    #   DATABASE_URI = "postgres://<username>:<password>@<database-ip>:<database_port>/<databasename>"
    }

    provisioner "remote-exec" {
      inline = [
        "sudo apt-get update",
        "sudo apt-get install -y ca-certificates curl gnupg lsb-release",
        "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
        "echo  \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
        "sudo apt-get update",
        "sudo apt-get install -y docker-ce docker-ce-cli containerd.io",
        "docker run -d --name app -e DATABASE_URI=\"$(scw-userdata DATABASE_URI)\" -p 80:8080 --restart=always europe-west1-docker.pkg.dev/efrei-devops/efrei-devops/app:latest",
        
      ]
    }
    connection {
      type     = "ssh"
      user     = "root"
      #password = "password"
      host     = self.public_ip
#      timeout  = "60s"
      #private_key = "file(/home/user/terra_ansible)"
      private_key = file("~/.ssh/id_rsa")
    }
}