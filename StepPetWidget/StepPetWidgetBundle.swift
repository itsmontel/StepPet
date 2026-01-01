//
//  VirtuPetWidgetBundle.swift
//  VirtuPetWidget
//
//  Widget Bundle for VirtuPet
//

import WidgetKit
import SwiftUI

@main
struct VirtuPetWidgetBundle: WidgetBundle {
    var body: some Widget {
        VirtuPetWidget()
        VirtuPetWidgetLiveActivity()
    }
}
