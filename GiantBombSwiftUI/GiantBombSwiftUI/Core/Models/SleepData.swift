//
//  SleepData.swift
//  GiantBombSwiftUI
//
//  Created by Fred Strout on 3/27/26.
//

import Foundation
import HealthKit

struct SleepData: Identifiable {
  let id = UUID()
  let startDate: Date
  let endDate: Date
  let value: HKCategoryValueSleepAnalysis
  
  var duration: TimeInterval {
    endDate.timeIntervalSince(startDate)
  }
  
  var formattedDuration: String {
    let hours = Int(duration) / 3600
    let minutes = (Int(duration) % 3600) / 60
    return "\(hours)h \(minutes)m"
  }
  
  var sleepStage: String {
    switch value {
    case .inBed:
      return "In Bed"
    case .asleepUnspecified:
      return "Asleep"
    case .awake:
      return "Awake"
    case .asleepCore:
      return "Core Sleep"
    case .asleepDeep:
      return "Deep Sleep"
    case .asleepREM:
      return "REM Sleep"
    @unknown default:
      return "Unknown"
    }
  }
  
  var formattedDate: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter.string(from: startDate)
  }
}
