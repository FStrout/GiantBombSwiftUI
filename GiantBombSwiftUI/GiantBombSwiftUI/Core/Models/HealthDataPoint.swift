//
//  HealthDataPoint.swift
//  GiantBombSwiftUI
//
//  Created by Fred Strout on 3/27/26.
//

import Foundation

struct HealthDataPoint: Identifiable {
  let id = UUID()
  let date: Date
  let value: Double
  let unit: String
  let type: HealthDataType
  
  var formattedValue: String {
    switch type {
    case .steps:
      return String(format: "%.0f", value)
    case .distance:
      return String(format: "%.2f", value)
    case .heartRate, .restingHeartRate:
      return String(format: "%.0f", value)
    case .activeEnergy:
      return String(format: "%.0f", value)
    case .vo2Max:
      return String(format: "%.1f", value)
    case .bodyMass:
      return String(format: "%.1f", value)
    case .height:
      return String(format: "%.1f", value)
    case .bloodPressure:
      return String(format: "%.0f", value)
    case .bloodGlucose:
      return String(format: "%.0f", value)
    case .bodyTemperature:
      return String(format: "%.1f", value)
    case .oxygenSaturation:
      return String(format: "%.0f", value)
    default:
      return String(format: "%.2f", value)
    }
  }
  
  var formattedDate: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }
}
