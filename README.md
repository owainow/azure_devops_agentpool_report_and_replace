# Azure DevOps Agent Pool Report and Replace Tool
A repository containing a bash script that loops through your Azure DevOps projects and generates a CSV report on the agent pools used by all of your pipelines with the option of also replacing pools based on a user defined pool map. This can be used to generate a report that contains all of the agentpools in use across your DevOps organisation. It can also be used to replace the pools used in these yaml files. 

## Getting Started

The only prerequisite for this repository is a PAT with permissions to view (or modify) projects, repositories and pipelines. For the --dry-run mode read access is required. For replacement read & write access is required. 

Please make a note of your PAT once you create it as it will not be shared again and is required for each run of the tool. (You can change this by running the auth lines locally first and removing them from the script). 

The tool is written as a bash script which looks for particular agent pools within YAML files in repos and cross-references their values with the agent pool values defined in the agent pool map:
This agent pool can be used to map self-hosted agent pools found under pool: name: or under pool: vm Image:.
This currently replaces vm Image with name for self-hosted pools/mdp. If you want to use this tool to change self-hosted pools to hosted DevOps runners the script can be easily augmented to replace name with vm Image for the agent pool map. 

```
# Define the mapping of old agent pool names to new agent pool names
declare -A AGENT_POOL_MAP=(
 ["Azure Pipelines"]="test"
 ["default"]="test"
)
```
The following argument is available:
* --dry-run - Generate CSV report but do not make changes to the pipeline files.


As the tool requires evaluating the pipeline YAML files itself all repositories are cloned onto the machine running the tool and removed after the report is generated. For larger organisations this can take some time to complete.

1. Clone the repository
2. Update the ORG_URL variable with your organisation url e.g. ORG_URL="https://dev.azure.com/owainow"
3. Run
 ``` . Agentpool_report_and_change.sh --dry-run```

4. Authenticate with either PAT or Interactive Login
5. Review CSV output

If you are happy with the changes then you can rerun the tool without the dry run option.

5. (Optional for live changes) - Run
 ``` . Agentpool_report_and_change.sh ``` 

## Output
### Example Terminal Output
<img width="1031" alt="image" src="https://github.com/user-attachments/assets/2c200900-318c-400c-b9ee-cf8d3725bfda" />


### CSV Output
An example output of the CSV file for two runs is below:
| run_mode | project | repo | changed_file | old_pool | new_pool | commit_hash | commit_date | |
|------------|---------------|----------------------------------------|---------------------|-----------------|----------|-------------|---------------------------|---|
| DRY_RUN | ado-pipelines | ado-pipelines | azure-pipelines.yml | default | test | | | |
| DRY_RUN | ado-pipelines | AKS-zero-trust-demo | azure-pipelines.yml | Azure Pipelines | test | | | |
| DRY_RUN | ado-pipelines | microservice-authentication-oauth2-aks | azure-pipelines.yml | Azure Pipelines | test | | | |
| DRY_RUN | ado-pipelines | microservice-authentication-oauth2-aks | azure-pipelines.yml | default | test | | | |
| NORMAL_RUN | ado-pipelines | ado-pipelines | azure-pipelines.yml | default | test | 426806f | 2025-01-16 10:29:16 +0000 | |
| NORMAL_RUN | ado-pipelines | AKS-zero-trust-demo | azure-pipelines.yml | Azure Pipelines | test | fefa350 | 2025-01-16 10:29:24 +0000 | |
| NORMAL_RUN | ado-pipelines | microservice-authentication-oauth2-aks | azure-pipelines.yml | Azure Pipelines | test | 89a3a6f | 2025-01-16 10:29:32 +0000 | |

## Contributing
Feel free to fork and create pull requests with any improvements or features you have added. Please ensure any feature additions are used through an argument  e.g. --dry-run. 
