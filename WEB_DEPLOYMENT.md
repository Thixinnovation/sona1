# 🌐 Web Deployment Guide

This application is now configured for web deployment using GitHub Pages!

## ✅ What's been configured

### 1. **pubspec.yaml** - Web-compatible dependencies
- Platform-specific dependencies have been configured
- Mobile-only packages (NFC, mobile_scanner, agora, geolocator) are excluded on web
- All core packages work perfectly on web

### 2. **web/index.html** - Production-ready
- Updated meta tags for PWA support
- Viewport configuration for responsive design
- SEO meta tags included
- Security headers configured

## 🚀 Quick Start - Local Testing

```bash
# Enable web (one-time)
flutter config --enable-web

# Run in development mode
flutter run -d chrome

# Build for production
flutter build web --release
```

## 📝 GitHub Pages Setup Instructions

### Step 1: Enable GitHub Pages
1. Go to your repository Settings
2. Navigate to **Pages** (left sidebar)
3. Set **Source** to "GitHub Actions"
4. Click Save

### Step 2: Create GitHub Actions Workflow
Create `.github/workflows/deploy-web.yml`:

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.0'
        channel: 'stable'
    
    - name: Enable web
      run: flutter config --enable-web
    
    - name: Get dependencies
      run: flutter pub get
    
    - name: Build web
      run: flutter build web --release --base-href=/Thix_id/
    
    - name: Deploy to GitHub Pages
      uses: peaceiris/actions-gh-pages@v3
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        publish_dir: ./build/web
```

### Step 3: Configure Supabase CORS
1. Go to Supabase Dashboard → Settings → API
2. Add these URLs to **Allowed Origins**:
   - `https://Thixinnovation.github.io`
   - `http://localhost:5000` (for local testing)

## 🔗 Access Your Deployed App

- **Default URL**: `https://Thixinnovation.github.io/Thix_id/`
- **Check deployment**: Go to Actions tab → Latest workflow run

## 📦 What Gets Deployed

The workflow compiles and deploys:
- ✅ Compiled Flutter web app
- ✅ All static assets (images, fonts, icons)
- ✅ JavaScript runtime
- ✅ Service worker (for PWA features)

## 🔒 Security Checklist

- [ ] Supabase CORS configured with GitHub Pages URL
- [ ] No sensitive keys in code (use environment variables)
- [ ] Repository is public (for free GitHub Pages)
- [ ] base-href matches repository name: `/Thix_id/`

## ⚙️ Troubleshooting

### Blank page after deployment
```
✗ Check browser console (F12) for errors
✗ Verify Supabase is initialized correctly
✗ Clear cache (Ctrl+Shift+Delete)
```

### CORS errors
```
✗ Add GitHub Pages URL to Supabase CORS origins
✗ Check Supabase URL in lib/supabase/supabase_config.dart
```

### Assets not loading
```
✗ Ensure base-href is correct: /Thix_id/
✗ Rebuild with: flutter build web --release --base-href=/Thix_id/
```

## 📞 Next Steps

1. ✅ Merge `feat/web-deployment` branch to `main`
2. ✅ GitHub Actions will auto-build and deploy
3. ✅ Monitor Actions tab for build status
4. ✅ Test at https://Thixinnovation.github.io/Thix_id/
5. ✅ Configure custom domain (optional)

---

**App is now production-ready for web!** 🎉
