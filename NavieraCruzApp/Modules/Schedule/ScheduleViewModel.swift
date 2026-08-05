import Foundation

@MainActor
class ScheduleViewModel: ObservableObject {
    @Published var schedules: [Schedule] = []
    @Published var isLoading: Bool = false
    
    private let scheduleService: ScheduleServiceProtocol
    
    init(scheduleService: ScheduleServiceProtocol = AppConfig.isMockActive ? MockScheduleService() : ProductionScheduleService()) {
        self.scheduleService = scheduleService
    }
    
    func loadSchedules() {
        isLoading = true
        Task {
            do {
                self.schedules = try await scheduleService.fetchMonthlySchedule()
            } catch {
                print("Error loading schedules: \(error)")
            }
            self.isLoading = false
        }
    }
}
