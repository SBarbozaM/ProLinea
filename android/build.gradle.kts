//santiago-19/11/25
allprojects {
    repositories {
        google()
        mavenCentral()
        jcenter() // solo lectura, ya no se actualiza pero aún sirve
        maven {"https://jitpack.io" }

        // Mirrors por si tu red bloquea dl.google.com
        maven { "https://maven.google.com" }
        maven { "https://storage.googleapis.com/download.flutter.io" }
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
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
