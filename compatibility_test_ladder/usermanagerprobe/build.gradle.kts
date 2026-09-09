plugins { id("com.android.application") }

android {
    namespace = "com.example.duplikaladder.umprobe"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.duplikaladder.umprobe"
        minSdk = 23
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
            // Minification stays ON, as everywhere else in the ladder, so a Release result
            // means what it says.
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// No dependencies: this probe uses only android.os.UserManager. Nothing Google, nothing
// Duplika -- so the identical APK runs on the host and in a container and any difference is
// attributable to the virtualization layer.
dependencies { }
