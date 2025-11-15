//
//  GymTrackerWidgetBundle.swift
//  GymTrackerWidget
//
//  Created by Arthur Rodolfo on 2025-11-15.
//

import WidgetKit
import SwiftUI

@main
struct GymTrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        GymTrackerWidget()
        GymTrackerWidgetControl()
        WorkoutLiveActivity()
    }
}
