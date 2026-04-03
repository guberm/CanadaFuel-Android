# Data Safety Declaration

Category: App content > Data safety

## Recommended declaration baseline
Use this as a working draft and validate in Play Console with your final SDK configuration.

- Data collected:
  - Location (used to detect nearest city)
  - Device or app identifiers (via ads SDK, as applicable)
  - App interactions or diagnostics (only if enabled by SDK defaults)
- Data shared:
  - Potentially with advertising SDK providers for ad delivery and measurement
- Security:
  - Data in transit protected by HTTPS for API calls
- User control:
  - Location and notifications are permission-based and can be revoked by user

## Evidence in app
- Geolocation package used for nearest city logic.
- AdMob SDK integrated and banner ads displayed.
- Shared preferences used for local settings persistence.

## Action checklist
1. Open Data safety form and complete each data type section.
2. Mark collection and sharing based on actual SDK behavior in production.
3. Verify encryption-in-transit and deletion/control statements are accurate.
4. Keep this declaration synchronized with your privacy policy text.
