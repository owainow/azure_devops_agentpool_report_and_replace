# Azure DevOps AgentPool Report and Replace Tool
A repository containing a bash script that loops through your Azure DevOps projects and generates a CSV report on the agent pools used by all of your pipelines with the option of also replacing pools based on a map. 

## Getting Started

The only pre-requiste for this repository is a PAT with permissions to view (or modify) projects, repositories and pipelines. For the --dry-run mode read access is required. For replacement read & write access is required.

1. Clone the repository
2. Run
   . agentpool_report_and_change.sh --dry-run
3. Authenticate with either PAT or Interactive Login
4. Review CSV output

If you are happy with the changes then you can rerun the tool without the dry run option. 

## Output
An example output of the CSV file for two runs is below:
| run_mode   | project       | repo                                   | changed_file        | old_pool        | new_pool | commit_hash | commit_date               |   |
|------------|---------------|----------------------------------------|---------------------|-----------------|----------|-------------|---------------------------|---|
| DRY_RUN    | ado-pipelines | ado-pipelines                          | azure-pipelines.yml | default         | test     |             |                           |   |
| DRY_RUN    | ado-pipelines | aks-zero-trust-demo                    | azure-pipelines.yml | Azure Pipelines | test     |             |                           |   |
| DRY_RUN    | ado-pipelines | microservice-authentication-oauth2-aks | azure-pipelines.yml | Azure Pipelines | test     |             |                           |   |
| DRY_RUN    | ado-pipelines | microservice-authentication-oauth2-aks | azure-pipelines.yml | default         | test     |             |                           |   |
| NORMAL_RUN | ado-pipelines | ado-pipelines                          | azure-pipelines.yml | default         | test     | 426806f     | 2025-01-16 10:29:16 +0000 |   |
| NORMAL_RUN | ado-pipelines | aks-zero-trust-demo                    | azure-pipelines.yml | Azure Pipelines | test     | fefa350     | 2025-01-16 10:29:24 +0000 |   |
| NORMAL_RUN | ado-pipelines | microservice-authentication-oauth2-aks | azure-pipelines.yml | Azure Pipelines | test     | 89a3a6f     | 2025-01-16 10:29:32 +0000 |   |


