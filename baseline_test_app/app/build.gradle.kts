plugins {
    id("com.android.application")
}

android {
    namespace = "com.example.duplikabaseline"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.duplikabaseline"
        minSdk = 23
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            // Use the local debug keystore so the release variant is installable
            // on the physical test device without introducing a private key.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}
