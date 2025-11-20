# Deployment Guide

This document describes how to deploy Adati using the CI/CD pipeline.

## Overview

The deployment process uses three separate workflows:

1. **build.yml** - Continuous integration builds (non-release)
2. **release-beta.yml** - Beta releases with Play Store deployment
3. **release-production.yml** - Production promotion with approval

## Prerequisites

### Required Secrets

Configure these in GitHub Settings → Secrets and variables → Actions:

#### Android Signing
- `KEYSTORE_FILE` - Base64 encoded keystore file
- `KEYSTORE_PASSWORD` - Keystore password
- `KEY_ALIAS` - Key alias name
- `KEY_PASSWORD` - Key password

#### Play Store Publishing
- `PLAY_STORE_JSON_KEY` - Full JSON content of Google Play service account key

### Setting up Play Store Service Account

1. Go to [Google Play Console](https://play.google.com/console)
2. Navigate to Setup → API access
3. Create a new service account or use existing
4. Grant permissions: Release to production, testing tracks
5. Download JSON key
6. Copy entire JSON content to `PLAY_STORE_JSON_KEY` secret

### GitHub Environments

Create a `production` environment with approval requirements:

1. Go to Settings → Environments
2. Click "New environment"
3. Name: `production`
4. Add protection rules:
   - Required reviewers: Add yourself
   - Wait timer: 5 minutes (optional)

## Deployment Workflows

### 1. CI Builds (Continuous Integration)

**Workflow:** `.github/workflows/build.yml`

**Triggers:**
- Push to main/master branch
- Pull requests
- Manual dispatch

**Purpose:**
- Validate builds on all platforms
- Run tests
- Produce debug builds for testing

**Usage:**
```bash
# Automatically runs on push/PR
# Manual trigger:
gh workflow run build.yml
```

### 2. Beta Release

**Workflow:** `.github/workflows/release-beta.yml`

**Triggers:**
- Push tags matching `v*` (e.g., `v0.2.0`)
- Manual dispatch

**What it does:**
1. Builds release artifacts for Android, Linux, Windows
2. Deploys Android AAB to Play Store beta/internal track
3. Creates GitHub prerelease with all artifacts

**Usage:**

**Via Tag (Recommended):**
```bash
# Update version in pubspec.yaml first
git tag v0.2.0
git push origin v0.2.0
```

**Via Manual Dispatch:**
1. Go to Actions → Beta Release → Run workflow
2. Choose branch
3. Enter version (e.g., 0.2.0)
4. Select track: internal or beta
5. Click "Run workflow"

**Artifacts produced:**
- `adati-VERSION-android.apk` - Android APK
- `adati-VERSION-android.aab` - Android App Bundle (on Play Store)
- `adati-VERSION-linux-x86_64.AppImage` - Linux AppImage
- `adati-VERSION-windows-x64.zip` - Windows executable

### 3. Production Release

**Workflow:** `.github/workflows/release-production.yml`

**Triggers:**
- Manual dispatch only

**What it does:**
1. Promotes Play Store beta → production (requires approval)
2. Converts GitHub prerelease → full release
3. Updates release notes

**Usage:**

1. Ensure beta testing is complete
2. Go to Actions → Production Release → Run workflow
3. Enter the beta tag to promote (e.g., `v0.2.0`)
4. Click "Run workflow"
5. **Wait for approval notification**
6. Approve the deployment in GitHub UI
7. Production release completes automatically

**Approval Process:**
- Deployment pauses at production environment
- Designated reviewers receive notification
- Review changes and approve/reject
- After approval, promotion continues automatically

## Version Management

Version is managed in `pubspec.yaml`:

```yaml
version: 0.2.0+1
#        ^^^^^ ^^
#        |     |
#        |     +-- Build number
#        +-------- Version name
```

**Version format:** `MAJOR.MINOR.PATCH+BUILD`

**Workflow:**
1. Update `pubspec.yaml` version
2. Commit changes
3. Create and push tag
4. Workflow automatically extracts version

## Release Checklist

### Before Beta Release

- [ ] Update version in `pubspec.yaml`
- [ ] Test locally: `flutter build apk --release`
- [ ] Update changelog (if any)
- [ ] Commit all changes
- [ ] Create and push version tag

### Beta Testing

- [ ] Monitor Play Store console for errors
- [ ] Test on multiple devices
- [ ] Collect feedback
- [ ] Fix critical issues

### Before Production

- [ ] Beta testing complete (at least 3-7 days)
- [ ] No critical bugs reported
- [ ] All features tested
- [ ] Release notes prepared

### After Production

- [ ] Monitor crash reports
- [ ] Check Play Store reviews
- [ ] Announce release (if applicable)

## Fastlane Commands

### Local Testing

Test Fastlane deployment locally (requires service account JSON):

```bash
# Set environment variable
export PLAY_STORE_JSON_KEY=$(cat path/to/service-account.json)

# Test internal track
cd android
bundle exec fastlane deploy_internal

# Test beta track
bundle exec fastlane deploy_beta

# Promote to production
bundle exec fastlane promote_production
```

### Available Lanes

- `deploy_internal` - Upload to internal testing track
- `deploy_beta` - Upload to beta testing track
- `promote_production` - Promote beta → production

## Troubleshooting

### Build Failures

**Flutter version mismatch:**
- Check `.github/workflows/*.yml` files use correct Flutter version
- Update `flutter-version: '3.38.1'` if needed

**Signing errors:**
- Verify all keystore secrets are set correctly
- Check keystore file is base64 encoded: `base64 -w 0 release.keystore`

### Fastlane Errors

**JSON key authentication:**
- Ensure `PLAY_STORE_JSON_KEY` contains full JSON (not base64)
- Verify service account has required permissions

**Upload errors:**
- Check version code in `pubspec.yaml` is incremented
- Ensure AAB file exists in expected path

**Track not found:**
- Verify track name matches Play Store console
- Create internal/beta track in Play Store console first

### GitHub Actions

**Workflow not triggering:**
- Check tag format matches `v*` pattern
- Verify workflow file is in `.github/workflows/`
- Check workflow has necessary permissions

**Approval not working:**
- Ensure `production` environment exists
- Verify reviewers are added to environment
- Check workflow uses `environment: production`

## Rollback Procedures

### Play Store Rollback

1. Go to Play Console → Production → Releases
2. Find previous version
3. Click "Promote to production"
4. Update rollout percentage or halt rollout

### GitHub Release Rollback

1. Go to Releases page
2. Find problematic release
3. Edit → Mark as prerelease or draft
4. Or delete release and artifacts

### Emergency Hotfix

1. Create hotfix branch from production tag
2. Apply fixes
3. Increment version (e.g., 0.2.0 → 0.2.1)
4. Follow beta release process
5. Fast-track to production after minimal testing

## Best Practices

1. **Always test beta** before promoting to production
2. **Increment version** for every release
3. **Use semantic versioning** (MAJOR.MINOR.PATCH)
4. **Monitor Play Store** console after releases
5. **Keep changelogs** updated
6. **Test locally** before pushing tags
7. **Use staging tracks** (internal/beta) properly
8. **Review approval required** for production

## Resources

- [Flutter Deployment Guide](https://docs.flutter.dev/deployment/cd)
- [Fastlane Documentation](https://docs.fastlane.tools/)
- [Google Play Console](https://play.google.com/console)
- [GitHub Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments)

