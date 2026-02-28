# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE A REPOSITORY WITH GITHUB ENVIRONMENTS
#   - create a private repository
#   - configure multiple deployment environments (dev, staging, production)
#   - set up environment-specific secrets and variables
#   - configure deployment policies and reviewers
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

module "repository" {
  source = "../../"

  name               = "my-app-with-environments"
  description        = "A repository demonstrating GitHub Environments functionality."
  visibility         = "private"
  has_issues         = true
  has_projects       = false
  has_wiki           = false
  allow_merge_commit = true
  allow_rebase_merge = false
  allow_squash_merge = true
  allow_auto_merge   = true
  auto_init          = true
  gitignore_template = "Node"
  license_template   = "mit"
  topics             = ["terraform", "github-environments", "devops"]

  # Create branches for different environments
  branches = [
    {
      name          = "develop"
      source_branch = "main"
      source_sha    = null
    },
    {
      name          = "staging"
      source_branch = "main"
      source_sha    = null
    }
  ]

  # Configure GitHub Environments
  environments = [
    {
      name = "development"

      # Development environment - less restrictive
      wait_timer        = 0
      can_admins_bypass = true

      # Allow deployments from develop and feature branches
      deployment_branch_policy = {
        protected_branches     = false
        custom_branch_policies = true
      }
      branch_patterns = ["develop", "feature/*"]

      # Development environment variables
      variables = {
        API_URL     = "https://dev-api.example.com"
        DEBUG       = "true"
        LOG_LEVEL   = "debug"
        ENVIRONMENT = "development"
      }

      # Development secrets
      secrets = {
        DATABASE_URL = {
          plaintext = "postgres://dev-user:dev-pass@dev-db:5432/myapp_dev"
        }
        API_KEY = {
          plaintext = "dev-api-key-12345"
        }
      }
    },

    {
      name = "staging"

      # Staging environment - moderate restrictions
      wait_timer        = 60 # 1 minute wait
      can_admins_bypass = true

      # Require review for staging deployments
      reviewers = {
        teams = ["developers"]
        users = []
      }

      # Allow deployments from staging and main branches
      deployment_branch_policy = {
        protected_branches     = false
        custom_branch_policies = true
      }
      branch_patterns = ["staging", "main"]

      # Staging environment variables
      variables = {
        API_URL     = "https://staging-api.example.com"
        DEBUG       = "false"
        LOG_LEVEL   = "info"
        ENVIRONMENT = "staging"
      }

      # Staging secrets (using encrypted values in real scenarios)
      secrets = {
        DATABASE_URL = {
          plaintext = "postgres://staging-user:staging-pass@staging-db:5432/myapp_staging"
        }
        API_KEY = {
          plaintext = "staging-api-key-67890"
        }
      }
    },

    {
      name = "production"

      # Production environment - strict restrictions
      wait_timer        = 300 # 5 minutes wait
      can_admins_bypass = false

      # Require multiple reviewers for production
      reviewers = {
        teams = ["platform-team", "security-team"]
        users = ["deployment-manager"]
      }

      # Only allow deployments from protected branches (main)
      deployment_branch_policy = {
        protected_branches     = true
        custom_branch_policies = false
      }

      # Production environment variables
      variables = {
        API_URL     = "https://api.example.com"
        DEBUG       = "false"
        LOG_LEVEL   = "warn"
        ENVIRONMENT = "production"
      }

      # Production secrets (in real scenarios, these would be encrypted)
      secrets = {
        DATABASE_URL = {
          plaintext = "postgres://prod-user:prod-pass@prod-db:5432/myapp_prod"
        }
        API_KEY = {
          plaintext = "prod-api-key-abcdef"
        }
      }
    }
  ]

  # Branch protection for main branch
  branch_protections_v4 = [
    {
      pattern                         = "main"
      enforce_admins                  = true
      require_signed_commits          = false
      required_linear_history         = false
      require_conversation_resolution = true
      allows_deletions                = false
      allows_force_pushes             = false
      blocks_creations                = false
      push_restrictions               = []

      required_status_checks = {
        strict   = true
        contexts = ["ci/tests", "ci/security-scan"]
      }

      required_pull_request_reviews = {
        dismiss_stale_reviews           = true
        restrict_dismissals             = false
        dismissal_restrictions          = []
        pull_request_bypassers          = []
        require_code_owner_reviews      = true
        required_approving_review_count = 2
      }
    }
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "repository_url" {
  value       = module.repository.html_url
  description = "The URL of the created repository"
}

output "environments" {
  value       = module.repository.environments
  description = "The created environments"
}

output "environment_variables" {
  value       = module.repository.environment_variables
  description = "The environment variables"
}

output "deployment_policies" {
  value       = module.repository.deployment_policies
  description = "The deployment policies"
} 