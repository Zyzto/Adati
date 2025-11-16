# Security Guidelines

This document outlines security best practices for the Adati project.

## 🔒 Sensitive Files

The following files should **NEVER** be committed to the repository:

- `.env` - Environment variables (API keys, tokens, etc.)
- `key.properties` - Android signing configuration
- `*.jks`, `*.keystore` - Android keystore files
- `local.properties` - Local Android SDK paths
- `*.p12`, `*.pem` - Certificates and private keys
- `*.mobileprovision` - iOS provisioning profiles
- Any file containing passwords, API keys, or tokens

These files are already listed in `.gitignore` and `.gitattributes` for additional protection.

## ✅ Verification

To verify no sensitive files are tracked in git:

```bash
git ls-files | grep -iE "(env|key|secret|password|token|credential)"
```

This should return nothing. If it returns files, remove them immediately:

```bash
git rm --cached <file>
git commit -m "Remove sensitive file"
```

## 🔑 API Keys and Tokens

### GitHub Token

The app uses a GitHub token for sending logs to GitHub Issues. This token should:

1. **Never be hardcoded** in source code
2. **Never be committed** to the repository
3. Be stored in `.env` file (local development) or GitHub Secrets (CI/CD)

#### Local Development

Create a `.env` file in the root directory:

```env
GITHUB_TOKEN=your_token_here
```

The `.env` file is already in `.gitignore` and will not be committed.

#### CI/CD (GitHub Actions)

For automated builds, use GitHub Secrets:

1. Go to your repository settings
2. Navigate to **Secrets and variables** → **Actions**
3. Add a new secret named `GITHUB_TOKEN`
4. Paste your GitHub Personal Access Token

The workflow can then use it as:
```yaml
env:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## 📱 Android Signing

### Keystore Security

- **Never commit** your keystore file (`.jks` or `.keystore`)
- **Never commit** `key.properties` with real values
- Store keystore files in a secure, backed-up location
- Use `key.properties.example` as a template only

See `android/SIGNING.md` for detailed signing setup instructions.

## 🛡️ Best Practices

1. **Review before committing**: Always review `git status` and `git diff` before committing
2. **Use environment variables**: Never hardcode secrets in source code
3. **Rotate credentials**: If any secret is exposed, rotate it immediately
4. **Use `.gitattributes`**: Additional protection layer (already configured)
5. **Regular audits**: Periodically check for accidentally committed secrets

## 🚨 If Secrets Are Exposed

If you accidentally commit sensitive information:

1. **Immediately rotate** the exposed credentials
2. **Remove from git history** using:
   ```bash
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch <file>" \
     --prune-empty --tag-name-filter cat -- --all
   ```
   Or use [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/)
3. **Force push** (coordinate with team first):
   ```bash
   git push origin --force --all
   ```
4. **Notify team members** to re-clone the repository

## 📚 Additional Resources

- [GitHub Security Best Practices](https://docs.github.com/en/code-security)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
- [Flutter Security](https://docs.flutter.dev/security)

## 🤝 Reporting Security Issues

If you discover a security vulnerability, please **DO NOT** open a public issue. Instead:

1. Email the maintainer directly
2. Or create a private security advisory on GitHub

We will respond promptly and work with you to resolve the issue.

