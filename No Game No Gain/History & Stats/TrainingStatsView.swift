//
//  TrainingStatsView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 20/01/2025.
//

import Charts
import SwiftData
import SwiftUI

struct TrainingStatsView: View {
    @Query private var sessions: [WorkoutSession]
    @Query private var exercises: [Exercise]
    @State private var selectedRange: TrainingStatsMath.Range = .week
    @State private var selectedMetric: TrainingStatsMath.Metric = .volume

    var body: some View {
        let now = Date()
        let calendar = Calendar.current
        let inputs = sessions.map(TrainingStatsMath.SessionInput.init)
        let points = TrainingStatsMath.chartPoints(
            sessions: inputs,
            range: selectedRange,
            now: now,
            calendar: calendar
        )
        let records = TrainingStatsMath.records(
            sessions: inputs,
            exercises: exercises.map(TrainingStatsMath.ExerciseBest.init)
        )
        let effort = TrainingStatsMath.effortRows(
            sessions: inputs,
            range: selectedRange,
            now: now,
            calendar: calendar
        )

        ScrollView {
            VStack(spacing: 20) {
                Picker("Range", selection: $selectedRange) {
                    ForEach(TrainingStatsMath.Range.allCases) { range in
                        Text(range.title).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if points.isEmpty {
                    Text("There are no finished workouts.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 180)
                        .padding()
                } else {
                    TrainingStatsChart(stats: points, selectedMetric: selectedMetric)
                        .frame(height: 300)
                        .padding()
                }

                Picker("Metric", selection: $selectedMetric) {
                    ForEach(TrainingStatsMath.Metric.allCases) { metric in
                        Text(metric.title).tag(metric)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                RecordsSection(records: records)
                EffortSection(rows: effort)
            }
            .padding(.vertical)
        }
        .navigationTitle("Training Stats")
    }
}

private struct TrainingStatsChart: View {
    let stats: [TrainingStatsMath.ChartPoint]
    let selectedMetric: TrainingStatsMath.Metric

    var body: some View {
        Chart {
            ForEach(stats) { stat in
                LineMark(
                    x: .value("Date", stat.date),
                    y: .value(selectedMetric.title, selectedMetric.plottedValue(of: stat))
                )
                .foregroundStyle(.blue)

                PointMark(
                    x: .value("Date", stat.date),
                    y: .value(selectedMetric.title, selectedMetric.plottedValue(of: stat))
                )
                .foregroundStyle(.blue)
            }
        }
        .chartYAxisLabel(selectedMetric.unit)
    }
}

private struct RecordsSection: View {
    let records: [TrainingStatsMath.Record]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Records")
                .font(.title2)
                .bold()
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(records) { record in
                        RecordCard(record: record)
                            .frame(width: 200)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

private struct RecordCard: View {
    let record: TrainingStatsMath.Record

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(record.exerciseName)
                .font(.headline)

            if let weight = record.weight {
                Text("\(weight, specifier: "%.1f") kg")
                    .font(.title3)
                    .bold()
            }

            if let reps = record.reps {
                Text("\(reps) reps")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

private struct EffortSection: View {
    let rows: [TrainingStatsMath.EffortRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Effort")
                .font(.title2)
                .bold()

            ForEach(rows) { row in
                HStack {
                    Text(row.workoutName)
                        .font(.headline)
                    Spacer()
                    Text("\(row.effort)")
                        .font(.title3)
                        .bold()
                }
            }
        }
        .padding(.horizontal)
    }
}

extension TrainingStatsMath.SessionInput {
    init(_ session: WorkoutSession) {
        self.init(
            workoutName: session.workout.name,
            endTime: session.endTime,
            duration: session.duration,
            effort: session.effort,
            sets: session.doneSets.map { TrainingStatsMath.SetInput(weight: $0.weight, reps: $0.reps) }
        )
    }
}

extension TrainingStatsMath.ExerciseBest {
    init(_ exercise: Exercise) {
        self.init(
            name: exercise.name,
            personalBestWeight: exercise.personalBestWeight,
            personalBestReps: exercise.personalBestReps
        )
    }
}

#Preview {
    TrainingStatsView()
        .modelContainer(for: [Exercise.self, Workout.self, WorkoutSession.self], inMemory: true)
}
