plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.smart_fitting_room"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Cambia este ID si lo quieres publicar
        applicationId = "com.example.smart_fitting_room"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Firmando con debug para desarrollo
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

/*
 ============================================================
 ▌ FIX PARA ERROR:
 ▌   Dependency "androidx.activity:activity-ktx:1.11.0"
 ▌   requires Android Gradle Plugin 8.9.1 but project uses 8.7.3
 ▌
 ▌ Solución:
 ▌  Forzar una versión compatible (1.9.0) para evitar el fallo.
 ============================================================
*/
configurations.all {
    resolutionStrategy {
        force("androidx.activity:activity:1.9.0")
        force("androidx.activity:activity-ktx:1.9.0")
    }
}
