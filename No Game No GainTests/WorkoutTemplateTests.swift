//
//  WorkoutTemplateTests.swift
//  No Game No GainTests
//

import Foundation
import SwiftData
import Testing
@testable import No_Game_No_Gain

@MainActor
struct WorkoutTemplateTests {
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Workout.self, Exercise.self, WorkoutSession.self])
        let configuration = ModelConfiguration(UUID().uuidString, schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    @Test("The catalog is Full Body, Push, and Pull, and nothing else")
    func testCatalogNames() {
        #expect(WorkoutTemplates.catalog.map(\.name) == ["Full Body", "Push", "Pull"])
        #expect(WorkoutTemplates.catalog.count == 3)
    }

    @Test("Full Body Back Squat is 3 sets of 5 to 8, resting 180, progressing by 2.5")
    func testFullBodyBackSquat() {
        let squat = WorkoutTemplates.catalog
            .first { $0.name == "Full Body" }?
            .exercises
            .first { $0.name == "Back Squat" }
        #expect(squat?.repFloor == 5)
        #expect(squat?.repCeiling == 8)
        #expect(squat?.restTime == 180)
        #expect(squat?.progressPerWorkout == 2.5)
        #expect(squat?.numberOfSets == 3)
    }

    @Test("A no-weight answer stores no load and does not keep the 60 kg default")
    func testNoWeightAnswerReplacesTheDefaultSet() {
        let template = WorkoutTemplates.catalog.first { $0.name == "Full Body" }
        let workout = WorkoutTemplates.makeWorkout(
            from: template!,
            answers: Array(repeating: .noWeightYet, count: template?.exercises.count ?? 0)
        )
        let row = workout.exercises.first { $0.name == "Bent-Over Row" }
        #expect(row?.sets.count == 3)
        #expect(row?.sets.allSatisfy {
            $0.weightUnset && $0.weight == 0 && $0.reps == 6 && $0.progress
        } == true)
        #expect(row?.sets.contains { $0.weight == 60 } == false)
        #expect(row?.repFloor == 6)
        #expect(row?.repCeiling == 10)
        #expect(row?.restTime == 120)
        #expect(row?.progressPerWorkout == 2.5)
        #expect(row?.numberOfSets == 3)
        #expect(row?.order == 2)

        let untouched = Exercise(name: "Bent-Over Row", order: 0)
        #expect(untouched.sets.first?.weight == 60)
        #expect(workout.exercises.allSatisfy { exercise in
            exercise.sets.allSatisfy { $0.weightUnset && $0.weight == 0 && $0.weight != 60 }
        } == true)
    }

    @Test("A typed weight of 80 is the planned weight on every set")
    func testTypedWeightBecomesThePlannedWeight() {
        let template = WorkoutTemplates.catalog.first { $0.name == "Push" }!
        var answers = Array(repeating: TemplateWeightAnswer.noWeightYet, count: template.exercises.count)
        let benchIndex = template.exercises.firstIndex { $0.name == "Bench Press" }!
        answers[benchIndex] = .weight(80)
        let workout = WorkoutTemplates.makeWorkout(from: template, answers: answers)
        let bench = workout.exercises.first { $0.name == "Bench Press" }
        #expect(bench?.sets.count == 4)
        #expect(bench?.sets.allSatisfy {
            $0.weight == 80 && $0.weightUnset == false && $0.reps == 5 && $0.progress
        } == true)
    }

    @Test("Building a copy does not create a workout session")
    func testCopyDoesNotCreateSession() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let template = WorkoutTemplates.catalog[0]
        let workout = WorkoutTemplates.makeWorkout(
            from: template,
            answers: Array(repeating: .weight(80), count: template.exercises.count)
        )
        context.insert(workout)
        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        #expect(sessions.count == 0)
    }

    @Test("A saved copy does not remove the template, and deleting the copy leaves three")
    func testDeletingCopyLeavesCatalog() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let template = WorkoutTemplates.catalog[0]
        let workout = WorkoutTemplates.makeWorkout(
            from: template,
            answers: Array(repeating: .noWeightYet, count: template.exercises.count)
        )
        context.insert(workout)
        #expect(WorkoutTemplates.catalog.map(\.name) == ["Full Body", "Push", "Pull"])
        context.delete(workout)
        #expect(WorkoutTemplates.catalog.count == 3)
        #expect(WorkoutTemplates.catalog.map(\.name) == ["Full Body", "Push", "Pull"])
    }
}
