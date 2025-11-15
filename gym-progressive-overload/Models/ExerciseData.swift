import Foundation

struct ExerciseDatabase {
    static let allExercises: [ExerciseInfo] = [
        // Chest
        ExerciseInfo(name: "Bench Press", muscleGroup: .chest),
        ExerciseInfo(name: "Incline Bench Press", muscleGroup: .chest),
        ExerciseInfo(name: "Decline Bench Press", muscleGroup: .chest),
        ExerciseInfo(name: "Dumbbell Bench Press", muscleGroup: .chest),
        ExerciseInfo(name: "Dumbbell Flyes", muscleGroup: .chest),
        ExerciseInfo(name: "Cable Flyes", muscleGroup: .chest),
        ExerciseInfo(name: "Push-ups", muscleGroup: .chest),
        ExerciseInfo(name: "Chest Press Machine", muscleGroup: .chest),

        // Back - Lats
        ExerciseInfo(name: "Pull-ups", muscleGroup: .lats),
        ExerciseInfo(name: "Chin-ups", muscleGroup: .lats),
        ExerciseInfo(name: "Lat Pulldown", muscleGroup: .lats),
        ExerciseInfo(name: "Close-Grip Pulldown", muscleGroup: .lats),
        ExerciseInfo(name: "Dumbbell Pullover", muscleGroup: .lats),

        // Back - Middle
        ExerciseInfo(name: "Barbell Row", muscleGroup: .middleBack),
        ExerciseInfo(name: "Dumbbell Row", muscleGroup: .middleBack),
        ExerciseInfo(name: "Cable Row", muscleGroup: .middleBack),
        ExerciseInfo(name: "T-Bar Row", muscleGroup: .middleBack),
        ExerciseInfo(name: "Chest Supported Row", muscleGroup: .middleBack),
        ExerciseInfo(name: "Face Pulls", muscleGroup: .middleBack),

        // Back - Lower
        ExerciseInfo(name: "Deadlift", muscleGroup: .lowerBack),
        ExerciseInfo(name: "Romanian Deadlift", muscleGroup: .lowerBack),
        ExerciseInfo(name: "Good Mornings", muscleGroup: .lowerBack),
        ExerciseInfo(name: "Back Extensions", muscleGroup: .lowerBack),

        // Shoulders
        ExerciseInfo(name: "Overhead Press", muscleGroup: .shoulders),
        ExerciseInfo(name: "Dumbbell Shoulder Press", muscleGroup: .shoulders),
        ExerciseInfo(name: "Arnold Press", muscleGroup: .shoulders),
        ExerciseInfo(name: "Lateral Raises", muscleGroup: .shoulders),
        ExerciseInfo(name: "Front Raises", muscleGroup: .shoulders),
        ExerciseInfo(name: "Rear Delt Flyes", muscleGroup: .shoulders),
        ExerciseInfo(name: "Upright Row", muscleGroup: .shoulders),
        ExerciseInfo(name: "Shrugs", muscleGroup: .shoulders),

        // Biceps
        ExerciseInfo(name: "Barbell Curl", muscleGroup: .biceps),
        ExerciseInfo(name: "Dumbbell Curl", muscleGroup: .biceps),
        ExerciseInfo(name: "Hammer Curl", muscleGroup: .biceps),
        ExerciseInfo(name: "Preacher Curl", muscleGroup: .biceps),
        ExerciseInfo(name: "Cable Curl", muscleGroup: .biceps),
        ExerciseInfo(name: "Concentration Curl", muscleGroup: .biceps),

        // Triceps
        ExerciseInfo(name: "Close-Grip Bench Press", muscleGroup: .triceps),
        ExerciseInfo(name: "Dips", muscleGroup: .triceps),
        ExerciseInfo(name: "Tricep Pushdown", muscleGroup: .triceps),
        ExerciseInfo(name: "Overhead Tricep Extension", muscleGroup: .triceps),
        ExerciseInfo(name: "Skull Crushers", muscleGroup: .triceps),
        ExerciseInfo(name: "Tricep Kickbacks", muscleGroup: .triceps),

        // Forearms
        ExerciseInfo(name: "Wrist Curls", muscleGroup: .forearms),
        ExerciseInfo(name: "Reverse Wrist Curls", muscleGroup: .forearms),
        ExerciseInfo(name: "Farmer's Walk", muscleGroup: .forearms),

        // Legs - Quads
        ExerciseInfo(name: "Squat", muscleGroup: .quads),
        ExerciseInfo(name: "Front Squat", muscleGroup: .quads),
        ExerciseInfo(name: "Leg Press", muscleGroup: .quads),
        ExerciseInfo(name: "Leg Extension", muscleGroup: .quads),
        ExerciseInfo(name: "Bulgarian Split Squat", muscleGroup: .quads),
        ExerciseInfo(name: "Lunges", muscleGroup: .quads),

        // Legs - Hamstrings
        ExerciseInfo(name: "Leg Curl", muscleGroup: .hamstrings),
        ExerciseInfo(name: "Nordic Curls", muscleGroup: .hamstrings),
        ExerciseInfo(name: "Stiff-Leg Deadlift", muscleGroup: .hamstrings),

        // Legs - Glutes
        ExerciseInfo(name: "Hip Thrust", muscleGroup: .glutes),
        ExerciseInfo(name: "Glute Bridge", muscleGroup: .glutes),
        ExerciseInfo(name: "Cable Kickbacks", muscleGroup: .glutes),

        // Legs - Calves
        ExerciseInfo(name: "Calf Raise", muscleGroup: .calves),
        ExerciseInfo(name: "Seated Calf Raise", muscleGroup: .calves),

        // Abs
        ExerciseInfo(name: "Crunches", muscleGroup: .abs),
        ExerciseInfo(name: "Planks", muscleGroup: .abs),
        ExerciseInfo(name: "Leg Raises", muscleGroup: .abs),
        ExerciseInfo(name: "Cable Crunches", muscleGroup: .abs),
        ExerciseInfo(name: "Ab Wheel", muscleGroup: .abs),
        ExerciseInfo(name: "Russian Twists", muscleGroup: .abs),
    ]

    static func exercisesByMuscleGroup(_ muscleGroup: MuscleGroup) -> [ExerciseInfo] {
        allExercises.filter { $0.muscleGroup == muscleGroup }
    }

    static func findExercise(byName name: String) -> ExerciseInfo? {
        allExercises.first { $0.name.lowercased() == name.lowercased() }
    }

    static func searchExercises(query: String) -> [ExerciseInfo] {
        guard !query.isEmpty else { return allExercises }
        return allExercises.filter {
            $0.name.lowercased().contains(query.lowercased()) ||
            $0.muscleGroup.rawValue.lowercased().contains(query.lowercased())
        }
    }
}
