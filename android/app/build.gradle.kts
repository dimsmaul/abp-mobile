plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Apply google-services only when the config file is present so a clean
// clone still builds. The file must include client entries for both the
// release applicationId (com.mobile.app.mobile) and the debug variant
// (com.mobile.app.mobile.debug) — Firebase Console "Add app" lets you
// register both under one project, then the downloaded google-services.json
// bundles both clients.
val googleServicesJson = file("google-services.json")
if (googleServicesJson.exists()) {
    apply(plugin = "com.google.gms.google-services")
}

android {
    namespace = "com.mobile.app.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.mobile.app.mobile"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Default label — gets overridden per build type below.
        manifestPlaceholders["appLabel"] = "FieldTrack"
    }

    buildTypes {
        getByName("release") {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            manifestPlaceholders["appLabel"] = "FieldTrack"
        }
        getByName("debug") {
            // Suffix the appId so a debug build installs alongside a release
            // build instead of overwriting it. Pair with a distinct label so
            // the launcher icon is easy to tell apart.
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
            manifestPlaceholders["appLabel"] = "FieldTrack Debug"
        }
    }
}

flutter {
    source = "../.."
}
