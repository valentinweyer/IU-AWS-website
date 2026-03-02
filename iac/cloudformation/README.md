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

## 4. Clone the IaC Repository

```bash
git clone https://github.com/valentinweyer/IU-AWS-website.git
cd IU-AWS-website
```

---

## 5. Deploy the CloudFormation Stack

```bash
aws cloudformation deploy \
  --template-file iac/cloudformation/amplify.yaml \
  --stack-name valentinweyer-com \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    GitHubAccessToken=<your-token> \
    GitHubRepositoryURL=https://github.com/<your-username>/valentinweyer.com \
  --region eu-central-1
```

Verify stack creation:

```bash
aws cloudformation describe-stacks \
  --stack-name valentinweyer-com \
  --region eu-central-1
```

The stack status should be `CREATE_COMPLETE`.

---

## 6. Trigger the First Deployment (Amplify)

### Option A – Via Console

1. Open: https://console.aws.amazon.com/amplify  
2. Select the newly created app  
3. Click **Deploy**

### Option B – Via CLI

List apps to retrieve the App ID:

```bash
aws amplify list-apps --region eu-central-1
```

Trigger the build:

```bash
aws amplify start-job \
  --app-id <APP_ID> \
  --branch-name main \
  --job-type RELEASE \
  --region eu-central-1
```

---

## Accessing the Deployed Website

After the first successful build, the website is available via the default Amplify domain.

The URL follows this pattern:

```
https://<branch>.<app-id>.amplifyapp.com
```

For example:

- **App ID:** `d3tqakx5ucx841`
- **Branch:** `main`

The website is therefore accessible at:

```
https://main.d3tqakx5ucx841.amplifyapp.com
```

---

## Notes

- Both the app and branch use `DeletionPolicy: Retain`. Deleting the stack will not delete Amplify resources.
- The build process is defined in `render-build.sh` at the root of the repository.
- The BuildSpec expects output in the `public/` directory.
- Cache configuration is set to `AMPLIFY_MANAGED_NO_COOKIES`.
- A rewrite rule redirects all unmatched routes to `index.html` with status `404-200`, enabling SPA-style routing.