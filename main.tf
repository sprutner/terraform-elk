provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}

##############################################################################
# VPC and subnet configuration
##############################################################################

resource "aws_subnet" "elastic_a" {
  vpc_id = "${lookup(var.aws_vpcs, var.aws_region)}"
  availability_zone = "${concat(var.aws_region, "a")}"
  cidr_block = "${lookup(var.aws_subnet_cidr_a, var.aws_region)}"

  tags {
    Name = "SearchA"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_route_table" "elastic_a" {
  vpc_id = "${lookup(var.aws_vpcs, var.aws_region)}"

  route {
    gateway_id = "${lookup(var.aws_virtual_gateway_a, var.aws_region)}"
    cidr_block = "${lookup(var.aws_virtual_gateway_cidr_a, var.aws_region)}"
  }
  route {
    instance_id = "${lookup(var.aws_nat_a, var.aws_region)}"
    cidr_block = "${lookup(var.aws_nat_cidr_a, var.aws_region)}"
  }

  tags {
    Name = "elastic route table a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_route_table_association" "elastic_a" {
  subnet_id = "${aws_subnet.elastic_a.id}"
  route_table_id = "${aws_route_table.elastic_a.id}"
}

resource "aws_subnet" "elastic_b" {
  vpc_id = "${lookup(var.aws_vpcs, var.aws_region)}"
  availability_zone = "${concat(var.aws_region, "b")}"
  cidr_block = "${lookup(var.aws_subnet_cidr_b, var.aws_region)}"

  tags {
    Name = "SearchB"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_route_table" "elastic_b" {
  vpc_id = "${lookup(var.aws_vpcs, var.aws_region)}"

  route {
    gateway_id = "${lookup(var.aws_virtual_gateway_b, var.aws_region)}"
    cidr_block = "${lookup(var.aws_virtual_gateway_cidr_b, var.aws_region)}"
  }
  route {
    instance_id = "${lookup(var.aws_nat_b, var.aws_region)}"
    cidr_block = "${lookup(var.aws_nat_cidr_b, var.aws_region)}"
  }

  tags {
    Name = "elastic route table b"
    Stream = "${var.stream_tag}"
  }
}

/*resource "aws_route_table_association" "elastic_b" {
  subnet_id = "${aws_subnet.elastic_b.id}"
  route_table_id = "${aws_route_table.elastic_b.id}"
}*/

##############################################################################
# Consul servers
##############################################################################

resource "aws_security_group" "consul_server" {
  name = "consul server"
  description = "Consul server, UI and maintenance."
  vpc_id = "${lookup(var.aws_vpcs, var.aws_region)}"

  // These are for maintenance
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // consul ui
  ingress {
    from_port = 8500
    to_port = 8500
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "consul server security group"
    stream = "${var.stream_tag}"
  }
}

resource "aws_security_group" "consul_agent" {
  name = "consul agent"
  description = "Consul agents internal traffic."
  vpc_id = "${lookup(var.aws_vpcs, var.aws_region)}"

  // These are for internal traffic
  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    self = true
  }

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "udp"
    self = true
  }

  tags {
    Name = "consul agent security group"
    stream = "${var.stream_tag}"
  }
}

module "consul_servers_a" {
  source = "./consul_server"

  name = "a"
  region = "${var.aws_region}"
  #fixme
  ami = "ami-69631053"
  subnet = "${aws_subnet.elastic_a.id}"
  #fixme
  instance_type = "t2.small"
  security_groups = "${concat(aws_security_group.consul_server.id, ",", aws_security_group.consul_agent.id, ",", var.additional_security_groups)}"
  key_name = "${var.key_name}"
  key_path = "${var.key_path}"
  #fixme
  num_nodes = "1"
  stream_tag = "${var.stream_tag}"
}

/*module "consul_servers_b" {
  source = "./consul_server"

  name = "b"
  region = "${var.aws_region}"
  #fixme
  ami = "ami-69631053"
  subnet = "${aws_subnet.elastic_b.id}"
  #fixme
  instance_type = "t2.small"
  security_groups = "${concat(aws_security_group.consul_server.id, ",", aws_security_group.consul_agent.id, ",", var.additional_security_groups)}"
  key_name = "${var.key_name}"
  key_path = "${var.key_path}"
  #fixme
  num_nodes = "1"
  stream_tag = "${var.stream_tag}"
}*/
##############################################################################
# Elasticsearch
##############################################################################

resource "aws_security_group" "elastic" {
  name = "elasticsearch"
  description = "Elasticsearch ports with ssh"
  vpc_id = "${lookup(var.aws_vpcs, var.aws_region)}"

  # SSH access from anywhere
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # elastic ports from anywhere.. we are using private ips so shouldn't
  # have people deleting our indexes just yet
  ingress {
    from_port = 9200
    to_port = 9399
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "elasticsearch security group"
    Stream = "${var.stream_tag}"
  }
}

module "elastic_nodes_a" {
  source = "./elastic"

  name = "a"
  region = "${var.aws_region}"
  ami = "${lookup(var.aws_amis, var.aws_region)}"
  subnet = "${aws_subnet.elastic_a.id}"
  instance_type = "${var.aws_instance_type}"
  elastic_group = "${aws_security_group.elastic.id}"
  security_groups = "${concat(aws_security_group.elastic.id, ",", var.additional_security_groups)}"
  key_name = "${var.key_name}"
  key_path = "${var.key_path}"
  num_nodes = "${var.es_num_nodes_a}"
  cluster = "${var.es_cluster}"
  environment = "${var.es_environment}"
  stream_tag = "${var.stream_tag}"
}

# elastic instances subnet a
/*module "elastic_nodes_b" {
  source = "./elastic"

  name = "b"
  region = "${var.aws_region}"
  ami = "${lookup(var.aws_amis, var.aws_region)}"
  subnet = "${aws_subnet.elastic_b.id}"
  instance_type = "${var.aws_instance_type}"
  elastic_group = "${aws_security_group.elastic.id}"
  security_groups = "${concat(aws_security_group.elastic.id, ",", var.additional_security_groups)}"
  key_name = "${var.key_name}"
  key_path = "${var.key_path}"
  num_nodes = "${var.es_num_nodes_b}"
  cluster = "${var.es_cluster}"
  environment = "${var.es_environment}"
  stream_tag = "${var.stream_tag}"
}*/

# the instances over SSH and logstash ports
resource "aws_security_group" "logstash" {
  name = "logstash"
  description = "Logstash ports with ssh"
  vpc_id = "${lookup(var.aws_vpcs, var.aws_region)}"

  # SSH access from anywhere
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 3333
    to_port = 3333
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 9292
    to_port = 9292
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Lumberjack
  ingress {
    from_port = 5000
    to_port = 5000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "logstash security group"
    Stream = "${var.stream_tag}"
  }
}

# logstash instances
module "logstash_nodes" {
  source = "./ec2"

  name = "logstash"
  region = "${var.aws_region}"
  ami = "${lookup(var.aws_logstash_amis, var.aws_region)}"
  subnet = "${aws_subnet.elastic_a.id}"
  instance_type = "${var.aws_instance_type}"
  security_groups = "${concat(aws_security_group.logstash.id, ",", var.additional_security_groups)}"
  key_name = "${var.key_name}"
  key_path = "${var.key_path}"
  num_nodes = 1
  stream_tag = "${var.stream_tag}"
}

#resource "aws_route53_zone" "search" {
#  name = "${var.domain_name}"
#}

# create hosted zone
# this should be private private
# zone_id = "${aws_route53_zone.search.zone_id}"
resource "aws_route53_record" "logstash" {
   zone_id = "${var.hosted_zone_id}"
   name = "logstash"
   type = "A"
   ttl = "30"
   records = ["${join(",", module.logstash_nodes.private-ips)}"]
}

# the instances over SSH and logstash ports
resource "aws_security_group" "kibana" {
  name = "kibana"
  description = "Kibana and nginx ports with ssh"
  vpc_id = "${lookup(var.aws_vpcs, var.aws_region)}"

  # SSH access from anywhere
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "kibana security group"
    Stream = "${var.stream_tag}"
  }
}

# Kibana instances
module "kibana_nodes" {
  source = "./ec2"

  name = "kibana"
  region = "${var.aws_region}"
  ami = "${lookup(var.aws_kibana_amis, var.aws_region)}"
  subnet = "${aws_subnet.elastic_a.id}"
  instance_type = "${var.aws_kibana_instance_type}"
  security_groups = "${concat(aws_security_group.kibana.id, ",", var.additional_security_groups)}"
  key_name = "${var.key_name}"
  key_path = "${var.key_path}"
  num_nodes = 1
  stream_tag = "${var.stream_tag}"
}
