//
//  SleepAnalysisView.swift
//  GiantBombSwiftUI
//
//  Created by Fred Strout on 3/27/26.
//

import SwiftUI
import HealthKit

struct SleepAnalysisView: View {
  @StateObject var viewModel: HealthKitViewModel
  @State private var showingAlert = false
  @State private var selectedDays = 7
  
  var body: some View {
    NavigationStack {
      Group {
        if !viewModel.isAuthorized {
          authorizationView
        } else {
          sleepView
        }
      }
      .navigationTitle("Sleep Analysis")
      .alert("Error", isPresented: $showingAlert) {
        Button("OK") { }
      } message: {
        Text(viewModel.error?.localizedDescription ?? "Unknown error")
      }
    }
    .onChange(of: viewModel.error != nil) { _, hasError in
      showingAlert = hasError
    }
  }
  
  // MARK: - Authorization View
  
  private var authorizationView: some View {
    VStack(spacing: 20) {
      Image(systemName: "bed.double.fill")
        .font(.system(size: 80))
        .foregroundStyle(.indigo)
      
      Text("HealthKit Access")
        .font(.title)
        .bold()
      
      Text("Grant access to view your sleep analysis data.")
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)
        .padding(.horizontal)
      
      Button {
        Task {
          await viewModel.requestAuthorization()
        }
      } label: {
        if viewModel.isLoading {
          ProgressView()
            .tint(.white)
        } else {
          Text("Grant Access")
        }
      }
      .buttonStyle(.borderedProminent)
      .disabled(viewModel.isLoading)
    }
    .padding()
  }
  
  // MARK: - Sleep View
  
  private var sleepView: some View {
    VStack {
      if viewModel.isLoading {
        ProgressView()
          .padding()
      } else if viewModel.sleepData.isEmpty {
        ContentUnavailableView(
          "No Sleep Data",
          systemImage: "bed.double.fill",
          description: Text("No sleep data available.")
        )
      } else {
        List {
          Section {
            sleepSummary
          }
          
          Section("Sleep Sessions") {
            ForEach(groupedSleepData.keys.sorted(by: >), id: \.self) { date in
              if let sessions = groupedSleepData[date] {
                SleepSessionView(date: date, sessions: sessions)
              }
            }
          }
        }
      }
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Menu {
          Button("Last 7 days") {
            selectedDays = 7
            Task { await viewModel.fetchSleepData(days: 7) }
          }
          Button("Last 14 days") {
            selectedDays = 14
            Task { await viewModel.fetchSleepData(days: 14) }
          }
          Button("Last 30 days") {
            selectedDays = 30
            Task { await viewModel.fetchSleepData(days: 30) }
          }
        } label: {
          Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
        }
      }
    }
    .task {
      await viewModel.fetchSleepData(days: selectedDays)
    }
  }
  
  // MARK: - Sleep Summary
  
  private var sleepSummary: some View {
    VStack(spacing: 12) {
      HStack {
        SleepStatCard(
          title: "Average Sleep",
          value: averageSleep,
          icon: "moon.stars.fill",
          color: .indigo
        )
        
        SleepStatCard(
          title: "Total Sessions",
          value: "\(groupedSleepData.count)",
          icon: "calendar",
          color: .blue
        )
      }
      
      HStack {
        SleepStatCard(
          title: "Longest Sleep",
          value: longestSleep,
          icon: "arrow.up.right",
          color: .green
        )
        
        SleepStatCard(
          title: "Shortest Sleep",
          value: shortestSleep,
          icon: "arrow.down.right",
          color: .orange
        )
      }
    }
    .listRowInsets(EdgeInsets())
    .listRowBackground(Color.clear)
  }
  
  // MARK: - Computed Properties
  
  private var groupedSleepData: [Date: [SleepData]] {
    Dictionary(grouping: viewModel.sleepData) { sleep in
      Calendar.current.startOfDay(for: sleep.startDate)
    }
  }
  
  private var averageSleep: String {
    guard !groupedSleepData.isEmpty else { return "0h 0m" }
    
    let totalDuration = groupedSleepData.values.map { sessions in
      sessions.reduce(0) { $0 + $1.duration }
    }.reduce(0, +)
    
    let average = totalDuration / Double(groupedSleepData.count)
    let hours = Int(average) / 3600
    let minutes = (Int(average) % 3600) / 60
    
    return "\(hours)h \(minutes)m"
  }
  
  private var longestSleep: String {
    let longest = groupedSleepData.values.map { sessions in
      sessions.reduce(0) { $0 + $1.duration }
    }.max() ?? 0
    
    let hours = Int(longest) / 3600
    let minutes = (Int(longest) % 3600) / 60
    
    return "\(hours)h \(minutes)m"
  }
  
  private var shortestSleep: String {
    let shortest = groupedSleepData.values.map { sessions in
      sessions.reduce(0) { $0 + $1.duration }
    }.min() ?? 0
    
    let hours = Int(shortest) / 3600
    let minutes = (Int(shortest) % 3600) / 60
    
    return "\(hours)h \(minutes)m"
  }
}

// MARK: - Supporting Views

struct SleepSessionView: View {
  let date: Date
  let sessions: [SleepData]
  
  private var totalDuration: String {
    let total = sessions.reduce(0) { $0 + $1.duration }
    let hours = Int(total) / 3600
    let minutes = (Int(total) % 3600) / 60
    return "\(hours)h \(minutes)m"
  }
  
  private var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(dateFormatter.string(from: date))
          .font(.headline)
        
        Spacer()
        
        Text(totalDuration)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      
      ForEach(sessions) { sleep in
        HStack {
          Circle()
            .fill(colorForSleepStage(sleep.value))
            .frame(width: 8, height: 8)
          
          Text(sleep.sleepStage)
            .font(.subheadline)
          
          Spacer()
          
          Text(sleep.formattedDuration)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
    .padding(.vertical, 4)
  }
  
  private func colorForSleepStage(_ value: HKCategoryValueSleepAnalysis) -> Color {
    switch value {
    case .asleepDeep:
      return .indigo
    case .asleepCore:
      return .blue
    case .asleepREM:
      return .purple
    case .awake:
      return .orange
    case .inBed:
      return .gray
    default:
      return .secondary
    }
  }
}

struct SleepStatCard: View {
  let title: String
  let value: String
  let icon: String
  let color: Color
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Image(systemName: icon)
          .foregroundStyle(color)
        
        Spacer()
      }
      
      Text(value)
        .font(.title2)
        .bold()
      
      Text(title)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(color.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}

#Preview {
  SleepAnalysisView(viewModel: HealthKitViewModel(container: .preview))
}
 
