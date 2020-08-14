//
//  ExploreViewController+CoachingOverlay.swift
//  GravityXR
//
//  Created by Avinash Shetty on 7/7/20.
//  Copyright © 2020 GravityXR. All rights reserved.
//

import Foundation
import ARKit

/*extension ExploreViewController: ARCoachingOverlayViewDelegate {

    /// - Tag: HideUI
    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        feedbackControl.isHidden = true
        controlsBGView.isHidden = true
    }

    /// - Tag: PresentUI
    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        
        if bShowingControlBar{
            controlsBGView.isHidden = false
        }
    }

    /// - Tag: StartOver
    func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
        restartExperience()
    }

    func setupCoachingOverlay() {
        // Set up coaching view
        coachingOverlay.session = sceneView.session
        coachingOverlay.delegate = self
        
        // Gravity requires to detect all types of anchors in a room, so set a goal for horizontal or vertical
        setGoal()

        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        sceneView.addSubview(coachingOverlay)
        
        NSLayoutConstraint.activate([
            coachingOverlay.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            coachingOverlay.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            coachingOverlay.widthAnchor.constraint(equalTo: view.widthAnchor),
            coachingOverlay.heightAnchor.constraint(equalTo: view.heightAnchor)
            ])
        
        setActivatesAutomatically()
        
    }

    /// - Tag: CoachingActivatesAutomatically
    func setActivatesAutomatically() {
        coachingOverlay.activatesAutomatically = true
    }

    /// - Tag: CoachingGoal
    func setGoal() {
        coachingOverlay.goal = .verticalPlane
    }
    
}*/
