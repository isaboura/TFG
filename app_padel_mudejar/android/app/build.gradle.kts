plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.app_padel_mudejar"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // 1. FORZAMOS A JAVA A USAR LA VERSIÓN 17
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // 2. FORZAMOS A KOTLIN A USAR LA VERSIÓN 17
    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.clubpadelmudejar.app"
        minSdk = flutter.minSdkVersion          // Dejamos el 21 fijo para que no falle en el S25 Ultra
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = file("/Users/ismail/key.jks")
            storePassword = "android"
            keyAlias = "key"
            keyPassword = "android"
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
