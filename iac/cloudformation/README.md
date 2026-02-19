# CloudFormation Deployment

This template defines the AWS Amplify application and branch configuration for the static website.

## Deployment Steps

1. Open AWS CloudFormation
2. Create a new stack
3. Upload `amplify.yaml`
4. Deploy the stack
5. Verify the Amplify build completes successfully

The template provisions:
- AWS Amplify App
- AWS Amplify Branch (main)
- Build configuration
- Rewrite rules
- CDN caching configuration