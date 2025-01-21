import SwiftUI
import SwiftData

struct LastWorkoutAndStatsView: View {
    @Binding var path: NavigationPath
    @Query var workoutSessions: [WorkoutSession]
    
    private var lastSession: WorkoutSession? {
        workoutSessions.sorted { $0.startTime > $1.startTime }.first
    }
    
    private var weeklyWorkouts: Int {
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        return workoutSessions.filter { session in
            session.startTime >= oneWeekAgo
        }.count
    }
    
    private var monthlyAverage: Double {
        let calendar = Calendar.current
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        
        let monthlyWorkouts = workoutSessions.filter { session in
            session.startTime >= oneMonthAgo
        }.count
        
        return Double(monthlyWorkouts) / 4.0 // Average per week
    }
    
    private var monthlyVolume: Double {
        let calendar = Calendar.current
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        
        return workoutSessions
            .filter { $0.startTime >= oneMonthAgo }
            .reduce(0) { $0 + $1.totalWeight() }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // Last Workout Card
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    Text("Last Workout")
                        .font(.subheadline)
                        .bold()
                }
                .padding(.bottom, 2)
                
                if let lastWorkout = lastSession {
                    Text(lastWorkout.workout.name)
                        .font(.title3)
                        .bold()
                    
                    Text("\(formatDate(lastWorkout.startTime)) • \(formatDuration(lastWorkout.duration))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("\(lastWorkout.workout.exercises.count) exercises • \(lastWorkout.doneSets.count) sets")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Text("Total Volume")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(lastWorkout.totalWeight())) kg")
                            .font(.caption)
                            .bold()
                    }
                    .padding(.top, 2)
                } else {
                    Text("No workouts yet")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding()
            .background(Color(red: 26/255, green: 26/255, blue: 26/255))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onTapGesture {
                path.append("WorkoutHistory")
            }
            
            // Training Stats Card
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(.secondary)
                    Text("Training Stats")
                        .font(.subheadline)
                        .bold()
                }
                .padding(.bottom, 2)
                
                VStack(spacing: 8) {
                    HStack {
                        Text("This Week")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(weeklyWorkouts) workouts")
                            .font(.callout)
                            .bold()
                    }
                    
                    HStack {
                        Text("Weekly Avg")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.1f workouts", monthlyAverage))
                            .font(.caption)
                            .bold()
                    }
                    
                    HStack {
                        Text("Monthly Volume")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(monthlyVolume)) kg")
                            .font(.caption)
                            .bold()
                    }
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding()
            .background(Color(red: 26/255, green: 26/255, blue: 26/255))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onTapGesture {
                path.append("WorkoutStats")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
}

#Preview {
    @Previewable @State var path = NavigationPath()
    return LastWorkoutAndStatsView(path: $path)
}
