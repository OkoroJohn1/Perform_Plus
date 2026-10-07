plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.perform.perform_plus"
    // flutter_secure_storage's compiled AAR metadata requires compiling
    // against API 37+ (confirmed: dropping this to flutter.compileSdkVersion,
    // 36, fails `checkReleaseAarMetadata` outright) -- this is a real
    // dependency requirement, not an arbitrary choice. Investigated and
    // reverted a change here that assumed 37 was an unreleased preview SDK;
    // it was wrong, see the "parsing the package" investigation elsewhere.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications requires this -- it uses java.time
        // APIs that need desugaring to run on the app's minSdk.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.perform.perform_plus"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // google_mlkit_text_recognition requires 21+. flutter.minSdkVersion
        // is currently 24, well above that, so left as the Flutter default
        // -- a hardcoded 21 here gets silently reverted back to this by
        // `flutter build`'s own project-template sync on every build.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            // "There was a problem parsing the package" on a real v0.2.3
            // install turned out to be a RED HERRING chase: short
            // obfuscated-looking resource names that collide case-
            // insensitively (res/9N.9.png vs res/9n.9.png) are present in
            // this app's release builds going back to v0.1.1 -- a version
            // confirmed installed successfully in the past -- so that
            // pattern was never actually fatal to Android's installer.
            // `adb install` on the real device gave the real answer:
            // `IOException: Requested internal only, but not enough space`.
            // The installer's generic UI dialog shows the same misleading
            // "parsing" message for a plain storage shortfall as it does
            // for an actually malformed package. compileSdk=37 (required by
            // flutter_secure_storage's AAR metadata) was also investigated
            // and ruled out. The real fix is reducing install size --
            // see `flutter build apk --split-per-abi` in the release
            // process, which matters far more than minification here.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
