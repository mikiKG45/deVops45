# --- The VPC ---
# A VPC is your own isolated virtual network in AWS. Everything else (subnets,
# EKS nodes, RDS) lives inside it.
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  # DNS support + hostnames are REQUIRED for EKS: nodes and pods resolve each
  # other and AWS service endpoints (like RDS) by DNS name. RDS private
  # endpoints also need this to hand out a resolvable hostname.
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name}-vpc"
  }
}

# --- Internet Gateway ---
# The doorway between the VPC and the public internet. Public subnets route
# through this to reach (and be reached from) the internet. Without it, nothing
# in the VPC can talk to the outside world.
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name}-igw"
  }
}

# --- Public subnets (one per AZ) ---
# These carve slices out of the VPC range. `count = length(var.azs)` means
# "make one of these for each AZ the caller gave us" (2 -> two subnets).
resource "aws_subnet" "public" {
  count = length(var.azs)

  vpc_id            = aws_vpc.this.id
  availability_zone = var.azs[count.index]

  # cidrsubnet() slices the /16 into /20 blocks. Index 0 -> 10.0.0.0/20,
  # index 1 -> 10.0.16.0/20. The "4" adds 4 bits to /16, giving /20.
  cidr_block = cidrsubnet(var.vpc_cidr, 4, count.index)

  # Anything launched here (an EKS node) automatically gets a PUBLIC IP, so it
  # can talk to the internet directly through the Internet Gateway — this is
  # what lets us skip the (paid) NAT gateway.
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-public-${var.azs[count.index]}"
    # Tells the AWS Load Balancer Controller: "put INTERNET-FACING load
    # balancers in these subnets." It auto-discovers subnets by this tag.
    "kubernetes.io/role/elb" = "1"
  }
}

# --- Private subnets (one per AZ) ---
# Same idea, but higher up the range and with NO public IPs and (later) no
# internet route. This is where RDS lives — unreachable from the internet.
resource "aws_subnet" "private" {
  count = length(var.azs)

  vpc_id            = aws_vpc.this.id
  availability_zone = var.azs[count.index]

  # Index +8 keeps private subnets in the high half: 10.0.128.0/20, 10.0.144.0/20.
  cidr_block = cidrsubnet(var.vpc_cidr, 4, count.index + 8)

  # No auto public IP — resources here are private by default.
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name}-private-${var.azs[count.index]}"
    # Tells the LB Controller: "put INTERNAL (VPC-only) load balancers here."
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# --- Public routing ---
# One route table shared by both public subnets.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name}-public-rt"
  }
}

# THE rule that makes public subnets public: "anything not inside the VPC
# (0.0.0.0/0 = the whole internet) leaves through the Internet Gateway."
# The implicit "local" route (VPC-internal traffic) is always present automatically.
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# Attach both public subnets to that route table. Without an association a subnet
# falls back to the VPC's "main" route table — so associating is what actually
# gives the subnet its behavior.
resource "aws_route_table_association" "public" {
  count = length(var.azs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- Optional NAT gateway (default OFF) ---
# A NAT lets PRIVATE subnets reach the internet OUTBOUND (e.g. download updates)
# without being reachable INbound. It costs ~$0.045/h + traffic, so we default
# it off and let nodes live in public subnets instead. Flip enable_nat_gateway
# to true for a production-realistic topology.
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = {
    Name = "${var.name}-nat-eip"
  }
}

resource "aws_nat_gateway" "this" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  # The NAT itself sits in a PUBLIC subnet (it needs internet access to forward).
  subnet_id = aws_subnet.public[0].id

  tags = {
    Name = "${var.name}-nat"
  }

  depends_on = [aws_internet_gateway.this]
}

# --- Private routing ---
# One route table per AZ (flexible: if NAT-per-AZ is ever enabled, each AZ can
# route to its own NAT). With NAT off, these tables have ONLY the implicit local
# route -> no path to the internet -> private subnets are truly isolated.
resource "aws_route_table" "private" {
  count = length(var.azs)

  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name}-private-rt-${var.azs[count.index]}"
  }
}

# This route only exists when NAT is enabled. It sends private outbound traffic
# through the NAT gateway. When NAT is off, count = 0 -> no internet route at all.
resource "aws_route" "private_nat" {
  count = var.enable_nat_gateway ? length(var.azs) : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

resource "aws_route_table_association" "private" {
  count = length(var.azs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
