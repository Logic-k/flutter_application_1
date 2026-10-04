import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// 서명 키 정보 파일. -PkeyPropertiesFile=<경로>로 바꿀 수 있다(키가 없을 때의 동작 확인용).
val keyPropertiesFile = rootProject.file(
    (project.findProperty("keyPropertiesFile") as String?) ?: "key.properties"
)
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}
// 키 정보가 있을 때만 release 서명 설정을 만든다. 키가 없어도 Gradle 구성과 debug·profile
// 빌드는 되지만, release 산출물은 파일 끝의 검사가 막는다(LAUNCH_AUDIT P0-14).
val hasReleaseKey = keyPropertiesFile.exists() && keyProperties["storeFile"] != null

android {
    namespace = "com.teammemorylink.memorylink"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // key.properties가 없을 때 as String 캐스팅으로 Gradle 구성 전체가 실패하지 않게 한다.
    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                keyAlias = keyProperties["keyAlias"] as String
                keyPassword = keyProperties["keyPassword"] as String
                storeFile = (keyProperties["storeFile"] as String).let { file(it) }
                storePassword = keyProperties["storePassword"] as String
            }
        }
    }

    defaultConfig {
        applicationId = "com.teammemorylink.memorylink"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }


    buildTypes {
        release {
            // 업로드 키가 있을 때만 서명한다. 예전처럼 debug 키로 조용히 서명한 "release"를
            // 만들지 않는다. 서명 없는 release 점검(최적화·매니페스트)이 필요하면
            // -PallowUnsignedRelease=true 를 준다. 그 산출물은 스토어에 올릴 수 없다.
            if (hasReleaseKey) {
                signingConfig = signingConfigs.getByName("release")
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// release 서명 키가 없으면 release 산출물을 만들지 않는다(LAUNCH_AUDIT P0-14).
gradle.taskGraph.whenReady {
    val wantsRelease = allTasks.any { task ->
        task.project == project && Regex("(assemble|bundle|package)Release").matches(task.name)
    }
    val allowUnsigned = project.findProperty("allowUnsignedRelease") == "true"
    if (wantsRelease && !hasReleaseKey && !allowUnsigned) {
        throw GradleException(
            "release 서명 키가 없습니다: ${keyPropertiesFile.path}. 업로드 키(key.properties)를 " +
                "준비하거나, 스토어에 올리지 않을 점검용 빌드면 -PallowUnsignedRelease=true 를 주세요."
        )
    }
}

flutter {
    source = "../.."
}
