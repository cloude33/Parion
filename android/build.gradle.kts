allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // Sadece projenin ana dizini altındaki alt projelerin build dizinini değiştir.
    // Farklı sürücüdeki (C:\... pub cache) pluginlerin kendi yerlerinde build olmasına izin ver.
    if (project.projectDir.absolutePath.startsWith(rootProject.projectDir.absolutePath)) {
        val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }
}

subprojects {
    project.evaluationDependsOn(":app")
    
    // Suppress obsolete Java version warnings
    tasks.withType<JavaCompile>().configureEach {
        options.compilerArgs.addAll(listOf("-Xlint:-options"))
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
