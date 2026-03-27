//
//  WorkoutData.swift
//  GiantBombSwiftUI
//
//  Created by Fred Strout on 3/27/26.
//

import Foundation
import HealthKit

struct WorkoutData: Identifiable {
  let id = UUID()
  let workoutType: HKWorkoutActivityType
  let startDate: Date
  let endDate: Date
  let duration: TimeInterval
  let totalEnergyBurned: Double?
  let totalDistance: Double?
  
  var workoutName: String {
    switch workoutType {
    case .running:
      return "Running"
    case .cycling:
      return "Cycling"
    case .swimming:
      return "Swimming"
    case .walking:
      return "Walking"
    case .yoga:
      return "Yoga"
    case .functionalStrengthTraining:
      return "Strength Training"
    case .traditionalStrengthTraining:
      return "Weight Training"
    case .coreTraining:
      return "Core Training"
    case .elliptical:
      return "Elliptical"
    case .stairClimbing:
      return "Stair Climbing"
    case .hiking:
      return "Hiking"
    case .dance:
      return "Dance"
    default:
      return "Other"
    }
  }
  
  var icon: String {
    switch workoutType {
    case .running:
      return "figure.run"
    case .cycling:
      return "bicycle"
    case .swimming:
      return "figure.pool.swim"
    case .walking:
      return "figure.walk"
    case .yoga:
      return "figure.mind.and.body"
    case .functionalStrengthTraining, .traditionalStrengthTraining:
      return "dumbbell.fill"
    case .coreTraining:
      return "figure.core.training"
    case .elliptical:
      return "figure.elliptical"
    case .stairClimbing:
      return "figure.stairs"
    case .hiking:
      return "figure.hiking"
    case .dance:
      return "figure.dance"
    default:
      return "figure.mixed.cardio"
    }
  }
  
  var formattedDuration: String {
    let hours = Int(duration) / 3600
    let minutes = (Int(duration) % 3600) / 60
    
    if hours > 0 {
      return "\(hours)h \(minutes)m"
    } else {
      return "\(minutes)m"
    }
  }
  
  var formattedDate: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: startDate)
  }
}
