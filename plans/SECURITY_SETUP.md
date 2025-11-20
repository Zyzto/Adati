# GitHub Secrets Setup for CI/CD

This guide explains how to set up GitHub Secrets for the Adati CI/CD workflow.

## Required Secrets

### GITHUB_TOKEN

Used for creating GitHub Issues when users send logs from the app.

#### Creating a GitHub Personal Access Token

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Give it a descriptive name: `Adati App - Log Reporting`
4. Select scopes:
   - `repo` - Full control of private repositories (if repo is private)
   - `public_repo` - Access public repositories (if repo is public)
5. Click "Generate token"
6. **Copy the token immediately** - you won't be able to see it again!

#### Adding to GitHub Secrets

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `GITHUB_TOKEN`
5. Value: Paste your token
6. Click **Add secret**

## Using Secrets in Workflows

The secrets are automatically available in GitHub Actions workflows as:

```yaml
env:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Security Best Practices

1. **Never commit tokens** to the repository
2. **Use fine-grained tokens** with minimal required permissions
3. **Rotate tokens regularly** (every 90 days recommended)
4. **Revoke tokens** if they're exposed or no longer needed
5. **Use different tokens** for different purposes (development vs production)

## Token Permissions

For the Adati app's log reporting feature, the token needs:
- `repo` scope (for private repos) OR `public_repo` scope (for public repos)
- Specifically: `issues:write` permission to create issues

## Troubleshooting

### Token not working in app

- Verify the token has the correct scopes
- Check that the token hasn't expired
- Ensure the `.env` file contains `GITHUB_TOKEN=your_token` for local testing

### CI/CD workflow fails

- Verify the secret is set in repository settings
- Check the secret name matches exactly (case-sensitive)
- Review workflow logs for specific error messages

