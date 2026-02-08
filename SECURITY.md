# 🔒 SECURITY - READ THIS FIRST

## ⚠️ IMPORTANT: Sensitive Files Not Included

This repository does **NOT** include sensitive configuration files. You must set them up manually.

---

## 📋 Required Files (Not in Git)

### 1. Environment Configuration
```bash
cp .env.example .env
# Edit .env with your actual API keys
```

### 2. Firebase Configuration
- Download `google-services.json` from [Firebase Console](https://console.firebase.google.com/project/rurboo-prod)
- Place in: `android/app/google-services.json`

### 3. Release Signing (For Play Store)
```bash
# Generate keystore
keytool -genkey -v -keystore ~/rurboo-driver-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias rurboo-driver

# Create android/key.properties with:
# storePassword=YOUR_PASSWORD
# keyPassword=YOUR_PASSWORD
# keyAlias=rurboo-driver
# storeFile=/path/to/rurboo-driver-release.jks
```

---

## 🔑 API Keys to Update

### Before Running App:
- [ ] `.env`: Add Google Maps API Key
- [ ] `android/app/google-services.json`: Download from Firebase

### Before Production:
- [ ] `lib/core/constants/payment_keys.dart`: Replace test key with LIVE Razorpay key
- [ ] `android/app/src/main/AndroidManifest.xml` (line 50): Update Google Maps API key with production-restricted key
- [ ] `android/key.properties`: Create for release signing

---

## 📖 Full Documentation

See [`security_guide.md`](file:///Users/adarshkumarpandey21/.gemini/antigravity/brain/afe09826-e89b-4abd-9a06-c701120f7ee9/security_guide.md) in artifacts for complete security documentation.

---

## ✅ Verification

**Check that sensitive files are ignored:**
```bash
git check-ignore -v .env android/app/google-services.json
```

**Should output:**
```
.gitignore:4:.env
.gitignore:7:android/app/google-services.json
```

If not, **DO NOT COMMIT**. Fix `.gitignore` first!

---

## 🚨 Never Commit These Files

- ❌ `.env`
- ❌ `android/app/google-services.json`
- ❌ `android/key.properties`
- ❌ `*.jks` or `*.keystore`

These files contain sensitive credentials and are properly gitignored.
