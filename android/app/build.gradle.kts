plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Apply google-services only when:
//   1. google-services.json exists (clean clones still build)
//   2. The build is for a variant whose applicationId matches an entry in
//      that JSON — by default the release applicationId. Debug builds
//      use a `.debug` applicationIdSuffix so the plugin fails the build
//      with "No matching client found" unless the debug variant is also
//      registered in Firebase Console. We skip the plugin entirely on
//      debug to keep the dev loop fast; FCM only works on release.
val googleServicesJson = file("google-services.json")
val isReleaseBuild = gradle.startParameter.taskNames.any { name ->
    val n = name.lowercase()
    n.contains("release") || n.contains("bundlerelease") || n.contains("assemblerelease")
}
if (googleServicesJson.exists() && isReleaseBuild) {
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
