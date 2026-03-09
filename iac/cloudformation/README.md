# Infrastructure as Code – AWS Amplify Hosting

This CloudFormation template provisions the AWS infrastructure for hosting a static website via AWS Amplify.

---

## Prerequisites

- An AWS account with sufficient permissions to create Amplify resources via CloudFormation
- AWS CLI installed and configured
- Access to a GitHub account

---

## 1. Fork the Website Repository

Fork the following repository to your own GitHub account:

```
https://github.com/valentinweyer/valentinweyer.com
```

After forking, your repository URL should look like:

```
https://github.com/<your-username>/valentinweyer.com
```

---

## 2. Create a GitHub Fine-Grained Personal Access Token

Create a fine-grained personal access token for your fork:

1. Go to: https://github.com/settings/personal-access-tokens
2. Click **Generate new token**
3. Configure:

- **Resource owner:** your GitHub account  
- **Repository access:** Only select repositories → select your fork (`valentinweyer.com`)  
- **Permissions:**
  - Metadata: Read-only
  - Webhooks: Read and write

Save the generated token — it will be required for deployment.

---

## 3. One-Time Setup: Connect AWS Amplify to GitHub

This step is required once per AWS account.

1. Open:
   https://console.aws.amazon.com/amplify/apps

2. Click **Create new app**

3. Under **Deploy your app**, select **GitHub**

4. Click **Next**

5. A GitHub authorization pop-up will appear.

6. Grant AWS Amplify permission to access your repository.

After authorization, Amplify and GitHub are connected.

You may cancel the wizard afterward — the connection remains active.

---

# 4. Clone the IaC Repository

Clone the repository containing the CloudFormation template and deployment script.

```bash
git clone https://github.com/valentinweyer/IU-AWS-website.git
cd IU-AWS-website
```

---
# 5. Deployment

The infrastructure and first Amplify deployment are automated using the provided script.

Set the required environment variables:

```bash
export GITHUB_ACCESS_TOKEN=github_...
export GITHUB_REPOSITORY_URL=https://github.com/<your-username>/valentinweyer.com
```

Run the deployment script:

```bash
./deploy.sh
```

The script performs the following steps automatically:

- Validates the CloudFormation template
- Deploys or updates the CloudFormation stack
- Creates the AWS Amplify application and branch
- Retrieves the generated Amplify App ID
- Triggers the initial Amplify build
- Prints the resulting deployment URL

After the build finishes, the website will be accessible via the Amplify domain.

---

# Automation Scope

Most of the deployment process is automated through the **CloudFormation template** and the **`deploy.sh` script**.

However, several steps must be completed manually due to security and provider limitations:

- Forking the website repository
- Creating a GitHub fine-grained personal access token
- Authorizing the AWS Amplify GitHub App

These steps require **interactive authentication with GitHub** and therefore cannot be automated in a reproducible deployment script.

Once these prerequisites are completed, the infrastructure deployment and the first Amplify build are fully automated.

---

# Notes

- Both the app and branch use `DeletionPolicy: Retain`. Deleting the stack will not delete Amplify resources.
- The build process is defined in `render-build.sh` at the root of the repository.
- The BuildSpec expects output in the `public/` directory.
- Cache configuration is set to `AMPLIFY_MANAGED_NO_COOKIES`.
- A rewrite rule redirects all unmatched routes to `index.html` with status `404-200`, enabling SPA-style routing.