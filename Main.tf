resource "aws_vpc" "VPC-Proyecto" {
    cidr_block = "10.10.0.0/16"

    tags = {
      "Name" = "VPC-Proyecto"
    }      
}

resource "aws_internet_gateway" "web-gateway" {
    vpc_id = aws_vpc.VPC-Proyecto.id  
}



resource "aws_subnet" "subred-publica1" {

    vpc_id = aws_vpc.VPC-Proyecto.id
    cidr_block = "10.10.4.0/24"
    availability_zone = "us-east-1a"

    tags = {
      "Name" = "subred-publica1"
    }  
}


resource "aws_subnet" "subred-publica2" {

    vpc_id = aws_vpc.VPC-Proyecto.id
    cidr_block = "10.10.3.0/24"
    availability_zone = "us-east-1b"

    tags = {
      "Name" = "subred-publica2"
    }  
}




resource "aws_subnet" "subred-privada1" {
    vpc_id = aws_vpc.VPC-Proyecto.id
    cidr_block = "10.10.1.0/24"
    availability_zone = "us-east-1a"

    tags = {
      "Name" = "subred-privada1"
    }
  
}

resource "aws_subnet" "subred-privada2" {
    vpc_id = aws_vpc.VPC-Proyecto.id
    cidr_block = "10.10.2.0/24"
    availability_zone = "us-east-1b"

    tags = {
      "Name" = "subred-privada2"
    }
  
}

resource "aws_route_table" "rutas-publicas" {
    vpc_id = aws_vpc.VPC-Proyecto.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.web-gateway.id
    }

    tags = {
      "Name" = "rutas-publicas"
    }
  
}

resource "aws_route_table_association" "ROUTES-SUBNETS-ASSOCIATION" {
    subnet_id = aws_subnet.subred-publica1.id
    route_table_id = aws_route_table.rutas-publicas.id  
}

resource "aws_route_table" "Rutas-Publicas2" {
    vpc_id = aws_vpc.VPC-Proyecto.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.web-gateway.id
    }

    tags = {
      "Name" = "Rutas-Publicas2"
    }  
}

resource "aws_route_table_association" "ROUTES-SUBNETS-ASSOCIATION-B" {
    subnet_id = aws_subnet.subred-publica2.id
    route_table_id = aws_route_table.Rutas-Publicas2.id  
}

resource "aws_eip" "EIP-NAT-GW" {
    vpc = true

    tags = {
        Name = "EIP-NAT-GW"
    }  
}

resource "aws_nat_gateway" "NAT-GateWay" {
    allocation_id = aws_eip.EIP-NAT-GW.id
    subnet_id = aws_subnet.subred-publica1.id

    tags = {
      "Name" = "NAT-GateWay"
    }
}

resource "aws_route_table" "ROUTES-PRIVATE-A" {
      vpc_id = aws_vpc.VPC-Proyecto.id

      route {
          cidr_block = "0.0.0.0/0"
          nat_gateway_id = aws_nat_gateway.NAT-GateWay.id
      }

      tags = {
        "Name" = "ROUTES-PRIVATE"
      }
}


resource "aws_route_table_association" "ROUTES-SUBNETS-PRIVATE-ASSOCIATION-A" {
    subnet_id = aws_subnet.subred-privada1.id
    route_table_id = aws_route_table.ROUTES-PRIVATE-A.id  
}

resource "aws_route_table" "ROUTES-PRIVATE-B" {
    vpc_id = aws_vpc.VPC-Proyecto.id

    route {
      cidr_block = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.NAT-GateWay.id
    }
    
    tags = {
      "Name" = "ROUTES-PRIVATE-B"
    }  
}

resource "aws_route_table_association" "ROUTES-SUBNETS-PRIVATE-ASSOCIATION-B" {
    subnet_id = aws_subnet.subred-privada2.id
    route_table_id = aws_route_table.ROUTES-PRIVATE-B.id  
}



resource "aws_security_group" "SG-Web-server" {
    name = "Allow_Traffic"
    description = "Allow_Traffic"
    vpc_id = aws_vpc.VPC-Proyecto.id

    ingress {
        description = "HTTP"
        from_port = 80
        to_port = 80
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
    }

    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
    }

    ingress {
      from_port = 8
      to_port = 0
      protocol = "icmp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all ping"
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      "Name" = "SG-Web-server"
    }
}

resource "aws_network_interface" "NIC-LINUX" {
    subnet_id = aws_subnet.subred-publica1.id
    private_ips = ["10.10.0.50"]
    security_groups = [aws_security_group.SG-Web-server.id]  
}


resource "aws_network_interface" "NIC-LINUX-PRIVATE-A" {
    subnet_id = aws_subnet.subred-privada1.id
    private_ips = ["10.10.1.50"]
    security_groups = [aws_security_group.SG-Web-server.id]   
}

resource "aws_network_interface" "NIC-LINUX-PRIVATE-B" {
    subnet_id = aws_subnet.subred-privada2.id
    private_ips = ["10.10.2.50"]
    security_groups = [aws_security_group.SG-Web-server.id]   
}

resource "aws_eip" "EIP-LINUX" {
    vpc = true
    network_interface = aws_network_interface.NIC-LINUX.id
    associate_with_private_ip = "10.10.0.50"
    depends_on = [
      aws_internet_gateway.web-gateway
    ]  
}

output "SERVER-PUBLIC-IP" {
    value = aws_eip.EIP-LINUX   
}

resource "aws_instance" "EC2-LINUX" {
    ami = "ami-0c02fb55956c7d316"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "bastion"

    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.NIC-LINUX.id
    }

    tags = {
      "Name" = "EC2-LINUX"
    }
     
}

resource "aws_instance" "EC2-LINUX-PRIVATE-A" {
    ami = "ami-02f8928b66d17a9d2"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "bastion"

    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.NIC-LINUX-PRIVATE-A.id
    }

     user_data = <<-EOF
            #!/bin/bash            
            sudo systemctl enable httpd
            sudo systemctl start httpd
            EOF

    tags = {
      "Name" = "EC2-LINUX-PRIVATE-A"
    }     
}

resource "aws_instance" "EC2-LINUX-PRIVATE-B" {
    ami = "ami-02f8928b66d17a9d2"
    instance_type = "t2.micro"
    availability_zone = "us-east-1b"
    key_name = "bastion"

    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.NIC-LINUX-PRIVATE-B.id
    }

    user_data = <<-EOF
            #!/bin/bash            
            sudo systemctl enable httpd
            sudo systemctl start httpd
            EOF


    tags = {
      "Name" = "Server-privado2"
    }
     
}

output "MY-SERVER-PRIVATE-IP" {
    value = aws_instance.EC2-LINUX.private_ip  
}


output "server_id" {
    value = aws_instance.EC2-LINUX.id  
}

resource "aws_security_group" "SG-LoadBalancer" {
    name = "Allow_Traffic_LB"
    description = "Allow_Traffic_LB"
    vpc_id = aws_vpc.VPC-Proyecto.id

    ingress {
        description = "HTTP"
        from_port = 80
        to_port = 80
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      "Name" = "SG-LoadBalancer"
    }
}

resource "aws_lb" "LoadBalancer" {
  name = "LoadBalancer"
  internal = false
  ip_address_type = "ipv4"
  load_balancer_type = "application"
  subnets = [aws_subnet.subred-publica1.id, aws_subnet.subred-publica2.id]

  security_groups = [aws_security_group.SG-LoadBalancer.id]

  tags = {
    "Name" = "LoadBalancer"
  }
  
}


resource "aws_lb_target_group" "TG-LoadBalancer" {
  name = "TG-LoadBalancer"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.VPC-Proyecto.id

  health_check {
    path = "/"
    protocol = "HTTP"
    interval = 10    
  }  
}

resource "aws_lb_listener" "Listener-web-server" {
  load_balancer_arn = aws_lb.LoadBalancer.arn
  port = "80" 
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.TG-LoadBalancer.arn
    type = "forward"
  }  
}

resource "aws_lb_target_group" "TARGET-GROUP-CLASES" {
  name = "TARGET-GROUP-CLASES"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.VPC-Proyecto.id  
}

resource "aws_lb_target_group_attachment" "ATTACH-TARGET-GROUP-A" {
  count = 2
  target_group_arn = aws_lb_target_group.TG-LoadBalancer.arn
  target_id = aws_instance.EC2-LINUX-PRIVATE-B.id
} 
resource "aws_lb_target_group_attachment" "ATTACH-TARGET-GROUP-B" {
  count = 2
  target_group_arn = aws_lb_target_group.TG-LoadBalancer.arn
  target_id = aws_instance.EC2-LINUX-PRIVATE-A.id  
}