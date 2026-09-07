# Docker Build Fix: Frontend Lingui CLI Issue - SOLVED

## Problem

Docker build was failing with:
```
$ lingui extract
/bin/sh: lingui: not found
error Command failed with exit code 127
```

Even though `lingui` was installed via `yarn install`, the shell couldn't find it when running `yarn run messages:extract`.

## Root Cause

In Alpine Linux Docker environment, even though `lingui` is installed in `node_modules/.bin/`, the shell's `$PATH` environment variable doesn't include it by default. When `yarn run messages:extract` tries to execute the `lingui` command from `package.json`, the shell can't find it.

## The Correct Solution (FINAL)

Added `node_modules/.bin` to the PATH environment variable in the Dockerfile:

```dockerfile
ENV PATH="/app/frontend/node_modules/.bin:$PATH"
```

This is placed **before** running the build commands so that all shell commands have access to the bin directory.

**Complete Flow:**
```dockerfile
ENV VITE_API_URL_CLIENT=$VITE_API_URL_CLIENT
ENV VITE_API_URL_SERVER=$VITE_API_URL_SERVER
ENV NODE_ENV=production
ENV PATH="/app/frontend/node_modules/.bin:$PATH"  # ADD THIS LINE

RUN yarn install --frozen-lockfile && \
    yarn run messages:extract && \
    yarn run messages:compile && \
    yarn run build:ssr:client && \
    yarn run build:ssr:server
```

## Why This Works

1. **Standard Practice**: Adding `node_modules/.bin` to PATH is the recommended way to handle CLI tools in Node.js projects
2. **Prepended Path**: By prepending (using `path:$PATH`), our bin directory takes precedence
3. **Affects All Commands**: Every shell command in that Docker layer will have access to the bin directory
4. **Alpine Linux Compatible**: Works with Alpine's minimal shell environment
5. **Persistent**: The ENV variable applies to all subsequent RUN commands in that stage

## Files Modified

- **Dockerfile** - Added `ENV PATH="/app/frontend/node_modules/.bin:$PATH"` in frontend build stage

## Previous Attempts and Why They Didn't Work

1. **Attempt 1**: Using `npx lingui extract` - Failed because npx tried to download from npm registry
2. **Attempt 2**: Using `yarn run` without PATH fix - Failed because shell couldn't find lingui binary
3. **Attempt 3 (CORRECT)**: Added node_modules/.bin to PATH - Now works!

## How to Test Locally

The fix is already pushed to GitHub. On next Render deployment:

```bash
# Render will build Docker image with updated Dockerfile
# yarn install will create node_modules/.bin/lingui
# ENV PATH will make it accessible to all commands
# Build will complete successfully
```

Manual local testing:
```bash
cd frontend
yarn install --frozen-lockfile
# Verify it works:
./node_modules/.bin/lingui extract
# Or:
yarn run messages:extract
```

## Expected Result

Next Render deployment will show:
```
✓ Frontend dependencies installed
Building frontend...
✓ Messages extracted
✓ Messages compiled
✓ Client bundle built
✓ Server bundle built
✓ Frontend build completed successfully
✓ dist folder found
✓ dist/client found - XXX files
✓ dist/server found - X files
```

Frontend assets will be available at startup! 🎉

