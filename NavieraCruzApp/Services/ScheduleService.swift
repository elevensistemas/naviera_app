import Foundation

protocol ScheduleServiceProtocol {
    func fetchMonthlySchedule() async throws -> [Schedule]
}

class MockScheduleService: ScheduleServiceProtocol {
    func fetchMonthlySchedule() async throws -> [Schedule] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return [
            Schedule(id: "sch1", shipId: "s1", date: Date(), cargoType: "Contenedores secos", details: "Descarga en Puerto Madryn"),
            Schedule(id: "sch2", shipId: "s3", date: Date().addingTimeInterval(86400*3), cargoType: "Pesca congelada", details: "Arribo programado a Ushuaia")
        ]
    }
}

class ProductionScheduleService: ScheduleServiceProtocol {
    func fetchMonthlySchedule() async throws -> [Schedule] {
        return try await APIClient.shared.request(endpoint: "/api/v1/schedule/", method: "GET")
    }
}

