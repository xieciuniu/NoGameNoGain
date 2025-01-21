//
//  WorkoutHistoryView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 21/01/2025.
//

import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @Query(sort: \WorkoutSession.startTime, order: .reverse) var workoutSessions: [WorkoutSession]
    @State private var expandedSession: WorkoutSession?
    @State private var expandedExercise: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Workouts List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(workoutSessions) { session in
                        WorkoutSessionCard(
                            session: session,
                            isExpanded: session == expandedSession,
                            expandedExercise: $expandedExercise
                        )
                        .onTapGesture {
                            withAnimation(.spring(duration: 0.3)) {
                                if expandedSession == session {
                                    expandedSession = nil
                                } else {
                                    expandedSession = session
                                }
                                expandedExercise = nil
                            }
                        }
                    }
                }
                .padding()
            }
            
            // Export Button
            Button(action: exportToPDF) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export Training History")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(red: 26/255, green: 26/255, blue: 26/255))
                .foregroundColor(.white)
            }
        }
        .background(Color.black)
        .navigationTitle("Training History")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Text("Back")
                        .foregroundStyle(.white)
                }
            }
        }
    }
    
    private func exportToPDF() {
        // TODO: Implement PDF export functionality
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
                .foregroundColor(isSelected ? .white : .gray)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.white.opacity(0.2) : Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

struct WorkoutSessionCard: View {
    let session: WorkoutSession
    let isExpanded: Bool
    @Binding var expandedExercise: String?
    
    // Grupowanie serii według ćwiczeń
    private var exerciseGroups: [String: [DoneSets]] {
        Dictionary(grouping: session.doneSets) { $0.exerciseName }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Session Header
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDate(session.startTime))
                    .font(.title3)
                    .bold()
                
                Text(formatDuration(session.duration))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("\(exerciseGroups.count) exercises • \(session.doneSets.count) sets")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(red: 26/255, green: 26/255, blue: 26/255))
            
            // Expanded Details
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(Array(exerciseGroups.keys.sorted()), id: \.self) { exerciseName in
                        if let sets = exerciseGroups[exerciseName] {
                            ExerciseDetailRow(
                                exerciseName: exerciseName,
                                sets: sets,
                                isExpanded: expandedExercise == exerciseName,
                                onTap: {
                                    withAnimation(.spring(duration: 0.3)) {
                                        if expandedExercise == exerciseName {
                                            expandedExercise = nil
                                        } else {
                                            expandedExercise = exerciseName
                                        }
                                    }
                                }
                            )
                            Divider()
                                .background(Color.gray.opacity(0.2))
                        }
                    }
                }
                .background(Color(red: 26/255, green: 26/255, blue: 26/255))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}


struct ExerciseDetailRow: View {
    let exerciseName: String
    let sets: [DoneSets]
    let isExpanded: Bool
    let onTap: () -> Void
    
    private var totalVolume: Double {
        sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Exercise Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exerciseName)
                        .font(.body)
                    
                    Text("\(sets.count) sets • \(Int(totalVolume))kg total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .foregroundStyle(.secondary)
            }
            .padding()
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
            
            // Expanded Sets Details
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(sets.sorted()) { set in
                        HStack {
                            Text("Set \(set.numberOfSet)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Text("\(Int(set.weight))kg × \(set.reps)")
                                .font(.caption)
                            
                            if !set.isDone {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .background(Color(red: 20/255, green: 20/255, blue: 20/255))
            }
        }
    }
}

#Preview {
    NavigationStack {
        WorkoutHistoryView()
    }
}
