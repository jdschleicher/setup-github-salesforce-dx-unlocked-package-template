

### repository where pipeline setup will be setup in
$github_repository = "setup-github-salesforce-dx-unlocked-package-template"

### either your username if personal repository or organization name that owns the repository
$github_organization_owner = "jdschleicher"

### provide your locally authenticated devhub alias
$devhub_alias = "devhub"
### how long will this pipeline be active (max 30)
$scratch_org_duration = 30
    
$environment_alias_to_github_secrets = @{ 
    "QA" = "QA_AUTH_URL"
    "UAT" = "UAT_AUTH_URL"     
    "PROD" = "PROD_AUTH_URL"
}

ForEach ($environment_alias in $environment_alias_to_github_secrets.Keys) {

    ### create required github environment where github secrets will be applied to
    gh api --method PUT -H "Accept: application/vnd.github.v3+json" /repos/$github_organization_owner/$github_repository/environments/$environment_alias

    $create_scratch_result_json = (sfdx force:org:create --targetdevhubusername $devhub_alias --definitionfile $project_scratch_def_json_path --setalias $environment_alias --durationdays $scratch_org_duration --setdefaultusername --loglevel trace --json )
    $create_scratch_result = $create_scratch_result_json | ConvertFrom-Json
    if ($create_scratch_result.status -eq 0 ) {

        $verbose_result_json = sfdx force:org:display -u $environment_alias --verbose --json
        $verbose_result = $verbose_result_json | ConvertFrom-Json
    
        $auth_url = $verbose_result.result.sfdxAuthUrl

        $github_secret_name = $($environment_alias_to_github_secrets["$environment_alias"])
        Write-Host $github_secret_name
        gh secret set $github_secret_name -b "$auth_url" --env $environment_alias

    }

}