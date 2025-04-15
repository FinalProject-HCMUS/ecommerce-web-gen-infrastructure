# E-commerce Website Generator Infrastructure as Code

This project provides scalable, reliable, and efficient infrastructure tailored specifically for an e-commerce website generator, utilizing modern cloud technologies and best practices.

> **Note:** All application code within the `src/` directory serves as placeholder code only, as the actual application development is maintained in a separate repository.

## Key Features

- **Infrastructure as Code (IaC):** Utilizes Terraform (HCL) to manage and automate cloud infrastructure.
- **Containerization:** Docker configurations enable seamless deployment and consistency across environments.
- **Multi-language Support:** Includes components written in Python, JavaScript, and HTML to support diverse application functionalities.
- **Scalability:** Architected to dynamically scale infrastructure based on traffic demand.
- **Security:** Emphasizes secure, compliant configurations following cloud security best practices.

## Repository Structure

The repository structure is organized clearly as follows:

```
ecommerce-infrastructure
├── infrastructure
│   ├── ecommerce-web-gen-chart
│   │   ├── charts
│   │   ├── Chart.yaml
│   │   ├── ecommerce-web-gen-chart-0.1.0.tgz
│   │   ├── templates
│   │   │   ├── code-gen.yaml
│   │   │   ├── preview.yaml
│   │   │   └── web-ui.yaml
│   │   └── values.yaml
│   └── terraform
│       ├── 1-variables.tf
│       ├── 2-providers.tf
│       ├── 3-vpc.tf
│       ├── 4-subnets.tf
│       ├── 5-gateways.tf
│       ├── 6-route-tables.tf
│       ├── 7-eks.tf
│       ├── 8-aws-load-balancer.tf
│       ├── 9-application.tf
│       └── 10-fargate-profile.tf
└── src
    ├── code-gen
    │   ├── Dockerfile
    │   ├── main.py
    │   └── requirements.txt
    ├── preview
    │   ├── Dockerfile
    │   ├── main.js
    │   └── package.json
    └── web-ui
        ├── Dockerfile
        └── index.html
```

## Prerequisites

Ensure the following prerequisites are installed on your local system before proceeding:

- [Terraform](https://www.terraform.io/downloads.html)
- [Docker](https://www.docker.com/get-started)
- [AWS CLI](https://aws.amazon.com/cli/)
- Python 3.x
- Node.js and npm

## Getting Started

Follow these steps to set up and provision your e-commerce infrastructure:

1. **Clone the repository:**

```bash
git clone https://github.com/hoangtu47/ecommerce-infrastructure.git
cd ecommerce-infrastructure
```

2. **Configure AWS CLI credentials:**

Ensure your AWS credentials are configured:

```bash
aws configure
```

3. **Configure Terraform variables:**

Navigate to the Terraform directory and update necessary configurations:

```bash
cd infrastructure/terraform
```

Adjust the variables in `1-variables.tf` or provide a `terraform.tfvars` file as appropriate for your setup.

4. **Provision Infrastructure:**

Initialize and apply the Terraform configurations:

```bash
terraform init
terraform apply
```

Confirm the proposed actions by typing `yes` when prompted.

5. **Verify Deployment:**

Upon completion, verify your deployment and access your newly provisioned infrastructure.

## Contributing

Contributions are highly welcomed! To contribute:

1. Fork this repository.
2. Create a feature branch (`git checkout -b feature/your-feature-name`).
3. Commit your changes (`git commit -m 'Add some feature'`).
4. Push to your branch (`git push origin feature/your-feature-name`).
5. Open a pull request for review.

## Contact

For questions, support, or collaboration, please contact [hoangtu47](https://github.com/hoangtu47).
