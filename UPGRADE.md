# Workout upgrade plan

Work the tasks in order. The first sessions stay inside the workout loop: who owns an in-progress session, whether relaunch returns to the same place, and whether ending the workout is tested without the screen. Health recording comes after that owner exists. A Watch app and AirPods heart rate come last.

## How agents should use this file

Take the first task whose dependencies are all `done` and whose status is `not started`. Set that status to `in progress` before editing code. When the work matches the **Done when** list, set the status to `done` and fill **Session** and **Report**. Use `blocked` when you stop before that, and say why in **Report**.

Leave every other task’s status block as you found it. Add new Swift files under `WorkoutSession/` to `No Game No Gain.xcodeproj/project.pbxproj` (file reference, build file, group, and Sources phase). The test target and `History & Stats` already sync from disk.

Allowed status values: `not started`, `in progress`, `done`, `blocked`.

## Overview

No Game No Gain can plan a workout, log sets, time rest, and award experience. The live session has no single owner. Starting writes a SwiftData `WorkoutSession` and a `UserDefaults` flag from `SelectWorkoutView`. `ContentView` shows `WorkoutView` only when both an open session (`endTime == nil`) and `isSession` are set. Pause and resume talk to `Stopwatch` and a second flag, `isRunning`. End is a button in `WorkoutView` that calls `WorkoutViewModel.workoutEnded`. The view model is an `ObservableObject` nested in an extension of `WorkoutView`, and its `WorkoutState` pause path is unused.

HealthKit already asks to write workouts and body mass, and to read energy, heart rate, steps, body mass, sleep, and workouts. The only save is body mass. Heart rate is authorized and never read during a session. There is no Watch app.

The upgrade keeps SwiftData as the record of the plan and the completed sets, and keeps `Stopwatch` as the clock. It adds one coordinator for start, pause, resume, end, and relaunch, then teaches that coordinator to record a Traditional Strength Training workout in Health. Live heart rate is a later session, owned by the Watch, with an iOS 26 iPhone session for AirPods after that. Workout alerts stay local notifications: the rest alert must also show while the app is open, End must clear the queue, and seven minutes without an action must remind the user that the workout is still in progress.

## Current problems

- Start, pause, resume, and end are spread across `SelectWorkoutView`, `ContentView`, `WorkoutView`, `WorkoutView-ViewModel.swift`, `Stopwatch`, and two `UserDefaults` keys (`isSession`, `isRunning`).
- `currentExercise` lives only in memory. Relaunch can reopen the session and the clocks, then `begin()` starts again at the first exercise.
- Set completion, load progression, personal bests, and end-of-workout experience run inside the view type, so they are hard to test without the screen. `WorkoutSessionTests` cover the model, not those rules.
- `HealthKitManager` is one class for authorization, charts, sleep, and body mass. Screens construct their own instances. The workout write permission is unused.
- A third-party app cannot open Apple’s Fitness Strength Training screen. The supported version of that idea is this app’s own `HKWorkoutSession` with activity type `.traditionalStrengthTraining`. The Watch must own that session to sample the Watch heart rate. AirPods heart rate is available to a workout session on iOS 26, not through a private earbuds API.
- `WorkoutSession.totalWeight()` adds the load of each set and does not multiply by reps. Leave that function as it is. Volume is a separate number on the view model.
- Rest alerts are local notifications from `WorkoutNotificationManager`. They show when the app is in the background. Nothing implements `UNUserNotificationCenterDelegate`, so the same alert is not presented while the workout screen is open. `cancelCurrentNotification()` drops only an in-memory id, End never calls it, and that id is lost when the screen is recreated. There is no inactivity reminder.

## Suggested order and dependencies

Do these in order. W5 touches different files, so it may run beside W1–W4. Everything else is serial because it shares the workout screen or the session owner.

| Order | Task | Depends on | May run beside |
| --- | --- | --- | --- |
| 1 | W1. One owner for the live workout | — | W5 |
| 2 | W2. Workout notifications | W1 | W5 |
| 3 | W3. Restore exercise and set | W1, W2 | W5 |
| 4 | W4. Test completion and ending | W1, W3 | W5 |
| 5 | W5. One HealthKit entry point | — | W1–W4 |
| 6 | W6. Save the strength workout | W1, W5 | — |
| 7 | W7. Watch session and heart rate | W1, W6 | — |
| 8 | W8. iPhone session for AirPods | W6, W7 | — |

Phase A is W1–W4. Phase B is W5–W6. Phase C is W7–W8. Start a later phase only after the earlier phase’s tasks are `done`.

## Leave these as they are

- `UserAccount` JSON file storage, experience formulas, and weekly challenges.
- Chart, sleep, step, and calorie query math inside `HealthKitManager`.
- `ObservableObject` types that a task does not already have to edit. `Stopwatch` is already `@Observable`. New session and health types may use `@Observable`.
- Folder layout, Swift 6, and a single deployment target. Targets today are Swift 5.0 and iOS 17.5, 17.6, or 18.2 depending on the configuration. Gate the iOS 26 phone workout API with `if #available`.
- `SceneDelegate.swift`. It is compiled and is not the app’s scene.
- Rest timing. Rest stays on `Stopwatch` and `RestClockView`. A Health session stays running through rest. Only the workout Pause button pauses it. The rest alert is scheduled from the exercise rest interval. W2 changes how that alert is presented and cancelled. It does not change the clock.
- Notification sound settings in `NotificationSettings`. W2 keeps the default and custom sounds already used for the rest alert.
- Apple’s Fitness app. Do not try to launch its Strength Training workout.

## Tasks

### W1. One owner for the live workout

**Status:** done
**Scope:** Medium (1–2 days)
**Depends on:** none
**Session:** WorkoutCoordinator owns start, pause, resume, and end. ContentView holds it and passes it through the environment. Screens no longer write `isSession` or `isRunning`.
**Report:** An open session is a `WorkoutSession` with `endTime == nil`, and that alone shows `WorkoutView`. End stamps `endTime` and `duration` from the workout clock, then clears the clock. A second end does not rewrite them. Experience and load progression still run in `WorkoutViewModel.workoutEnded`, called from the coordinator with the frozen duration. `togglePause` and `WorkoutState` are gone. `StopwatchTests` and `WorkoutCoordinatorTests` passed on the iPhone 17 simulator.

`SelectWorkoutView.selectedWorkout` inserts a `WorkoutSession` and sets `isSession`. `ContentView` reads that flag plus the open-session query. `WorkoutView` clears the flag on End, and writes `isRunning` around `Stopwatch` on Pause and Resume. `WorkoutViewModel.togglePause` is a second, unused pause path.

Move start, pause, resume, end, and “is a workout open” into one coordinator that the screens call. SwiftData remains the saved session. An open session is one with `endTime == nil`. The stopwatch remains the clock the buttons already use. Behavior of the current buttons stays the same.

**Done when:**

- No screen writes `isSession` or `isRunning` itself.
- Start inserts one open session and shows `WorkoutView`.
- Pause freezes both clocks. Resume continues them. End sets `endTime` and `duration`, returns home, and does not advance the clock after pause.
- Relaunch during a paused workout stays paused. Relaunch during a running workout keeps wall-clock elapsed time. These match the existing `StopwatchTests`.
- The unused `togglePause` path is gone, so pause has one implementation.
- `StopwatchTests` still pass, and new tests cover start, end, and the paused relaunch rule at the coordinator.

### W2. Workout notifications

**Status:** done
**Scope:** Small (about 1 day)
**Depends on:** W1
**Session:** WorkoutNotificationManager schedules the rest alert and a repeating 7 minute inactivity reminder with stable ids. WorkoutCoordinator owns that manager. End clears both. A notification delegate presents the banner, list, and sound while the app is open.
**Report:** Rest stays “Rest Time Over” / “Time to start next set!” with the existing default or custom sound. The ids are `workout.rest` and `workout.inactivity`. The inactivity title is “Workout Still in Progress”. Pause and resume replace the reminder and leave a pending rest alert. Scheduling rest, and applying the stored weight, reps, RPE, or exercise note, does not reset the wait. A real edit does. Start arms the reminder only when a new session is inserted. A second end does not remove or schedule again. Tests inject a recorder and a clock. WorkoutNotificationTests and WorkoutCoordinatorTests passed on the iPhone 17 simulator, 19 tests and 0 failures. A visible banner still depends on the user allowing alerts.

`WorkoutNotificationManager` schedules one local notification, “Rest Time Over”, from `setComplete` and from `updateRestTimeNotification`. That request is delivered by the system when the app is in the background. The app never sets `UNUserNotificationCenter.delegate`, so iOS does not show the alert, banner, or sound while the workout screen is open. Cancel keeps a single UUID in memory and removes only that id. End does not cancel anything. Recreating the screen loses the id, so an older rest request can stay in the queue. No other code schedules notifications.

Keep these as local notifications. Do not add remote push. Show the rest alert while the app is open with the same title, body, and sound as the background notification. Give the rest request and the inactivity request stable identifiers, so a new schedule replaces the previous one and End can remove both even after the screen is recreated.

On End, `WorkoutCoordinator.end` clears every workout notification this manager scheduled. Pause, rest, Done, and Failed do not clear the whole queue. Ending twice removes nothing further and does not schedule another alert.

If the user does not perform an action for 7 minutes, send one local notification that the workout is still in progress. Starting the workout is an action, so the wait begins then. Each later action cancels that request and starts a new 7 minute wait. After the reminder fires, schedule the next one 7 minutes later until the user acts or the workout ends. The moving rest clock is not an action. Actions are Done, Failed, Previous, Next, Pause, Resume, editing weight, reps, or RPE, editing notes, and adding an exercise. The reminder still applies while the workout is paused. End cancels it.

**Done when:**

- With the workout screen open, the rest alert appears and plays its sound when the rest interval ends. The same alert still appears when the app is in the background.
- The rest request uses a stable id. Scheduling a new rest alert replaces the previous one.
- End removes the pending rest alert and the pending inactivity reminder. A relaunch after End does not deliver either.
- Seven minutes after the last action, one notification reminds the user that the workout is in progress. An action before that replaces the pending reminder. A second reminder is due 7 minutes after the first if the user still does nothing.
- Pause does not cancel the inactivity wait. Rest ticking does not reset it.
- Tests cover schedule, replace, the foreground presentation options, the 7 minute reset, and clearing both requests on End. They inject the notification center or a recorder and a clock, so they do not wait 7 minutes or require a visible banner.

### W3. Restore exercise and set

**Status:** done
**Scope:** Small (about 1 day)
**Depends on:** W1, W2
**Session:** `WorkoutSession.currentExerciseIndex` stores the sorted-exercise cursor. `begin()` reads it when the workout screen appears. Previous and Next save it. The set index still comes from `doneSets`.
**Report:** A new view model on a saved open session returns to that exercise with the same completed sets. The fields show the next planned set, or the last planned set once they are all logged. `currentSet` stays the completed count, so another Done does not reuse the last set number. Previous, Next, Done, and Failed stay inside the plan. A new session starts at index 0. An out-of-range index clamps to the last exercise. `totalWeight()` is unchanged. WorkoutExerciseRestoreTests, WorkoutSessionTests, and WorkoutCoordinatorTests passed on the iPhone 17 simulator, 25 tests and 0 failures.

`currentExercise` and the in-memory cursor start at zero every time `WorkoutView` appears. `begin()` then loads the first exercise. Completed sets already persist on `WorkoutSession.doneSets`, and `setWeightRepsSet()` can rebuild the set index for the current exercise from those sets.

Store the current exercise on the open session and read it when the workout screen appears. Keep using completed sets to choose the set index.

**Done when:**

- Force-quit on a later exercise and relaunch lands on that exercise, with the same completed sets.
- The set field shows the next planned set for that exercise, or the last planned set once they are all logged.
- Previous, Next, Done, and Failed still move within the planned workout.
- A new workout still starts at the first exercise.
- A test covers restore without opening the SwiftUI screen.

### W4. Test completion and ending

**Status:** done
**Scope:** Medium (1–2 days)
**Depends on:** W1, W3
**Session:** WorkoutCompletion logs a set and applies experience, personal records, the strength goal, and load progression. WorkoutCoordinator.end calls finish before it stamps the clock. The workout screen still schedules the rest alert and moves the set cursor.
**Report:** A completed set stores weight, reps, rest, RPE, and isDone. A failed set stays isDone false and does not raise planned load. Load progression still requires every planned set done at or above the planned weight, and it still changes only sets with progress enabled. A heavier set updates personalBestWeight, personalBestReps, and personalRecords once per improvement, including a failed heavier set. End sets endTime and duration from the workout clock and applies the existing ExperienceSystem calculation once. A second end does not award experience again. totalWeight() is unchanged. WorkoutCompletionTests, WorkoutCoordinatorTests, WorkoutNotificationTests, WorkoutExerciseRestoreTests, and WorkoutSessionTests passed on the iPhone 17 simulator, 42 tests and 0 failures.

Done and Failed call `setComplete`. That appends a `DoneSets`, updates personal bests, and can update the strength goal. `workoutEnded` stamps the session, runs `updateProgressWeight`, and adds experience through `ExperienceSystem` and the `UserAccount` file. Those rules sit inside the `WorkoutView` extension.

Pull that behavior behind the coordinator, or a type the coordinator calls, so a unit test can finish a set and end a workout without the view. Keep the current formulas.

**Done when:**

- A completed set is stored with weight, reps, rest, RPE, and `isDone`.
- A failed set is stored with `isDone == false` and does not increase load on the plan.
- Load progression still runs only when every planned set for that exercise was completed at or above the planned weight, and only on sets with progress enabled.
- A heavier set updates `personalBestWeight` and `personalBestReps` and counts a personal record once for that improvement.
- End sets `endTime` and `duration` from the workout clock and applies the existing experience calculation.
- Tests cover those cases. `WorkoutSession.totalWeight()` is unchanged.

### W5. One HealthKit entry point

**Status:** done
**Scope:** Small (about half a day)
**Depends on:** none
**Session:** Screens use `HealthKitManager.shared`. `WorkoutHealthRecording` covers authorization. Chart screens still call the concrete type.
**Report:** `TodayActivitiesView` and `BodyWeightAndPersonalGoalView` no longer construct `HealthKitManager()`. The unused `HKHealthStore` on the activities view is gone. Home already used `.shared`. Query methods are unchanged, and the public initializer stays for `HealthKitTests`. Those tests passed on the iPhone 17 Pro simulator, 4 tests and 0 failures.

`HealthKitManager` is a class with a `shared` instance and a public initializer. `TodayActivitiesView`, `BodyWeightAndPersonalGoalView`, and `HomeScreenView` create their own instances. Queries use completion handlers, plus one `async` sleep method.

Keep the query implementations. Route screen calls through one shared instance so the later workout recorder is not a third copy of `HKHealthStore`. Add a small protocol only for the operations the workout flow will need (authorization and, in W6, saving a workout). Chart screens can keep calling the concrete type.

**Done when:**

- Body weight still saves and reads back.
- Steps, active energy, and sleep on the home screen still load.
- Screens in this task no longer call `HealthKitManager()`.
- Chart, sleep, and statistic query code is unchanged apart from the call site.
- Existing `HealthKitTests` still pass.

### W6. Save the strength workout

**Status:** done
**Scope:** Medium (1–2 days)
**Depends on:** W1, W5
**Session:** WorkoutCoordinator.end asks WorkoutHealthRecorder to save one indoor traditional strength workout after the session is stamped. The sample start is the session start. The duration is the workout clock, so a pause gap is excluded. HealthKitManager writes it with HKWorkoutBuilder and does not start HKWorkoutSession.
**Report:** A second end, or an end with no sets, still leaves one sample. Pause, rest, and an open session do not save. The Health permission text is “Your Health data will be shown in app” and “Your training data will be saved in Apple Health.” HealthKitTests, WorkoutCoordinatorTests, WorkoutNotificationTests, WorkoutCompletionTests, and WorkoutHealthTests passed on the iPhone 17 Pro simulator, 33 tests and 0 failures. The tests use a fake store. A visible Health sample still needs the user to allow workout write.

The app requests permission to write `HKWorkoutType` and never saves one. On End, write one Traditional Strength Training workout for the session’s start, end, and duration. Build it from the coordinator. Indoor `.traditionalStrengthTraining` is the activity type. This slice does not start a live `HKWorkoutSession` and does not need a Watch.

While editing the purpose strings, replace the update string so the system dialog reads as a normal sentence. The build setting today is `"Your training data will be saved in Aplle Health"` with an extra pair of quotes and a typo.

**Done when:**

- Ending a workout saves one workout of type traditional strength training with that session’s start and duration.
- Ending twice, or ending with no sets, does not write a second sample for the same session.
- Pause and rest do not create workouts. A discarded or still-open session does not appear in Health.
- Body-mass save still works, and home-screen reads still work.
- The Health permission text no longer shows the extra quotes or “Aplle”.
- The save is testable with a fake store, or the test states that a simulator cannot accept the Health write and checks the sample the recorder would save.

### W7. Watch session and heart rate

**Status:** done
**Scope:** Large (3–5 days, plus a real Apple Watch)
**Depends on:** W1, W6
**Session:** Starting a workout asks HealthKit to open the Watch app with one indoor traditional strength configuration. The Watch creates the session and live builder. The phone sends the workout clock, the time since the last set, and the exercise rest setting, and the Watch sends heart rate and active energy back. Pause, resume, and end stay on the phone. The Watch has no End button. Rest does not pause the session. End of a Watch session does not write the hand-built sample. A failed Watch launch still saves through the W6 path. Recovery keeps the Watch session only while an open workout is still on the phone, on the exercise stored by W3.
**Report:** The paired Apple Watch pass matches the Done-when list. The phone shows heart rate and active energy through rest, pause and resume follow the phone, End stops the Watch and returns home with one strength workout, reopening the phone lands on the same exercise while the Watch session is still running, and a phone with no Watch still saves through W6. The Watch does not log sets, edit the plan, or read the account. Its large clock is the time since the last set, with that exercise’s rest setting under it. WorkoutHealthTests covered the save, pause, mirrored end, and recovery cases. No Game No GainTests passed on the iPhone 17 simulator, 74 tests and 0 failures, before the phone-clock channel.

Add a watchOS companion whose job is the Health workout. The phone asks HealthKit to open that watch app with an indoor traditional strength configuration (`startWatchApp(toHandle:)`). The Watch creates the primary `HKWorkoutSession` and `HKLiveWorkoutBuilder` with `HKLiveWorkoutDataSource`, then mirrors the session to the phone. The phone shows heart rate and active energy. Set logging stays on the phone. The Watch UI can be a thin running screen: heart rate, elapsed time, and end.

Pause on the phone pauses the Health session. Resume resumes it. Rest does not pause it. End stops the session and saves that builder’s workout in place of the hand-built sample from W6. Enable the workout-processing background mode. On launch, recover an active session with `recoverActiveWorkoutSession` when the Watch is still running it.

**Done when:**

- Starting a workout on the phone starts one Traditional Strength Training session on a paired Watch.
- Heart rate and active energy update on the phone during the workout, including through rest.
- Pause stops that collection. Resume continues it. End writes one workout and returns the phone home.
- Killing the phone and reopening it reattaches to a session the Watch is still running, on the same exercise from W3.
- A phone with no paired Watch still completes W6’s save-on-end path.
- The Watch app does not log sets, edit the plan, or read the account file.

### W8. iPhone session for AirPods

**Status:** in progress
**Scope:** Large (2–4 days, needs iOS 26 and AirPods Pro 3 or a Bluetooth heart-rate monitor)
**Depends on:** W6, W7
**Session:** When the Watch app does not launch, iOS 26 starts one indoor strength session on the phone. HealthKit supplies heart rate from AirPods or a Bluetooth monitor. The phone does not read those devices itself. End saves that session’s workout instead of the hand-built sample. iOS 17 and 18, and a phone session that cannot start, still use the W6 save. A Watch session still owns the workout. The workout screen shows heart rate and calories only while a Watch is in the session or a heart-rate sample has arrived.
**Report:** WorkoutHealthTests passed on the iPhone 17 simulator, including the phone session, the Watch path, and the save-on-end fallback. Live heart rate from AirPods or a Bluetooth monitor still needs a device check before this can be marked done.

iOS 26 can run `HKWorkoutSession` on the iPhone. The phone has no optical heart-rate sensor. During that session, AirPods Pro 3 (and a paired Bluetooth heart-rate monitor) can supply heart rate after the user allows heart-rate read and workout read/write. Keep the app’s deployment target. Gate this path with `if #available(iOS 26, *)`.

Use it when no Watch session is available. Older systems keep the W6 save-on-end behavior. The recorder from W6 and W7 stays the only type that talks to the workout session.

**Done when:**

- On iOS 26, with Heart Rate enabled on supported AirPods, or with a Bluetooth heart-rate monitor connected, a phone-only workout shows live heart rate and saves one strength workout at the end.
- On iOS 17 and 18, start, pause, and end behave as they do after W6, and the app still builds for those targets.
- A paired Watch still uses the W7 path, so the phone does not start a second session.
- The app does not read the earbuds over a private protocol.

## What finished looks like

Phase A: start, pause, resume, end, and relaunch go through one owner. W2 shows the rest alert while the app is open, clears scheduled workout notifications on End, and reminds the user after seven minutes without an action. The same exercise comes back, and set completion plus ending have tests.

Phase B: End writes one Traditional Strength Training workout to Health, and the home screen’s existing Health reads still work.

Phase C: the same workout collects heart rate from the Watch, and on iOS 26 from AirPods or a Bluetooth monitor when no Watch is in the session.
