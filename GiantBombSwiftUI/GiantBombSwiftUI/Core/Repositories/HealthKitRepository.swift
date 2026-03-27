//
//  HealthKitRepository.swift
//  GiantBombSwiftUI
//
//  Created by Fred Strout on 3/27/26.
//

import Combine
import Foundation
import HealthKit

enum HealthKitError: LocalizedError {
  case notAvailable
  case authorizationFailed
  case noData
  case queryFailed(String)
  
  var errorDescription: String? {
    switch self {
    case .notAvailable:
      return "HealthKit is not available on this device"
    case .authorizationFailed:
      return "Failed to authorize HealthKit access"
    case .noData:
      return "No data available"
    case .queryFailed(let message):
      return "Query failed: \(message)"
    }
  }
}

// MARK: - Protocol

@MainActor
protocol HealthKitRepositoryProtocol: ObservableObject {
  var isAuthorized: Bool { get }
  var authorizationError: Error? { get }
  var isHealthKitAvailable: Bool { get }
  
  func requestAuthorization() async throws
  
  func fetchQuantityData(
    for type: HealthDataType,
    startDate: Date,
    endDate: Date
  ) async throws -> [HealthDataPoint]
  
  func fetchStatistics(
    for type: HealthDataType,
    startDate: Date,
    endDate: Date
  ) async throws -> HKStatistics?
  
  func fetchDailyStatistics(
    for type: HealthDataType,
    startDate: Date,
    endDate: Date
  ) async throws -> [HealthDataPoint]
  
  func fetchWorkouts(
    startDate: Date,
    endDate: Date
  ) async throws -> [WorkoutData]
  
  func fetchSleepData(
    startDate: Date,
    endDate: Date
  ) async throws -> [SleepData]
  
  func fetchBloodPressure(
    startDate: Date,
    endDate: Date
  ) async throws -> [(systolic: Double, diastolic: Double, date: Date)]
  
  func writeSampleData(for type: HealthDataType, value: Double, date: Date) async throws
}

// MARK: - Concrete Implementation

@MainActor
final class HealthKitRepository: HealthKitRepositoryProtocol {
  private let healthStore = HKHealthStore()
  
  @Published var isAuthorized = false
  @Published var authorizationError: Error?
  
  nonisolated init() {
    // Default initializer - allows creation from any context
  }
  
  // MARK: - Availability Check
  
  var isHealthKitAvailable: Bool {
    HKHealthStore.isHealthDataAvailable()
  }
  
  // MARK: - Authorization
  
  func requestAuthorization() async throws {
    guard isHealthKitAvailable else {
      throw HealthKitError.notAvailable
    }
    
    let allTypes = Set(HealthDataType.allCases.compactMap { $0.sampleType })
    
    // Additional types for blood pressure (need both systolic and diastolic)
    var typesToRead = allTypes
    if let diastolic = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic) {
      typesToRead.insert(diastolic)
    }
    
    // Request authorization
    do {
      try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
      isAuthorized = true
    } catch {
      authorizationError = error
      throw HealthKitError.authorizationFailed
    }
  }
  
  // MARK: - Fetch Quantity Data
  
  func fetchQuantityData(
    for type: HealthDataType,
    startDate: Date,
    endDate: Date = Date()
  ) async throws -> [HealthDataPoint] {
    guard let quantityType = type.sampleType as? HKQuantityType else {
      throw HealthKitError.queryFailed("Invalid quantity type")
    }
    
    let predicate = HKQuery.predicateForSamples(
      withStart: startDate,
      end: endDate,
      options: .strictStartDate
    )
    
    return try await withCheckedThrowingContinuation { continuation in
      let query = HKSampleQuery(
        sampleType: quantityType,
        predicate: predicate,
        limit: HKObjectQueryNoLimit,
        sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
      ) { _, samples, error in
        if let error = error {
          continuation.resume(throwing: HealthKitError.queryFailed(error.localizedDescription))
          return
        }
        
        guard let samples = samples as? [HKQuantitySample] else {
          continuation.resume(returning: [])
          return
        }
        
        let dataPoints = samples.map { sample in
          HealthDataPoint(
            date: sample.startDate,
            value: sample.quantity.doubleValue(for: type.unit),
            unit: type.unit.unitString,
            type: type
          )
        }
        
        continuation.resume(returning: dataPoints)
      }
      
      healthStore.execute(query)
    }
  }
  
  // MARK: - Fetch Statistics
  
  func fetchStatistics(
    for type: HealthDataType,
    startDate: Date,
    endDate: Date = Date()
  ) async throws -> HKStatistics? {
    guard let quantityType = type.sampleType as? HKQuantityType else {
      throw HealthKitError.queryFailed("Invalid quantity type")
    }
    
    let predicate = HKQuery.predicateForSamples(
      withStart: startDate,
      end: endDate,
      options: .strictStartDate
    )
    
    return try await withCheckedThrowingContinuation { continuation in
      let query = HKStatisticsQuery(
        quantityType: quantityType,
        quantitySamplePredicate: predicate,
        options: [.cumulativeSum, .discreteAverage, .discreteMin, .discreteMax]
      ) { _, statistics, error in
        if let error = error {
          continuation.resume(throwing: HealthKitError.queryFailed(error.localizedDescription))
          return
        }
        
        continuation.resume(returning: statistics)
      }
      
      healthStore.execute(query)
    }
  }
  
  // MARK: - Fetch Daily Statistics
  
  func fetchDailyStatistics(
    for type: HealthDataType,
    startDate: Date,
    endDate: Date = Date()
  ) async throws -> [HealthDataPoint] {
    guard let quantityType = type.sampleType as? HKQuantityType else {
      throw HealthKitError.queryFailed("Invalid quantity type")
    }
    
    var interval = DateComponents()
    interval.day = 1
    
    let predicate = HKQuery.predicateForSamples(
      withStart: startDate,
      end: endDate,
      options: .strictStartDate
    )
    
    return try await withCheckedThrowingContinuation { continuation in
      let query = HKStatisticsCollectionQuery(
        quantityType: quantityType,
        quantitySamplePredicate: predicate,
        options: [.cumulativeSum, .discreteAverage],
        anchorDate: startDate,
        intervalComponents: interval
      )
      
      query.initialResultsHandler = { _, collection, error in
        if let error = error {
          continuation.resume(throwing: HealthKitError.queryFailed(error.localizedDescription))
          return
        }
        
        guard let collection = collection else {
          continuation.resume(returning: [])
          return
        }
        
        var dataPoints: [HealthDataPoint] = []
        
        collection.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
          var value: Double = 0
          
          if let sum = statistics.sumQuantity() {
            value = sum.doubleValue(for: type.unit)
          } else if let average = statistics.averageQuantity() {
            value = average.doubleValue(for: type.unit)
          }
          
          if value > 0 {
            dataPoints.append(HealthDataPoint(
              date: statistics.startDate,
              value: value,
              unit: type.unit.unitString,
              type: type
            ))
          }
        }
        
        continuation.resume(returning: dataPoints)
      }
      
      healthStore.execute(query)
    }
  }
  
  // MARK: - Fetch Workouts
  
  func fetchWorkouts(
    startDate: Date,
    endDate: Date = Date()
  ) async throws -> [WorkoutData] {
    let predicate = HKQuery.predicateForSamples(
      withStart: startDate,
      end: endDate,
      options: .strictStartDate
    )
    
    return try await withCheckedThrowingContinuation { continuation in
      let query = HKSampleQuery(
        sampleType: HKObjectType.workoutType(),
        predicate: predicate,
        limit: HKObjectQueryNoLimit,
        sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
      ) { _, samples, error in
        if let error = error {
          continuation.resume(throwing: HealthKitError.queryFailed(error.localizedDescription))
          return
        }
        
        guard let workouts = samples as? [HKWorkout] else {
          continuation.resume(returning: [])
          return
        }
        
        let workoutData = workouts.map { workout in
          // Extract energy burned - handles iOS 18+ deprecation
          var energyBurned: Double?
          if #available(iOS 18.0, *) {
            if let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
               let stats = workout.statistics(for: energyType),
               let sum = stats.sumQuantity() {
              energyBurned = sum.doubleValue(for: .kilocalorie())
            }
          } else {
            energyBurned = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie())
          }
          
          // Extract distance - handles iOS 18+ deprecation
          var distance: Double?
          if #available(iOS 18.0, *) {
            if let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning),
               let stats = workout.statistics(for: distanceType),
               let sum = stats.sumQuantity() {
              distance = sum.doubleValue(for: .meter())
            }
          } else {
            distance = workout.totalDistance?.doubleValue(for: .meter())
          }
          
          return WorkoutData(
            workoutType: workout.workoutActivityType,
            startDate: workout.startDate,
            endDate: workout.endDate,
            duration: workout.duration,
            totalEnergyBurned: energyBurned,
            totalDistance: distance
          )
        }
        
        continuation.resume(returning: workoutData)
      }
      
      healthStore.execute(query)
    }
  }
  
  // MARK: - Fetch Sleep Data
  
  func fetchSleepData(
    startDate: Date,
    endDate: Date = Date()
  ) async throws -> [SleepData] {
    guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
      throw HealthKitError.queryFailed("Invalid sleep type")
    }
    
    let predicate = HKQuery.predicateForSamples(
      withStart: startDate,
      end: endDate,
      options: .strictStartDate
    )
    
    return try await withCheckedThrowingContinuation { continuation in
      let query = HKSampleQuery(
        sampleType: sleepType,
        predicate: predicate,
        limit: HKObjectQueryNoLimit,
        sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
      ) { _, samples, error in
        if let error = error {
          continuation.resume(throwing: HealthKitError.queryFailed(error.localizedDescription))
          return
        }
        
        guard let samples = samples as? [HKCategorySample] else {
          continuation.resume(returning: [])
          return
        }
        
        let sleepData = samples.compactMap { sample -> SleepData? in
          guard let value = HKCategoryValueSleepAnalysis(rawValue: sample.value) else {
            return nil
          }
          
          return SleepData(
            startDate: sample.startDate,
            endDate: sample.endDate,
            value: value
          )
        }
        
        continuation.resume(returning: sleepData)
      }
      
      healthStore.execute(query)
    }
  }
  
  // MARK: - Fetch Blood Pressure
  
  func fetchBloodPressure(
    startDate: Date,
    endDate: Date = Date()
  ) async throws -> [(systolic: Double, diastolic: Double, date: Date)] {
    guard let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic),
          let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic) else {
      throw HealthKitError.queryFailed("Invalid blood pressure type")
    }
    
    let predicate = HKQuery.predicateForSamples(
      withStart: startDate,
      end: endDate,
      options: .strictStartDate
    )
    
    // Fetch systolic
    let systolicSamples = try await fetchQuantitySamples(type: systolicType, predicate: predicate)
    let diastolicSamples = try await fetchQuantitySamples(type: diastolicType, predicate: predicate)
    
    // Match systolic and diastolic by date
    var results: [(systolic: Double, diastolic: Double, date: Date)] = []
    
    for systolic in systolicSamples {
      if let diastolic = diastolicSamples.first(where: { abs($0.startDate.timeIntervalSince(systolic.startDate)) < 1 }) {
        results.append((
          systolic: systolic.quantity.doubleValue(for: .millimeterOfMercury()),
          diastolic: diastolic.quantity.doubleValue(for: .millimeterOfMercury()),
          date: systolic.startDate
        ))
      }
    }
    
    return results
  }
  
  private func fetchQuantitySamples(
    type: HKQuantityType,
    predicate: NSPredicate
  ) async throws -> [HKQuantitySample] {
    try await withCheckedThrowingContinuation { continuation in
      let query = HKSampleQuery(
        sampleType: type,
        predicate: predicate,
        limit: HKObjectQueryNoLimit,
        sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
      ) { _, samples, error in
        if let error = error {
          continuation.resume(throwing: HealthKitError.queryFailed(error.localizedDescription))
          return
        }
        
        continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
      }
      
      healthStore.execute(query)
    }
  }
  
  // MARK: - Write Sample Data (for testing)
  
  func writeSampleData(for type: HealthDataType, value: Double, date: Date = Date()) async throws {
    guard let quantityType = type.sampleType as? HKQuantityType else {
      throw HealthKitError.queryFailed("Invalid quantity type")
    }
    
    let quantity = HKQuantity(unit: type.unit, doubleValue: value)
    let sample = HKQuantitySample(
      type: quantityType,
      quantity: quantity,
      start: date,
      end: date
    )
    
    try await healthStore.save(sample)
  }
}
// MARK: - Protocol Extension (Default Parameters)

extension HealthKitRepositoryProtocol {
  func fetchQuantityData(
    for type: HealthDataType,
    startDate: Date,
    endDate: Date = Date()
  ) async throws -> [HealthDataPoint] {
    try await fetchQuantityData(for: type, startDate: startDate, endDate: endDate)
  }
  
  func fetchStatistics(
    for type: HealthDataType,
    startDate: Date,
    endDate: Date = Date()
  ) async throws -> HKStatistics? {
    try await fetchStatistics(for: type, startDate: startDate, endDate: endDate)
  }
  
  func fetchDailyStatistics(
    for type: HealthDataType,
    startDate: Date,
    endDate: Date = Date()
  ) async throws -> [HealthDataPoint] {
    try await fetchDailyStatistics(for: type, startDate: startDate, endDate: endDate)
  }
  
  func fetchWorkouts(
    startDate: Date,
    endDate: Date = Date()
  ) async throws -> [WorkoutData] {
    try await fetchWorkouts(startDate: startDate, endDate: endDate)
  }
  
  func fetchSleepData(
    startDate: Date,
    endDate: Date = Date()
  ) async throws -> [SleepData] {
    try await fetchSleepData(startDate: startDate, endDate: endDate)
  }
  
  func fetchBloodPressure(
    startDate: Date,
    endDate: Date = Date()
  ) async throws -> [(systolic: Double, diastolic: Double, date: Date)] {
    try await fetchBloodPressure(startDate: startDate, endDate: endDate)
  }
  
  func writeSampleData(for type: HealthDataType, value: Double, date: Date = Date()) async throws {
    try await writeSampleData(for: type, value: value, date: date)
  }
}

// MARK: - Mock Implementation (for unit tests & SwiftUI previews)

#if DEBUG
@MainActor
final class MockHealthKitRepository: HealthKitRepositoryProtocol {
  
  @Published var isAuthorized = false
  @Published var authorizationError: Error?
  
  var isHealthKitAvailable: Bool = true
  
  // Stubbed data
  var stubbedQuantityData: [HealthDataPoint] = []
  var stubbedStatistics: HKStatistics?
  var stubbedDailyStatistics: [HealthDataPoint] = []
  var stubbedWorkouts: [WorkoutData] = []
  var stubbedSleepData: [SleepData] = []
  var stubbedBloodPressure: [(systolic: Double, diastolic: Double, date: Date)] = []
  var stubbedError: Error?
  
  // Track method calls
  var requestAuthorizationCalled = false
  var lastFetchedDataType: HealthDataType?
  var lastWrittenSample: (type: HealthDataType, value: Double, date: Date)?
  
  func requestAuthorization() async throws {
    requestAuthorizationCalled = true
    
    if let error = stubbedError {
      authorizationError = error
      throw error
    }
    
    isAuthorized = true
  }
  
  func fetchQuantityData(
    for type: HealthDataType,
    startDate: Date,
    endDate: Date
  ) async throws -> [HealthDataPoint] {
    lastFetchedDataType = type
    
    if let error = stubbedError {
      throw error
    }
    
    return stubbedQuantityData
  }
  
  func fetchStatistics(
    for type: HealthDataType,
    startDate: Date,
    endDate: Date
  ) async throws -> HKStatistics? {
    lastFetchedDataType = type
    
    if let error = stubbedError {
      throw error
    }
    
    return stubbedStatistics
  }
  
  func fetchDailyStatistics(
    for type: HealthDataType,
    startDate: Date,
    endDate: Date
  ) async throws -> [HealthDataPoint] {
    lastFetchedDataType = type
    
    if let error = stubbedError {
      throw error
    }
    
    return stubbedDailyStatistics
  }
  
  func fetchWorkouts(
    startDate: Date,
    endDate: Date
  ) async throws -> [WorkoutData] {
    if let error = stubbedError {
      throw error
    }
    
    return stubbedWorkouts
  }
  
  func fetchSleepData(
    startDate: Date,
    endDate: Date
  ) async throws -> [SleepData] {
    if let error = stubbedError {
      throw error
    }
    
    return stubbedSleepData
  }
  
  func fetchBloodPressure(
    startDate: Date,
    endDate: Date
  ) async throws -> [(systolic: Double, diastolic: Double, date: Date)] {
    if let error = stubbedError {
      throw error
    }
    
    return stubbedBloodPressure
  }
  
  func writeSampleData(for type: HealthDataType, value: Double, date: Date) async throws {
    lastWrittenSample = (type, value, date)
    
    if let error = stubbedError {
      throw error
    }
  }
}
#endif

