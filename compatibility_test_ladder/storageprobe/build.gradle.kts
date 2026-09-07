plugins { id("com.android.application") }

android {
    namespace = "com.example.duplikaladder.storageprobe"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.duplikaladder.storageprobe"
        minSdk = 23
        targetSdk = 35
        versionCode = 2
        versionName = "1.1"
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
