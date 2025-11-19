# GitHub Environments Configuration

This guide explains how to set up GitHub Environments for the production deployment workflow.

## Overview

GitHub Environments provide deployment protection rules, including:
- Required reviewers (manual approval gates)
- Wait timers
- Deployment branches restrictions
- Environment secrets

For Adati, we use the `production` environment to require manual approval before promoting releases to production.

## Setup Instructions

### 1. Navigate to Environments

1. Go to your repository on GitHub
2. Click **Settings** (repository settings, not user settings)
3. In the left sidebar, click **Environments**
4. Click **New environment**

### 2. Create Production Environment

1. **Environment name:** `production`
2. Click **Configure environment**

### 3. Configure Protection Rules

#### Required Reviewers

1. Check **Required reviewers**
2. Click **Add reviewers**
3. Select yourself and/or team members who should approve production deployments
4. **Recommended:** At least 1-2 reviewers

**Note:** Reviewers receive a notification when a deployment is waiting for approval.

#### Wait Timer (Optional)

1. Check **Wait timer**
2. Enter minutes (e.g., `5`)
3. This creates a mandatory pause before deployment

**Use case:** Gives time to cancel if deployment was triggered accidentally.

#### Deployment Branches

1. Under **Deployment branches**, select one of:
   - **All branches** - Allow production deployments from any branch
   - **Protected branches only** - Restrict to protected branches
   - **Selected branches** - Specify branch patterns

**Recommended:** "All branches" since production workflow uses manual dispatch with specific tags.

### 4. Save Configuration

Click **Save protection rules**

## How It Works

### Deployment Flow

1. **Trigger:** User runs Production Release workflow
2. **Pause:** Workflow pauses at `promote-play-store` job
3. **Notification:** Reviewers receive email notification
4. **Review:** Reviewers check:
   - Beta testing results
   - No critical bugs
   - Release notes ready
5. **Approve/Reject:** Reviewer approves or rejects deployment
6. **Continue:** If approved, workflow continues automatically

### Viewing Pending Deployments

1. Go to **Actions** tab
2. Find the running workflow
3. Click on the workflow run
4. You'll see "Waiting for approval" status
5. Click **Review deployments** button

### Approving Deployments

1. On the workflow run page, click **Review deployments**
2. Check the environment: `production`
3. **Optional:** Add comment explaining approval decision
4. Click **Approve and deploy** or **Reject**

### Viewing Deployment History

1. Go to **Deployments** (next to Pull Requests)
2. Filter by environment: `production`
3. See all production deployments and their status

## Workflow Configuration

The production workflow references the environment:

```yaml
jobs:
  promote-play-store:
    runs-on: ubuntu-latest
    environment: production  # This line triggers the protection rules
    steps:
      # ... deployment steps
```

When the job reaches this step, it pauses for approval.

## Best Practices

### Reviewer Selection

- **Minimum:** At least 1 reviewer
- **Recommended:** 2 reviewers for redundancy
- **Team:** Include both technical lead and QA lead if possible

### Review Checklist

Before approving production deployment, verify:

- [ ] Beta testing completed successfully
- [ ] No critical bugs in beta
- [ ] All features tested
- [ ] Release notes prepared
- [ ] Version number incremented correctly
- [ ] Play Store metadata up to date (if changed)

### Deployment Timing

Consider:
- **Time of day:** Deploy during business hours for quick response
- **Day of week:** Avoid Fridays (weekend support issues)
- **Holidays:** Avoid deploying before holidays
- **Traffic:** Check app analytics for low-usage periods

### Emergency Procedures

For critical hotfixes:
1. Still use production environment approval
2. Fast-track review (notify reviewers urgently)
3. Consider smaller rollout percentage in Play Store
4. Monitor closely after approval

## Troubleshooting

### "Environment not found" Error

**Cause:** Environment not created or misspelled

**Solution:**
1. Check environment name is exactly `production` (case-sensitive)
2. Verify environment exists in Settings → Environments

### Reviewer Not Notified

**Cause:** Notification settings or permissions issue

**Solution:**
1. Check reviewer has repository access
2. Verify reviewer's GitHub notification settings
3. Manually notify reviewer via other channels

### Can't Approve Own Deployment

**Cause:** GitHub prevents self-approval for security

**Solution:**
- Add another team member as reviewer
- For solo projects: Use wait timer instead of required reviewers

### Approval Not Progressing Workflow

**Cause:** Workflow timeout or job configuration issue

**Solution:**
1. Check workflow hasn't timed out (default 6 hours)
2. Verify `environment: production` is on the correct job
3. Check GitHub Actions status page for incidents

## Advanced Configuration

### Multiple Environments

Create additional environments for different purposes:

- `staging` - Pre-production testing
- `beta` - Beta releases (no approval needed)
- `production` - Production releases (approval required)

### Environment Secrets

Store environment-specific secrets:

1. Go to Settings → Environments → production
2. Scroll to **Environment secrets**
3. Click **Add secret**
4. Useful for: production-only API keys, analytics tokens

### Branch Protection

Combine with branch protection for additional security:

1. Settings → Branches
2. Add rule for `main` branch
3. Require pull request reviews
4. Prevent force pushes

## Testing the Configuration

### Test Approval Flow

1. Create a test workflow that uses the environment:

```yaml
name: Test Production Environment

on:
  workflow_dispatch:

jobs:
  test:
    runs-on: ubuntu-latest
    environment: production
    steps:
      - run: echo "Testing production environment approval"
```

2. Run the workflow
3. Verify approval is required
4. Test approval process
5. Confirm workflow continues after approval

## Resources

- [GitHub Environments Documentation](https://docs.github.com/en/actions/deployment/targeting-different-environments)
- [Deployment Protection Rules](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment#deployment-protection-rules)
- [Required Reviewers](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment#required-reviewers)

## Summary

The production environment ensures:
✅ Manual human approval before production releases
✅ Audit trail of who approved deployments
✅ Ability to reject deployments
✅ Time to cancel accidental deployments
✅ Compliance with release procedures

This prevents accidental production deployments and ensures proper review processes.

