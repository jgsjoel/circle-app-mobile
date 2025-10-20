// Import the necessary Android Gradle Plugin class for type-safe configuration
import com.android.build.gradle.BaseExtension
import org.gradle.api.file.Directory

plugins {
    // ENSURE the Android Application Plugin is defined here.
    // Use apply false to only declare the plugin version for subprojects.
    id("com.android.application") version "8.7.0" apply false
    // You should also define the Kotlin plugin here if used in your project
    id("org.jetbrains.kotlin.android") version "1.8.22" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// --- Custom Build Directory Setup (No change needed) ---

// Define the new root build directory outside the android folder (e.g., ../../build)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // Set each subproject's build directory to a unique folder inside the new root (e.g., ../../build/app)
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// --- Type-Safe Namespace Fix (MUST COME BEFORE evaluationDependsOn) ---

subprojects {
    afterEvaluate {
        // Use the type-safe method to find the Android extension
        project.extensions.findByName("android")?.let { extension ->
            // Safely cast the generic extension to the required type
            (extension as? BaseExtension)?.let { androidExtension ->
                // If a subproject (plugin) is missing a namespace, assign one.
                if (androidExtension.namespace.isNullOrEmpty()) {
                    // project.group returns Any!, so use .toString() to be safe.
                    androidExtension.namespace = project.group.toString()
                }
            }
        }
    }
}

// --- Dependency Ordering (MOVED TO THE END) ---
// This must be placed AFTER all afterEvaluate blocks
subprojects {
    project.evaluationDependsOn(":app")
}

// --- Clean Task (No change needed) ---

tasks.register<Delete>("clean") {
    // Delete the root build directory as defined above
    delete(rootProject.layout.buildDirectory)
}