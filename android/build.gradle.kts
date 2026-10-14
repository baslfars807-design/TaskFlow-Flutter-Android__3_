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
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Align Java compile tasks across Android plugin modules after AGP has configured
// their variants. This fixes file_picker's Kotlin JVM 1.8 vs Java JVM 11 mismatch.
gradle.projectsEvaluated {
    allprojects {
        if (name != "app") {
            tasks.withType<org.gradle.api.tasks.compile.JavaCompile>().configureEach {
                sourceCompatibility = "1.8"
                targetCompatibility = "1.8"
            }
        }
    }
}
