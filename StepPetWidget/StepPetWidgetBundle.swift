//
//  StepPetWidgetBundle.swift
//  StepPetWidget
//
//  Widget Bundle for StepPet
//

import WidgetKit
import SwiftUI

@main
struct StepPetWidgetBundle: WidgetBundle {
    var body: some Widget {
        StepPetWidget()
        StepPetWidgetLiveActivity()
    }
}
