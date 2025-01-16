#!/bin/bash

# Set Azure DevOps organization
ORG_URL="<Your ORG_URL>"

# Define whether this is a dry run
DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "Running in DRY RUN mode. No commits or pushes will occur."
else
  echo "Running in NORMAL mode."
fi

# Log in to Azure DevOps with PAT through terminal
az devops configure --defaults organization=https://dev.azure.com/owainow
az devops login


# Define the mapping of old agent pool names to new agent pool names
declare -A AGENT_POOL_MAP=(
    ["Azure Pipelines"]="test"
    ["default"]="test"
    ["ubuntu-latest"]="default"
)

# Path to the CSV log (relative to the directory containing this script)
CSV_LOG="pool_changes.csv"


# Function to initialize CSV with headers
initialize_csv() {
    if [ ! -f "$CSV_LOG" ] || [ ! -s "$CSV_LOG" ]; then
        echo "run_mode,project,repo,changed_file,old_pool,new_pool,commit_hash,commit_date" > "$CSV_LOG"
        echo "Initialized CSV with headers."
    fi
}


# Ensure the CSV is created and has headers before any data is added
initialize_csv

# Changing location of CSV for repos to use. 
CSV_LOG="../pool_changes.csv"

# Fetch all projects in the organization
projects=$(az devops project list --organization "$ORG_URL" --query "value[].name" -o tsv)

for project in $projects; do
    echo "Processing project: $project"
    repos=$(az repos list --organization "$ORG_URL" --project "$project" --query "[].name" -o tsv)

    for repo in $repos; do
        repo=$(echo "$repo" | tr -d '\r')
        echo "  Cloning repository: $repo"
        
        # Suppress clone output; show errors if any
        git clone "$ORG_URL/$project/_git/$repo" > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "    Failed to clone repository: $repo"
            continue
        fi
        echo "    Successfully cloned $repo"

        cd "$repo" || continue

        # Determine default branch
        default_branch=$(git remote show origin 2>/dev/null | sed -n '/HEAD branch/s/.*: //p')

        # Normalize any CRLF line endings in *.yml files
        find . -name "*.yml" -exec dos2unix {} \; 2>/dev/null

        for old_pool in "${!AGENT_POOL_MAP[@]}"; do
            new_pool="${AGENT_POOL_MAP[$old_pool]}"
            echo "    Replacing agent pool: $old_pool with $new_pool"

            # 1) Single-line: pool: name: old_pool
            find . -name "*.yml" -exec sed -i -E \
                "s/(pool:\s*name:\s*)\"?$old_pool\"?/\1$new_pool/g" {} +

            # 2) Multiline: pool:
            #                  name: old_pool
            find . -name "*.yml" -exec sed -i -z -E \
                "s/pool:\r?\n(\s*)name:\s*\"?$old_pool\"?/pool:\n\1name: $new_pool/g" {} +

            # 3) Multiline: pool:
                #  vmImage: something
                find . -name "*.yml" -exec sed -i -z -E \
                    "s/pool:\r?\n(\s*)vmImage:\s*\"?$old_pool\"?/pool:\n\1name: $new_pool\n\1vmImage: $old_pool/g" {} +

            # Get list of changed YAML files
            changed_files=$(git diff --name-only -- '*.yml')

            if [ -z "$changed_files" ]; then
                echo "    No changes needed for $repo."
            else
                if [ "$DRY_RUN" = true ]; then
                    echo "    DRY RUN: The following changes would be committed:"
                    git --no-pager diff --stat -- '*.yml'

                    # Log each changed file in CSV
                    for changed_file in $changed_files; do
                        echo "DRY_RUN,${project},${repo},${changed_file},${old_pool},${new_pool},,," >> "$CSV_LOG"
                    done

                    # Revert changes to keep the working directory clean
                    git restore .
                else
                    # Commit changes quietly
                    git add *.yml
                    git commit -m "Updated agent pool from $old_pool to $new_pool" > /dev/null 2>&1

                    # Get commit info
                    commit_hash=$(git rev-parse --short HEAD)
                    commit_date=$(git show -s --format=%ci HEAD)

                    # Push changes quietly
                    if [ -n "$default_branch" ]; then
                        git push origin "$default_branch" > /dev/null 2>&1
                    else
                        git push origin master > /dev/null 2>&1
                    fi

                    echo "    Updated and pushed changes to $repo."

                    # Log each changed file in CSV
                    for changed_file in $changed_files; do
                        echo "NORMAL_RUN,${project},${repo},${changed_file},${old_pool},${new_pool},${commit_hash},${commit_date}" >> "$CSV_LOG"
                    done
                fi
            fi
        done

        cd ..
        rm -rf "$repo"
    done
done

echo "YAML agent pool updates completed."
