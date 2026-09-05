allprojects {
    repositories {
        google()
        mavenCentral()
        // FreeReflection (a Bcore runtime dependency) is published only on JitPack.
        // Build-time resolution only; the app never downloads code at runtime.
        maven { url = uri("https://www.jitpack.io") }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
