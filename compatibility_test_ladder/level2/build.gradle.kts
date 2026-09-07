plugins { id("com.android.application") }

android {
    namespace = "com.example.duplikaladder.level2"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.duplikaladder.level2"
        minSdk = 23
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }
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
