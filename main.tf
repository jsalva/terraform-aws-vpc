
########################
## Required variables ##
########################

variable "vpc_name" {
    description = "The name of the VPC. Best not to include non-alphanumeric characters."
}

variable "vpc_region" {
    description = "Target region for the VPC"
}

variable "availability_zones" {
    description = "Will launch parallel resources in these Availability Zones"
    type = "list"
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

resource "aws_subnet" "private" {
    count = "${length(var.availability_zones)}"
    vpc_id = "${aws_vpc.main.id}"
    availability_zone = "${element(var.availability_zones, count.index)}"
    cidr_block = "10.0.${count.index+1}.0/24"
    map_public_ip_on_launch = false

    tags {
        Name = "${var.vpc_name}-Private Subnet ${count.index+1}"
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

resource "aws_subnet" "public" {

    count = "${length(var.availability_zones)}"
    vpc_id = "${aws_vpc.main.id}"
    availability_zone = "${element(var.availability_zones, count.index)}"
    cidr_block = "10.0.${count.index+1}${count.index+1}.0/24"
    map_public_ip_on_launch = true

    tags {
        Name = "${var.vpc_name}-Public Subnet ${count.index+1}"
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

resource "aws_eip" "nat_gateway" {

    vpc = true

}

##################
## NAT Gateways ##
##################

resource "aws_nat_gateway" "nat_gateway" {

    subnet_id = "${aws_subnet.public.1.id}"
    allocation_id = "${aws_eip.nat_gateway.id}"

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

# Routes traffic through the NAT Gateway
resource "aws_route_table" "private_routes" {

    vpc_id = "${aws_vpc.main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.nat_gateway.id}"
    }

    tags {
        Name = "${var.vpc_name}-Private-Routing"
        VPC = "${var.vpc_name}"
        ManagedBy = "terraform"
    }

}

# Private subnet associations
resource "aws_route_table_association" "private" {

    count = "${length(var.availability_zones)}"
    subnet_id = "${element(aws_subnet.private.*.id,count.index)}"
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

# Public subnet associations
resource "aws_route_table_association" "public" {

    count = "${length(var.availability_zones)}"
    subnet_id = "${element(aws_subnet.public.*.id,count.index)}"
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
    value = "${list(aws_subnet.private.*.cidr_block)}"
}

output "vpc_private_subnet_ids" {
    value = "${list(aws_subnet.private.*.id)}"
}

output "vpc_public_subnets" {
    value = "${list(aws_subnet.public.*.cidr_block)}"
}

output "vpc_public_subnet_ids" {
    value = "${list(aws_subnet.public.*.id)}"
}
