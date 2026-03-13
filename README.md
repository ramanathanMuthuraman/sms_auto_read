# sms_spike

Flutter spike app for testing [`smart_auth`](https://pub.dev/packages/smart_auth) SMS flows on Android.

## What this app tests

- App signature generation (`getAppSignature`)
- SMS Retriever API (`getSmsWithRetrieverApi`)
- SMS User Consent API (`getSmsWithUserConsentApi`)
- Phone Number Hint API (`requestPhoneNumberHint`)

## Prerequisites

- Physical Android device (not emulator)
- Google Play Services available on device
- A second phone/SMS sender to send test OTP messages

This project already meets `smart_auth` Android requirements:

- Java 11
- Android Gradle Plugin >= 8.3.2
- Gradle >= 8.4
- Kotlin >= 1.8

## Run

```bash
flutter pub get
flutter run
```

## Test: SMS Retriever API

1. Tap **Get App Signature**.
2. Tap **Start Retriever API**.
3. Send SMS to the test device in this format:

```text
<#> Your OTP is 123456
<APP_SIGNATURE_FROM_APP>
```

4. App should auto-capture the OTP without extra permissions.

## Test: SMS User Consent API

1. Tap **Start User Consent API**.
2. Send an OTP SMS (include a 4-8 digit code by default).
3. Accept the Android consent dialog.
4. App should display extracted code and full SMS.

## Notes

- Default OTP regex is `\\d{4,8}` and can be changed in the UI.
- No `READ_SMS` permission is needed for these APIs.
- If OTP is not extracted, check regex and SMS format.
