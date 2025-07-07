import com.android.build.gradle.LibraryExtension

buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        // Make sure the required version is here if you used it.
        classpath("com.android.tools.build:gradle:8.1.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library")) {
            extensions.configure<LibraryExtension>("android") {
                if (namespace == null) {
                    namespace = "com.example.${project.name.replace("-", "_")}"
                }
            }
        }
    }
}

// Setting a common build path
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    layout.buildDirectory.set(newBuildDir.dir(name))
    evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
