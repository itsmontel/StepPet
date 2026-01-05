# VirtuPet Waitlist Setup Guide

## ✅ Security First
Your Supabase keys are now stored securely on the server side using Netlify serverless functions. No keys are exposed in your client-side code!

---

## 📋 Setup Steps

### 1. Install Function Dependencies

In your terminal, navigate to the website directory and install dependencies:

```bash
cd website/netlify/functions
npm install
```

This installs the `@supabase/supabase-js` package needed for the serverless function.

---

### 2. Set Environment Variables in Netlify

1. Go to your **Netlify Dashboard**
2. Select your site
3. Go to **Site settings** → **Environment variables**
4. Click **Add a variable** and add these two:

   **Variable 1:**
   - **Key:** `SUPABASE_URL`
   - **Value:** `https://your-project-id.supabase.co`
   - (Get this from Supabase → Settings → API → Project URL)

   **Variable 2:**
   - **Key:** `SUPABASE_ANON_KEY`
   - **Value:** `your-anon-key-here`
   - (Get this from Supabase → Settings → API → anon public key)

5. Click **Save**

---

### 3. Deploy to Netlify

1. **Push your code to Git** (if using Git)
2. **Or drag & drop** the `website` folder to Netlify
3. Netlify will automatically:
   - Detect the `netlify/functions` folder
   - Install dependencies
   - Deploy your function

---

### 4. Test It!

1. Visit your deployed website
2. Try joining the waitlist from any form
3. Check Supabase → **Table Editor** → `waitlist` table
4. You should see the new entry with the `source` column!

---

## 🔍 How It Works

1. **User fills out form** → JavaScript calls `/`.netlify/functions/waitlist`
2. **Netlify function** → Receives request, uses secure environment variables
3. **Supabase** → Function inserts data into `waitlist` table
4. **Response** → Returns success/error to user

**No keys are ever exposed to the browser!** 🔒

---

## 📊 View Analytics

In Supabase, run these queries to see your analytics:

```sql
-- See which form converts best
SELECT * FROM waitlist_by_source;

-- See daily trends
SELECT * FROM waitlist_daily_signups;

-- See overall stats
SELECT * FROM waitlist_summary;
```

---

## 🐛 Troubleshooting

**Function not working?**
- Check Netlify → **Functions** tab → Look for errors
- Verify environment variables are set correctly
- Check function logs in Netlify dashboard

**Still using localStorage?**
- The function falls back to localStorage if the API call fails
- Check browser console for errors
- Make sure the function is deployed correctly

---

## ✅ Done!

Your waitlist is now secure and ready to collect signups! 🎉

