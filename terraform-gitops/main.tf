terraform {
  required_providers {
    harness = {
      source = "harness/harness"
      version = "0.44.5"
    }
  }

}


resource "harness_platform_gitops_agent" "gitops_agent" {
  identifier = "austintest-agent"
  # account_id = "tjgVkyI9Sq63D6w9gUiVFQ"
  # project_id = "CSE_Lab_Project"
  # org_id     = "CSE_Labs"
  name       = "austintest-agent"
  type       = "MANAGED_ARGO_PROVIDER"
  metadata {
    namespace         = "austin-test-ns"
    high_availability = true
  }
  tags = {
    Email = "DL-PODGandalf@Citizensbank.com"
    Maintainer = "Enterprise PaaS Engineering"
    Team = "PaaS"
  }
}
