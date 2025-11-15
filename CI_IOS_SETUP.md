# iOS Build Automation

This project now includes a GitHub Actions workflow (`.github/workflows/ios-build.yml`) that builds and signs the iOS app on every push to `main`/`master` or via manual dispatch. To use it:

1. **Create a new GitHub repository** and push the contents of `parent_app` (this directory) as the root of that repo:
   ```bash
   git init
   git add .
   git commit -m "Initial parent app"
   git remote add origin <YOUR_REPO_URL>
   git push -u origin main
   ```

2. **Add the required GitHub Secrets** under *Settings → Secrets and variables → Actions*:
   - `IOS_CERTIFICATE_BASE64` – base64 string of your signing certificate (`.p12`).
   - `IOS_CERTIFICATE_PASSWORD` – password for the `.p12` file.
   - `IOS_PROVISION_PROFILE_BASE64` – base64 string of the provisioning profile (`.mobileprovision`).
   - `IOS_TEAM_ID` – Apple Developer Team ID (used to update `ExportOptions.plist`).
   - Optional TestFlight upload: `APP_STORE_CONNECT_API_KEY` and `APP_STORE_CONNECT_ISSUER_ID`.

3. **Update bundle identifiers / provisioning**:
   - The default bundle id is `com.example.parentApp`; change it in `ios/Runner.xcodeproj/project.pbxproj` (and match your provisioning profile).
   - `ios/ExportOptions.plist` contains placeholders that the workflow replaces based on your secrets.

4. **Trigger the workflow**:
   - Push to `main`/`master` or run it manually from the *Actions* tab (`Build iOS App`).
   - The signed `.ipa` is uploaded as the `parent-app-ios` artifact.

5. **Troubleshooting**:
   - Ensure CocoaPods dependencies are committed (`ios/Podfile.lock`).
   - If the workflow cannot find the provisioning profile, verify the base64 secret and that it matches your bundle ID.
   - For local signed builds, run `flutter build ipa --export-options-plist=ios/ExportOptions.plist` on macOS with the same certificate/profile.

This mirrors the Flutter student app pipeline so both apps follow the same release process.
