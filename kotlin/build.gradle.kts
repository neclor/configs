group = ""
version = ""
description = ""

plugins {
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.kotlin.multiplatform)
    application
}

application {
    mainClass = "MainKt"
}

repositories {
    mavenCentral()
}

kotlin {
    jvmToolchain(24)
}

dependencies {
    implementation(libs.ktor.client.core)

    testImplementation(libs.kotlin.test)
}

tasks.test {
    useJUnitPlatform()
}
