
########################
## Required variables ##
########################

variable "vpc_name" {
    description = "The name of the VPC. Best not to include non-alphanumeric characters."
}

variable "vpc_region" {
    description = "Target region for the VPC"
}

#########
## VPC ##
#########

# The VPC contains six subnets, three public and three private, one
# for each availability zone. Instances in the private subnets can
# communicate with the outside via a NAT Gateway

resource "aws_vpc" "main" {

    cidr_block = "10.0.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true

    tags {
        Name = "${var.vpc_name}"
        ManagedBy = "terraform"
    }

    lifecycle {
        create_before_destroy = true
    }

}

#####################
## Private Subnets ##
#####################

resource "aws_subnet" "private_1" {

    vpc_id = "${aws_vpc.main.id}"
    availability_zone = "${var.vpc_region}a"
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = false

    tags {
        Name = "${var.vpc_name}-Private Subnet 1"
        VPC = "${var.vpc_name}"
        ManagedBy = "terraform"
    }

    lifecycle {
        create_before_destroy = true
    }

}

resource "aws_subnet" "private_2" {

    vpc_id = "${aws_vpc.main.id}"
    availability_zone = "${var.vpc_region}b"
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch = false

    tags {
        Name = "${var.vpc_name}-Private Subnet 2"
        VPC = "${var.vpc_name}"
        ManagedBy = "terraform"
    }

    lifecycle {
        create_before_destroy = true
    }

}

resource "aws_subnet" "private_3" {

    vpc_id = "${aws_vpc.main.id}"
    availability_zone = "${var.vpc_region}c"
    cidr_block = "10.0.3.0/24"
    map_public_ip_on_launch = false

    tags {
        Name = "${var.vpc_name}-Private Subnet 3"
        VPC = "${var.vpc_name}"
        ManagedBy = "terraform"
    }

    lifecycle {
        create_before_destroy = true
    }

}

####################
## Public Subnets ##
####################

resource "aws_subnet" "public_1" {

    vpc_id = "${aws_vpc.main.id}"
    availability_zone = "${var.vpc_region}a"
    cidr_block = "10.0.11.0/24"
    map_public_ip_on_launch = true

    tags {
        Name = "${var.vpc_name}-Public Subnet 1"
        VPC = "${var.vpc_name}"
        ManagedBy = "terraform"
    }

    lifecycle {
        create_before_destroy = true
    }

}

resource "aws_subnet" "public_2" {

    vpc_id = "${aws_vpc.main.id}"
    availability_zone = "${var.vpc_region}b"
    cidr_block = "10.0.22.0/24"
    map_public_ip_on_launch = true

    tags {
        Name = "${var.vpc_name}-Public Subnet 2"
        VPC = "${var.vpc_name}"
        ManagedBy = "terraform"
    }

    lifecycle {
        create_before_destroy = true
    }

}

resource "aws_subnet" "public_3" {

    vpc_id = "${aws_vpc.main.id}"
    availability_zone = "${var.vpc_region}c"
    cidr_block = "10.0.33.0/24"
    map_public_ip_on_launch = true

    tags {
        Name = "${var.vpc_name}-Public Subnet 3"
        VPC = "${var.vpc_name}"
        ManagedBy = "terraform"
    }

    lifecycle {
        create_before_destroy = true
    }

}

######################
## Internet gateway ##
######################

resource "aws_internet_gateway" "gateway" {

    vpc_id = "${aws_vpc.main.id}"

    tags {
        Name = "${var.vpc_name}-Internet-Gateway"
        VPC = "${var.vpc_name}"
        ManagedBy = "terraform"
    }

    lifecycle {
        create_before_destroy = true
    }

}

######################
## NAT Gateway EIPs ##
######################

resource "aws_eip" "nat_gateway_1" {
    vpc = true
}

##################
## NAT Gateways ##
##################

resource "aws_nat_gateway" "nat_gateway_1" {
    subnet_id = "${aws_subnet.public_1.id}"
    allocation_id = "${aws_eip.nat_gateway_1.id}"
}

##################
## Route tables ##
##################

# Re-maps the "main" route table to our custom one
resource "aws_main_route_table_association" "main_routes" {

    vpc_id = "${aws_vpc.main.id}"
    route_table_id = "${aws_route_table.private_routes.id}"

}

#####################################
## Route tables: private instances ##
#####################################

# Routes traffic through the NAT gateway
resource "aws_route_table" "private_routes" {

    vpc_id = "${aws_vpc.main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.nat_gateway_1.id}"
    }

    tags {
        Name = "${var.vpc_name}-Private-Routing"
        VPC = "${var.vpc_name}"
        ManagedBy = "terraform"
    }

}

# Subnet associations
# Private subnet 1
resource "aws_route_table_association" "private_a1" {

    subnet_id = "${aws_subnet.private_1.id}"
    route_table_id = "${aws_route_table.private_routes.id}"

}

# Subnet associations
# Private subnet 2
resource "aws_route_table_association" "private_a2" {

    subnet_id = "${aws_subnet.private_2.id}"
    route_table_id = "${aws_route_table.private_routes.id}"

}

# Subnet associations
# Private subnet 3
resource "aws_route_table_association" "private_a3" {

    subnet_id = "${aws_subnet.private_3.id}"
    route_table_id = "${aws_route_table.private_routes.id}"

}

####################################
## Route tables: public instances ##
####################################

# Routes through the internet gateway
resource "aws_route_table" "public_routes" {

    vpc_id = "${aws_vpc.main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.gateway.id}"
    }

    tags {
        Name = "${var.vpc_name}-Public-Routing"
        VPC = "${var.vpc_name}"
        ManagedBy = "terraform"
    }

}

# Subnet associations
# Public subnet 1
resource "aws_route_table_association" "public_a1" {

    subnet_id = "${aws_subnet.public_1.id}"
    route_table_id = "${aws_route_table.public_routes.id}"

}

# Subnet associations
# Public subnet 2
resource "aws_route_table_association" "public_a2" {

    subnet_id = "${aws_subnet.public_2.id}"
    route_table_id = "${aws_route_table.public_routes.id}"

}

# Subnet associations
# Public subnet 3
resource "aws_route_table_association" "public_a3" {

    subnet_id = "${aws_subnet.public_3.id}"
    route_table_id = "${aws_route_table.public_routes.id}"

}

#############
## Outputs ##
#############

output "vpc_id" {
    value = "${aws_vpc.main.id}"
}

output "vpc_region" {
    value = "${var.vpc_region}"
}

output "vpc_private_subnets" {
    value = "${aws_subnet.private_1.cidr_block},${aws_subnet.private_2.cidr_block},${aws_subnet.private_3.cidr_block}"
}

output "vpc_private_subnet_ids" {
    value = "${aws_subnet.private_1.id},${aws_subnet.private_2.id},${aws_subnet.private_3.id}"
}

output "vpc_public_subnets" {
    value = "${aws_subnet.public_1.cidr_block},${aws_subnet.public_2.cidr_block},${aws_subnet.public_3.cidr_block}"
}

output "vpc_public_subnet_ids" {
    value = "${aws_subnet.public_1.id},${aws_subnet.public_2.id},${aws_subnet.public_3.id}"
}
