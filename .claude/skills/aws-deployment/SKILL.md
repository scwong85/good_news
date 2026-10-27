---
name: aws-deployment
description: Deployment and infrastructure for Good News (Fly.io for MVP, AWS ECS/Fargate later).
---

# Deployment

- Spec: docs/deployment.md. MVP on Fly.io; keep configs portable (12-factor env vars, Docker images).
- AWS path: ECS/Fargate, RDS Postgres, ElastiCache Redis, S3 + CloudFront.
- Do not add CI/CD workflows until the owner asks (decision log #12).
- Encryption at rest/in transit, backup + restore drill, secrets in platform store.
