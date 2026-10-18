# Simple Planes Fabric 1.21.1 port — incomplete source port

This archive is a work-in-progress source migration from the supplied Simple Planes 1.19.2 JAR. It is **not a ready-to-install JAR** and has not passed compilation or a Minecraft launch test.

## Existing migration work
- Updated target to Minecraft 1.21.1, Java 21, Fabric Loader 0.16.5, Fabric API 0.102.1+1.21.1, Loom 1.7.4 and Gradle 8.8.
- Updated `fabric.mod.json` dependency bounds and Mixin compatibility level.
- Migrated many `ResourceLocation` constructors and registry references to 1.21.1 forms.
- Reworked creative tab registration and item-group population.
- Migrated entity type construction to `EntityType.Builder`.
- Added a `DataComponents.CUSTOM_DATA` helper for plane item entity data.
- Updated several block-entity and `ItemStack` serialization paths to use registry access.
- Removed the legacy EnchantmentHelper overwrite mixin and migrated armor-upgrade enchantment lookup to registry holders.
- Migrated old Mojang `Vector3f`/quaternion usage to JOML types, including plane orientation math and camera transforms.
- Updated dynamic block-item model lookups to `ModelResourceLocation.inventory(ResourceLocation)`.

## Networking migration attempted in this increment
- Added a typed `CustomPacketPayload` wrapper for the existing packet byte formats.
- Added `PayloadTypeRegistry.playC2S()` / `playS2C()` registrations and switched receiver registration to typed payload handlers.
- Updated client-to-server and server-to-client sends to send typed payload instances.
- Updated the custom plane spawn packet to use a clientbound custom-payload packet.
- Replaced direct uses of Fabric's old `PacketByteBufs.create()` helper with `FriendlyByteBuf` backed by Netty buffers.

This is a source-level migration only. The new networking code still needs compilation and runtime verification; the generic byte-wrapper is a compatibility bridge, not a final optimized packet schema. Other high-risk areas still need API validation, including entity spawn-data handling, screen-handler factories, render/mixin method signatures, and registry-aware item/NBT serialization.

## Recipe migration in this increment
- Replaced the legacy custom recipe serializer methods (`fromJson` / `fromNetwork` / `toNetwork`) with the Minecraft 1.21.1 `MapCodec` and `StreamCodec` API.
- Added a `RecipeInput` implementation for the workbench's two input slots and updated recipe methods to accept registry access where required by 1.21.1.
- Registered the custom recipe type through the built-in recipe-type registry.
- Updated workbench menu code to unwrap `RecipeHolder` values and handle an empty recipe list without indexing it.
- Migrated recipe result JSON objects from the legacy `item` field to the newer `id` field. All recipe JSON files passed a JSON syntax parse check; this does not validate them against Minecraft's runtime codecs.

## Build verification blocker
Attempted `./gradlew build --no-daemon` again after the networking changes. The wrapper still cannot download Gradle 8.8 because `services.gradle.org` cannot be resolved (`UnknownHostException`). No compilation result is available. The current environment therefore cannot establish whether the source compiles or produce a verified mod JAR.

## Next required work
1. Compile and validate the typed networking bridge and recipe migration against the real Minecraft/Fabric dependencies.
2. Resolve remaining screen-handler, spawn-data, renderer and mixin API changes.
3. Build with Gradle, fix compiler errors iteratively, then launch a test instance and verify plane spawning, riding, controls, upgrades, inventories and multiplayer packet flow.

**Status:** incomplete source port; no installable JAR has been produced or verified.

## Extended screen-handler migration in this increment
- Migrated the three extended menu types to typed opening data (`VAR_INT` for plane IDs and UTF-8 strings for storage type).
- Updated screen-opening factories to return typed data instead of writing raw bytes, and updated client menu constructors to consume decoded data.
- Removed a client-only `Minecraft` dependency from the shared plane-inventory menu constructor by resolving the entity through the supplied player inventory.
- This removes another 1.20-era screen-handler API pattern, but still awaits compilation against the exact Fabric API dependency.


## Client GUI migration in this increment
- Migrated the four container screens from the pre-1.20 `PoseStack` screen method signatures to the `GuiGraphics` signatures used by Minecraft 1.21.1. Existing upgrade-specific drawing continues to receive `graphics.pose()` to avoid changing the model/upgrade rendering contract in this pass.
- Migrated the upgrade-removal selection list's decoration and entry render signatures to `GuiGraphics`, and changed its title draw call to `GuiGraphics.drawString`.
- Updated the HUD callback method to accept `GuiGraphics` and `DeltaTracker`, extracting the pose stack for the existing custom HUD drawing.
- Removed a redundant explicit render call for the upgrade-removal list, because it is already registered as a screen widget and is rendered by the parent screen.

These are source-level changes only. They have not been compiled against Minecraft 1.21.1 because the Gradle distribution/dependencies remain unavailable in this environment. Some adjacent rendering helper APIs and widget constructors may still require migration; do not treat this archive as a tested build.

## Client registration and defensive checks (progress 12)
- Fixed the item tint registration call to use Fabric's `ColorProviderRegistry.ITEM` API instead of a nonexistent `ColorProviderBuiltInRegistries` symbol, which would prevent compilation.
- Removed stale `PacketByteBufs` imports from three packets after the networking bridge migration.
- Added null guards around HUD rendering and the inventory key handler so those paths do not dereference a missing client player during loading or screen transitions.

These changes are source-level checks only. A full Gradle compile remains blocked because this environment cannot resolve `services.gradle.org`; no compile or game test is claimed.

## Tracked entity-data serializer migration (progress 13)
- Replaced the legacy `EntityDataSerializer.write/read` implementation with the 1.21.1 `StreamCodec` contract using `RegistryFriendlyByteBuf`.
- Registered the quaternion serializer through Fabric's `FabricEntityDataRegistry` with the stable namespaced ID `simpleplanes:quaternion`, rather than relying on the legacy integer-only vanilla registration path.
- Moved serializer registration earlier in mod initialization so it runs before custom entity classes initialize their tracked-data accessors.
- This addresses a high-risk 1.21.1 API change in synchronization of plane orientation. Compilation and multiplayer synchronization remain unverified because the Gradle distribution/dependencies are not available in this environment.

## Network buffer lifetime and stale-world guards (progress 14)
- Removed unnecessary `retain()` calls from the plane-spawn and upgrade-update receivers. Each receiver now releases its owned buffer exactly once after scheduled processing, rather than leaving a retained reference behind.
- Added checks for a missing client level or missing/non-plane entity before applying spawn or upgrade data, preventing a disconnect/world transition or out-of-order packet from causing a null dereference or invalid cast.
- These are targeted lifecycle fixes in the typed-payload compatibility bridge. They are not a substitute for compilation or multiplayer testing; Gradle is still unavailable in the current environment.

## Network buffer ownership cleanup (progress 15)
- Added `RawPayload.fromBufferAndRelease` so temporary Netty-backed buffers are released after their contents are copied into immutable byte-array payloads.
- Updated client-to-server packet sends and entity-spawn payload creation to use the releasing helper.
- Changed multi-recipient server sends to build one immutable payload before iterating over tracking players, avoiding repeated copies and preventing reuse of a released buffer.
- Added a common server-receiver wrapper that releases each temporary receive buffer after the legacy packet handler has synchronously decoded its fields.
- Added release and stale-entity/world guards to the jukebox and upgrade-removal client receivers.

These changes target packet-buffer lifetime and stale-entity handling. They are source-reviewed only; compilation and multiplayer behavior are still unverified because Gradle cannot currently be downloaded in this environment.

## Camera quaternion isolation (progress 16)
- Changed the plane camera setup to compose rotations on copies of the previous/current plane quaternions. JOML quaternion multiplication mutates the receiver, so the old code could accidentally modify the plane's stored orientation every time the camera was updated.
- Added a defensive early return if the active camera has no entity or vehicle during world transitions.
- Reviewed the touched method and verified the expected patch is present. Full compile/game validation remains blocked by unavailable Gradle distribution and is still required.


## GameRenderer mixin signature migration (progress 17)
- Updated `MixinGameRenderer` to target the Minecraft 1.21.1 `renderLevel(DeltaTracker)` method instead of the removed legacy signature that expected a `PoseStack` parameter and injected at `Camera.getXRot()`.
- The mixin now calls the camera adjustment hook at the start of the modern render-level method, using the current partial tick value. This avoids a guaranteed method/signature mismatch at mixin application.
- Limitation: the temporary `PoseStack` passed to the legacy camera helper is not Minecraft's active render matrix, so camera roll is not applied by this change. The position/yaw/pitch calculations are retained, but roll needs a dedicated 1.21.1 matrix/camera integration. This is explicitly not treated as complete camera-render migration.
- Confirmed the 1.21.1 `GameRenderer.renderLevel(DeltaTracker)` and `LivingEntityRenderer.render(..., PoseStack, ...)` signatures against the 1.21.1 mappings reference. Full compilation remains unverified because Gradle cannot be downloaded in this environment.


## Renderer model initialization cleanup (progress 18)
- Removed the `MixinEntityRenderDispatcher` injection that captured `EntityRendererProvider.Context` as a local variable with `CAPTURE_FAILHARD`. Local-variable capture is brittle across mapped Minecraft bytecode and could abort client startup if the local layout changes.
- Moved upgrade-model baking into the Fabric entity-renderer factories, where the renderer context is provided directly. A context identity guard avoids baking the same upgrade models repeatedly for the four custom renderers while still allowing a fresh renderer context after resource reload to rebuild them.
- Removed the deleted mixin from the client mixin configuration. This is a source-level lifecycle fix; compilation and resource-reload behavior still require testing in a real Fabric 1.21.1 runtime.

## Camera injection timing correction (progress 19)
- Replaced the `GameRenderer.renderLevel` HEAD hook with a `Camera.setup` TAIL hook. Vanilla initializes the camera during `Camera.setup`; modifying it at the beginning of `renderLevel` is too early and can be overwritten by vanilla during the same frame.
- The new hook applies the existing plane position/yaw/pitch calculation after vanilla camera setup, and the obsolete `MixinGameRenderer` was removed from the mixin configuration and source tree.
- Camera roll is still not applied to Minecraft's active camera quaternion: the existing helper accepts a `PoseStack`, and the temporary stack passed here cannot affect the camera. This change corrects timing for position and Euler angles but remains source-reviewed only, not compiled or game-tested.


## Camera orientation completion pass (progress 20)
- Removed the temporary `PoseStack` from the camera hook: it was not part of Minecraft's active world-render transform, so rotating it had no visible effect.
- Added a small `CameraAccessor` mixin interface to invoke vanilla's protected `Camera.setRotation(yaw, pitch)` method. The plane camera now updates the actual camera quaternion together with yaw/pitch instead of only writing Euler fields.
- Applied the interpolated plane roll to the camera's actual quaternion and refreshed the cached look/up/left vectors from that orientation so near-plane and view-direction calculations stay aligned.
- Updated the mixin config to include the accessor. This is a source-level correction based on the 1.21.1 Camera API; the project still needs a real Gradle compile and in-game test, which remain blocked by unavailable Gradle distribution/dependencies in this environment.

## Network input validation hardening (progress 21)
- Added bounds checks before converting client-supplied enum ordinals in throttle and workbench-cycle packets. Invalid values are ignored instead of causing an `ArrayIndexOutOfBoundsException` on the server.
- Switched those enum reads to unsigned bytes, matching the wire format written by the sender.
- Added a null-sender guard before handling upgrade removal, and guarded the workbench action against a missing sender.
- These are source-level defensive fixes. Build/runtime verification remains unavailable because the Gradle distribution and Minecraft/Fabric dependencies are not cached and the environment cannot resolve `services.gradle.org`.


## Spawn packet API migration (progress 22)
- Removed the legacy `ClientboundAddEntityPacket(FriendlyByteBuf)` decode and `.write(FriendlyByteBuf)` serialization pattern, which is not available in Minecraft 1.21.1.
- The custom plane-spawn payload now serializes the spawn fields explicitly and reconstructs the vanilla packet with the 1.21.1 public field-based constructor.
- Added an unknown-entity-type guard before scheduling client world changes, while preserving the plane upgrade spawn data appended after the vanilla spawn fields.
- This patch was source-reviewed against the 1.21.1 mappings reference; it has not been compiled because the Gradle distribution cannot be downloaded in this environment (`services.gradle.org` DNS failure).

## Validation pass performed 2026-10-18
- Confirmed the project targets Minecraft 1.21.1 and Java 21 in Gradle properties and Fabric metadata.
- Parsed all 118 JSON files under `src/main/resources`; all are syntactically valid JSON.
- Counted 137 Java source files.
- Retried `./gradlew build --no-daemon` with Java 21. It fails before Gradle starts because the wrapper cannot resolve `services.gradle.org` (`UnknownHostException`). This is an environment/network blocker, not a compiler result.

## Important release status
This archive remains a **source port candidate, not a completed or verified mod**. Without a successful Gradle compile and launch test, API mismatches and runtime problems may remain. Do not rename this source archive to `.jar` or install it as a mod. On a machine with network access, run `./gradlew build --no-daemon`; fix reported compiler errors, then test in a clean Fabric 1.21.1 instance (single-player and multiplayer) before release.

## Validation pass after user supplied Gradle 8.14.6
- Extracted and launched the supplied Gradle 8.14.6 distribution successfully under Java 21.
- Ran `/mnt/data/gradle-8.14.6/bin/gradle -p /mnt/data/simpleplanes_work build --no-daemon`.
- Gradle itself starts, but the build stops during plugin resolution before Java compilation: `fabric-loom` 1.7.4 cannot be resolved because the environment cannot resolve external Maven hosts (`maven.fabricmc.net`, `plugins.gradle.org`). A direct network check confirmed DNS resolution fails in this environment.
- No `.jar` was produced. This is an external dependency/network blocker, not evidence that compilation succeeds or fails.


## Build attempt after Gradle 8.14.6 was provided (progress 24)
- Re-ran the build using the supplied Gradle 8.14.6 distribution. Gradle launches, but plugin resolution fails before compilation because `fabric-loom:1.7.4` cannot be resolved from Fabric Maven / Maven Central / Gradle Plugin Portal in this environment.
- Updated `gradle/wrapper/gradle-wrapper.properties` to Gradle 8.14.6 so the project wrapper matches the distribution provided by the user and no longer requests Gradle 8.8.
- This is not a completed mod build: no `.jar` was produced, and no game launch test has been run. The next blocker is obtaining Loom and Minecraft/Fabric dependencies from Maven repositories.

## Build resolution follow-up (progress 25)
- Added an explicit Gradle plugin resolution rule mapping the `fabric-loom` plugin ID to its published module coordinate (`net.fabricmc:fabric-loom:<version>`). This bypasses reliance on the Gradle plugin marker artifact and is a useful compatibility fallback when resolving Loom from Fabric Maven.
- Re-ran the build with the user-provided Gradle 8.14.6 distribution. Plugin resolution still fails before compilation because external Maven repositories are unreachable from this execution environment. This change does not establish compile success; a network-enabled build remains required.


## Dependency metadata and build plugin pass (progress 26)
- Corrected the Fabric mod dependency identifier from the nonexistent `fabric` mod ID to `fabric-api`, so Fabric Loader can resolve the required API dependency when loading the mod.
- Updated Fabric Loom from 1.7.4 to 1.8.13, a newer Loom line appropriate for modern 1.21.x development and the supplied Gradle 8.14.6 distribution.
- Revalidated `fabric.mod.json` as JSON.
- Retried build after the change: plugin/dependency resolution remains blocked in this environment because the external Maven hosts cannot be resolved. No JAR is produced and compilation/game launch are still unverified.

## Build helper pass (progress 27)
- Added `build.bat` and `build.sh` so a user with the supplied Gradle 8.14.6 distribution can invoke the build without the wrapper trying to download Gradle again.
- Added `BUILDING.md` with JDK, folder layout, build commands, and the remaining requirement for Maven access to download Fabric Loom and Minecraft/Fabric dependencies.
- Retested with the supplied Gradle 8.14.6 distribution. Gradle starts, but plugin resolution fails before Java compilation because `net.fabricmc:fabric-loom:1.8.13` cannot be resolved in this environment. The external Maven hosts remain unreachable here.
- This pass improves the build workflow only; it does not claim source compilation, a produced JAR, or runtime validation.

## Defensive item tint rendering fix (progress 28)
- Hardened `PlaneItemColors.getColor`: block models with no quads on the sampled face now fall back to the default tint instead of throwing when `.get(0)` is called on an empty list. This prevents a client-side crash during item tinting for invisible/nonstandard block models.
- Corrected the animated texture pixel sampling coordinate to use `frameX` for the horizontal offset rather than mistakenly using `frameY` for both axes.
- Verified source patch presence and re-parsed resource JSON. This is a targeted source fix, not a compile/test claim: Gradle still cannot resolve Fabric Loom because Maven repositories are unreachable in this environment.

## Payload immutability and size guard (progress 29)
- Added a 1 MiB maximum size for the typed-payload compatibility bridge and used the bounded `FriendlyByteBuf.readByteArray(maxLength)` decoder to reject oversized payload bodies instead of allocating arbitrarily large byte arrays.
- Made `RawPayload` defensively copy input data and return a copy from its accessor, preventing a queued network payload from being mutated by the caller after construction.
- Added `tools/validate_project.py`, an offline structural check for JSON syntax, Minecraft/Fabric metadata, main/client entrypoint source files, configured mixin source files, unique packet IDs, and the expected source tree size.
- Ran the offline validator successfully: 26 structural assertions, 118 JSON files, 137 Java files, and 14 packet IDs checked.
- Retried Gradle 8.14.6 build. It still fails before Java compilation because `net.fabricmc:fabric-loom:1.8.13` cannot be resolved from the configured Maven repositories in this environment. The payload change has not been compiled or runtime-tested; this archive is still not a verified installable JAR.

## Continuation check after progress 29 (2026-10-18)
- Restored the latest progress-29 archive and reran `tools/validate_project.py`: all 26 structural assertions passed (118 JSON files, 137 Java files, 14 packet IDs).
- Extracted the user-provided Gradle 8.14.6 distribution and ran Gradle directly against this project. Gradle 8.14.6 starts correctly under Java 21, but dependency/plugin resolution fails at `fabric-loom:1.8.13` before Java compilation; the plugin artifact is unavailable from the configured Fabric Maven, Maven Central, and Gradle Plugin Portal repositories in this execution environment.
- This confirms the failure is still before compilation. No JAR has been produced, and no claim of compile success or game testing is made. The next meaningful step requires a network-enabled environment (or a cache containing Loom plus all Minecraft/Fabric dependencies), after which compiler errors can be addressed iteratively.

## Build workflow and clean source archive (progress 31)
- Added a GitHub Actions workflow that builds with JDK 21 and Gradle 8.14.6 and publishes `build/libs/*.jar` as a workflow artifact only after a successful build.
- Updated `BUILDING.md` with the CI workflow and clearer JDK/Gradle requirements.
- Updated the Windows build helper to check that Java is available and warn when the reported version does not look like Java 21.
- Removed local `.gradle` caches and build outputs from the distributable source archive so it contains project sources rather than machine-specific transient files.
- Revalidated the ZIP integrity, all 118 JSON files, and the Minecraft 1.21.1 / Java 21 mod metadata. These checks do not replace Java compilation.
- Re-ran Gradle 8.14.6 under Java 21: build still fails during Fabric Loom plugin resolution before Java compilation because the external Maven artifact cannot be resolved in this environment. No installable JAR is produced or claimed. The CI workflow is included but has not been run on GitHub yet.


## Offline validation and CI gate (progress 32)
- Expanded `tools/validate_project.py` to verify metadata-declared resources: the mod icon, access widener, and mixin configuration file must exist in `src/main/resources`. This catches packaging mistakes before a full game launch.
- Added the offline validator as an explicit GitHub Actions step before Gradle build, so missing metadata resources fail early and clearly.
- Ran the expanded validator locally; the source tree passes. Re-ran Gradle 8.14.6: the build still stops at Fabric Loom plugin resolution, before Java compilation, because the Maven artifact cannot be fetched from this environment. The Loom 1.8.13 artifact itself is published, so changing to a random version would not solve the demonstrated connectivity issue. No JAR has been produced.


## Build helper reliability fix (progress 33)
- Fixed `build.bat` error handling: the previous `%ERRORLEVEL%` capture was inside a parenthesized block, where expansion can happen before Gradle finishes. The script now branches immediately on `if errorlevel 1`, so a failed Gradle build cannot be reported as successful due to a stale exit code.
- Added a post-build listing of JAR files from `build\libs`.
- Re-ran offline project validation successfully (29 structural assertions, 118 JSON files, 137 Java files, 14 packet IDs).
- Retried the real Gradle build: it still fails before compilation because DNS/network access to `maven.fabricmc.net` is unavailable. A genuine compiled mod JAR cannot be generated in this runtime without the Fabric Loom and Minecraft/Fabric dependencies; no placeholder JAR is being presented as a mod.
