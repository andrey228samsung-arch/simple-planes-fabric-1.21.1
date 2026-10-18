# Building Simple Planes (Fabric 1.21.1)

This is a source port in progress; it is **not yet a verified, installable mod JAR**.

## Requirements

- JDK 21
- Internet access for the first build, so Gradle can download Fabric Loom, Minecraft mappings/libraries, Fabric Loader, and Fabric API.
- Gradle 8.14.6 (the included helper scripts detect an extracted `../gradle-8.14.6/` directory, or use Gradle from `PATH`).

## Windows

1. Extract this project folder.
2. Extract `gradle-8.14.6-bin.zip` beside the project folder so `../gradle-8.14.6/bin/gradle.bat` exists, or install Gradle 8.14.6 and add it to `PATH`.
3. Install/select JDK 21 and ensure `java -version` reports version 21.
4. Run `build.bat` from the project folder or double-click it.
5. If the build succeeds, the mod JAR will be under `build/libs/`.

## Linux/macOS

Run `./build.sh` from a terminal with JDK 21 and Gradle 8.14.6 available.

## CI build

A GitHub Actions workflow is included at `.github/workflows/build.yml`. After pushing this source tree to a GitHub repository, run the **Build Simple Planes (Fabric 1.21.1)** workflow. A successful run publishes the JAR as a workflow artifact for 14 days.

## Important

The wrapper (`gradlew` / `gradlew.bat`) downloads its Gradle distribution from `services.gradle.org`. The helper scripts can use an already extracted Gradle distribution, but they cannot bypass Maven downloads: Fabric Loom and Minecraft/Fabric dependencies still need network access. A successful Gradle startup is not proof that the mod compiled. Only treat the JAR as usable after `build` succeeds and it has been tested in a Fabric 1.21.1 client/server.
