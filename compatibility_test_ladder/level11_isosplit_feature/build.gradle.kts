plugins { id("com.android.dynamic-feature") }

android {
    namespace = "com.example.duplikaladder.isosplit.feature"
    compileSdk = 36

    defaultConfig {
        minSdk = 23
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    implementation(project(":level11_isosplit"))
}
