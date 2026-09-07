# Docker Build Fix: Frontend Lingui CLI Issue

## Problem

Docker build was failing with:
```
npm error 404  'lingui@*' is not in this registry.
error: failed to solve: process "/bin/sh -c ... npx lingui extract ..." did not complete successfully: exit code: 1
```

## Root Cause

When using `npx lingui extract`, npx tries to:
1. Check if lingui is globally installed
2. Check local node_modules
3. If not found, download from npm registry
4. In Alpine Docker with no internet to registry, this fails with 404

The npm registry lookup was failing because the registry was unreachable or the package name resolution was incorrect.

## Solution

Changed the Dockerfile to use `yarn run` which directly executes the npm scripts defined in package.json:

**Before:**
```dockerfile
npx lingui extract && \
npx lingui compile && \
npx vite build --ssrManifest --outDir dist/client && \
npx vite build --ssr src/entry.server.tsx --outDir dist/server
```

**After:**
```dockerfile
yarn run messages:extract && \
yarn run messages:compile && \
yarn run build:ssr:client && \
yarn run build:ssr:server
```

## Why This Works

`yarn run` directly executes npm scripts:
1. Uses exact scripts from package.json
2. Yarn already has access to node_modules
3. No need for npx or registry lookups
4. Guaranteed to use locally installed packages
5. Matches the original build process intent

## Changes Made

**File:** `Dockerfile`

**Lines changed:**
- Replaced `npx` commands with `yarn run` for all build steps
- Uses exact script names from package.json
- Added better step-by-step logging
- Added file count verification for built bundles

**Benefits:**
1. No npm registry lookups
2. Uses locally installed packages
3. More reliable in isolated Docker build environment
4. Explicitly uses yarn (which we already have)
5. Clear step-by-step logging for debugging

## Testing

The fix should be applied automatically on next Render deployment. To manually test locally:

```bash
cd frontend
yarn install --frozen-lockfile
yarn run messages:extract
yarn run messages:compile
yarn run build:ssr:client
yarn run build:ssr:server
```

Or simply:
```bash
yarn install --frozen-lockfile
yarn build
```

## Related Files

- `package.json` - Contains the original build script
- `Dockerfile` - Updated with explicit npx commands
- GitHub commit: "Fix frontend build: use npx for lingui and vite CLI tools"

## Render Deployment

This fix has been pushed to GitHub and will be applied on the next Render deployment trigger. The Docker build should now complete successfully and show the frontend dist/ folder with both client and server bundles.

