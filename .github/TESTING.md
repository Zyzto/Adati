# CI/CD Testing Guide

This guide provides instructions for testing the new CI/CD pipeline workflows.

## Prerequisites

Before testing, ensure:
- [ ] All workflow files are committed and pushed
- [ ] GitHub secrets are configured (KEYSTORE_FILE, KEYSTORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD)
- [ ] PLAY_STORE_JSON_KEY secret is configured (optional for initial build tests)
- [ ] Production environment is created (see ENVIRONMENTS.md)

## Testing Order

Test workflows in this order:

1. **Build Workflow** (CI) - Safest, no deployment
2. **Beta Release Workflow** - Deploys to beta/internal track
3. **Production Workflow** - Requires approval, promotes to production

## 1. Testing Build Workflow

**File:** `.github/workflows/build.yml`

**Purpose:** Validate that builds work on all platforms without deployment.

### Manual Trigger Test

1. Go to Actions → Build
2. Click "Run workflow"
3. Select branch: `main` or your current branch
4. Click "Run workflow"

### Expected Results

- ✅ Build Android job completes successfully
- ✅ Build Linux job completes successfully  
- ✅ Build Windows job completes successfully
- ✅ Android debug APK artifact is uploaded
- ⏱️ Total time: ~15-20 minutes

### Verification

1. Check all three jobs show green checkmarks
2. Click on Android job → Artifacts
3. Verify `android-debug-apk` is present
4. Download and test APK on Android device (optional)

### Troubleshooting

**If Android build fails:**
- Check Flutter version compatibility
- Verify build_runner generates files correctly
- Check Android dependencies

**If Linux build fails:**
- Check system dependencies installed correctly
- Verify Flutter Linux build works

**If Windows build fails:**
- Check Windows-specific Flutter dependencies
- Verify build_runner on Windows

## 2. Testing Beta Release Workflow

**File:** `.github/workflows/release-beta.yml`

**Purpose:** Full release cycle with Play Store deployment.

### Preparation

Before triggering:

1. **Update version** in `pubspec.yaml`:
```yaml
version: 0.2.1+2  # Increment from current version
```

2. **Commit changes:**
```bash
git add pubspec.yaml
git commit -m "Bump version to 0.2.1"
git push
```

### Method 1: Via Git Tag (Recommended)

```bash
# Create and push tag
git tag v0.2.1
git push origin v0.2.1
```

Workflow triggers automatically.

### Method 2: Manual Trigger

1. Go to Actions → Beta Release
2. Click "Run workflow"
3. Enter version: `0.2.1`
4. Select track: `internal` (safer for first test)
5. Click "Run workflow"

### Expected Results

**Build Phase:**
- ✅ Android build completes (~10 min)
- ✅ Linux build completes (~8 min)
- ✅ Windows build completes (~7 min)
- ✅ All artifacts uploaded

**Deploy Phase:**
- ✅ Play Store deployment job runs
- ✅ AAB uploaded to selected track
- ⏱️ Play Store processing: 10-30 minutes

**Release Phase:**
- ✅ GitHub prerelease created
- ✅ All platform artifacts attached
- ⏱️ Total time: ~25-35 minutes

### Verification Checklist

**GitHub:**
- [ ] Check Actions → Beta Release shows success
- [ ] Go to Releases
- [ ] Verify prerelease `v0.2.1` exists
- [ ] Download and verify artifacts:
  - `adati-0.2.1-android.apk`
  - `adati-0.2.1-android.aab`
  - `adati-0.2.1-linux-x86_64.AppImage`
  - `adati-0.2.1-windows-x64.zip`

**Play Store Console:**
- [ ] Go to [Play Console](https://play.google.com/console)
- [ ] Navigate to Release → Testing → Internal (or Beta)
- [ ] Verify version 0.2.1 appears
- [ ] Check status: "Available to testers"
- [ ] Review rollout status

**Functional Testing:**
- [ ] Install APK from GitHub release
- [ ] Test app functionality
- [ ] Check for crashes
- [ ] Verify version shows correctly in app

### Troubleshooting

**Deploy to Play Store fails:**

Check error message:

**"Invalid JSON key"**
- Solution: Verify PLAY_STORE_JSON_KEY secret contains valid JSON
- Check: Service account has upload permissions

**"Version code already used"**
- Solution: Increment build number in pubspec.yaml
- Example: `0.2.1+2` → `0.2.1+3`

**"Track not found"**
- Solution: Create internal/beta track in Play Console first
- Go to: Release → Setup → Manage tracks

**GitHub release fails:**
- Solution: Check repository permissions
- Verify: Workflow has `contents: write` permission

## 3. Testing Production Release Workflow

**File:** `.github/workflows/release-production.yml`

**Purpose:** Promote beta to production with approval gate.

### Prerequisites

- [ ] Beta release tested and approved
- [ ] Production environment configured (see ENVIRONMENTS.md)
- [ ] At least one reviewer added to production environment
- [ ] No critical bugs in beta

### Trigger Production Release

1. Go to Actions → Production Release
2. Click "Run workflow"
3. Enter prerelease tag: `v0.2.1` (the beta version to promote)
4. Click "Run workflow"

### Expected Flow

**1. Workflow Starts**
- Job begins: `promote-play-store`
- Status: "Waiting"

**2. Approval Required**
- 🛑 Workflow pauses
- Notification sent to reviewers
- Yellow badge: "Waiting for approval"

**3. Reviewer Actions**
- Reviewer clicks "Review deployments"
- Reviews beta testing results
- Checks for issues
- Approves or rejects

**4. After Approval**
- ✅ Play Store promotion continues
- ✅ Beta promoted to production
- ✅ GitHub prerelease → full release
- ⏱️ Total time: ~5-10 minutes + approval time

### Verification Checklist

**Play Store:**
- [ ] Go to Play Console → Production
- [ ] Verify version 0.2.1 in production
- [ ] Check rollout status
- [ ] Monitor for crashes/errors

**GitHub:**
- [ ] Go to Releases
- [ ] Verify v0.2.1 is no longer prerelease
- [ ] Check updated release notes
- [ ] Verify production tag

**App Store Listing:**
- [ ] Check app appears in Play Store
- [ ] Verify correct version shown
- [ ] Test "Update" flow for existing users

### Testing Approval Flow

**Test rejection:**
1. Trigger production release
2. When prompted, click "Reject"
3. Verify workflow stops
4. Verify production unchanged

**Test approval:**
1. Trigger production release again
2. Review deployment
3. Add approval comment
4. Click "Approve and deploy"
5. Verify workflow completes

### Troubleshooting

**"Environment not found"**
- Solution: Create production environment
- See: ENVIRONMENTS.md for setup

**"No reviewers configured"**
- Solution: Add reviewers to environment
- Go to: Settings → Environments → production

**Promotion fails:**
- Check: Beta version exists in Play Store
- Verify: Service account has production permissions
- Review: Play Console error messages

**GitHub release update fails:**
- Check: Workflow has correct permissions
- Verify: Tag exists
- Review: Release exists and is prerelease

## 4. Local Testing with act

**Purpose:** Test workflows locally before pushing.

### Setup

Ensure `.actrc` is configured:
```bash
cat .actrc
```

Should contain Android SDK image configuration.

### Test Build Workflow

```bash
cd /path/to/adati
act -W .github/workflows/build.yml -j build-android
```

**Expected:**
- ✅ Flutter setup succeeds
- ✅ Dependencies installed
- ✅ Build completes
- ⚠️ May take longer first time (Docker image download)

**Note:** Play Store deployment steps won't run with act (requires GitHub secrets).

### Limitations with act

- ❌ Can't test Play Store deployment (requires real secrets)
- ❌ Can't test GitHub releases (requires real repo)
- ✅ Can test build steps
- ✅ Can test dependency installation
- ✅ Can validate workflow syntax

**Note:** Git ownership issues in Docker are automatically fixed by the workflows when running with `act` (detected via `ACT` environment variable). This fix doesn't affect GitHub Actions.

## Test Scenarios

### Scenario 1: First Release

1. Run build workflow to validate
2. Run beta release with `internal` track
3. Test internally
4. Run beta release with `beta` track
5. Collect feedback
6. Run production release

### Scenario 2: Hotfix Release

1. Create hotfix branch
2. Apply fix
3. Increment patch version (0.2.1 → 0.2.2)
4. Run beta release with `internal` track
5. Quick validation
6. Promote to production immediately

### Scenario 3: Major Release

1. Update version (0.2.0 → 0.3.0)
2. Run beta release
3. Extended beta testing (1-2 weeks)
4. Monitor Play Console for issues
5. Promote to production
6. Staged rollout (10% → 50% → 100%)

## Monitoring

### During Testing

**Watch for:**
- Workflow run times
- Error messages
- Artifact sizes
- Upload success rates

**Tools:**
- GitHub Actions UI
- Play Console
- Local device testing

### After Deployment

**Monitor:**
- Crash rates in Play Console
- User reviews
- Download numbers
- Performance metrics

**Response times:**
- Critical: Immediate
- High: Within 24 hours  
- Medium: Within week
- Low: Next release

## Rollback Testing

### Test Rollback Scenario

1. Deploy version 0.2.1 to production
2. Identify "critical issue" (simulated)
3. Go to Play Console → Production
4. Promote previous version (0.2.0)
5. Verify rollback works
6. Document process

### Emergency Procedures

Practice:
- Halting rollout
- Rolling back version
- Disabling app temporarily
- Communicating with users

## Success Criteria

### Build Workflow

- ✅ All platforms build successfully
- ✅ Artifacts generated correctly
- ✅ Completes in under 25 minutes
- ✅ Works with act locally

### Beta Release Workflow

- ✅ All builds succeed
- ✅ Play Store upload successful
- ✅ GitHub prerelease created
- ✅ All artifacts downloadable
- ✅ Version increments correctly

### Production Release Workflow

- ✅ Approval gate works
- ✅ Promotion successful
- ✅ GitHub release updated
- ✅ Audit trail visible
- ✅ Can reject deployments

## Reporting Issues

If tests fail:

1. **Check workflow logs**
   - Actions → Workflow run → Job → Step

2. **Collect information**
   - Error messages
   - Workflow run URL
   - Secrets configuration status

3. **Common fixes**
   - Verify secrets are set
   - Check version numbers
   - Validate service account permissions

4. **Document findings**
   - What failed
   - Error messages
   - Steps to reproduce

## Next Steps

After successful testing:

1. Document any issues found
2. Update workflows if needed
3. Train team on new process
4. Schedule first production release
5. Set up monitoring alerts
6. Plan regular releases

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Fastlane Guide](https://docs.fastlane.tools/)
- [Play Console Help](https://support.google.com/googleplay/android-developer/)
- Project documentation:
  - DEPLOYMENT.md
  - ENVIRONMENTS.md
  - android/fastlane/README.md

