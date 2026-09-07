plugins { id("com.android.application") }

android {
    namespace = "com.example.duplikaladder.level7fixture"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.duplikaladder.level7fixture"
        minSdk = 23
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
        externalNativeBuild {
            cmake {
                cppFlags += ""
            }
        }
    }
    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }
    splits {
        abi {
            isEnable = true
            reset()
            include("arm64-v8a", "x86_64")
            isUniversalApk = false
        }
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
