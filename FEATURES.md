# Feature and fix queue

Work the tasks in order. This file is the product queue. `UPGRADE.md` remains the live-workout and Health session plan. Do not mark W7 or W8 from this file. F11 and F12 are the only tasks that edit the Watch app. They do not finish W7 or W8, and they do not change when the Health workout session starts, pauses, or saves.

## How agents should use this file

Take the first task whose dependencies are all `done` and whose status is `not started`. Set that status to `in progress` and append a **Log** line before editing code. When the work matches the **Done when** list, set the status to `done`, fill **Session** and **Report**, and append another **Log** line. Use `blocked` when you stop before that, and say why in **Report** and the log.

Leave every other task’s status block and log as you found it. Do not renumber tasks or rewrite their **Done when** lists. If the finished work reveals a follow-up, add a new task at the bottom with the next free id, status `not started`, and a **Depends on** line. Do not bury that follow-up inside a `done` task.

Allowed status values: `not started`, `in progress`, `done`, `blocked`.

Log line shape: `- YYYY-MM-DD — <status> — <one sentence of what changed or why it stopped>`.

## Branches and pull requests

Each feature task is one branch from current `main` and one pull request back to `main`. This applies to every task in this file.

- Branch name: `f<id>-<short-slug>`, for example `f1-real-experience`.
- Do the task only on that branch. Do not commit feature work straight to `main`.
- When **Done when** is met, open a pull request to `main`. The title includes the task id. The body says what changed and how it was checked.
- Merge that pull request before starting the next task, so the next branch contains its dependencies.
- One task per pull request. A follow-up is a new task id and a new branch.

New Swift files under `WorkoutSession/`, `WorkoutsCreator/`, `Components/`, or `DataStructures/` must be added to `No Game No Gain.xcodeproj/project.pbxproj` (file reference, build file, group, and Sources phase). The test target, `History & Stats`, and `No Game No Gain Watch App` already sync from disk. A new widget extension target must be added to the project and the scheme.

## Leave these as they are

- `UPGRADE.md`, and when a Health workout session starts, pauses, or saves. Leave the Watch app alone except in F11 and F12.
- `WorkoutSession.totalWeight()`. It adds each set’s load and does not multiply by reps. Volume in stats is a separate number.
- The XP formulas in `ExperienceSystem`. Fixing the display does not retune them.
- The copy-then-assign update of `weeklyWorkouts` inside `calculateXPMultiplier`.
- Query math in `HealthKitManager`. Call the methods that already exist.
- `WorkoutViewModel` as an `ObservableObject`.
- Rest timing, the rest and inactivity notifications, and `SceneDelegate.swift`.
- `UserSettings.weightUnitKg`. Kilograms stay the unit until a later task converts stored loads.

## Current problems

- `HomeScreenView` draws `ProgressBarView` from `expToTextUI`, which is fixed at 400. The account file is not that source. `LevelsView` receives `userAccount.exp` and then blurs ranks with `levelTest`, which is fixed at 5000.
- The Settings button adds 100 XP and navigates to `TrainingStatsView`. `NotificationSettingsView` and `UserSettings` are not on that path. `StatsView` is an unused placeholder.
- `TrainingStatsViewModel.loadMockData()` fills a year of random points and three hardcoded records (Przysiad, Martwy ciąg, Wyciskanie leżąc). The home “Training Stats” card already counts real sessions. Its monthly volume uses `totalWeight()`, so it is a sum of loads.
- `PersonalGoalView` is a wheel of tenths for either body weight or one lift. The home card always says “Lose 5kg”. `goalProgress` defaults to 65. The progress bar is a chain of special cases.
- `ChallengeView` always shows “Lift a total of 5t”, progress 2365 of 5000, and “6d 4h”. `ExperienceSystem.generateWeeklyChallenge` is unused. The next version stays a dummy: the weight target is 1.4 times the previous goal.
- `TodayActivitiesView` shows today’s steps with a fixed “Goal: 18000”, calories with no goal, and sleep as `hours:minutes` without a padded minute. Tapping a card replaces the whole row with one chart.
- `WorkoutHistoryView` includes open sessions and defines `FilterButton` without using it. There is no importer.
- `WorkoutCompletion.updateProgressWeight` adds `progressPerWorkout` to the load when every planned set was completed at or above the planned weight. Reps never change. A set cannot be saved as “no weight yet”.
- End Workout calls `WorkoutCoordinator.end` immediately. There is no summary and nowhere to record how hard the session felt. Per-set RPE is stored on `DoneSets` and is not shown.
- The Watch screen shows the rest clock, the current, average, and highest heart rate, and active energy. It cannot mark a set done. The phone link sends the clock to the Watch and heart rate and energy back. It does not send the exercise, the weight, or the reps.
- Nothing is drawn on the iPhone Lock Screen during a workout. There is no switch for it.

## Tasks

### F1. Show the real experience

**Status:** done
**Scope:** Small (under a day)
**Depends on:** none
**Session:** The home bar reads `userAccount.exp` after the account file loads, and home reloads that file when it appears, including after a finished workout replaces the home screen. `LevelsView` unlocks a rank when that same XP has reached the rank’s start. The Settings button no longer adds XP.
**Report:** `ProgressBarView(exp: 400)` shows Gym Bro. 400 unlocks Gym Bro and leaves Iron Warrior locked. The fixed 400 and 5000 values are gone, and the Settings +100 write is gone. Rank and completion tests passed on the iPhone 17 simulator.
**Log:**
- 2026-11-15 — in progress — The home bar and rank list will read the XP stored on the account, and Settings will stop adding 100 XP.
- 2026-11-15 — done — The home bar and the rank list use the account XP. Opening Settings no longer adds 100 XP.

The home rank bar and the rank list must use the XP already stored on `UserAccount`. Ending a workout already adds XP through `WorkoutCompletion.finish`. This task does not change that formula.

**Done when:**

- The home bar uses `userAccount.exp` after the account file loads, and it updates when the user returns from a finished workout.
- `LevelsView` blurs locked ranks from that same XP. The hardcoded 5000 is gone.
- Opening Settings does not add XP. The +100 write is gone in this task even if F2 has not replaced the screen yet.
- `calculateWorkoutXP`, the multipliers, and the `weeklyWorkouts` copy-then-assign stay as they are.
- A test or a preview check shows a known XP value on the bar and the matching rank title. The existing completion tests still pass.

### F2. Make Settings a settings screen

**Status:** done
**Scope:** Small (about 1 day)
**Depends on:** F1
**Session:** The home Settings button opens `SettingsView`. That screen edits the display name on the account file and shows the existing notification sound controls. The sound choice is saved when it changes. Training stats stay on the home stats card. The screen does not add XP and has no pounds switch.
**Report:** Saving the name “Ada” reloads as “Ada” and leaves XP unchanged. A custom sound reloads from a fresh settings object. Settings and notification tests passed on the iPhone 17 simulator.
**Log:**
- 2026-11-15 — in progress — Settings will edit the account name and the existing notification sound, and it will stop opening the stats screen.
- 2026-11-15 — done — Settings edits the saved name and the notification sound. The home button no longer opens training stats.

Settings currently opens the stats screen. `NotificationSettingsView` already edits the rest-alert sound and is not linked from home. `UserAccount.name` has no editor.

**Done when:**

- The home Settings button opens a settings screen and does not open `TrainingStatsView`.
- The screen edits the display name saved on the account file, and it presents the existing notification sound controls.
- It does not grant XP and does not offer a pounds switch.
- Training stats stay reachable from the home stats card.
- Name and sound survive a relaunch.

### F3. Progress reps, then weight

**Status:** done
**Scope:** Medium (1–2 days)
**Depends on:** F2
**Session:** A successful exercise adds one rep while the planned reps are below the ceiling. At the ceiling it adds `progressPerWorkout` and sets the reps back to the floor. With no stored range, the planned reps are both the floor and the ceiling, so the load still moves. A set marked “no weight yet” stores no load, stays empty, and is skipped. `totalWeight()` still adds the stored loads.
**Report:** Completion, session, and restore tests passed on the iPhone 17 simulator. Below the ceiling, 5 reps become 6 and the weight stays. At the ceiling, the weight rises by 2.5 and the reps return to 5. A short set, a failed set, and a light set do not change the plan. An empty-weight set stays empty and does not take a personal record.
**Log:**
- 2026-11-15 — in progress — A successful exercise will add a rep until the ceiling, then add weight and return to the rep floor. A set can stay without a weight.
- 2026-11-15 — done — Reps progress until the ceiling, then the load moves and the reps return to the floor. A set can stay without a weight.

A successful exercise is one where every set with progress enabled was logged done, at or above the planned weight, and at or above the planned reps. Failed or lighter sets do not progress that exercise.

Each exercise has a rep floor and a rep ceiling. Existing exercises default both to the reps already on their sets, so an old plan still moves the load once those reps are hit. When the planned reps are below the ceiling, a success adds 1 rep and does not add weight. When the planned reps are already at the ceiling, a success adds `progressPerWorkout` to the weight and sets the reps back to the floor.

A set can be marked “no weight yet”. Those sets show an empty weight, store no load to progress, and are skipped by this rule until the user enters a weight. `totalWeight()` is unchanged.

**Done when:**

- Success below the rep ceiling increases reps by 1 and leaves the weight.
- Success at the ceiling increases the weight by `progressPerWorkout` and resets reps to the floor.
- A failed set, a light set, or a set under the planned reps does not change the plan.
- Sets with progress turned off do not change.
- “No weight yet” stays empty across a finished workout and does not gain weight or reps.
- Existing plans with no stored range still progress the load after the planned reps are hit.
- Tests cover those cases without the workout screen. `totalWeight()` is unchanged.

### F4. End-of-workout summary and effort

**Status:** done
**Scope:** Medium (1–2 days)
**Depends on:** F3
**Session:** Phone End opens a summary and leaves the workout open. Confirm stores effort from 1 to 10 and then ends the session once. Dismiss does not end it. The summary shows the name, duration, exercises, done and failed sets, volume as weight times reps, personal records, the XP this ending will add, and the rep or load change, or that the plan did not change. The preview does not keep the weekly-workout increment. A Watch end still saves with empty effort.
**Report:** Summary tests passed on the iPhone 17 simulator. The preview leaves XP and the week unchanged and lists a rep change before it is saved. Confirm stores effort 7, awards that previewed XP once, and a second end does not award again. Ending without the summary leaves effort empty.
**Log:**
- 2026-11-15 — in progress — Phone End will open a summary and store effort before the session closes. A Watch end still saves without effort.
- 2026-11-15 — done — Phone End shows a summary, stores effort, and awards XP once. A Watch end still saves with no effort.

End Workout on the phone opens a summary before the session is closed. The summary shows the workout name, duration, exercises, done and failed sets, volume as weight times reps, personal records from this session, and the XP this ending will add. The XP preview uses the existing formula and does not increment `weeklyWorkouts`.

The user picks an effort from 1 to 10 before confirming. Confirm stores that effort on the session and then calls the existing `WorkoutCoordinator.end` once. Dismissing the summary returns to the open workout and does not stamp `endTime`. A second confirm does not award XP again.

A Watch-driven end still ends the session without waiting on this sheet. Effort stays empty in that case.

**Done when:**

- Phone End shows the summary and leaves the workout open until confirm.
- Confirm stores effort 1...10, awards XP once, and returns home.
- The summary lists the load or rep change F3 applied, or says the plan did not change.
- Dismiss does not set `endTime`, duration, or effort, and does not add XP.
- A Watch-driven end still saves the workout and does not require effort.
- Tests cover preview-without-save, one award on confirm, and no award when the session is already ended.

### F5. Rebuild goals

**Status:** done
**Scope:** Medium (1–2 days)
**Depends on:** F4
**Session:** One typed goal replaces the wheel. The home card shows the direction, one bar from the value when the goal was set, and the current value. With no goal it says to set one. Reaching the target says it is done, and clearing returns to the empty card. Body weight and a heavier set still move the active goal.
**Report:** A fresh account and the old 65 default are not shown as a goal. Losing 2.5 kg from 80 is halfway at 78.75 and done at 77.5. Gaining 10 kg from 70 is halfway at 75. A strength goal reads “Bench Press to 80 kg” and starts from that exercise’s best. Set, edit, and clear survive a JSON round trip. “Lose 5kg” is gone. Goal and completion tests passed on the iPhone 17 simulator.
**Log:**
- 2026-11-15 — in progress — The goal wheel and the “Lose 5kg” card will become one typed goal with a single bar.
- 2026-11-15 — done — The home card shows one typed goal, and an empty account no longer presents 65.

Replace the wheel and the branched progress view with one goal flow. The user picks body weight or one exercise, sees the current value (latest body mass, or that exercise’s best), and types a target. The screen states the direction in one line, such as “Lose 2.5 kg” or “Bench Press to 80 kg”. One bar runs from the value at the time the goal was set to the target.

There is one active goal. The home card shows that sentence, the bar, and the current value. With no goal, the card says to set one and does not show “Lose 5kg”. Reaching the target shows a done state and a way to set the next target. Clearing a goal returns to the empty state.

Body-weight progress still follows the mass the user saves. Strength progress still follows a heavier set on the chosen exercise, including the write that `WorkoutCompletion` already makes. The default `goalProgress` of 65 is not shown as a real goal.

**Done when:**

- Setting, editing, and clearing a goal updates the home card and survives a relaunch.
- A weight target below the start reads as losing weight. A target above the start reads as gaining weight. The bar moves in that direction.
- A strength goal names the exercise and uses its best as current progress.
- The hardcoded “Lose 5kg” label is gone.
- An empty account does not present 65 as progress.
- Existing completion behavior that updates the active strength goal still does so.

### F6. Dummy challenge at 1.4×

**Status:** done
**Scope:** Small (about 1 day)
**Depends on:** F5
**Session:** One home challenge steps the weight target by 1.4 times the last one. With no active goal it starts from 5000 kg, so the card shows 7000 kg. The countdown and the bar use a stored 7 day window, and the bar is the volume of sessions that ended inside it. When the window ends, the finished target becomes the previous goal and the next one is 1.4 times that.
**Report:** No goal and the old empty weight goal seed 5000 and show 7000. An active goal of 100 shows 140. After one week, 5000 becomes a previous goal of 7000 and a target of 9800. Six days and four hours left reads “6d 4h” from the date, not from a fixed label. Volume is weight times reps, and an open or earlier session does not count. The strings “2365”, “6d 4h”, and “Lift a total of 5t” are gone from the card. Challenge tests passed on the iPhone 17 simulator.
**Log:**
- 2026-11-15 — in progress — The home challenge will show 1.4 times the last target and this window’s volume.
- 2026-11-15 — done — The home card steps the challenge by 1.4 and counts this window’s volume.

Keep a single home challenge. Do not use `generateWeeklyChallenge`. The weight target is the previous goal multiplied by 1.4.

Seed the previous goal from the active goal’s target when the user has one, otherwise from 5000 kg, which is the 5t card on screen today. The shown target is that seed times 1.4. The window is 7 days from a stored start, and the countdown is computed from that date. Progress is the volume (weight times reps) of ended sessions inside the window. When the window ends, the previous goal becomes the target that just finished, the next target is that number times 1.4, and a new 7 day window starts. This rollover can run when the home screen appears. It does not need a notification.

**Done when:**

- The card shows a target of 1.4 times the stored previous goal, a real countdown, and progress from this window’s volume.
- The fixed “2365”, “6d 4h”, and “Lift a total of 5t” strings are gone.
- After the window elapses, the next target is 1.4 times the target that just ended.
- A test covers the 1.4 step and the seed of 5000 when no goal exists.
- No other challenge types are added.

### F7. Training stats from real sessions

**Status:** done
**Scope:** Medium (1–2 days)
**Depends on:** F6
**Session:** The stats screen charts ended workouts for the week, month, or year. Volume is weight times reps, and the other metrics are sets, reps, and duration in minutes. Records show an exercise name with its best weight and reps only after a workout has ended. Effort from a finished session in the selected range is listed. The home card uses that same volume, and an open session does not count toward the week, the weekly average, or the month.
**Report:** An empty history has no points and no records. Ending a session adds the point and shows Bench at 100 kg and 8 reps. 100 kg × 5 and 40 kg × 10 is 900, with 2 sets and 15 reps. A session 8 days ago is outside the week, 40 days ago is outside the month, and 400 days ago is outside the year. An open session is left out of the points, the volume, and the effort list. Effort 7 is listed and a missing effort is not. The mock generator and the sample lift names are gone. totalWeight() is unchanged. Unit tests passed on the iPhone 17 simulator, 122 tests and 0 failures.
**Log:**
- 2026-11-15 — in progress — Training stats will chart ended sessions, and the home card will use weight times reps.
- 2026-11-15 — done — The chart, records, and effort read finished workouts, and the home volume is weight times reps.

`TrainingStatsView` reads ended `WorkoutSession` rows. Week, month, and year limit the chart. The metrics are volume (weight times reps), set count, rep count, and duration. Personal records come from `Exercise.personalBestWeight` and `personalBestReps`, with the exercise name and no sample Polish lifts.

The home stats card uses the same volume definition for the month, and it does not count a session that is still open. An empty history shows an empty state, not random points.

**Done when:**

- The chart and the records change when a session is ended, and they show nothing when no session has ended.
- Week, month, and year each drop sessions outside that range.
- Volume on this screen and on the home card is weight times reps. `totalWeight()` is unchanged.
- Effort from F4 is visible on the stats screen for sessions that have it.
- The mock generator and the sample record names are gone.

### F8. History filters

**Status:** not started
**Scope:** Small (about 1 day)
**Depends on:** F7
**Session:**
**Report:**
**Log:**
- (none yet)

This is the “importing workouts with filters” item: the history list that brings sessions in, using the unused `FilterButton`. It is not a file import and not a Health import. If that reading is wrong, mark this task `blocked` and add a replacement task instead of building an importer.

The list shows ended sessions only. Filters are the workout name and a range of week, month, year, or all. The existing `FilterButton` is the control. Expanding a session still shows its sets.

**Done when:**

- Open sessions stay off this list.
- Choosing a workout name hides other workouts. Choosing a range hides sessions outside it. All shows every ended session.
- Clearing a filter restores the matching sessions.
- Export stays the existing unimplemented button. This task does not add PDF export.

### F9. Steps, calories, and sleep detail

**Status:** not started
**Scope:** Medium (1–2 days)
**Depends on:** F8
**Session:**
**Report:**
**Log:**
- (none yet)

Keep the three home cards. Each opens its own detail instead of replacing the row. Detail shows today’s value, an optional goal, progress toward that goal, and the recent bars from the existing HealthKit chart methods. Do not change those query methods.

Steps keep 18000 as the default goal. Calories and sleep have no goal until the user sets one. Sleep is shown as hours and zero-padded minutes. Goals are stored on the account file. The home card shows the goal only when one is set, and it shows today’s value either way.

**Done when:**

- Steps, calories, and sleep each open a detail and return to the three cards.
- A saved goal survives a relaunch and appears on the home card and the detail.
- Sleep reads as a clock time, including minutes below 10.
- With Health unavailable or denied, the detail says so and does not show a fake number.
- `HealthKitManager` query math is unchanged.

### F10. Template workouts and onboarding

**Status:** not started
**Scope:** Large (3–5 days)
**Depends on:** F9
**Session:**
**Report:**
**Log:**
- (none yet)

Add a templates place next to “Your Workouts” in the workout creator. Ship three built-in plans as data, not as rows already in the store: a full-body session, a push session, and a pull session. Each exercise has a rep floor, a rep ceiling, rest, and `progressPerWorkout`. Choosing one copies it into a normal `Workout` the user can edit and delete. The copy is what they start. The catalog itself is not a live session.

Onboarding runs when the user takes a template, and it is also offered from Start Workout when they have no workouts. It prepares that one plan. For each exercise it asks the weight they use and offers “No weight yet”, which uses the F3 empty-weight flag. It does not ask them to pick a load. After the questions, the copied workout is saved and they can start it or leave it in the list.

Do not add more plans, a multi-day generator, or a second questionnaire in this task.

**Done when:**

- Templates are listed separately from the user’s workouts.
- Adopting a template creates one editable workout and does not start a session by itself.
- Onboarding can leave any exercise without a weight, and those exercises match the F3 “no weight yet” rule.
- Entered weights become the planned weight on the copy.
- A user who already has workouts can still open the catalog. A user with none is offered onboarding from Start Workout.
- Deleting the copy does not remove the template.

### F11. Mark a set done from the Watch

**Status:** not started
**Scope:** Medium (1–2 days)
**Depends on:** F3
**Session:**
**Report:**
**Log:**
- (none yet)

The phone still owns the session and the set log. The Watch asks the phone to log the current set. If `UPGRADE.md` W7 is not `done`, mark this task `blocked` and stop. Do not finish the Watch Health session here.

The Watch shows the current exercise name, the planned weight, the planned reps, and which set this is. A single tap never logs a set. The first action only asks “Mark this set done?” and repeats the exercise, weight, and reps. A separate Confirm action logs it. Cancel, covering the Watch, or leaving that prompt logs nothing. Scrolling and the rest clock do not confirm.

Confirm uses the same path as Done on the phone (`WorkoutCompletion.logSet` with `isDone` true) and the weight and reps on screen. The phone answers with the next set, or the next exercise when this one is finished. The same in-flight request cannot log a second set. The Watch does not write SwiftData, end the workout, or edit the plan.

**Done when:**

- The Watch shows the exercise, weight, reps, and set the phone is on, including “no weight yet” from F3.
- One tap does not log a set. Confirm logs one done set on the phone, and the Watch moves to the next planned set.
- Cancel logs nothing. A repeated confirm for the set already logged does not add another set.
- Pause, rest, and End behave as they do after W7. The Watch still has no End button.
- A test covers the confirm, the cancel, and the duplicate request without a paired Watch.

### F12. Current, average, and highest heart rate

**Status:** done
**Scope:** Small (about 1 day)
**Depends on:** F11
**Session:** The Watch reads the current, average, and highest heart rate from the live builder statistics it already collects. Those three go to the phone on the existing metrics link and show on the Watch and in WorkoutLiveMetricsView. A missing number stays a dash. End stores the average and the highest on the workout session and clears the live numbers. Pause does not reset them.
**Report:** The phone link test feeds 120, then 130 with no new average or highest, and the coordinator keeps 110 and 150. End writes those two onto the session and clears the live values. No second Health sampler was added. The Watch screen shows the same three numbers. History shows the stored average and highest when a finished session has them. The user confirmed on the paired Watch that this matches the workout.
**Log:**
- 2026-11-07 — in progress — The user asked for average and highest heart rate on the Watch, stored on the phone for later statistics.
- 2026-11-07 — done — Live current, average, and highest heart rate show on the Watch and the phone. End saves the average and the highest on the session.
- 2026-11-07 — done — The user tested a workout and confirmed the average, the highest, and the saved values.

Show the session heart rate the way Apple Workout does: the current rate, the average, and the highest. Take all three from the live builder statistics the Watch already collects. Send them on the existing phone link and show them on the Watch and in `WorkoutLiveMetricsView`.

**Done when:**

- During a workout the Watch and the phone show current, average, and highest beats per minute.
- The average and the highest cover this session only. Pause does not reset them. End clears them.
- A missing sample shows a dash. It does not show zero.
- The Health workout is still saved the same way. This task does not add a second sampler.
- A test can feed the three numbers across the phone link without a heart-rate sensor.

### F13. Optional Lock Screen workout card

**Status:** not started
**Scope:** Medium (1–2 days)
**Depends on:** F2
**Session:**
**Report:**
**Log:**
- (none yet)

Add one iPhone Lock Screen card for the open workout, as a Live Activity. It shows the workout elapsed time, the current exercise name, the planned weight, and the reps to do. The elapsed time uses the workout clock, so pause freezes it. It is not the rest clock.

The card is off until the user turns it on. One switch is on the settings screen from F2, and the same switch is on the workout screen. Turning it on while a workout is open shows the card. Turning it off removes the card immediately. The choice is stored and survives a relaunch. Ending the workout removes the card. No workout means no card.

This is not a Watch face complication and not a Home Screen widget. The Live Activity UI lives in a widget extension. Add that target to the project and the scheme.

**Done when:**

- With the switch on, the Lock Screen shows elapsed time, exercise name, weight, and reps for the open workout, and those values follow the phone when the set or exercise changes.
- Pause freezes the elapsed time. Resume continues it. End removes the card.
- With the switch off, starting or continuing a workout does not show the card. Turning it off removes a card that is already visible.
- The switch is on the settings screen and on the workout screen, and both edit the same stored value.
- A locked phone with no open workout does not show the card.

### F14. AirPods heart rate

**Status:** not started
**Scope:** Large (2–4 days, needs iOS 26 and AirPods or a Bluetooth heart-rate monitor)
**Depends on:** F13
**Session:**
**Report:**
**Log:**
- (none yet)

A worn Apple Watch keeps the workout and its heart rate. AirPods heart rate is later, after the tasks above. Do not take a launched or mirrored Watch session away so the phone can collect AirPods samples. That handoff blocked normal Watch heart-rate monitoring.

When this task starts, the phone session stays the path from `UPGRADE.md` W8: iOS 26 starts one indoor strength session only when the Watch app does not launch. HealthKit supplies heart rate from AirPods or a Bluetooth monitor. The app does not read those devices itself. A Watch that joins later discards the phone session and saves the workout. This task does not mark W8 done.

**Done when:**

- A worn Watch keeps measuring heart rate for the whole workout. The phone does not release that session or replace its samples.
- On iOS 26, when the Watch app does not launch, one phone session shows live heart rate from AirPods or a Bluetooth monitor and saves that workout.
- A Watch that joins after the phone session discards the phone session and owns the save.
- iOS 17 and 18 still use the hand-built save when no Watch session is running.
- Heart Rate stays an AirPods setting. The app does not read earbuds over a private protocol.

### F15. Whole experience, a test control, and an effort chart

**Status:** done
**Scope:** Small (under a day)
**Depends on:** F4
**Session:** Debug settings can replace the stored experience. Awarded experience is rounded to a whole number, and the home bar and summary show that whole number. The workout row keeps previous sets visible, and “No weight yet” sits where the arrow was. The summary opens with levels 1...10, the selected description, and the last effort for the same workout when one is saved.
**Report:** Summary, completion, settings, and rank tests passed on the iPhone 17 simulator. A saved experience of 250 reloads as 250. The previewed and awarded experience have no fraction. The last effort for a workout is the newest ended session with that name.
**Log:**
- 2026-11-15 — in progress — Settings will be able to set the account experience while testing. Experience will show as a whole number. The summary will lead with an effort chart.
- 2026-11-15 — done — Debug settings can set experience. Experience shows as a whole number, and the summary leads with an effort chart.

The experience already stored from earlier workouts stays. A Debug settings control can replace it. Awarded and shown experience is a whole number. The workout row drops the arrow that hid previous sets, and “No weight yet” takes that spot. The end summary leads with an effort chart, a description of the selected level, and the last effort for the same workout. The other statistics stay below that chart.

**Done when:**

- A Debug build’s settings screen can set the account experience, and that value is still there after a relaunch.
- The home bar, the summary, and a newly awarded total show no decimal places.
- The workout row no longer has the show-or-hide arrow. “No weight yet” is on that second line, and previous sets stay listed.
- The summary starts with levels 1...10, the selected level’s description, and the last saved effort for this workout when one exists. Statistics follow that chart.
- The XP formulas and the weekly-workout copy-then-assign stay as they are.

### F16. Show the whole exercise name

**Status:** done
**Scope:** Small (under a day)
**Depends on:** F15
**Session:** The exercise name on the workout row wraps onto as many lines as it needs. The weight and reps stay beside the first line.
**Report:** The one-line limit and the trailing ellipsis are gone. A long name stays fully visible.
**Log:**
- 2026-11-15 — in progress — The exercise name will wrap so the whole name stays visible.
- 2026-11-15 — done — A long exercise name wraps onto multiple lines instead of ending in an ellipsis.

**Done when:**

- A long exercise name on the workout row is fully visible on more than one line.
- The weight and reps stay on that row.

## What finished looks like

The home bar, ranks, and stats use the account and the ended sessions. Settings edits the name and the alert sound. A finished phone workout asks for effort, shows what was lifted, and then applies the rep-then-weight step. One goal reads clearly on the home card. The challenge target steps by 1.4. Steps, calories, and sleep open a detail with an optional goal. A new user can take one built-in workout and try it before choosing weights. From the Watch, confirming a set logs it on the phone. Heart rate shows the current, average, and highest rate from the Watch. The iPhone Lock Screen can show the elapsed time, exercise, weight, and reps, and that card has one switch. AirPods heart rate waits until that queue is finished.
