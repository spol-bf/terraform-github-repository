[<img src="https://raw.githubusercontent.com/mineiros-io/brand/3bffd30e8bdbbde32c143e2650b2faa55f1df3ea/mineiros-primary-logo.svg" width="400"/>][homepage]

[![license][badge-license]][apache20]
[![Terraform Version][badge-terraform]][releases-terraform]
[![Join Slack][badge-slack]][slack]

# Create a repository with GitHub Environments

This example demonstrates how to use the terraform-github-repository module to create a repository with GitHub Environments, including environment-specific secrets, variables, and deployment policies.

## Features Demonstrated

- **Multiple Environments**: Development, Staging, and Production environments with different configurations
- **Environment Variables**: Environment-specific configuration variables
- **Environment Secrets**: Secure storage of environment-specific secrets
- **Deployment Policies**: Branch-based deployment restrictions
- **Reviewers**: Required approvals for sensitive environments
- **Wait Timers**: Deployment delays for production environments
- **Branch Protection**: Integration with existing branch protection features

## Environment Configuration

### Development Environment
- **Access**: Open access for developers
- **Branches**: `develop`, `feature/*`
- **Wait Timer**: None
- **Reviewers**: None
- **Admin Bypass**: Enabled

### Staging Environment
- **Access**: Requires team review
- **Branches**: `staging`, `main`
- **Wait Timer**: 1 minute
- **Reviewers**: `developers` team
- **Admin Bypass**: Enabled

### Production Environment
- **Access**: Highly restricted
- **Branches**: Protected branches only (`main`)
- **Wait Timer**: 5 minutes
- **Reviewers**: `platform-team`, `security-team`, and `deployment-manager`
- **Admin Bypass**: Disabled
- **Self-Review**: Prevented

## Usage

The code in [main.tf] defines a complete repository setup with environments:

```hcl
module "repository" {
  source = "mineiros-io/repository/github"
  
  name = "my-app-with-environments"
  
  environments = [
    {
      name = "development"
      deployment_branch_policy = {
        custom_branch_policies = true
      }
      branch_patterns = ["develop", "feature/*"]
      variables = {
        API_URL = "https://dev-api.example.com"
        DEBUG   = "true"
      }
      secrets = {
        DATABASE_URL = { plaintext = "postgres://dev-db:5432/myapp" }
      }
    },
    {
      name = "production"
              wait_timer = 300
        can_admins_bypass = false
        reviewers = {
        teams = ["platform-team"]
        users = ["deployment-manager"]
      }
      deployment_branch_policy = {
        protected_branches = true
      }
      variables = {
        API_URL = "https://api.example.com"
        DEBUG   = "false"
      }
      secrets = {
        DATABASE_URL = { plaintext = "postgres://prod-db:5432/myapp" }
      }
    }
  ]
}
```

## Running the Example

### Prerequisites

- Terraform >= 1.0
- GitHub Provider >= 4.20
- GitHub organization with appropriate permissions
- Environment variables:
  - `GITHUB_TOKEN`: GitHub personal access token
  - `GITHUB_OWNER`: GitHub organization name

### Steps

1. **Clone the repository**:
   ```bash
   git clone https://github.com/mineiros-io/terraform-github-repository.git
   cd terraform-github-repository/examples/with-environments
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Plan the deployment**:
   ```bash
   terraform plan
   ```

4. **Apply the configuration**:
   ```bash
   terraform apply
   ```

5. **Verify the setup**:
   - Check the repository in GitHub
   - Navigate to Settings > Environments
   - Verify environment configurations, secrets, and variables

6. **Clean up** (when done):
   ```bash
   terraform destroy
   ```

## Expected Resources

This example will create:

- 1 GitHub repository with branch protection
- 2 additional branches (`develop`, `staging`)
- 3 environments (`development`, `staging`, `production`)
- 12 environment variables (4 per environment)
- 6 environment secrets (2 per environment)
- 4 deployment policies (branch patterns for dev and staging)

## Security Considerations

### Secrets Management

In this example, secrets are provided as plaintext for demonstration purposes. In production:

- Use encrypted secrets with the GitHub CLI or API
- Store sensitive values in external secret management systems
- Use Terraform variables or external data sources for secret values
- Never commit plaintext secrets to version control

### Environment Access

The example demonstrates different access patterns:

- **Development**: Open access for rapid iteration
- **Staging**: Team-based reviews for quality assurance
- **Production**: Multi-team approval with strict controls

### Branch Protection

The example includes branch protection for the `main` branch:

- Required status checks
- Required pull request reviews
- Conversation resolution required
- No force pushes or deletions allowed

## Troubleshooting

### Common Issues

1. **Provider Version**: Ensure GitHub provider >= 4.20 for environment support
2. **Permissions**: Verify GitHub token has repository and organization permissions
3. **Team Names**: Ensure referenced teams exist in the organization
4. **Branch Patterns**: Verify branch patterns match your branching strategy

### Validation Errors

The module includes validation for:

- Environment names (1-255 characters)
- Wait timers (0-43200 seconds)
- Secret format (exactly one of plaintext or encrypted)
- Branch patterns (required when custom policies are enabled)

## Next Steps

After running this example, you can:

- Customize environment configurations for your workflow
- Add more environments (e.g., `testing`, `preview`)
- Integrate with your CI/CD pipeline
- Set up automated deployments using GitHub Actions
- Configure environment-specific protection rules

<!-- References -->

[main.tf]: https://github.com/mineiros-io/terraform-github-repository/blob/main/examples/with-environments/main.tf
[homepage]: https://mineiros.io/?ref=terraform-github-repository
[badge-license]: https://img.shields.io/badge/license-Apache%202.0-brightgreen.svg
[badge-terraform]: https://img.shields.io/badge/terraform-1.x-623CE4.svg?logo=terraform
[badge-slack]: https://img.shields.io/badge/slack-@mineiros--community-f32752.svg?logo=slack
[releases-terraform]: https://github.com/hashicorp/terraform/releases
[apache20]: https://opensource.org/licenses/Apache-2.0
[slack]: https://join.slack.com/t/mineiros-community/shared_invite/zt-ehidestg-aLGoIENLVs6tvwJ11w9WGg 