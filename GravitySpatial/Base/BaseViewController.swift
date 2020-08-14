// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

import ARKit
import Foundation
import SceneKit
import UIKit
import AzureSpatialAnchors

// Colors for the local anchors to indicate status
let readyColor = UIColor.blue.withAlphaComponent(0.7)           // light blue for a local anchor
let savedColor = UIColor.green.withAlphaComponent(0.7)          // green when the cloud anchor was saved successfully
let foundColor = UIColor.yellow.withAlphaComponent(0.9)         // yellow when we successfully located a cloud anchor
let deletedColor = UIColor.black.withAlphaComponent(0.7)        // grey for a deleted cloud anchor
let failedColor = UIColor.red.withAlphaComponent(0.7)           // red when there was an error

// Special dictionary key used to track an unsaved anchor
let unsavedAnchorId = "placeholder-id"

public class BaseViewController: UIViewController, ARSCNViewDelegate, ASACloudSpatialAnchorSessionDelegate {
    
    // Set this to the account ID provided for the Azure Spatial Service resource.
    let spatialAnchorsAccountId = "dc5d51fa-6474-4e75-810e-65c0acaefbe8"
    
    // Set this to the account key provided for the Azure Spatial Service resource.
    let spatialAnchorsAccountKey = "E1S4+U33gXRG+G052727s0uwWEWS+N4tK73K8Hs1gqs="

    @IBOutlet var sceneView: ARSCNView!

    var mainButton: UIButton!
    var feedbackControl: UIButton!
    var errorControl: UIButton!
    
    var anchorVisuals = [String : AnchorVisual]()
    var cloudSession: ASACloudSpatialAnchorSession? = nil
    var cloudAnchor: ASACloudSpatialAnchor? = nil
    var localAnchor: ARAnchor? = nil
    
    var enoughDataForSaving = false     // whether we have enough data to save an anchor
    var currentlyPlacingAnchor = false  // whether we are currently placing an anchor
    var ignoreMainButtonTaps = false    // whether we should ignore taps to wait for current demo step finishing
    var saveCount = 0                   // the number of anchors we have saved to the cloud
    var step = DemoStep.prepare         // the next step to perform
    var targetId : String? = nil        // the cloud anchor identifier to locate
    var lookupArray : [String] = []        // the cloud anchor array to locate

    func onCloudAnchorCreated() { assertionFailure("Must be implemented in subclass") }

    func onNewAnchorLocated(_ cloudAnchor: ASACloudSpatialAnchor) { }

    func onLocateAnchorsCompleted() { }
    
    func onCameraStable(){ }
    
    // MARK: - View Management
    
    @objc func mainButtonTap(sender: UIButton) { assertionFailure("Must be implemented in subclass") }
    
    @objc func backButtonTap(sender: UIButton) {
        moveToMainMenu()
    }
    
    func moveToMainMenu() {
        self.dismiss(animated: false, completion: nil)
    }
    
    public override var prefersStatusBarHidden: Bool {
        return true
    }
    
    public override func viewDidLoad() {
        
        //(UIApplication.shared.delegate as! AppDelegate).restrictRotation = .portrait
        super.viewDidLoad()
        
        sceneView.delegate = self              // Set the view's delegate
        sceneView.showsStatistics = false      // Show statistics such as fps and timing information
        sceneView.scene = SCNScene()           // Create a new scene and set it on the view
        
        // Main button
        mainButton = addButton()
        mainButton.addTarget(self, action:#selector(mainButtonTap), for: .touchDown)
        
        // Control to go back to the menu screen
//        backButton = addButton()
//        backButton.addTarget(self, action:#selector(backButtonTap), for: .touchDown)
//        backButton.backgroundColor = .clear
//        backButton.setTitleColor(.blue, for: .normal)
//        backButton.contentHorizontalAlignment = .left
//        backButton.setTitle("Done", for: .normal)
        
         // Control to indicate when we can create an anchor
        feedbackControl = addButton()
        feedbackControl.backgroundColor = .clear
        feedbackControl.setTitleColor(.white, for: .normal)
        feedbackControl.contentHorizontalAlignment = .center
        feedbackControl.isHidden = true
        
        // Control to show errors and verbose text
        errorControl = addButton()
        errorControl.isHidden = true

        layoutButtons()

        if (spatialAnchorsAccountId == "Set me" || spatialAnchorsAccountKey == "Set me") {
            mainButton.isHidden = true
            errorControl.isHidden = false
            showLogMessage(text: "Set spatialAnchorsAccountId and spatialAnchorsAccountKey in BaseViewController.swift", here: errorControl)
        }
        else {
            // Start the demo
            mainButtonTap(sender: mainButton)
        }
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutButtons()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        super.touchesBegan(touches, with: event)

        //This is implemented in the sub classes

        
    }
    
    // MARK: - ARKit Delegates
        
    public func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        print(error)
    }
    
    public func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    public func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        if let cloudSession = cloudSession {
            cloudSession.reset()
        }
    }
    
    // MARK: - SceneKit Delegates
    
    public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // per-frame scenekit logic
        // modifications don't go through transaction model
        if let cloudSession = cloudSession {
            cloudSession.processFrame(sceneView.session.currentFrame)
            
            if (currentlyPlacingAnchor && enoughDataForSaving && localAnchor != nil) {
                createCloudAnchor()
            }
        }
    }
    
    // MARK: - Azure Spatial Anchors Helper Functions
    
    func startSession() {
        cloudSession = ASACloudSpatialAnchorSession()
        cloudSession!.session = sceneView.session
        cloudSession!.logLevel = .information
        cloudSession!.delegate = self
        cloudSession!.configuration.accountId = spatialAnchorsAccountId
        cloudSession!.configuration.accountKey = spatialAnchorsAccountKey
        cloudSession!.start()
        
        errorControl.isHidden = true
        enoughDataForSaving = false
    }
    
    func createLocalAnchor(anchorLocation: simd_float4x4) {
        if (localAnchor == nil) {
            localAnchor = ARAnchor(transform: anchorLocation)
            sceneView.session.add(anchor: localAnchor!)
            
            // Put the local anchor in the anchorVisuals dictionary with a special key
            let visual = AnchorVisual()
            visual.identifier = unsavedAnchorId
            visual.localAnchor = localAnchor
            anchorVisuals[visual.identifier] = visual
            
            mainButton.setTitle("Create Cloud Hotspot (once at 100%)", for: .normal)
        }
    }
    
    func createCloudAnchor() {}
    
    func stopSession() {
        if let cloudSession = cloudSession {
            cloudSession.stop()
            cloudSession.dispose()
        }
        
        cloudAnchor = nil
        localAnchor = nil
        cloudSession = nil
        
        for visual in anchorVisuals.values {
            if let node = visual.node{
                node.removeFromParentNode()
            }
        }
        
        anchorVisuals.removeAll()
    }
    
    func lookForAnchor() {
        guard let lookupID = targetId else {
            return
        }
        
        let criteria = ASAAnchorLocateCriteria()!
        if self.lookupArray.count > 0 {
            criteria.identifiers = self.lookupArray
        }else{
            let ids = [lookupID]
            criteria.identifiers = ids
        }
        

        cloudSession!.createWatcher(criteria)
        mainButton.setTitle("Locating Hotspots ...", for: .normal)
    }
    
    func lookForNearbyAnchors() {
        
        guard let found = anchorVisuals[targetId!] else {return}
        
        let criteria = ASAAnchorLocateCriteria()!
        let nearCriteria = ASANearAnchorCriteria()!
        nearCriteria.distanceInMeters = 50
        nearCriteria.sourceAnchor = anchorVisuals[targetId!]!.cloudAnchor

        criteria.nearAnchor = nearCriteria
        cloudSession!.createWatcher(criteria)
        mainButton.setTitle("Locating Hotspots ...", for: .normal)
    }
    
    func deleteFoundAnchors() {
        if (anchorVisuals.count == 0) {
            mainButton.setTitle("Hotspot not found yet", for: .normal)
            return
        }
        
        mainButton.setTitle("Deleting found Hotspot(s) ...", for: .normal)

        /*
        for visual in anchorVisuals.values {
            if let visualCloudAnchor = visual.cloudAnchor {
                cloudSession!.delete(visualCloudAnchor, withCompletionHandler: { (error: Error?) in
                    self.ignoreMainButtonTaps = false
                    self.saveCount -= 1
                    
                    if let error = error {
                        visual.node?.geometry?.firstMaterial?.diffuse.contents = failedColor
                        DispatchQueue.main.async {
                            self.errorControl.isHidden = false
                            self.errorControl.setTitle(error.localizedDescription, for: .normal)
                        }
                    }
                    else {
                        visual.node?.geometry?.firstMaterial?.diffuse.contents = deletedColor
                    }
                    
                    if (self.saveCount == 0) {
                        self.step = .stopSession
                        DispatchQueue.main.async {
                            self.mainButton.setTitle("Cloud Hotspot(s) deleted. Tap to stop Session", for: .normal)
                        }
                    }
                })
            }
        }*/
    }
    
    // MARK: - ASACloudSpatialAnchorSession Delegates
    
    public func onLogDebug(_ cloudSpatialAnchorSession: ASACloudSpatialAnchorSession!, _ args: ASAOnLogDebugEventArgs!) {
        if let message = args.message {
            print(message)
        }
    }
    
//    // You can use this helper method to get an authentication token via Azure Active Directory.
//    internal func tokenRequired(_ cloudSpatialAnchorSession: ASACloudSpatialAnchorSession!, _ args: ASATokenRequiredEventArgs!) {
//        let deferral = args.getDeferral()
//        // AAD user token scenario to get an authentication token
//        AuthenticationHelper.acquireAuthenticationToken { (token: String?, error: Error?) in
//            if error != nil {
//                let errMessage = error!.localizedDescription
//                DispatchQueue.main.async {
//                    self.errorControl.isHidden = false
//                    self.errorControl.setTitle(errMessage, for: .normal)
//                }
//            }
//            if token != nil {
//                args.authenticationToken = token
//            }
//            deferral?.complete()
//        }
//    }
    
    public func anchorLocated(_ cloudSpatialAnchorSession: ASACloudSpatialAnchorSession!, _ args: ASAAnchorLocatedEventArgs!) {
        let status = args.status
        switch (status) {
        case .alreadyTracked:
            // Ignore if we were already handling this.
            break
        case .located:
            let anchor = args.anchor!
            print("Cloud Anchor found! Identifier: \(anchor.identifier ?? "nil"). Location: \(BaseViewController.matrixToString(value: anchor.localAnchor.transform))")
            let visual = AnchorVisual()
            visual.cloudAnchor = anchor
            visual.identifier = anchor.identifier
            visual.localAnchor = anchor.localAnchor
            anchorVisuals[visual.identifier] = visual
            sceneView.session.add(anchor: anchor.localAnchor)
            onNewAnchorLocated(anchor)
        case .notLocatedAnchorDoesNotExist:
            break
        case .notLocated:
            break
        @unknown default:
            break
        }
    }
    
    public func locateAnchorsCompleted(_ cloudSpatialAnchorSession: ASACloudSpatialAnchorSession!, _ args: ASALocateAnchorsCompletedEventArgs!) {
        print("Anchor locate operation completed completed for watcher with identifier: \(args.watcher!.identifier)")
        onLocateAnchorsCompleted()
    }
    
    public func sessionUpdated(_ cloudSpatialAnchorSession: ASACloudSpatialAnchorSession!, _ args: ASASessionUpdatedEventArgs!) {
        let status = args.status!
        let message = BaseViewController.statusToString(status: status, step: step)
        enoughDataForSaving = status.recommendedForCreateProgress >= 1.0
        showLogMessage(text: message, here: feedbackControl)
    }
    
    public func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        
        switch camera.trackingState {
                            
            case .limited(.excessiveMotion):
                print("############## camera did change tracking state: limited, excessive motion")
                            
            case .limited(.initializing):
                print("############## camera did change tracking state: limited, initializing")
            
            case .normal:
                print("############## camera did change tracking state: normal")
                onCameraStable()
            
            case .notAvailable:
                print("############## camera did change tracking state: not available")
            
            case .limited(.insufficientFeatures):
                print("############## insufficientFeatures")
            case .limited(.relocalizing):
                print("############## relocalizing")
            case .limited(_):
                print("############## limited")
        }
    }
    
    public func error (_ cloudSpatialAnchorSession: ASACloudSpatialAnchorSession!, _ args: ASASessionErrorEventArgs!) {
        if let errorMessage = args.errorMessage {
            DispatchQueue.main.async {
                self.errorControl.isHidden = false
            }
            showLogMessage(text: errorMessage, here: errorControl)
            print("Error code: \(args.errorCode), message: \(errorMessage)")
        }
    }
    
    // MARK: - UI Helpers

    private func layoutButtons() {
        layoutButton(mainButton, top: Double(sceneView.bounds.size.height - 180), lines: Double(1.0))
        //layoutButton(backButton, top: 20, lines: 1)
        layoutButton(feedbackControl, top: Double(sceneView.bounds.size.height - 140), lines: Double(1.0))
        layoutButton(errorControl, top: Double(sceneView.bounds.size.height - 400), lines: Double(5.0))
    }

    private func layoutButton(_ button: UIButton, top: Double, lines: Double) {
        let wideSize = sceneView.bounds.size.width - 20.0
        button.frame = CGRect(x: 10.0, y: top, width: Double(wideSize), height: lines * 40)
        if (lines > 1) {
            button.titleLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        }
    }

    func addButton() -> UIButton {
        let result = UIButton(type: .system)
        result.setTitleColor(.black, for: .normal)
        result.setTitleShadowColor(.white, for: .normal)
        result.backgroundColor = UIColor.lightGray.withAlphaComponent(0.6)
        sceneView.addSubview(result)
        return result
    }
    
    func showLogMessage(text: String, here: UIView!) {
        let button = here as? UIButton
        let textField = here as? UITextField
        
        DispatchQueue.main.async {
            button?.setTitle(text, for: .normal)
            textField?.text = text
        }
        
        //print("Log message- \(text)")
    }

    // MARK: - Formatting Helpers
    
    static func matrixToString(value: matrix_float4x4) -> String {
        return String.init(format: "[[%.3f %.3f %.3f %.3f] [%.3f %.3f %.3f %.3f] [%.3f %.3f %.3f %.3f] [%.3f %.3f %.3f %.3f]]",
                           value.columns.0[0], value.columns.1[0], value.columns.2[0], value.columns.3[0],
                           value.columns.0[1], value.columns.1[1], value.columns.2[1], value.columns.3[1],
                           value.columns.0[2], value.columns.1[2], value.columns.2[2], value.columns.3[2],
                           value.columns.0[3], value.columns.1[3], value.columns.2[3], value.columns.3[3])
    }
    
    static func statusToString(status: ASASessionStatus, step: DemoStep) -> String {
        let feedback = feedbackToString(userFeedback: status.userFeedback)
        
        if (step == .createCloudAnchor) {
            let progress = status.recommendedForCreateProgress
            return String.init(format: "%.0f%% progress. %@", progress * 50, feedback)
        }
        else {
            return feedback
        }
    }
    
    static func feedbackToString(userFeedback: ASASessionUserFeedback) -> String {

        if (userFeedback == .notEnoughMotion) {
            return ("Not enough motion.")
        }
        else if (userFeedback == .motionTooQuick) {
            return ("Motion is too quick.")
        }
        else if (userFeedback == .notEnoughFeatures) {
            return ("Not enough features.")
        }
        else {
            return "Move slowly to detect hotspots! 🤳"
        }
    }
        

}
