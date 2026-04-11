import Foundation
import Configuration

// MARK: - Container Runtime

/// Supported container runtimes.
public enum ContainerRuntime: String, Codable, Sendable, CaseIterable {
    case docker         = "docker"
    case appleContainer = "container"

    /// The CLI executable name for this runtime.
    public var executable: String { rawValue }
}

// MARK: - Container Config

/// Configuration for running a CLI tool inside a container.
///
/// Attach a `ContainerConfig` to any service config (`CardanoConfig`,
/// `KupoConfig`, etc.) to have the corresponding CLITool execute commands
/// via `docker exec` / `container exec` (for interactive tools) or
/// `docker run` / `container run` (for long-running daemons).
public struct ContainerConfig: Codable, Sendable {

    // MARK: - Core Identity

    /// The container runtime to use.
    public var runtime: ContainerRuntime

    /// The image to use when launching a new container (`docker run`).
    public var imageName: String

    /// The container name. Required for exec-mode tools. Optional for run-mode
    /// daemons (if nil, the runtime assigns a random name).
    public var containerName: String?

    // MARK: - Volume Mounts

    /// Volume mounts in `"host/path:container/path[:options]"` format.
    public var volumes: [String]?

    // MARK: - Environment

    /// Environment variables in `"KEY=VALUE"` format.
    public var environment: [String]?

    // MARK: - Networking

    /// Port mappings in `"hostPort:containerPort[/proto]"` format.
    public var ports: [String]?

    /// Docker network to attach the container to (e.g. `"host"`, `"bridge"`).
    public var network: String?

    // MARK: - Runtime Behaviour

    /// Restart policy (e.g. `"no"`, `"always"`, `"unless-stopped"`, `"on-failure"`).
    public var restart: String?

    /// Working directory inside the container (`--workdir`).
    public var workingDir: String?

    /// User to run as inside the container, e.g. `"1000:1000"` or `"cardano"`.
    public var user: String?

    /// Hostname for the container.
    public var hostname: String?

    /// Run the container with elevated privileges.
    public var privileged: Bool?

    /// Remove the container automatically on exit (`--rm`).
    public var removeOnExit: Bool?

    /// Run in detached (background) mode (`-d`). Defaults to `true` for daemon tools.
    public var detach: Bool?

    /// Override the image's default entrypoint.
    public var entrypoint: String?

    /// Platform override, e.g. `"linux/amd64"` or `"linux/arm64"`.
    public var platform: String?

    // MARK: - Resource Limits

    /// Memory limit, e.g. `"512m"` or `"2g"`.
    public var memory: String?

    /// CPU quota, e.g. `"1.5"` for 1.5 CPUs.
    public var cpus: String?

    // MARK: - Security

    /// Linux capabilities to add, e.g. `["NET_ADMIN"]`.
    public var capAdd: [String]?

    /// Linux capabilities to drop.
    public var capDrop: [String]?

    /// Mount the root filesystem as read-only.
    public var readOnly: Bool?

    // MARK: - Logging

    /// Log driver, e.g. `"json-file"`, `"syslog"`, `"none"`.
    public var logDriver: String?

    /// Log driver options in `"key=value"` format.
    public var logOptions: [String]?

    // MARK: - Labels

    /// Container labels in `"key=value"` format.
    public var labels: [String]?

    // MARK: - Init

    public init(
        runtime: ContainerRuntime = .docker,
        imageName: String,
        containerName: String? = nil,
        volumes: [String]? = nil,
        environment: [String]? = nil,
        ports: [String]? = nil,
        network: String? = nil,
        restart: String? = nil,
        workingDir: String? = nil,
        user: String? = nil,
        hostname: String? = nil,
        privileged: Bool? = nil,
        removeOnExit: Bool? = nil,
        detach: Bool? = nil,
        entrypoint: String? = nil,
        platform: String? = nil,
        memory: String? = nil,
        cpus: String? = nil,
        capAdd: [String]? = nil,
        capDrop: [String]? = nil,
        readOnly: Bool? = nil,
        logDriver: String? = nil,
        logOptions: [String]? = nil,
        labels: [String]? = nil
    ) {
        self.runtime = runtime
        self.imageName = imageName
        self.containerName = containerName
        self.volumes = volumes
        self.environment = environment
        self.ports = ports
        self.network = network
        self.restart = restart
        self.workingDir = workingDir
        self.user = user
        self.hostname = hostname
        self.privileged = privileged
        self.removeOnExit = removeOnExit
        self.detach = detach
        self.entrypoint = entrypoint
        self.platform = platform
        self.memory = memory
        self.cpus = cpus
        self.capAdd = capAdd
        self.capDrop = capDrop
        self.readOnly = readOnly
        self.logDriver = logDriver
        self.logOptions = logOptions
        self.labels = labels
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case runtime
        case imageName      = "image_name"
        case containerName  = "container_name"
        case volumes
        case environment
        case ports
        case network
        case restart
        case workingDir     = "working_dir"
        case user
        case hostname
        case privileged
        case removeOnExit   = "remove_on_exit"
        case detach
        case entrypoint
        case platform
        case memory
        case cpus
        case capAdd         = "cap_add"
        case capDrop        = "cap_drop"
        case readOnly       = "read_only"
        case logDriver      = "log_driver"
        case logOptions     = "log_options"
        case labels
    }

    // MARK: - ConfigReader Init

    /// Creates a `ContainerConfig` from the provided reader using the given namespace prefix.
    ///
    /// - Parameters:
    ///   - config: The config reader to read values from.
    ///   - namespace: The dot-separated key prefix, e.g. `"kupo.container"`.
    public init(config: ConfigReader, namespace: String) throws {
        func key(_ codingKey: CodingKeys) -> ConfigKey {
            return ConfigKey("\(namespace).\(codingKey.rawValue)")
        }

        guard let runtimeRaw = config.string(forKey: key(.runtime)),
              let runtime = ContainerRuntime(rawValue: runtimeRaw) else {
            throw SwiftCardanoUtilsError.configurationMissing(
                "\(namespace).runtime is required and must be 'docker' or 'container'"
            )
        }
        guard let imageName = config.string(forKey: key(.imageName)) else {
            throw SwiftCardanoUtilsError.configurationMissing(
                "\(namespace).image_name is required"
            )
        }

        self.runtime        = runtime
        self.imageName      = imageName
        self.containerName  = config.string(forKey: key(.containerName))
        self.volumes        = config.stringArray(forKey: key(.volumes))
        self.environment    = config.stringArray(forKey: key(.environment))
        self.ports          = config.stringArray(forKey: key(.ports))
        self.network        = config.string(forKey: key(.network))
        self.restart        = config.string(forKey: key(.restart))
        self.workingDir     = config.string(forKey: key(.workingDir))
        self.user           = config.string(forKey: key(.user))
        self.hostname       = config.string(forKey: key(.hostname))
        self.privileged     = config.bool(forKey: key(.privileged))
        self.removeOnExit   = config.bool(forKey: key(.removeOnExit))
        self.detach         = config.bool(forKey: key(.detach))
        self.entrypoint     = config.string(forKey: key(.entrypoint))
        self.platform       = config.string(forKey: key(.platform))
        self.memory         = config.string(forKey: key(.memory))
        self.cpus           = config.string(forKey: key(.cpus))
        self.capAdd         = config.stringArray(forKey: key(.capAdd))
        self.capDrop        = config.stringArray(forKey: key(.capDrop))
        self.readOnly       = config.bool(forKey: key(.readOnly))
        self.logDriver      = config.string(forKey: key(.logDriver))
        self.logOptions     = config.stringArray(forKey: key(.logOptions))
        self.labels         = config.stringArray(forKey: key(.labels))
    }

    // MARK: - Convenience Factory

    /// Returns a `ContainerConfig` initialised from `config` under `namespace`, or `nil`
    /// if `<namespace>.image_name` is absent (i.e. no container section is configured).
    ///
    /// Use this instead of a manual sentinel-key check in service config `init(config:)`.
    public static func tryInit(config: ConfigReader, namespace: String) throws -> ContainerConfig? {
        let imageKey = ConfigKey("\(namespace).\(CodingKeys.imageName.rawValue)")
        guard config.string(forKey: imageKey) != nil else { return nil }
        return try ContainerConfig(config: config, namespace: namespace)
    }
}
