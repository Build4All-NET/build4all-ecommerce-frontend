import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration

    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.build4all.front"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.build4all.opl1.test" // later you’ll change per app
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

  signingConfigs {
    create("release") {
        keyAlias = keystoreProperties.getProperty("keyAlias")
        keyPassword = keystoreProperties.getProperty("keyPassword")
        storePassword = keystoreProperties.getProperty("storePassword")

        val storeFilePath = keystoreProperties.getProperty("storeFile")
        if (!storeFilePath.isNullOrBlank()) {
            storeFile = file(storeFilePath) // relative to android/app because you're in app module
        }
    }
}


    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release") // ✅ IMPORTANT
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    implementation("androidx.core:core-splashscreen:1.0.1")
    
}

flutter {
    source = "../.."
}
