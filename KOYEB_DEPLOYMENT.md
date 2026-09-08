# Deploy Hi.Events to Koyeb (FREE)

Koyeb is a completely free platform for deploying Docker containers. This guide walks you through deploying Hi.Events.

## Prerequisites

- GitHub account (code is already there)
- Koyeb account (free signup at koyeb.com)
- 5 minutes

## Step 1: Create Koyeb Account

1. Go to https://www.koyeb.com
2. Click **Sign Up**
3. Sign up with GitHub (easier)
4. Verify email

## Step 2: Create a New Service

1. In Koyeb dashboard, click **Create Service**
2. Choose **Docker** as the builder
3. Select **GitHub** as source
4. Authorize Koyeb to access your GitHub account
5. Select repository: `Hi.Events`
6. Select branch: `master`
7. Click **Continue**

## Step 3: Configure Docker Build

In the build configuration:

1. **Dockerfile:** `Dockerfile.koyeb`
2. **Build context:** `/` (root)
3. Click **Continue**

## Step 4: Set Environment Variables

You MUST set these secrets before deployment:

1. Click **Env variables**
2. Click **Add secret** and add these:

```
APP_KEY = (generate with: php artisan key:generate --show)
JWT_SECRET = (generate with: openssl rand -hex 32)
DB_PASSWORD = (any strong password)
```

**To generate APP_KEY locally:**
```bash
cd backend
php artisan key:generate --show
# Copy the key (starts with "base64:")
```

**To generate JWT_SECRET:**
```bash
openssl rand -hex 32
# Or use: node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

3. Copy the values into Koyeb secrets

## Step 5: Configure Service

1. **Service name:** `hi-events`
2. **Instance type:** Free
3. **Port:** 80 (already set)
4. **Health check:** 
   - Path: `/`
   - Initial delay: 30s
   - Interval: 15s
   - Timeout: 5s

## Step 6: Deploy

1. Click **Deploy**
2. Wait 5-10 minutes for build and deployment
3. Once deployed, you'll get a URL like: `https://hi-events-xxxxx.koyeb.app`

## Step 7: Update Configuration

After deployment succeeds, update environment variables:

1. Go to your service settings
2. Update:
   ```
   VITE_API_URL_CLIENT = https://hi-events-xxxxx.koyeb.app/api
   ```
   (Replace `xxxxx` with your actual Koyeb URL)

3. Redeploy by going to **Deployments** → **Redeploy latest**

## Step 8: Verify It Works

1. Open your service URL in browser
2. You should see the Hi.Events login page
3. Try to sign up at `/auth/register`
4. If you get errors, check **Logs** in Koyeb dashboard

## Troubleshooting

### API returns 404
- Check logs: Click **Logs** tab
- Verify `VITE_API_URL_CLIENT` matches your Koyeb URL
- Redeploy after updating

### Database connection failed
- Check `DB_PASSWORD` matches in environment
- Make sure PostgreSQL addon is provisioned (check **Add-ons** tab)

### "Application not starting"
- Check **Logs** for error messages
- Common issue: missing secrets → add APP_KEY and JWT_SECRET

### Slow deployment
- First build takes 10-15 minutes (normal)
- Subsequent updates are faster

## Accessing the Application

**Frontend:** `https://hi-events-xxxxx.koyeb.app`
**API:** `https://hi-events-xxxxx.koyeb.app/api`
**API Docs:** `https://hi-events-xxxxx.koyeb.app/docs/api` (if Scramble enabled)

## Free Tier Limits

- ✅ 1 service instance (always running)
- ✅ 5GB PostgreSQL database
- ✅ 256MB Redis cache
- ✅ Auto SSL/HTTPS
- ✅ Auto scaling: 1-2 instances
- ❌ No credit card required

## Advanced: Custom Domain (Optional)

1. In service settings, click **Custom domain**
2. Add your domain
3. Update DNS records (Koyeb will show instructions)
4. SSL certificate auto-generated

## Getting Help

- Check logs: Koyeb Dashboard → Service → **Logs**
- Check application errors: `/api/health` endpoint
- GitHub Issues: https://github.com/Damarice/Hi.Events/issues

---

**That's it!** Your Hi.Events app is now live on Koyeb, completely free. 🚀
