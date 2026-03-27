//
//  HealthDataType.swift
//  GiantBombSwiftUI
//
//  Created by Fred Strout on 3/27/26.
//

import Foundation
import HealthKit

enum HealthDataType: String, CaseIterable, Identifiable {
  case steps = "Steps"
  case distance = "Distance"
  case heartRate = "Heart Rate"
  case activeEnergy = "Active Energy"
  case restingHeartRate = "Resting Heart Rate"
  case vo2Max = "VO2 Max"
  case bodyMass = "Body Mass"
  case height = "Height"
  case sleepAnalysis = "Sleep"
  case workouts = "Workouts"
  case bloodPressure = "Blood Pressure"
  case bloodGlucose = "Blood Glucose"
  case bodyTemperature = "Body Temperature"
  case oxygenSaturation = "Oxygen Saturation"
  
  var id: String { rawValue }
  
  var sampleType: HKSampleType? {
    switch self {
    case .steps:
      return HKQuantityType.quantityType(forIdentifier: .stepCount)
    case .distance:
      return HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)
    case .heartRate:
      return HKQuantityType.quantityType(forIdentifier: .heartRate)
    case .activeEnergy:
      return HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
    case .restingHeartRate:
      return HKQuantityType.quantityType(forIdentifier: .restingHeartRate)
    case .vo2Max:
      return HKQuantityType.quantityType(forIdentifier: .vo2Max)
    case .bodyMass:
      return HKQuantityType.quantityType(forIdentifier: .bodyMass)
    case .height:
      return HKQuantityType.quantityType(forIdentifier: .height)
    case .sleepAnalysis:
      return HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)
    case .workouts:
      return HKObjectType.workoutType()
    case .bloodPressure:
      return HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)
    case .bloodGlucose:
      return HKQuantityType.quantityType(forIdentifier: .bloodGlucose)
    case .bodyTemperature:
      return HKQuantityType.quantityType(forIdentifier: .bodyTemperature)
    case .oxygenSaturation:
      return HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)
    }
  }
  
  var unit: HKUnit {
    switch self {
    case .steps:
      return .count()
    case .distance:
      return .meter()
    case .heartRate, .restingHeartRate:
      return HKUnit.count().unitDivided(by: .minute())
    case .activeEnergy:
      return .kilocalorie()
    case .vo2Max:
      return HKUnit.literUnit(with: .milli).unitDivided(by: .gramUnit(with: .kilo)).unitDivided(by: .minute())
    case .bodyMass:
      return .pound()
    case .height:
      return .inch()
    case .bloodPressure:
      return .millimeterOfMercury()
    case .bloodGlucose:
      return HKUnit.gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci))
    case .bodyTemperature:
      return .degreeFahrenheit()
    case .oxygenSaturation:
      return .percent()
    default:
      return .count()
    }
  }
  
  var icon: String {
    switch self {
    case .steps:
      return "figure.walk"
    case .distance:
      return "location.fill"
    case .heartRate, .restingHeartRate:
      return "heart.fill"
    case .activeEnergy:
      return "flame.fill"
    case .vo2Max:
      return "lungs.fill"
    case .bodyMass:
      return "scalemass.fill"
    case .height:
      return "ruler.fill"
    case .sleepAnalysis:
      return "bed.double.fill"
    case .workouts:
      return "figure.run"
    case .bloodPressure:
      return "waveform.path.ecg"
    case .bloodGlucose:
      return "cross.vial.fill"
    case .bodyTemperature:
      return "thermometer.medium"
    case .oxygenSaturation:
      return "o.circle.fill"
    }
  }
}
