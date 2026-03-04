import Testing
import Foundation
@testable import SwiftCardanoUtils

// MARK: - ContainerChecks Integration Tests
//
// These tests call the real container runtime CLI (docker / container).
// Each test is gated with .enabled(if:) so it shows as disabled — not passed —
// in Xcode when the required runtime is unavailable.
//
// Prerequisites for Docker tests:
//   • Docker daemon running:  docker info
//   • Test image present:     docker pull alpine:latest
//
// Prerequisites for Apple Container tests:
//   • Apple Container installed and daemon running: container system status
//     (start it first with: container system start)
//   • Test image present:                           container pull alpine:latest
//
// To run only these tests:
//   swift test --filter ContainerChecksIntegrationTests

@Suite("ContainerChecks Integration Tests (requires Docker)")
struct ContainerChecksIntegrationTests {

    // MARK: - Test Constants

    /// Lightweight image that must be present locally for integration tests.
    static let testImage = "alpine:latest"

    /// Image name guaranteed not to exist locally.
    static let nonExistentImage = "nonexistent-image-swiftcardanoutils-xyz-12345:latest"

    /// A real image with a tag that should not exist.
    static let nonExistentTag = "alpine:nonexistent-tag-swiftcardanoutils-xyz"

    // MARK: - Runtime Availability (evaluated once at test discovery)

    /// `true` when the Docker daemon is reachable on this machine.
    static let isDockerAvailable: Bool = checkRuntime(.docker)

    /// `true` when the Apple Container CLI and daemon are available on this machine.
    static let isAppleContainerAvailable: Bool = checkRuntime(.appleContainer)

    /// `true` when Docker is available **and** the test image is already pulled.
    static let isDockerWithTestImage: Bool = {
        guard isDockerAvailable else { return false }
        return isImagePresent(testImage, runtime: .docker)
    }()

    /// `true` when Apple Container is available **and** the test image is already pulled.
    static let isAppleContainerWithTestImage: Bool = {
        guard isAppleContainerAvailable else { return false }
        return isImagePresent(testImage, runtime: .appleContainer)
    }()

    // MARK: - Availability Helpers

    /// Checks that the container runtime daemon is reachable.
    ///
    /// - Docker: `docker info`
    /// - Apple Container: `container system status`
    ///   Start the service first with `container system start` if needed.
    private static func checkRuntime(_ runtime: ContainerRuntime) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        switch runtime {
        case .docker:
            process.arguments = ["docker", "info"]
        case .appleContainer:
            process.arguments = ["container", "system", "status"]
        }
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    /// Returns `true` if `imageName` is present in the local image store for `runtime`.
    private static func isImagePresent(
        _ imageName: String,
        runtime: ContainerRuntime = .docker
    ) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [
            runtime.executable, "images", "--quiet",
            "--filter", "reference=\(imageName)"
        ]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            let output = String(
                data: pipe.fileHandleForReading.readDataToEndOfFile(),
                encoding: .utf8
            ) ?? ""
            return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } catch {
            return false
        }
    }

    // MARK: - Docker: Image Present

    @Test("checkImage succeeds when image is present locally (Docker)",
          .enabled(if: ContainerChecksIntegrationTests.isDockerWithTestImage))
    func testCheckImageSucceedsForPresentImage() throws {
        let config = ContainerConfig(runtime: .docker, imageName: Self.testImage)
        #expect(throws: Never.self) {
            try ContainerChecks.checkImage(config: config)
        }
    }

    // MARK: - Docker: Image Absent

    @Test("checkImage throws binaryNotFound for a non-existent image (Docker)",
          .enabled(if: ContainerChecksIntegrationTests.isDockerAvailable))
    func testCheckImageThrowsForNonExistentImage() throws {
        let config = ContainerConfig(runtime: .docker, imageName: Self.nonExistentImage)

        #expect(throws: SwiftCardanoUtilsError.self) {
            try ContainerChecks.checkImage(config: config)
        }

        // Verify it's specifically a binaryNotFound error with the image name
        do {
            try ContainerChecks.checkImage(config: config)
        } catch let error as SwiftCardanoUtilsError {
            switch error {
            case .binaryNotFound(let msg):
                #expect(msg.contains(Self.nonExistentImage))
            default:
                Issue.record("Expected binaryNotFound but got: \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("checkImage throws binaryNotFound for an image with a non-existent tag (Docker)",
          .enabled(if: ContainerChecksIntegrationTests.isDockerAvailable))
    func testCheckImageThrowsForNonExistentTag() throws {
        // Defensive: skip if the made-up tag somehow exists (essentially impossible)
        guard !Self.isImagePresent(Self.nonExistentTag, runtime: .docker) else { return }

        let config = ContainerConfig(runtime: .docker, imageName: Self.nonExistentTag)
        #expect(throws: SwiftCardanoUtilsError.self) {
            try ContainerChecks.checkImage(config: config)
        }
    }

    @Test("checkImage error message includes pull hint (Docker)",
          .enabled(if: ContainerChecksIntegrationTests.isDockerAvailable))
    func testCheckImageErrorMessageContainsPullHint() throws {
        let config = ContainerConfig(runtime: .docker, imageName: Self.nonExistentImage)

        do {
            try ContainerChecks.checkImage(config: config)
            Issue.record("Expected checkImage to throw")
        } catch let error as SwiftCardanoUtilsError {
            switch error {
            case .binaryNotFound(let message):
                #expect(message.contains("docker pull") || message.contains("Pull"))
            default:
                break
            }
        } catch {}
    }

    // MARK: - Docker: Multiple Different Images

    @Test("checkImage correctly identifies presence vs absence for different images",
          .enabled(if: ContainerChecksIntegrationTests.isDockerWithTestImage))
    func testCheckImageDistinguishesPresentFromAbsent() throws {
        let presentConfig = ContainerConfig(runtime: .docker, imageName: Self.testImage)
        let absentConfig  = ContainerConfig(runtime: .docker, imageName: Self.nonExistentImage)

        #expect(throws: Never.self) {
            try ContainerChecks.checkImage(config: presentConfig)
        }
        #expect(throws: SwiftCardanoUtilsError.self) {
            try ContainerChecks.checkImage(config: absentConfig)
        }
    }

    // MARK: - Apple Container Runtime

    @Test("checkImage succeeds for present image via Apple Container runtime",
          .enabled(if: ContainerChecksIntegrationTests.isAppleContainerWithTestImage))
    func testCheckImageAppleContainerRuntime() throws {
        let config = ContainerConfig(runtime: .appleContainer, imageName: Self.testImage)
        #expect(throws: Never.self) {
            try ContainerChecks.checkImage(config: config)
        }
    }

    @Test("checkImage throws for non-existent image via Apple Container runtime",
          .enabled(if: ContainerChecksIntegrationTests.isAppleContainerAvailable))
    func testCheckImageAppleContainerRuntimeImageAbsent() throws {
        let config = ContainerConfig(runtime: .appleContainer, imageName: Self.nonExistentImage)
        #expect(throws: SwiftCardanoUtilsError.self) {
            try ContainerChecks.checkImage(config: config)
        }
    }

    // MARK: - Filter Precision

    @Test("checkImage uses --filter reference= for accurate tag matching",
          .enabled(if: ContainerChecksIntegrationTests.isDockerWithTestImage))
    func testCheckImageFilterIsTagSpecific() throws {
        // "alpine:latest" is present, but "alpine:made-up-tag-abc" must not be
        guard !Self.isImagePresent("alpine:made-up-tag-abc", runtime: .docker) else { return }

        let config = ContainerConfig(runtime: .docker, imageName: "alpine:made-up-tag-abc")
        #expect(throws: SwiftCardanoUtilsError.self) {
            try ContainerChecks.checkImage(config: config)
        }
    }
}
