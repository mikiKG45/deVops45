# deVops45

A hands-on DevOps training project: a production-shaped AWS platform provisioned
entirely as code, designed to be created and destroyed on demand to stay inside
the AWS free credit.

> **Status:** Phase 1 — repo scaffold. See [Roadmap](#roadmap).

## Architecture (target)

- **VPC** across 2 AZs — public subnets for EKS nodes, private subnets for RDS
- **EKS** cluster with a managed node group, IRSA enabled
- **RDS** PostgreSQL, private subnets only, reachable *only* from the cluster
- **Demo app** exposed to the internet through an ALB Ingress
- **Argo CD** reconciling application manifests from this repo (GitOps)
- **CloudWatch Container Insights** for native observability
- **GitHub Actions** for `terraform plan / apply / destroy`, authenticated via OIDC

## Repository layout

| Path | Purpose |
|---|---|
| `bootstrap/` | Resources that must exist *before* everything else: Terraform state bucket, lock table, ECR, budget guardrail, GitHub OIDC role |
| `modules/network/` | VPC, subnets, routing, security groups |
| `modules/eks/` | EKS control plane, managed node group, addons, IRSA/OIDC provider |
| `modules/database/` | RDS instance, subnet group, security group |
| `modules/irsa-role/` | Reusable IAM-Roles-for-Service-Accounts module |
| `environments/dev/` | The dev environment — calls the modules |
| `k8s/argocd/` | Argo CD installation and Application definitions |
| `k8s/apps/` | Demo application manifests |
| `scripts/` | Helper scripts, incl. cleanup for resources `terraform destroy` leaves behind |
| `.github/workflows/` | CI/CD pipelines |

## Design decisions

Deliberate choices made up front, with the reasoning, so they can be revisited later.

| Decision | Choice | Why |
|---|---|---|
| **Internet exposure** | No domain — raw ALB hostname, HTTP only | Free and simple. Route53 + ACM + ExternalDNS can be added in Phase 5 without rework. |
| **Private subnet egress** | No NAT Gateway — nodes run in **public** subnets | Saves ~$33/month and, more usefully, removes a resource that is slow to both create and destroy, which speeds up the apply/destroy cycle. RDS still lives in private subnets and is isolated by security group. The `network` module exposes `enable_nat_gateway` (default `false`) so the production-realistic topology is one variable away. |
| **GitOps engine** | Argo CD | Most widely used in industry; the web UI makes reconciliation visible while learning. |
| **Node instance type** | `t3.medium` x2 | Not a RAM decision — a **max-pods** one. The VPC CNI caps a `t3.small` at 11 pods, ~4 of which are daemonsets, leaving too little headroom for Argo CD (5-7 pods) alongside CoreDNS, the LB controller and the app. `t3.medium` allows 17. Alternative: `t3.small` with VPC CNI prefix delegation. |
| **Image builds** | Built in GitHub Actions, pushed to ECR | No local Docker required, and it keeps the build in the pipeline where it belongs. |

## Cost model

The environment is **destroyed whenever it is not in use**. The EKS control plane
bills at $0.10/hr even with zero nodes, so stopping means a full `terraform destroy`,
not scaling the node group down.

| Component | ~$/hour |
|---|---|
| EKS control plane | 0.100 |
| 2x t3.medium nodes | 0.083 |
| RDS db.t4g.micro | 0.016 |
| ALB | 0.023 |
| **Total** | **~0.22** |

Left running that is ~$160/month. At ~3 hours/day it is closer to $20/month,
which stretches the $100 credit across roughly four months.

A **$10 AWS Budget alarm** is provisioned in `bootstrap/` as the guardrail.

## Roadmap

- [ ] **Phase 0** — AWS account, IAM user, MFA, CLI profile
- [ ] **Phase 1** — Repo scaffold + bootstrap layer (state backend, ECR, budget, GitHub OIDC)
- [ ] **Phase 2** — `network` module
- [ ] **Phase 3** — `eks` module
- [ ] **Phase 4** — `irsa-role` + `database` modules
- [ ] **Phase 5** — Demo app + ALB Ingress
- [ ] **Phase 6** — CloudWatch Container Insights
- [ ] **Phase 7** — Argo CD + GitHub Actions pipelines
- [ ] **Phase 8** — Documentation and security hardening pass

## Usage

_To be written as the phases land._
