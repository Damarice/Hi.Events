# Hi.Events Testing Guide - Post-Deployment

## Service Status
✅ **Deployed**: https://hi-events-g3dx.onrender.com
✅ **Frontend SSR**: Running at port 5678
✅ **Backend API**: Running at /api endpoint
✅ **Database**: Connected
✅ **SaaS Mode**: Enabled

---

## Critical Test #1: Super Admin Login

### Steps:
1. Open in browser: https://hi-events-g3dx.onrender.com/auth/login
2. Enter credentials:
   - **Email**: `flynnduerrel@gmail.com`
   - **Password**: `Password123!`
3. Click "Login"

### Expected Result:
- ✅ Login successful
- ✅ Redirected to dashboard or home page
- ✅ No error messages
- ✅ JWT token in browser storage (check DevTools → Application → Local Storage)

### If It Fails:
**What to look for in browser console (F12 → Console tab):**
- CORS errors? → API URL misconfiguration
- 401/403 errors? → Authentication failed, check database
- Network errors? → Backend not responding, check Render logs
- "Cannot reach API"? → Frontend/backend not communicating

---

## Critical Test #2: User Registration

### Steps:
1. Open in browser: https://hi-events-g3dx.onrender.com/auth/register
2. Fill in form:
   - **First Name**: `Test`
   - **Last Name**: `User`
   - **Email**: `test@example.com` (use unique email)
   - **Password**: `Password123!`
   - **Confirm Password**: `Password123!`
   - Check "Receive product updates" (optional)
3. Click "Register"

### Expected Result (SaaS Mode):
- ✅ Account created
- ✅ Redirected to email verification page
- ✅ You'll see message about verifying email
- ✅ New account in database with `email_verified_at = NULL`

### Expected Result (Non-SaaS):
- ✅ Account created
- ✅ Auto-logged in
- ✅ Redirected to dashboard
- ✅ Email already verified

### If It Fails:
Check browser console for:
- Validation errors? → Fix form data
- Email already exists error? → Use different email
- Internal server error (500)? → Check Render backend logs
- Network error? → Frontend/backend communication issue

---

## Critical Test #3: Verify Account Was Created

After registering, check the database by running on Render:

```bash
# Check if the account exists
php artisan setup:check-accounts

# For the newly registered user, check directly:
# (This would need database access or API call)
```

---

## Data Flow Verification

### Frontend → Backend Communication Check

**In browser DevTools (F12):**

1. Open **Network** tab
2. Attempt login or registration
3. Look for requests to:
   - ✅ `https://hi-events-g3dx.onrender.com/api/auth/login` (POST)
   - ✅ `https://hi-events-g3dx.onrender.com/api/auth/register` (POST)
4. Check response status:
   - 200/201 = Success
   - 401/403 = Auth failure
   - 422 = Validation error
   - 500 = Server error
   - Network error = Connection issue

---

## Key Credentials for Testing

### Pre-Created Super Admin Accounts
```
Email: flynnduerrel@gmail.com
Password: Password123!
Status: SUPERADMIN (full access)

---

Email: menganyidamarice@gmail.com
Password: Password123!
Status: SUPERADMIN (full access)
```

### Test User Account
Create during registration test with any email/password combination.

---

## Environment Configuration Verification

### Check Frontend Variables Were Set
Look at rendered HTML source (View Page Source):
- Search for: `VITE_API_URL_CLIENT`
- Should show: `https://hi-events-g3dx.onrender.com/api`

### Check Backend SaaS Mode
Visit: https://hi-events-g3dx.onrender.com/api/health (if endpoint exists)
Or check Render logs for: `APP_SAAS_MODE_ENABLED=true`

---

## Troubleshooting Checklist

| Issue | Check | Solution |
|-------|-------|----------|
| Login page loads but can't login | Browser console for errors | Check credentials, verify API reachable |
| "Cannot reach API" error | Check API URL in frontend | Verify `VITE_API_URL_CLIENT` is set correctly |
| 502 Bad Gateway | Render logs | Wait, service may still be starting |
| Registration fails with 422 | Network tab response | Check validation errors in response |
| Account created but can't login | Database check | Run `php artisan setup:check-accounts` |
| Email verification not working | Check queue/scheduler | Look for email job logs |

---

## Success Indicators

✅ All tests pass when:
1. Super admin can login with provided credentials
2. New users can register with valid data
3. Frontend makes successful API calls
4. No 502/503 errors appearing
5. Accounts are created in database
6. Browser console shows no CORS errors

---

## Next Steps if All Tests Pass

1. ✅ Provide client with:
   - Super admin credentials: `flynnduerrel@gmail.com` / `Password123!`
   - Registration URL: `https://hi-events-g3dx.onrender.com/auth/register`
   - Login URL: `https://hi-events-g3dx.onrender.com/auth/login`

2. ✅ Have client test:
   - Registration with their email
   - Email verification process
   - Creating events as organizer
   - Setting up tickets/products
   - Testing checkout flow

3. ✅ Monitor for issues:
   - Check Render logs for errors
   - Monitor email delivery
   - Test with multiple browsers

---

## Running Remote Commands

To execute commands on Render, you'll need shell access. Render doesn't provide direct SSH, but you can:

1. **Check logs in Render Dashboard:**
   - Go to your service
   - Click "Logs" tab
   - Search for error messages

2. **Via Laravel Tinker (if available):**
   ```bash
   php artisan tinker
   DB::table('users')->where('email', 'flynnduerrel@gmail.com')->first();
   ```

3. **Via Database Connection:**
   - Use PostgreSQL client to connect directly to Render database
   - Check tables: `users`, `accounts`, `account_user`

---

## Browser DevTools Tips

### To Access Console:
- Windows/Linux: Press `F12` or `Ctrl+Shift+I`
- Mac: Press `Cmd+Option+I`

### Check Network Requests:
1. Open DevTools
2. Click "Network" tab
3. Refresh page or perform action
4. Look for requests to `/api/` endpoints
5. Click on request to see full details, response, headers

### Check Local Storage (for JWT token):
1. Open DevTools
2. Click "Application" tab
3. Click "Local Storage"
4. Look for `Bearer` token or `access_token`
5. Token should be present after successful login

### Check Errors:
1. Open DevTools
2. Click "Console" tab
3. Look for red error messages
4. Click on error to see full stack trace

---

## Report Results

After testing, provide:
1. ✅ Can super admin login? (Yes/No, errors if any)
2. ✅ Can register new user? (Yes/No, errors if any)
3. ✅ Any browser console errors? (Screenshot/details)
4. ✅ Any network failures? (Screenshot/details)
5. ✅ Status page loads correctly? (Yes/No)

