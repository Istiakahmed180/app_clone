plugins { id("com.android.application") }

android {
    namespace = "com.example.duplikaladder.isosvc"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.duplikaladder.isosvc"
        // bindIsolatedService() and instance names arrived in API 29.
        minSdk = 29
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }
    buildFeatures { buildConfig = true }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    signingConfigs { getByName("debug") }
    buildTypes {
        release {
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}
