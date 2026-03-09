import com.android.build.gradle.BaseExtension
import com.android.build.gradle.LibraryExtension
import com.android.build.gradle.AppExtension
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
    afterEvaluate {
        // We use 'findByName' to safely check if the project is an Android module
        val androidExtension = project.extensions.findByName("android")
        if (androidExtension is BaseExtension) {
            // Fix 1: Use a String for compileSdkVersion to satisfy the type requirement
            // Some environments prefer "android-35", others accept 35. 
            // "35" as a string is the most compatible middle ground.
            androidExtension.compileSdkVersion("android-35")

            // Fix 2: Properly set the namespace if it's missing (Isar fix)
            if (androidExtension.namespace == null) {
                androidExtension.namespace = "com.${project.name.replace("-", ".")}"
            }

            // Fix 3: Iterate through configurations to fix targetSdkVersion
            // This ensures all sub-libraries recognize the 'lStar' attribute
            when (androidExtension) {
                is LibraryExtension -> {
                    androidExtension.defaultConfig.targetSdk = 35
                }
                is AppExtension -> {
                    androidExtension.defaultConfig.targetSdk = 35
                }
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
