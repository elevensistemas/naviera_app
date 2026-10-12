import Foundation

// MARK: - API Stream Event (NDJSON)
struct NCSStreamEvent: Codable {
    let type: String // "log", "result", "error"
    let logClass: String? // "info", "warning", "error"
    let content: String?
    let structured: NCSStructuredVesselData?

    enum CodingKeys: String, CodingKey {
        case type
        case logClass = "class"
        case content
        case structured
    }
}

// MARK: - Structured Telemetry Data for Vessels
struct NCSStructuredVesselData: Codable, Equatable {
    let vesselName: String?
    let status: String?
    let speed: String?
    let coordinates: String?
    let eta: String?
    let fuelLevel: String?
    let cargoWeight: String?

    enum CodingKeys: String, CodingKey {
        case vesselName = "vessel_name"
        case status
        case speed
        case coordinates
        case eta
        case fuelLevel = "fuel_level"
        case cargoWeight = "cargo_weight"
    }

    init(
        vesselName: String? = nil,
        status: String? = nil,
        speed: String? = nil,
        coordinates: String? = nil,
        eta: String? = nil,
        fuelLevel: String? = nil,
        cargoWeight: String? = nil
    ) {
        self.vesselName = vesselName
        self.status = status
        self.speed = speed
        self.coordinates = coordinates
        self.eta = eta
        self.fuelLevel = fuelLevel
        self.cargoWeight = cargoWeight
    }

    // Flexible decoder to accept strings, numbers, or nulls without decoding errors
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.vesselName = try? container.decodeIfPresent(String.self, forKey: .vesselName)
        self.status = try? container.decodeIfPresent(String.self, forKey: .status)

        if let speedDouble = try? container.decodeIfPresent(Double.self, forKey: .speed) {
            self.speed = "\(speedDouble) nudos"
        } else {
            self.speed = try? container.decodeIfPresent(String.self, forKey: .speed)
        }

        self.coordinates = try? container.decodeIfPresent(String.self, forKey: .coordinates)
        self.eta = try? container.decodeIfPresent(String.self, forKey: .eta)

        if let fuelDouble = try? container.decodeIfPresent(Double.self, forKey: .fuelLevel) {
            self.fuelLevel = "\(Int(fuelDouble))%"
        } else {
            self.fuelLevel = try? container.decodeIfPresent(String.self, forKey: .fuelLevel)
        }

        if let cargoDouble = try? container.decodeIfPresent(Double.self, forKey: .cargoWeight) {
            self.cargoWeight = "\(cargoDouble) Ton"
        } else {
            self.cargoWeight = try? container.decodeIfPresent(String.self, forKey: .cargoWeight)
        }
    }
}

// MARK: - UI Message Model
enum NCSMessageSender: String, Codable {
    case user
    case assistant
    case system
}

struct NCSLogItem: Identifiable, Codable {
    let id: UUID
    let category: String
    let message: String
    let timestamp: Date

    init(id: UUID = UUID(), category: String = "info", message: String, timestamp: Date = Date()) {
        self.id = id
        self.category = category
        self.message = message
        self.timestamp = timestamp
    }
}

struct NCSAIMessage: Identifiable {
    let id: UUID
    let sender: NCSMessageSender
    var text: String
    var logs: [NCSLogItem]
    var structuredData: NCSStructuredVesselData?
    let timestamp: Date
    var isStreaming: Bool
    var isAudioPlaying: Bool

    init(
        id: UUID = UUID(),
        sender: NCSMessageSender,
        text: String,
        logs: [NCSLogItem] = [],
        structuredData: NCSStructuredVesselData? = nil,
        timestamp: Date = Date(),
        isStreaming: Bool = false,
        isAudioPlaying: Bool = false
    ) {
        self.id = id
        self.sender = sender
        self.text = text
        self.logs = logs
        self.structuredData = structuredData
        self.timestamp = timestamp
        self.isStreaming = isStreaming
        self.isAudioPlaying = isAudioPlaying
    }
}
