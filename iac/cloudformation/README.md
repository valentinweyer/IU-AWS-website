# Infrastructure as Code – AWS Amplify Hosting

This CloudFormation template provisions the AWS infrastructure for hosting a static website via AWS Amplify.

## Prerequisites

- An AWS account with sufficient permissions to create Amplify resources via CloudFormation
- A GitHub fine-grained personal access token with the following configuration:
  - **Resource owner:** your GitHub account
  - **Repository access:** Only select repositories — select the website repository
  - **Permissions:**
    - Metadata: Read-only (required)
    - Webhooks: Read and write

## Parameters

| Parameter | Description |
|---|---|
| `GitHubAccessToken` | GitHub fine-grained personal access token. Requires Metadata (read-only) and Webhooks (read and write) permissions. Never logged or stored in plaintext (`NoEcho: true`). |
| `GitHubRepositoryURL` | URL of the GitHub repository to connect to Amplify. Should point to your fork, e.g. `https://github.com/<your-username>/IU-AWS-website`. |


## Deployment

1. Fork this repository to your own GitHub account.

2. Create a GitHub fine-grained personal access token for your fork (see [Prerequisites](#prerequisites)).

3. Clone your fork:
```bash
   git clone https://github.com/<your-username>/IU-AWS-website.git
   cd IU-AWS-website
```

4. Deploy the CloudFormation stack:
```bash
   aws cloudformation deploy \
     --template-file iac/cloudformation/amplify.yaml \
     --stack-name valentinweyer-com \
     --capabilities CAPABILITY_NAMED_IAM \
     --parameter-overrides \
       GitHubAccessToken=<your-token> \
       GitHubRepositoryURL=https://github.com/<your-username>/valentinweyer.com
```

5. Once the stack creation is complete, open the [AWS CloudFormation console](https://console.aws.amazon.com/cloudformation) and verify the stack status shows `CREATE_COMPLETE`.

6. Navigate to the [AWS Amplify console](https://console.aws.amazon.com/amplify), select the newly created app, and trigger the first deployment by clicking **Deploy**.

## Notes

- Both the app and branch have `DeletionPolicy: Retain` — deleting the stack will **not** delete the Amplify resources.
- The build process is defined in `render-build.sh` at the root of the repository. The BuildSpec calls this script and expects output in the `public/` directory.
- Cache config is set to `AMPLIFY_MANAGED_NO_COOKIES` to avoid cookie-based caching issues.
- A rewrite rule redirects all unmatched routes to `index.html` with a `404-200` status, enabling SPA-style routing.