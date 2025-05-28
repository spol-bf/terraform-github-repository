# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# GITHUB REPOSITORY ENVIRONMENTS
# This file manages GitHub repository environments, deployment policies, secrets, and variables
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ---------------------------------------------------------------------------------------------------------------------
# LOCALS - Environment Data Transformations
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Create a map of environments for easier resource management
  environments_map = { for env in var.environments : env.name => env }

  # Create a flattened list of all team names used in environments for data source lookup
  environment_teams = toset(flatten([
    for env in var.environments : try(env.reviewers.teams, [])
  ]))

  # Flatten environment secrets for resource creation
  environment_secrets = merge([
    for env_name, env in local.environments_map : {
      for secret_name, secret_value in try(env.secrets, {}) :
      "${env_name}:${secret_name}" => {
        environment  = env_name
        secret_name  = secret_name
        secret_value = secret_value
      }
    }
  ]...)

  # Flatten environment variables for resource creation
  environment_variables = merge([
    for env_name, env in local.environments_map : {
      for var_name, var_value in try(env.variables, {}) :
      "${env_name}:${var_name}" => {
        environment    = env_name
        variable_name  = var_name
        variable_value = var_value
      }
    }
  ]...)

  # Create deployment policies map for environments with custom branch policies
  deployment_policies = {
    for env_name, env in local.environments_map : env_name => env
    if try(env.deployment_branch_policy.custom_branch_policies, false) && length(try(env.branch_patterns, [])) > 0
  }

  # Flatten branch patterns for deployment policies
  deployment_branch_patterns = merge([
    for env_name, env in local.deployment_policies : {
      for idx, pattern in env.branch_patterns :
      "${env_name}:${idx}" => {
        environment = env_name
        pattern     = pattern
      }
    }
  ]...)
}

# ---------------------------------------------------------------------------------------------------------------------
# DATA SOURCES - Team ID Lookups
# ---------------------------------------------------------------------------------------------------------------------

# Data source to look up team IDs from team slugs
data "github_team" "environment_teams" {
  for_each = local.environment_teams
  slug     = replace(lower(each.value), "/[^a-z0-9_]/", "-")
}

# ---------------------------------------------------------------------------------------------------------------------
# GITHUB REPOSITORY ENVIRONMENTS
# ---------------------------------------------------------------------------------------------------------------------

resource "github_repository_environment" "environment" {
  for_each = local.environments_map

  repository  = github_repository.repository.name
  environment = each.key

  # Wait timer configuration (0-43200 seconds)
  wait_timer = try(each.value.wait_timer, null)

  # Admin bypass configuration
  can_admins_bypass = try(each.value.can_admins_bypass, true)

  # Reviewers configuration
  # Note: teams must be specified as team slugs, and they must already have access to the repository
  dynamic "reviewers" {
    for_each = try(each.value.reviewers, null) != null ? [each.value.reviewers] : []
    content {
      teams = [
        for team_slug in try(reviewers.value.teams, []) :
        data.github_team.environment_teams[team_slug].id
      ]
      users = try(reviewers.value.users, [])
    }
  }

  # Deployment branch policy configuration
  dynamic "deployment_branch_policy" {
    for_each = try(each.value.deployment_branch_policy, null) != null ? [each.value.deployment_branch_policy] : []
    content {
      protected_branches     = try(deployment_branch_policy.value.protected_branches, false)
      custom_branch_policies = try(deployment_branch_policy.value.custom_branch_policies, false)
    }
  }

  # Ensure environments are created after repository and team assignments
  depends_on = [
    github_repository.repository,
    github_team_repository.team_repository,
    github_team_repository.team_repository_by_slug,
    data.github_team.environment_teams
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# GITHUB REPOSITORY ENVIRONMENT DEPLOYMENT POLICIES
# ---------------------------------------------------------------------------------------------------------------------

resource "github_repository_environment_deployment_policy" "deployment_policy" {
  for_each = local.deployment_branch_patterns

  repository     = github_repository.repository.name
  environment    = github_repository_environment.environment[each.value.environment].environment
  branch_pattern = each.value.pattern

  depends_on = [github_repository_environment.environment]
}

# ---------------------------------------------------------------------------------------------------------------------
# GITHUB ACTIONS ENVIRONMENT SECRETS
# ---------------------------------------------------------------------------------------------------------------------

resource "github_actions_environment_secret" "environment_secret" {
  for_each = local.environment_secrets

  repository  = github_repository.repository.name
  environment = each.value.environment
  secret_name = each.value.secret_name

  # Support both plaintext and encrypted secrets
  plaintext_value = try(each.value.secret_value.plaintext, null)
  encrypted_value = try(each.value.secret_value.encrypted, null)

  depends_on = [github_repository_environment.environment]
}

# ---------------------------------------------------------------------------------------------------------------------
# GITHUB ACTIONS ENVIRONMENT VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

resource "github_actions_environment_variable" "environment_variable" {
  for_each = local.environment_variables

  repository    = github_repository.repository.name
  environment   = each.value.environment
  variable_name = each.value.variable_name
  value         = each.value.variable_value

  depends_on = [github_repository_environment.environment]
} 