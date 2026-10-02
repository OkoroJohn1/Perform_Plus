package com.perform.perform_plus

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity, not FlutterActivity -- local_auth's biometric
// prompt (FingerprintManager/BiometricPrompt) requires a FragmentActivity.
class MainActivity : FlutterFragmentActivity()
