plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.personal.fitness_tracker"
    // 36 because flutter_local_notifications compiles against it. Backward
    // compatible; targetSdk stays where it is, so runtime behaviour is
    // unchanged.
    compileSdk = 36
    // Pinned to the NDK already installed in the local SDK. The Android
    // cmdline-tools component is absent on this machine, so Gradle cannot
    // auto-download a different revision.
    ndkVersion = "28.2.13676358"

    compileOptions {
        // Required by flutter_local_notifications, which uses java.time to
        // schedule alerts and relies on desugaring for it below API 26.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.personal.fitness_tracker"
        minSdk = 26
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
