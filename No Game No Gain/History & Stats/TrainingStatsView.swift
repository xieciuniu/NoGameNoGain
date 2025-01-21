//
//  TrainingStatsView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 20/01/2025.
//

import SwiftUI
import Charts

// MARK: - Models
struct TrainingStats: Identifiable {
    let id = UUID()
    let date: Date
    let totalWeight: Double
    let averageSets: Double
    let averageReps: Double
    let duration: TimeInterval
}

struct PersonalRecord: Identifiable {
    let id = UUID()
    let exerciseName: String
    let weight: Double
    let date: Date
}

// MARK: - ViewModel
class TrainingStatsViewModel: ObservableObject {
    @Published var selectedTimeRange: TimeRange = .week
        @Published var selectedMetric: TrainingMetric = .totalWeight
        @Published var trainingStats: [TrainingStats] = []
        @Published var personalRecords: [PersonalRecord] = []
        
        enum TimeRange {
            case week, month, year
            
            var title: String {
                switch self {
                case .week: return "Week"
                case .month: return "Month"
                case .year: return "Year"
                }
            }
        }
        
        enum TrainingMetric: String, CaseIterable {
            case totalWeight = "Total Weight"
            case avgSets = "Average Sets"
            case avgReps = "Average Reps"
            
            var title: String {
                return self.rawValue
            }
            
            func getValue(from stat: TrainingStats) -> Double {
                switch self {
                case .totalWeight: return stat.totalWeight
                case .avgSets: return stat.averageSets
                case .avgReps: return stat.averageReps
                }
            }
            
            var unit: String {
                switch self {
                case .totalWeight: return "kg"
                case .avgSets: return "sets"
                case .avgReps: return "reps"
                }
            }
        }
    
    init() {
        loadMockData()
    }
    
    private func loadMockData() {
        // Przykładowe dane treningowe
        let calendar = Calendar.current
        let now = Date()
        
        // Generowanie danych dla ostatnich 12 miesięcy
        trainingStats = (0..<365).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
            return TrainingStats(
                date: date,
                totalWeight: Double.random(in: 1000...3000),
                averageSets: Double.random(in: 3...5),
                averageReps: Double.random(in: 8...12),
                duration: TimeInterval.random(in: 3600...7200)
            )
        }
        
        // Przykładowe rekordy osobiste
        personalRecords = [
            PersonalRecord(exerciseName: "Przysiad", weight: 140.0, date: Date()),
            PersonalRecord(exerciseName: "Martwy ciąg", weight: 180.0, date: Date()),
            PersonalRecord(exerciseName: "Wyciskanie leżąc", weight: 100.0, date: Date())
        ]
    }
}

// MARK: - Views
struct TrainingStatsView: View {
    @StateObject private var viewModel = TrainingStatsViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Selector dla zakresu czasu
                Picker("Zakres czasu", selection: $viewModel.selectedTimeRange) {
                    ForEach([TrainingStatsViewModel.TimeRange.week,
                            .month,
                             .year], id: \.self) { range in
                        Text(range.title).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Główny wykres
                ChartView(stats: viewModel.trainingStats,
                         selectedMetric: viewModel.selectedMetric)
                    .frame(height: 300)
                    .padding()
                
                // Selector typu danych
                Picker("Data type", selection: $viewModel.selectedMetric) {
                    ForEach(TrainingStatsViewModel.TrainingMetric.allCases, id: \.self) { metric in
                        Text(metric.title).tag(metric)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Sekcja najlepszych wyników
                BestResultsSection(stats: viewModel.trainingStats,
                                 records: viewModel.personalRecords)
            }
            .padding(.vertical)
        }
        .navigationTitle("Training Stats")
    }
}

struct ChartView: View {
    let stats: [TrainingStats]
    let selectedMetric: TrainingStatsViewModel.TrainingMetric
    
    var body: some View {
        Chart {
            ForEach(stats) { stat in
                LineMark(
                    x: .value("Data", stat.date),
                    y: .value(selectedMetric.title,
                            selectedMetric.getValue(from: stat))
                )
                .foregroundStyle(.blue)
                
                // Linia trendu
                RuleMark(
                    y: .value("Średnia",
                            stats.map { selectedMetric.getValue(from: $0) }
                                .reduce(0, +) / Double(stats.count))
                )
                .foregroundStyle(.red.opacity(0.3))
            }
        }
    }
}

struct BestResultsSection: View {
    let stats: [TrainingStats]
    let records: [PersonalRecord]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Best Results")
                .font(.title2)
                .bold()
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(records) { record in
                        RecordCard(record: record)
                            .frame(width: 200) // Stała szerokość dla wszystkich kart
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct RecordCard: View {
    let record: PersonalRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(record.exerciseName)
                .font(.headline)
                .lineLimit(1)
            
            Text("\(record.weight, specifier: "%.1f") kg")
                .font(.title3)
                .bold()
            
            Text(record.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    TrainingStatsView()
}
