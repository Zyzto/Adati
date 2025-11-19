# Fastlane Documentation

This directory contains Fastlane configuration for automating Play Store deployments.

## Setup

### Prerequisites

1. **Ruby** (2.6 or higher)
2. **Bundler**: `gem install bundler`
3. **Google Play Service Account** with API access

### Installation

```bash
cd android
bundle install
```

This installs Fastlane and its dependencies specified in the Gemfile.

## Configuration Files

### Appfile

Defines the app package name:
- `package_name`: Android package identifier

### Fastfile

Defines deployment lanes (automated workflows):
- `deploy_internal`: Upload to internal testing track
- `deploy_beta`: Upload to beta testing track
- `promote_production`: Promote beta to production

## Available Lanes

### deploy_internal

Uploads app to Play Store internal testing track.

**Usage:**
```bash
cd android
export PLAY_STORE_JSON_KEY=$(cat path/to/service-account.json)
bundle exec fastlane deploy_internal
```

**Requirements:**
- Built AAB file at `../build/app/outputs/bundle/release/app-release.aab`
- `PLAY_STORE_JSON_KEY` environment variable set

**Use case:**
- Quick testing with small group
- Pre-beta validation
- Internal QA team testing

### deploy_beta

Uploads app to Play Store beta testing track.

**Usage:**
```bash
cd android
export PLAY_STORE_JSON_KEY=$(cat path/to/service-account.json)
bundle exec fastlane deploy_beta
```

**Requirements:**
- Built AAB file at `../build/app/outputs/bundle/release/app-release.aab`
- `PLAY_STORE_JSON_KEY` environment variable set

**Use case:**
- Public beta testing
- Opt-in testers
- Pre-production validation

### promote_production

Promotes current beta version to production.

**Usage:**
```bash
cd android
export PLAY_STORE_JSON_KEY=$(cat path/to/service-account.json)
bundle exec fastlane promote_production
```

**Requirements:**
- Active beta release to promote
- `PLAY_STORE_JSON_KEY` environment variable set

**Use case:**
- Production releases
- After successful beta testing
- Requires manual approval in CI/CD

## Environment Variables

### PLAY_STORE_JSON_KEY

Contains the full JSON content of your Google Play service account key.

**Format:** Raw JSON string (not base64 encoded)

**Example:**
```bash
export PLAY_STORE_JSON_KEY='{"type":"service_account","project_id":"...",...}'
```

**In CI/CD:**
Set as GitHub secret, Fastlane reads it automatically from ENV.

## Google Play Service Account Setup

### Creating Service Account

1. Open [Google Play Console](https://play.google.com/console)
2. Go to Setup → API access
3. Click "Create new service account"
4. Follow link to Google Cloud Console
5. Create service account with name like "GitHub Actions CI"
6. Grant role: "Service Account User"
7. Create and download JSON key

### Granting Permissions

Back in Play Console:
1. Go to Setup → API access
2. Find your service account in the list
3. Click "Grant access"
4. Select your app
5. Grant permissions:
   - Release to production, exclude devices, and use Play App Signing
   - Release to testing tracks: internal, closed, open
   - Manage testing tracks and edit tester lists
6. Save changes

### Storing the Key

**For local testing:**
```bash
# Save JSON to secure location
mv ~/Downloads/service-account-*.json ~/.credentials/adati-play-store.json

# Use in terminal
export PLAY_STORE_JSON_KEY=$(cat ~/.credentials/adati-play-store.json)
```

**For CI/CD:**
1. Copy entire JSON content
2. Go to GitHub → Settings → Secrets
3. Create new secret: `PLAY_STORE_JSON_KEY`
4. Paste JSON content (not base64 encoded)

## Local Testing

### Build and Deploy

Complete local deployment workflow:

```bash
# 1. Build release AAB
cd /path/to/adati
flutter build appbundle --release

# 2. Set credentials
export PLAY_STORE_JSON_KEY=$(cat ~/.credentials/adati-play-store.json)

# 3. Deploy to internal track
cd android
bundle exec fastlane deploy_internal

# Or deploy to beta
bundle exec fastlane deploy_beta
```

### Dry Run

Test Fastlane configuration without uploading:

```bash
# Validate Fastfile syntax
bundle exec fastlane validate

# List available lanes
bundle exec fastlane lanes
```

## Troubleshooting

### Common Errors

#### "Google Api Error: Invalid request"

**Cause:** Service account lacks permissions

**Solution:**
1. Check Play Console → API access
2. Verify service account has release permissions
3. Ensure app is linked to service account

#### "The APK/AAB could not be parsed"

**Cause:** AAB file not found or corrupted

**Solution:**
```bash
# Verify AAB exists
ls -lh ../build/app/outputs/bundle/release/app-release.aab

# Rebuild if needed
flutter clean
flutter build appbundle --release
```

#### "Version code X has already been used"

**Cause:** Version code not incremented in pubspec.yaml

**Solution:**
```yaml
# Update in pubspec.yaml
version: 0.2.0+2  # Increment the build number (+2)
```

Then rebuild:
```bash
flutter build appbundle --release
```

#### "Authentication failed"

**Cause:** Invalid or expired service account key

**Solution:**
1. Verify JSON key is complete and valid
2. Check service account is still active in Cloud Console
3. Regenerate key if necessary
4. Update `PLAY_STORE_JSON_KEY` secret

### Debug Mode

Enable verbose output:

```bash
bundle exec fastlane deploy_beta --verbose
```

### Check Fastlane Version

```bash
bundle exec fastlane --version
```

Update if needed:
```bash
bundle update fastlane
```

## CI/CD Integration

### GitHub Actions

Fastlane is automatically invoked in workflows:

**Beta Release:** `.github/workflows/release-beta.yml`
```yaml
- uses: ruby/setup-ruby@v1
  with:
    ruby-version: '3.2'
    bundler-cache: true
    working-directory: android

- name: Deploy to Play Store
  env:
    PLAY_STORE_JSON_KEY: ${{ secrets.PLAY_STORE_JSON_KEY }}
  run: |
    cd android
    bundle exec fastlane deploy_beta
```

**Production Release:** `.github/workflows/release-production.yml`
```yaml
- name: Promote to Production
  env:
    PLAY_STORE_JSON_KEY: ${{ secrets.PLAY_STORE_JSON_KEY }}
  run: |
    cd android
    bundle exec fastlane promote_production
```

## Best Practices

1. **Always test locally** before pushing to CI/CD
2. **Use internal track** for initial testing
3. **Increment version code** for every upload
4. **Keep service account key secure** - never commit to repo
5. **Use Gemfile.lock** - commit to ensure reproducible builds
6. **Test with staged rollout** in production
7. **Monitor Play Console** after deployments
8. **Keep Fastlane updated** - run `bundle update fastlane` regularly

## Advanced Usage

### Custom Metadata

To upload store listing metadata:

```ruby
# In Fastfile
lane :deploy_beta do
  upload_to_play_store(
    track: 'beta',
    aab: '../build/app/outputs/bundle/release/app-release.aab',
    json_key_data: ENV['PLAY_STORE_JSON_KEY'],
    skip_upload_metadata: false,  # Enable metadata upload
    skip_upload_images: false,    # Enable images upload
    metadata_path: './metadata'   # Path to metadata files
  )
end
```

### Staged Rollout

Deploy to percentage of users:

```ruby
lane :deploy_production_staged do
  upload_to_play_store(
    track: 'production',
    aab: '../build/app/outputs/bundle/release/app-release.aab',
    json_key_data: ENV['PLAY_STORE_JSON_KEY'],
    rollout: '0.1'  # 10% rollout
  )
end
```

### Screenshots

Automate screenshot upload:

```ruby
lane :upload_screenshots do
  upload_to_play_store(
    skip_upload_apk: true,
    skip_upload_aab: true,
    skip_upload_metadata: true,
    skip_upload_images: false,
    skip_upload_screenshots: false
  )
end
```

## Resources

- [Fastlane Documentation](https://docs.fastlane.tools/)
- [Fastlane Supply (Play Store)](https://docs.fastlane.tools/actions/supply/)
- [Flutter CD Guide](https://docs.flutter.dev/deployment/cd)
- [Play Console Help](https://support.google.com/googleplay/android-developer/)

## Support

For issues:
1. Check troubleshooting section above
2. Review Fastlane logs for detailed errors
3. Consult Play Console for app-specific issues
4. Check [Fastlane GitHub Issues](https://github.com/fastlane/fastlane/issues)

