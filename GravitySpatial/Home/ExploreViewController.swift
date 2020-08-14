//
//  ExploreViewController.swift
//  GravityXR
//
//  Created by Avinash Shetty on 4/25/20.
//  Copyright © 2020 GravityXR. All rights reserved.
//

import Foundation
import CoreLocation
import Alamofire
import AVFoundation
import ARKit

public class ExploreViewController: BaseViewController, BrowserDelegate, UITableViewDataSource, UITableViewDelegate {

    private var session: Session!
    @IBOutlet var handView: UIImageView!

    @IBOutlet var experiencesTableView: UITableView!
    @IBOutlet var experiencePickerPopUp: UIView!
    @IBOutlet var experiencePickerLabel: UILabel!
    @IBOutlet var controlsBGView: UIVisualEffectView!
    @IBOutlet var controlsView: UIStackView!
    
    var experiences:[Experience] = []
    var filters:[Industry] = []
    var filteredAnchors:[String] = []

    var textManager: TextManager!
    var restartExperienceButtonIsEnabled = true

    var bShowingControlBar = false
    //let coachingOverlay = ARCoachingOverlayView()

    // Enum for card states
    enum CardState {
        case collapsed
        case expanded
    }
    
    var filtersButton: UIButton!
    var captureButton: UIButton!
    var restartButton: UIButton!

    @IBOutlet weak var messagePanel: UIView!
    @IBOutlet weak var messageLabel: UILabel!

    var cards:[Card] = [] //Data model
    var nodeDictionary: [String: Any] = [:] //node content

    var walls:[Wall] = [] //Data model
    var wallAnchors: [String: Any] = [:]

    // Variable determines the next state of the card expressing that the card starts and collapased
    var nextState:CardState {
        return cardVisible ? .collapsed : .expanded
    }

    // Variable for card view controller
    var cardViewController:BrowserController!

    // Variable for effects visual effect view
    var visualEffectView:UIVisualEffectView!
    
    // Starting and end card heights will be determined later
    var endCardHeight:CGFloat = 0
    var startCardHeight:CGFloat = 0
    
    // Current visible state of the card
    var cardVisible = false

    // Empty property animator array
    var runningAnimations = [UIViewPropertyAnimator]()
    var animationProgressWhenInterrupted:CGFloat = 0
    var hotspotsFoundSoundEffect: AVAudioPlayer?

    typealias DataFetchCompletion = (_ succeeded: Bool) -> Void
    let networkQueue = DispatchQueue(label: "com.gravityxr.api", qos: .background, attributes: .concurrent)

    
    public override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        self.mainButton.isHidden = true
        self.feedbackControl.setTitle("Move your phone to start the experience", for: .normal)
        
        // Prevent the screen from being dimmed after a while.
        UIApplication.shared.isIdleTimerDisabled = true
        
    }
    
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.handView.isHidden = true

        if ARWorldTrackingConfiguration.isSupported {
            
            // Start the ARSession.
            if(!self.experiencePickerPopUp.isHidden){ //before picking an experience

                self.experiences.removeAll()
                self.updateInstructionLabel()
                
                if (nil ==  UserDefaults.standard.string(forKey: "userToken")){
                    getGuestAccessKey()
                }else{
                    self.fetchNearbyExperiences()
                }
            }

        } else {
            // This device does not support 6DOF world tracking.
            let sessionErrorMsg = "This app requires world tracking. World tracking is only available on iOS devices with A9 processor or newer. " +
            "Please quit the application."
            displayErrorMessage(title: "Unsupported platform", message: sessionErrorMsg, allowRestart: false)
        }

    }
    
    
    public override func viewDidLoad() {
        
        super.viewDidLoad()

        self.cardViewController = self.createBrowserController()

        cardViewController.delegate = self
        self.experiencesTableView.register(TableCell.self, forCellReuseIdentifier: "exploreExperienceCell")
        self.experiencesTableView.separatorStyle = .none
        self.setupUIControls()

        self.getFilters()
                   

        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        self.sceneView.debugOptions = []
        
        // Run the view's session
        self.sceneView.session.run(configuration)
    }
    
    func setupUIControls() {
                
        self.controlsView.layoutMargins = UIEdgeInsets(top: 20, left: 5, bottom: 20, right: 0)
        self.controlsView.axis = .vertical
        self.controlsBGView.layer.cornerRadius = 8.0
        self.controlsBGView.clipsToBounds = true

        //show filter button
        self.addFilterButton()

        //show filter button
        self.addCaptureButton()

        //for switching experience
        self.addRestartExperienceButton()
        
        self.controlsView.addArrangedSubview(self.captureButton)
        self.controlsView.addArrangedSubview(self.filtersButton)
        self.controlsView.addArrangedSubview(self.restartButton)
        
        self.controlsBGView.isHidden = !bShowingControlBar

        textManager = TextManager(viewController: self)
        
        // Set appearance of message output panel
        messagePanel.layer.cornerRadius = 4.0
        messagePanel.clipsToBounds = true
        messagePanel.isHidden = true
        messageLabel.text = ""
    }
    
    func createBrowserController() -> BrowserController{
        
        print("Creating Browser Controller2")
        let bundle = Bundle(for: BrowserController.self)
        let storyboard = UIStoryboard(name: "SpatialView", bundle: bundle)
        return storyboard.instantiateViewController(withIdentifier: "browser") as! BrowserController

    }
    
    func addRestartExperienceButton(){
        
        let result = UIButton(type: .custom)
        result.setTitleColor(.black, for: .normal)
        result.setTitleShadowColor(.white, for: .normal)
        result.setImage(UIImage(named:"restart_white"), for: .normal)
        
        result.addTarget(self, action:#selector(restartButtonTapped), for: .touchDown)
        
        self.restartButton = result

    }
    
    //MARK:- Calculate distance from node
     func getDistanceFromNodeToCamera(cameraTransform:simd_float4x4){
        DispatchQueue.main.async {
            self.sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
                
                 //let distance = simd_distance(node.simdTransform.columns.3, (sceneView.session.currentFrame?.camera.transform.columns.3)!);
                 let distance = simd_distance(node.simdTransform.columns.3, (cameraTransform.columns.3));
                 
                 if distance > 3{
                     node.isHidden = true
                 }else{
                      node.isHidden = false
                 }
            }
        }
     }
    
    
    //MARK: - Azure callbacks
    override func onLocateAnchorsCompleted() {
        
        ignoreMainButtonTaps = false
        
        if (step == .lookForAnchor) {
            step = .lookForNearbyAnchors
            
            self.handView.layer.removeAllAnimations()
            self.handView.isHidden = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.lookForNearbyAnchors()
            }
            
        }else{
            step = .deleteFoundAnchors
            
            DispatchQueue.main.async {
                
                self.mainButton.isHidden = true
                self.feedbackControl.isHidden = true
                            
                //self.playHotspotsFound()
            }
        }

    }
    
    func playHotspotsFound(){
        let path = Bundle.main.path(forResource: "discovered.mp3", ofType:nil)!
        let url = URL(fileURLWithPath: path)

        do {
            hotspotsFoundSoundEffect = try AVAudioPlayer(contentsOf: url)
            hotspotsFoundSoundEffect?.play()
        } catch {
            // couldn't load file :(
        }
    }
    
    func playHotspotsTapped(){
        let path = Bundle.main.path(forResource: "subtleTap.mp3", ofType:nil)!
        let url = URL(fileURLWithPath: path)

        do {
            hotspotsFoundSoundEffect = try AVAudioPlayer(contentsOf: url)
            hotspotsFoundSoundEffect?.play()
        } catch {
            // couldn't load file :(
        }
    }

    func logDistanceBetweenNodes(){
        
        var oldNode:SCNNode? = nil
        
        for visual in anchorVisuals.values {
                           
            if((oldNode != nil) && (visual.node != nil)){
                
                let distance = SCNVector3.distanceFrom(vector: oldNode!.position, toVector: visual.node!.position)
                
                print("^^^^^^^^^^^^^^^^^^")
                print("Distance \(distance) from \(visual.identifier)")
                print("^^^^^^^^^^^^^^^^^^")
                
            }
            oldNode = visual.node
        }
    }
    
    func createObjectAnchor(y:Float) -> ARAnchor {
        
        let sceneView = self.sceneView
        let currentFrame = sceneView!.session.currentFrame
        
        // Place AR objects upright infront of camera
        var translation = matrix_identity_float4x4
        translation.columns.3.z = 0
        translation.columns.3.y = y - 2
        
        let transform = currentFrame!.camera.transform
        let rotation = matrix_float4x4(SCNMatrix4MakeRotation(Float.pi/2, 0, 0, 1))
        
        let anchorTransform = matrix_multiply(transform, matrix_multiply(translation, rotation))
        return ARAnchor(transform: anchorTransform)
        
    }

    
    //MARK: - Actions
    
    @objc override func mainButtonTap(sender: UIButton) {
        if (ignoreMainButtonTaps) {
            return
        }
        
        switch (step) {
            case .prepare:
                //mainButton.setTitle("Tap to Start Experience", for: .normal)
                self.feedbackControl.setTitle("Move your phone to start the experience", for: .normal)

                step = .lookForAnchor
            case .lookForAnchor:
                ignoreMainButtonTaps = true
                stopSession()
                startSession()
                
                // We will get a call to onLocateAnchorsCompleted which will move to the next step when the locate operation completes.
                lookForAnchor()
            case .lookForNearbyAnchors:
                if (anchorVisuals.count == 0) {
                    mainButton.setTitle("First hotspot not found yet", for: .normal)
                    return
                }
                ignoreMainButtonTaps = true

                // We will get a call to onLocateAnchorsCompleted which will move to the next step when the locate operation completes.
                lookForNearbyAnchors()
            case .deleteFoundAnchors:
                ignoreMainButtonTaps = true
            case .stopSession:
                stopSession()
                moveToMainMenu()
            default:
                assertionFailure("invalid state")
        }
    }

        
    func updateTrackingInfo(){
        
        guard let frame = self.sceneView.session.currentFrame else {return}
        guard let lightEstimate = frame.lightEstimate?.ambientIntensity else{return}
        
        if lightEstimate < 100 {
            self.feedbackControl.isHidden = false
            self.feedbackControl.setTitle("Limited Tracking: Too Dark", for: .normal)
        }else{
            self.feedbackControl.isHidden = true
        }
        
    }
    
    //MARK: - AR Callbacks
    
   /* override func sessionWasInterrupted(_ session: ARSession) {
        textManager.blurBackground()
        textManager.showAlert(title: "Session Interrupted", message: "The session will be reset after the interruption has ended.")
    }
    
    override func sessionInterruptionEnded(_ session: ARSession) {
        textManager.unblurBackground()
        //session.run(standardConfiguration, options: [.resetTracking, .removeExistingAnchors])
        restartExperience()
        textManager.showMessage("RESETTING SESSION")
    }
    
    override func session(_ session: ARSession, didFailWithError error: Error) {
        self.feedbackControl.isHidden = false
        self.feedbackControl.setTitle("Could not initialize AR Session", for: .normal)
    }
    
    override func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        DispatchQueue.main.async {
            self.updateTrackingInfo()
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        
        textManager.showTrackingQualityInfo(for: camera.trackingState, autoHide: true)
        
        switch camera.trackingState {
        case .notAvailable:
            fallthrough
        case .limited:
            textManager.escalateFeedback(for: camera.trackingState, inSeconds: 3.0)
        case .normal:
            textManager.cancelScheduledMessage(forType: .trackingStateEscalation)
        }
    }*/

    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        for visual in anchorVisuals.values {
           
            if (visual.localAnchor == anchor) {

                if let hotspot = nodeDictionary[visual.identifier] as? SCNNode {

                   /* Experiment - Tilt the hotspots based on distance to the ground
                     if let root = hotspot.childNodes.first{
                        
                        if let anchor = visual.localAnchor{
                            
                            //tilt the hotspots if they are below the scene frame
                            let yRot:Float = Helper.getRotationY(anchor.transform)
                            let position = Helper.getPosition(anchor.transform)

                            //print("$$$\n\(anchor.transform)\nyRot : \(yRot), yRot : \(yRot), zRot : \(zRot), position:  \(position)\n")
                            if(yRot > 45){
                                root.rotation = SCNVector4(0,1,0,0)
                            }
                            
                            var xVal = ((position.y)*50)
                            if xVal < 10 {
                                xVal = (xVal < -45) ? -89.0 : ((xVal > -20.0) ? -45.0 : -10.0)
                                let xEulerRot = Float(xVal).asRadians() // x rotation
                                root.eulerAngles = SCNVector3(xEulerRot,0,0)
                            }
                            
                        }
                    }*/
                
                    //hotspot.faceCamera()
                    visual.node = hotspot
                
                } else if let wall = wallAnchors[visual.identifier] as? SCNNode {
                    visual.node = wall
                }
                    
                return visual.node
            }
        }
        
        return nil
    }
        

    //MARK: - Data
    
    func getGuestAccessKey()
    {
        let guestAccessURL = Endpoint.guestToken.urlStr
                
        AF.request(guestAccessURL, method: .get, headers: Endpoint.guestToken.headers, interceptor: RequestInterceptor())
        .responseDecodable(of: Guest.self){ response in
            
            let statusCode = response.response?.statusCode

            print("Guest Access response - \(statusCode)")
            switch response.result {
                case .success:
                    guard let guest:Guest = response.value else { return }
                    print(guest)
                    UserDefaults.standard.set(guest.token, forKey:"userToken")

                    DispatchQueue.main.async {
                        self.fetchNearbyExperiences()
                    }
                case let .failure(error):
                    print(error)
            }
        }
    }
    
    
    func fetchNearbyExperiences(){
        
        let getExperiencesURL = Endpoint.experiences.urlStr

        AF.request(getExperiencesURL, method: .get, headers: Endpoint.experiences.headers, interceptor: RequestInterceptor())
          .responseDecodable(of: [Experience].self){ response in
            
            let statusCode = response.response?.statusCode
            print("fetchNearbyExperiences - \(statusCode)")

            switch response.result {
                case .success:
                    guard let allExperiences:[Experience] = response.value else { return }
                
                    for experience in allExperiences{
                        if(experience.location != nil){
                            if(experience.status == "launch"){
                                let expLoc = CLLocation(latitude: experience.location?.latitude ?? 0.0, longitude:experience.location?.longitude ?? 0.0)
                                if(LocationManager.shared.distanceFromLocation(with: expLoc) == Proximity.withinMile ||
                                    LocationManager.shared.distanceFromLocation(with: expLoc) == Proximity.close){
                                    self.experiences.append(experience)
                                }
                           }
                        }
                    }
                    DispatchQueue.main.async {
                        self.updateInstructionLabel()
                        self.experiencesTableView.reloadData()
                    }
                case let .failure(error):
                    print(error)
            }
            
        }
    }
            
    func fetchOcclusionWalls (forExperienceID experienceID: String){

        let wallsForExperienceURL = Endpoint.walls(id:experienceID).urlStr
        
        AF.request(wallsForExperienceURL, method: .get, headers: Endpoint.experiences.headers, interceptor: RequestInterceptor())
          .responseDecodable(of: [Wall].self){ response in
            
            //let statusCode = response.response?.statusCode

            switch response.result {
                case .success:
                    guard let responseWalls:[Wall] = response.value else { return }
                    self.walls = responseWalls
                
                    var wallAnchorID:String?

                    for wall in self.walls {
                        if (wall.anchorId != nil) && wall.anchorId!.count > 0 {
                            wallAnchorID = wall.anchorId
                            
                            //Create ProductCards for every valid card with anchor
                            let wallNode = OcclusionWall(data: wall)
                            self.wallAnchors[wallAnchorID!] = wallNode
                        }
                    }
                    
                case let .failure(error):
                    print(error)
            }
        }
    }
    
    
    func updateInstructionLabel(){
        
        if(self.experiences.count == 1){
            self.experiencePickerLabel.text = "We Found 1 Nearby Experience. Tap to explore"
        }else if(self.experiences.count > 0){
            self.experiencePickerLabel.text = "We Found \(self.experiences.count) Nearby Experiences. Tap to explore"
        }else{
            if(CLLocationManager.locationServicesEnabled()){
                self.experiencePickerLabel.text = "Sorry. We do not have any nearby experiences. Check back soon."
            }else{
                self.experiencePickerLabel.text = "The app needs location permissions to find nearby experiences."
            }
        }
    }
    

    //MARK: - Layout Cards
    
    ///Enter data for buttons card here
    func createProductCard(info:Card) -> SCNNode?{
             
        guard let config = info.cardConfig else {return nil}
        
        switch(config.type){
            case "Product Card":
                return ProductCard(data: info, prevCard: nil, cardType:.cardScn, buttonType: .buttonAnchorScn)
            case "Custom Card":
                return CustomCard(data: info, prevCard: nil, cardType:.cardScn, buttonType: .buttonAnchorScn)
            default:
                return ProductCard(data: info, prevCard: nil, cardType:.cardScn, buttonType: .buttonAnchorScn)
        }
    }
    
    override func onCameraStable(){
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {

            // Create a session configuration
             let configuration = ARWorldTrackingConfiguration()
             self.sceneView.debugOptions = []
             self.sceneView.session.delegate = self

             // Run the view's session
             self.sceneView.session.run(configuration)
             self.step = .lookForAnchor

             self.ignoreMainButtonTaps = true
             self.stopSession()
             
             self.startSession()
             self.lookForAnchor()
        }
    }

    
    func launchExperience(with id:String){
        
        // Set up coaching overlay.
        //self.setupCoachingOverlay()
        self.feedbackControl.isHidden = false

        //Fetch experience hotspots and initialize ARSession only on completion
        fetchHotspots(experienceID: id){ [weak self] succeeded in

            DispatchQueue.main.async {

                if succeeded {

                    //self!.nudgeUserToMovePhoneForPlaneDetection()
                    //Once the camera is stable we initialize the session with needed properties
                    self!.experiencePickerPopUp.isHidden = true
                    self?.feedbackControl.isHidden = true

                }else{
                    self!.experiencePickerPopUp.isHidden = false
                }
            }
        }
        
        self.fetchOcclusionWalls(forExperienceID: id)

    }
    
    func fetchHotspots(experienceID: String, completion: @escaping DataFetchCompletion) {

        let cardsForExperienceURL = Endpoint.cards(id:experienceID).urlStr
        
        AF.request(cardsForExperienceURL, method: .get, headers: Endpoint.experiences.headers, interceptor: RequestInterceptor())
            .responseDecodable(of: [Card].self){ response in
            
            switch response.result {
                case .success:
                    guard let responseCards:[Card] = response.value else { return }
                    self.cards = responseCards
                
                    var experienceAnchorId:String?

                    for card in self.cards {
                        if let cardAnchorID = card.anchorId {
                            
                            if(cardAnchorID.count > 0){
                                let cardAnchorArr = cardAnchorID.components(separatedBy: ",")
                                
                                if(card.status == "active"){
                                    
                                    for cardAnchor in cardAnchorArr {
                                        //Create ProductCards for every valid card with anchor
                                        let cardNode = self.createProductCard(info: card)
                                        
                                        self.nodeDictionary[cardAnchor] = cardNode
                                        experienceAnchorId = cardAnchor
                                        
                                        print("cardAnchorID : \(cardAnchorID)\n cardAnchor: \(cardAnchor)")

                                    }
                                }
                            }
                        }
                    }
                    
                    if let experienceAnchorId = experienceAnchorId { //found an anchor to look for in the area
                        self.targetId = experienceAnchorId
                        self.lookupArray = Array(self.nodeDictionary.keys)
                        print("experienceAnchorId : \(experienceAnchorId)\n lookupArray: \(self.lookupArray)")
                        completion(true)

                    }else{
                        completion(false)
                    }
                                    

                case let .failure(error):
                    completion(false)
                    print(error)
            }
        }

    }
    
    func nudgeUserToMovePhoneForPlaneDetection() {
        
        DispatchQueue.main.async {

            self.handView.isHidden = false
    
            let oldPosition = self.handView.layer.position
            var leftPosition = oldPosition
            leftPosition.x -= 100
            var rightPosition = oldPosition
            rightPosition.x += 100

            
            let animation: CABasicAnimation = CABasicAnimation(keyPath: "position")
            animation.fromValue = self.handView.layer.position
            animation.toValue = rightPosition
            animation.byValue = leftPosition
            animation.duration = 2.00
            animation.autoreverses = true
            animation.repeatCount = 4
            self.handView.layer.position = oldPosition
            self.handView.layer.add(animation, forKey: "moveAnimation")

        }
        
    }
    
    
    //MARK: - Card
    func setupCard(url: URL) {
        
        // Setup starting and ending card height
        endCardHeight = self.view.frame.height * 0.8
        startCardHeight = self.view.frame.height * 0.1
        
        // Add Visual Effects View
        visualEffectView = UIVisualEffectView()
        visualEffectView.frame = self.view.frame
        self.view.addSubview(visualEffectView)

        self.view.addSubview(cardViewController.view)

        // Add CardViewController xib to the bottom of the screen, clipping bounds so that the corners can be rounded
        cardViewController.setupUI(url: url)

        cardViewController.view.frame = CGRect(x: 0, y: self.view.frame.height - startCardHeight, width: self.view.bounds.width, height: endCardHeight)
        cardViewController.view.clipsToBounds = true
        self.visualEffectView.effect = UIBlurEffect(style: .dark)

        // Add tap and pan recognizers
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ExploreViewController.handleCardTap(recognzier:)))
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ExploreViewController.handleCardPan(recognizer:)))

        cardViewController.handleArea.addGestureRecognizer(tapGestureRecognizer)
        cardViewController.handleArea.addGestureRecognizer(panGestureRecognizer)
        
        animateTransitionIfNeeded(state: .expanded, duration: 0.1)

    }
    
    // Handle tap gesture recognizer
    @objc
    func handleCardTap(recognzier:UITapGestureRecognizer) {
        switch recognzier.state {
            // Animate card when tap finishes
        case .ended:
            animateTransitionIfNeeded(state: nextState, duration: 0.9)
        default:
            break
        }
    }
    
    // Handle pan gesture recognizer
    @objc
    func handleCardPan (recognizer:UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            // Start animation if pan begins
            startInteractiveTransition(state: nextState, duration: 0.9)
            
        case .changed:
            // Update the translation according to the percentage completed
            let translation = recognizer.translation(in: self.cardViewController.handleArea)
            var fractionComplete = translation.y / endCardHeight
            fractionComplete = cardVisible ? fractionComplete : -fractionComplete
            updateInteractiveTransition(fractionCompleted: CGFloat(fractionComplete))
        case .ended:
            // End animation when pan ends
            continueInteractiveTransition()
        default:
            break
        }
    }

     // Animate transistion function
     func animateTransitionIfNeeded (state:CardState, duration:TimeInterval) {
         // Check if frame animator is empty
         if runningAnimations.isEmpty {
             // Create a UIViewPropertyAnimator depending on the state of the popover view
             let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                 switch state {
                 case .expanded:
                     // If expanding set popover y to the ending height and blur background
                    self.cardViewController.view.frame.origin.y = self.view.frame.height - self.endCardHeight
                     self.visualEffectView.effect = UIBlurEffect(style: .dark)
    
                 case .collapsed:
                     // If collapsed set popover y to the starting height and remove background blur
                     self.cardViewController.view.frame.origin.y = self.view.frame.height//-self.startCardHeight
                     
                     self.visualEffectView.effect = nil
                 }
             }
             
             // Complete animation frame
             frameAnimator.addCompletion { _ in
                 self.cardVisible = !self.cardVisible
                 self.runningAnimations.removeAll()
             }
             
             // Start animation
             frameAnimator.startAnimation()
             
             // Append animation to running animations
             runningAnimations.append(frameAnimator)
             
             // Create UIViewPropertyAnimator to round the popover view corners depending on the state of the popover
             let cornerRadiusAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
                 switch state {
                 case .expanded:
                     // If the view is expanded set the corner radius to 30
                     self.cardViewController.view.layer.cornerRadius = 30
                     
                 case .collapsed:
                     // If the view is collapsed set the corner radius to 0
                     self.cardViewController.view.layer.cornerRadius = 0
                 }
             }
             
             // Start the corner radius animation
             cornerRadiusAnimator.startAnimation()
             
             // Append animation to running animations
             runningAnimations.append(cornerRadiusAnimator)
             
         }
     }
     
     // Function to start interactive animations when view is dragged
     func startInteractiveTransition(state:CardState, duration:TimeInterval) {
         
         // If animation is empty start new animation
         if runningAnimations.isEmpty {
             animateTransitionIfNeeded(state: state, duration: duration)
         }
         
         // For each animation in runningAnimations
         for animator in runningAnimations {
             // Pause animation and update the progress to the fraction complete percentage
             animator.pauseAnimation()
             animationProgressWhenInterrupted = animator.fractionComplete
         }
     }
     
     // Funtion to update transition when view is dragged
     func updateInteractiveTransition(fractionCompleted:CGFloat) {
         // For each animation in runningAnimations
         for animator in runningAnimations {
             // Update the fraction complete value to the current progress
             animator.fractionComplete = fractionCompleted + animationProgressWhenInterrupted
         }
     }
     
     // Function to continue an interactive transisiton
     func continueInteractiveTransition (){
         // For each animation in runningAnimations
         for animator in runningAnimations {
             // Continue the animation forwards or backwards
             animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
         }
     }

    
    
    //MARK: - Tableview
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.experiences.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCell(withIdentifier: "exploreExperienceCell", for: indexPath)

        if cell.detailTextLabel == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "exploreExperienceCell")
        }

        cell.textLabel?.text = experiences[indexPath.row].name
        cell.textLabel?.textAlignment = .center
        cell.selectionStyle = .blue
        //cell.contentView.backgroundColor = UIColor(hex: "E8EBF1")
        //cell.layer.cornerRadius = 20
        //cell.layer.masksToBounds = false
        

        if let loc = experiences[indexPath.row].location{
            let distance = LocationManager.shared.distanceFromLocation(with: CLLocation(latitude: loc.latitude ?? 0, longitude: loc.longitude ?? 0))
            switch distance {
            case .close:
                cell.detailTextLabel?.text = "< 50m"
            case .withinMile:
                cell.detailTextLabel?.text = "\(loc.name) - 1 mile"
            default:
                cell.detailTextLabel?.text = loc.name
            }
        }
        
        return cell

    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let expId = experiences[indexPath.row].id
        launchExperience(with: String(expId))
        
        experiencePickerPopUp.isHidden = true
            
    }
        
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90.0
    }

    //MARK:- Error handling

    func displayErrorMessage(title: String, message: String, allowRestart: Bool = false) {
        
        // Blur the background.
        textManager.blurBackground()
        
        if allowRestart {
            // Present an alert informing about the error that has occurred.
            let restartAction = UIAlertAction(title: "Reset", style: .default) { _ in
                self.textManager.unblurBackground()
                self.restartExperience()
            }
            textManager.showAlert(title: title, message: message, actions: [restartAction])
        } else {
            textManager.showAlert(title: title, message: message, actions: [])
        }
    }
    
    func restartExperience() {
        
        stopSession()
        let standardConfiguration = ARWorldTrackingConfiguration()

        // Run the view's session
        self.sceneView.session.run(standardConfiguration, options: [.resetTracking, .removeExistingAnchors])
        
        textManager.scheduleMessage("Experience Restarted",
                                    inSeconds: 5,
                                    messageType: .planeEstimation)
    }
    
    @objc func restartButtonTapped(sender: UIButton) {

        stopSession()
        self.experiencePickerPopUp.isHidden = false
        bShowingControlBar = false
        self.controlsBGView.isHidden = !bShowingControlBar
        
    }
    

}

extension ExploreViewController:ARSessionDelegate{
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
         // Do something with the new transform
        // let currentTransform = frame.camera.transform
       // getDistanceFromNodeToCamera(cameraTransform: currentTransform)
     }
}

//Motion
/*extension ExploreViewController {
    
    func showStartAnimation(){
        
        // create a reversing MotionSequence with its reversingMode set to contiguous to create a fluid animation from its child motions
        let sequence = MotionSequence().reverses(.sequential)

        // set up motions for each circle and add them to the MotionSequence
        for x in 0..<4 {
            // motion to animate a topAnchor constraint down
            let down = Motion(target: constraints["y\(x)"]!,
                              properties: [PropertyData("constant", 60.0)],
                              duration: 0.4,
                              easing: EasingQuartic.easeInOut())

            // motion to change background color of circle
            let color = Motion(target: circles[x],
                               statesForProperties: [PropertyStates(path: "backgroundColor", end: UIColor.init(red: 91.0/255.0, green:189.0/255.0, blue:231.0/255.0, alpha:1.0))],
                               duration: 0.3,
                               easing: EasingQuadratic.easeInOut())

            // wrap the Motions in a MotionGroup and set it to reverse
            let group = MotionGroup(motions: [down, color]).reverses(syncsChildMotions: true)

            // add group to the MotionSequence
            sequence.add(group)
        }
        sequence.start()

    }
}*/
