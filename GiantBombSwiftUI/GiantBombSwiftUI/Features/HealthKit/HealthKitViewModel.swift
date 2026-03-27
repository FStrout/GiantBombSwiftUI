//
//  HealthKitViewModel.swift
//  GiantBombSwiftUI
//
//  Created by Fred Strout on 3/27/26.
//

import Combine
import Foundation
import HealthKit

@MainActor
class HealthKitViewModel: ObservableObject {
  private let repository: any HealthKitRepositoryProtocol
  
  @Published var isAuthorized = false
  @Published var isLoading = false
  @Published var error: Error?
  @Published var healthData: [HealthDataPoint] = []
  @Published var workouts: [WorkoutData] = []
  @Published var sleepData: [SleepData] = []
  @Published var bloodPressureData: [(systolic: Double, diastolic: Double, date: Date)] = []
  @Published var statistics: HealthStatistics?
  
  init(container: DIContainer) {
    self.repository = container.healthkitRepository
  }
  
  // MARK: - Authorization
  
  func requestAuthorization() async {
    isLoading = true
    error = nil
    
    do {
      try await repository.requestAuthorization()
      isAuthorized = true
    } catch {
      self.error = error
      isAuthorized = false
    }
    
    isLoading = false
  }
  
  // MARK: - Fetch Health Data
  
  func fetchHealthData(for type: HealthDataType, days: Int = 7) async {
    isLoading = true
    error = nil
    
    let endDate = Date()
    let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
    
    do {
      healthData = try await repository.fetchQuantityData(
        for: type,
        startDate: startDate,
        endDate: endDate
      )
    } catch {
      self.error = error
      healthData = []
    }
    
    isLoading = false
  }
  
  // MARK: - Fetch Daily Statistics
  
  func fetchDailyData(for type: HealthDataType, days: Int = 7) async {
    isLoading = true
    error = nil
    
    let endDate = Date()
    let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
    
    do {
      healthData = try await repository.fetchDailyStatistics(
        for: type,
        startDate: startDate,
        endDate: endDate
      )
    } catch {
      self.error = error
      healthData = []
    }
    
    isLoading = false
  }
  
  // MARK: - Fetch Statistics
  
  func fetchStatistics(for type: HealthDataType, days: Int = 7) async {
    isLoading = true
    error = nil
    
    let endDate = Date()
    let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
    
    do {
      let stats = try await repository.fetchStatistics(
        for: type,
        startDate: startDate,
        endDate: endDate
      )
      
      if let stats = stats {
        statistics = HealthStatistics(
          average: stats.averageQuantity()?.doubleValue(for: type.unit),
          min: stats.minimumQuantity()?.doubleValue(for: type.unit),
          max: stats.maximumQuantity()?.doubleValue(for: type.unit),
          sum: stats.sumQuantity()?.doubleValue(for: type.unit),
          unit: type.unit.unitString
        )
      } else {
        statistics = nil
      }
    } catch {
      self.error = error
      statistics = nil
    }
    
    isLoading = false
  }
  
  // MARK: - Fetch Workouts
  
  func fetchWorkouts(days: Int = 30) async {
    isLoading = true
    error = nil
    
    let endDate = Date()
    let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
    
    do {
      workouts = try await repository.fetchWorkouts(
        startDate: startDate,
        endDate: endDate
      )
    } catch {
      self.error = error
      workouts = []
    }
    
    isLoading = false
  }
  
  // MARK: - Fetch Sleep Data
  
  func fetchSleepData(days: Int = 7) async {
    isLoading = true
    error = nil
    
    let endDate = Date()
    let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
    
    do {
      sleepData = try await repository.fetchSleepData(
        startDate: startDate,
        endDate: endDate
      )
    } catch {
      self.error = error
      sleepData = []
    }
    
    isLoading = false
  }
  
  // MARK: - Fetch Blood Pressure
  
  func fetchBloodPressure(days: Int = 30) async {
    isLoading = true
    error = nil
    
    let endDate = Date()
    let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
    
    do {
      bloodPressureData = try await repository.fetchBloodPressure(
        startDate: startDate,
        endDate: endDate
      )
    } catch {
      self.error = error
      bloodPressureData = []
    }
    
    isLoading = false
  }
  
  // MARK: - Write Sample Data
  
  func writeSampleData(for type: HealthDataType, value: Double) async {
    isLoading = true
    error = nil
    
    do {
      try await repository.writeSampleData(for: type, value: value)
    } catch {
      self.error = error
    }
    
    isLoading = false
  }
}

// MARK: - Supporting Models

struct HealthStatistics {
  let average: Double?
  let min: Double?
  let max: Double?
  let sum: Double?
  let unit: String
  
  func formattedValue(_ value: Double?) -> String {
    guard let value = value else { return "N/A" }
    return String(format: "%.2f", value)
  }
}
