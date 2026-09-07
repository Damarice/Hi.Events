# Docker Build Fix: Frontend Lingui CLI Issue

## Problem

Docker build was failing with:
```
error: sh: lingui: not found
error Command failed with exit code 127.
```

## Root Cause

When running `yarn build`, which includes `npm run messages:extract` that tries to execute `lingui` directly, the command was not found in Alpine Linux because:

1. `lingui` is installed as a dev dependency in `node_modules/.bin/`
2. npm/yarn should handle this automatically, but in this Docker context, the shell couldn't find it
3. The `$PATH` environment variable didn't include `./node_modules/.bin`

## Solution

Changed the Dockerfile to use `npx` explicitly for CLI tools:

**Before:**
```dockerfile
yarn build 2>&1
```

**After:**
```dockerfile
npx lingui extract && \
npx lingui compile && \
npx vite build --ssrManifest --outDir dist/client && \
npx vite build --ssr src/entry.server.tsx --outDir dist/server
```

## Why This Works

`npx` is a package runner that:
1. Comes with npm automatically (since npm 5.2+)
2. Looks in `./node_modules/.bin/` for executables
3. Executes the found package with proper context
4. Works reliably in Docker environments

## Changes Made

**File:** `Dockerfile`

**Lines changed:**
- Replaced single `yarn build` command with explicit `npx` calls for each step
- Added better step-by-step logging
- Added file count verification for built bundles

**Benefits:**
1. More visibility into each build step
2. Better error messages if any step fails
3. Explicit rather than implicit execution
4. Matches how modern CI/CD systems handle builds

## Testing

The fix should be applied automatically on next Render deployment. To manually test locally:

```bash
cd frontend
yarn install --frozen-lockfile
npx lingui extract
npx lingui compile
npx vite build --ssrManifest --outDir dist/client
npx vite build --ssr src/entry.server.tsx --outDir dist/server
```

## Related Files

- `package.json` - Contains the original build script
- `Dockerfile` - Updated with explicit npx commands
- GitHub commit: "Fix frontend build: use npx for lingui and vite CLI tools"

## Render Deployment

This fix has been pushed to GitHub and will be applied on the next Render deployment trigger. The Docker build should now complete successfully and show the frontend dist/ folder with both client and server bundles.

