import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = file("../key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use {
            load(it)
        }
    }
}

android {
    namespace = "com.forudyog.justcards"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.forudyog.justcards"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            val keyAliasValue = keystoreProperties["keyAlias"] as String?
            val keyPasswordValue = keystoreProperties["keyPassword"] as String?
            val storeFileValue = keystoreProperties["storeFile"] as String?
            val storePasswordValue = keystoreProperties["storePassword"] as String?

            if (keyAliasValue != null && keyPasswordValue != null &&
                storeFileValue != null && storePasswordValue != null) {
                create("release") {
                    keyAlias = keyAliasValue
                    keyPassword = keyPasswordValue
                    // storeFile path in key.properties is relative to android/ directory
                    storeFile = rootProject.file(storeFileValue)
                    storePassword = storePasswordValue
                }
            }
        }
    }

    buildTypes {
        release {
            // Use release signing config if it exists, otherwise fall back to debug signing
            signingConfig = signingConfigs.findByName("release")
                ?: signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
