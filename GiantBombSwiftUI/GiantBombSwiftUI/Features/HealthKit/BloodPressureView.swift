//
//  BloodPressureView.swift
//  GiantBombSwiftUI
//
//  Created by Fred Strout on 3/27/26.
//

import SwiftUI

struct BloodPressureView: View {
  @StateObject var viewModel: HealthKitViewModel
  @State private var showingAlert = false
  @State private var selectedDays = 30
  
  var body: some View {
    NavigationStack {
      Group {
        if !viewModel.isAuthorized {
          authorizationView
        } else {
          bloodPressureView
        }
      }
      .navigationTitle("Blood Pressure")
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
      Image(systemName: "waveform.path.ecg")
        .font(.system(size: 80))
        .foregroundStyle(.red)
      
      Text("HealthKit Access")
        .font(.title)
        .bold()
      
      Text("Grant access to view your blood pressure data.")
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
  
  // MARK: - Blood Pressure View
  
  private var bloodPressureView: some View {
    VStack {
      if viewModel.isLoading {
        ProgressView()
          .padding()
      } else if viewModel.bloodPressureData.isEmpty {
        ContentUnavailableView(
          "No Blood Pressure Data",
          systemImage: "waveform.path.ecg",
          description: Text("No blood pressure readings available.")
        )
      } else {
        List {
          Section {
            bloodPressureSummary
          }
          
          Section("Recent Readings") {
            ForEach(viewModel.bloodPressureData.indices, id: \.self) { index in
              let reading = viewModel.bloodPressureData[index]
              BloodPressureRow(
                systolic: reading.systolic,
                diastolic: reading.diastolic,
                date: reading.date
              )
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
            Task { await viewModel.fetchBloodPressure(days: 7) }
          }
          Button("Last 30 days") {
            selectedDays = 30
            Task { await viewModel.fetchBloodPressure(days: 30) }
          }
          Button("Last 90 days") {
            selectedDays = 90
            Task { await viewModel.fetchBloodPressure(days: 90) }
          }
        } label: {
          Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
        }
      }
    }
    .task {
      await viewModel.fetchBloodPressure(days: selectedDays)
    }
  }
  
  // MARK: - Blood Pressure Summary
  
  private var bloodPressureSummary: some View {
    VStack(spacing: 12) {
      HStack {
        BPStatCard(
          title: "Avg Systolic",
          value: String(format: "%.0f", averageSystolic),
          unit: "mmHg",
          color: .red
        )
        
        BPStatCard(
          title: "Avg Diastolic",
          value: String(format: "%.0f", averageDiastolic),
          unit: "mmHg",
          color: .blue
        )
      }
      
      HStack {
        BPStatCard(
          title: "Highest",
          value: "\(Int(maxSystolic))/\(Int(maxDiastolic))",
          unit: "mmHg",
          color: .orange
        )
        
        BPStatCard(
          title: "Lowest",
          value: "\(Int(minSystolic))/\(Int(minDiastolic))",
          unit: "mmHg",
          color: .green
        )
      }
      
      // Blood Pressure Guidelines
      VStack(alignment: .leading, spacing: 8) {
        Text("Blood Pressure Guidelines")
          .font(.caption)
          .foregroundStyle(.secondary)
        
        HStack(spacing: 16) {
          GuidelineIndicator(color: .green, label: "Normal: <120/80")
          GuidelineIndicator(color: .yellow, label: "Elevated: 120-129/80")
        }
        
        HStack(spacing: 16) {
          GuidelineIndicator(color: .orange, label: "High Stage 1: 130-139/80-89")
          GuidelineIndicator(color: .red, label: "High Stage 2: ≥140/90")
        }
      }
      .padding()
      .background(Color.secondary.opacity(0.1))
      .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .listRowInsets(EdgeInsets())
    .listRowBackground(Color.clear)
  }
  
  // MARK: - Computed Properties
  
  private var averageSystolic: Double {
    guard !viewModel.bloodPressureData.isEmpty else { return 0 }
    return viewModel.bloodPressureData.map { $0.systolic }.reduce(0, +) / Double(viewModel.bloodPressureData.count)
  }
  
  private var averageDiastolic: Double {
    guard !viewModel.bloodPressureData.isEmpty else { return 0 }
    return viewModel.bloodPressureData.map { $0.diastolic }.reduce(0, +) / Double(viewModel.bloodPressureData.count)
  }
  
  private var maxSystolic: Double {
    viewModel.bloodPressureData.map { $0.systolic }.max() ?? 0
  }
  
  private var maxDiastolic: Double {
    viewModel.bloodPressureData.map { $0.diastolic }.max() ?? 0
  }
  
  private var minSystolic: Double {
    viewModel.bloodPressureData.map { $0.systolic }.min() ?? 0
  }
  
  private var minDiastolic: Double {
    viewModel.bloodPressureData.map { $0.diastolic }.min() ?? 0
  }
}

// MARK: - Supporting Views

struct BloodPressureRow: View {
  let systolic: Double
  let diastolic: Double
  let date: Date
  
  private var category: (String, Color) {
    if systolic < 120 && diastolic < 80 {
      return ("Normal", .green)
    } else if systolic < 130 && diastolic < 80 {
      return ("Elevated", .yellow)
    } else if systolic < 140 || diastolic < 90 {
      return ("High Stage 1", .orange)
    } else {
      return ("High Stage 2", .red)
    }
  }
  
  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 6) {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
          Text("\(Int(systolic))")
            .font(.title2)
            .bold()
            .foregroundStyle(.red)
          
          Text("/")
            .font(.title3)
            .foregroundStyle(.secondary)
          
          Text("\(Int(diastolic))")
            .font(.title2)
            .bold()
            .foregroundStyle(.blue)
          
          Text("mmHg")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        
        Text(date.formatted(date: .abbreviated, time: .shortened))
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      
      Spacer()
      
      VStack(alignment: .trailing, spacing: 4) {
        Text(category.0)
          .font(.caption)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(category.1.opacity(0.2))
          .foregroundStyle(category.1)
          .clipShape(Capsule())
      }
    }
    .padding(.vertical, 4)
  }
}

struct BPStatCard: View {
  let title: String
  let value: String
  let unit: String
  let color: Color
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.caption)
        .foregroundStyle(.secondary)
      
      HStack(alignment: .firstTextBaseline, spacing: 4) {
        Text(value)
          .font(.title2)
          .bold()
        
        Text(unit)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(color.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}

struct GuidelineIndicator: View {
  let color: Color
  let label: String
  
  var body: some View {
    HStack(spacing: 6) {
      Circle()
        .fill(color)
        .frame(width: 8, height: 8)
      
      Text(label)
        .font(.caption2)
    }
  }
}

#Preview {
  BloodPressureView(viewModel: HealthKitViewModel(container: .preview))
}
