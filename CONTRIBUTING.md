
# Contribution tips

## How to run and build flutter app
`flutter clean`  
`flutter pub get`    
`flutter pub upgrade --major-versions`
`dart run build_runner build --delete-conflicting-outputs`  

## How to release
`git tag v0.0.2`      
`git push --tags`    
`flutter build appbundle --release`  

## CI builds (GitHub Actions)
Workflow **Build (Android, iOS, Windows)** (`.github/workflows/build.yml`):
- **Trigger:** push/PR to `main`, or manually (`workflow_dispatch`).
- **Release builds:** Android APK, Windows exe+dll. iOS is simulator only (no release for simulator).
- **Android** requires GitHub Secrets on every run:
  - `ANDROID_KEYSTORE_BASE64` – keystore (.jks) as base64 (on Linux: `base64 -w0 keystore.jks`)
  - `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`

## Deploy (Google Play & App Store)
Workflow **Deploy** (`.github/workflows/deploy.yml`):
- **Trigger:** tag `v*` (`git tag v1.0.0` → `git push --tags`) or manually (`workflow_dispatch`).
- On manual run: choose track (internal / alpha / beta / production), whether to deploy Android and/or iOS.

### Google Play
- **Secrets:** same as build + `GOOGLE_PLAY_CREDENTIALS` – JSON key from Google Play service account (Cloud Console → Service Accounts → Create Key → JSON). App must exist in Play Console and service account must have access.

### App Store (TestFlight)
- **Secrets:**  
  - `BUILD_CERTIFICATE_BASE64` – Apple Distribution certificate (.p12) as base64  
  - `P12_PASSWORD` – .p12 password  
  - `BUILD_PROVISION_PROFILE_BASE64` – App Store provisioning profile (.mobileprovision) as base64  
  - `APPSTORE_API_PRIVATE_KEY` – contents of .p8 key from App Store Connect API  
- **Variables:**  
  - `APPSTORE_ISSUER_ID`, `APPSTORE_API_KEY_ID` – from App Store Connect → Users and Access → Keys  
  - `IOS_PROFILE_NAME` – exact provisioning profile name for `eu.mobisync.home` (as in Developer Portal)
