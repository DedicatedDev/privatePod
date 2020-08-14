//
//  SceneAnimations.swift
//  GravityXR
//
//  Created by Simranjeet Aulakh on 07/07/20.
//  Copyright © 2020 GravityXR. All rights reserved.
//

import Foundation
import ARKit

extension SCNNode {
    func scaleAnimation(scale:CGFloat,duration:TimeInterval){
          //Animate the card
          let action = SCNAction.scale(to: scale, duration:duration)
        
          self.runAction(action)
      }
    
    func fadeInOut(opacity:CGFloat,duration:TimeInterval){
        SCNTransaction.animationDuration = duration
        self.opacity = opacity
    }
    
    func bounceAnim(){
        let moveUp = SCNAction.moveBy(x: 0, y: 1, z: 0, duration: 1)
        moveUp.timingMode = .easeInEaseOut;
        let moveDown = SCNAction.moveBy(x: 0, y: -1, z: 0, duration: 1)
        moveDown.timingMode = .easeInEaseOut;
        let moveSequence = SCNAction.sequence([moveUp,moveDown])
        let moveLoop = SCNAction.repeat(moveSequence, count: 5)
        self.runAction(moveLoop)
    }
    
    func spinAnim(){
        let spin = CABasicAnimation(keyPath: "rotation")
        // Use from-to to explicitly make a full rotation around z
        spin.fromValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 0, w: 0))
        spin.toValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 0, w: Float(CGFloat(2 * M_PI))))
        spin.duration = 3
        spin.repeatCount = .infinity
        self.addAnimation(spin, forKey: "spin around")
    }
    
    func pulseAnim(){
        let pulseSize:CGFloat = 5.0
        let pulsePlane = SCNPlane(width: pulseSize, height: pulseSize)
        pulsePlane.firstMaterial?.isDoubleSided = true
        pulsePlane.firstMaterial?.diffuse.contents = UIColor.blue
        let pulseNode = SCNNode(geometry: pulsePlane)

        let pulseShaderModifier =
        "#pragma transparent; \n" +
        "vec4 originalColour = _surface.diffuse; \n" +
        "vec4 transformed_position = u_inverseModelTransform * u_inverseViewTransform * vec4(_surface.position, 1.0); \n" +
        "vec2 xy = vec2(transformed_position.x, transformed_position.y); \n" +
        "float xyLength = length(xy); \n" +
        "float xyLengthNormalised = xyLength/" + String(describing: pulseSize / 2) + "; \n" +
        "float speedFactor = 1.5; \n" +
        "float maxDist = fmod(u_time, speedFactor) / speedFactor; \n" +
        "float distbasedalpha = step(maxDist, xyLengthNormalised); \n" +
        "distbasedalpha = max(distbasedalpha, maxDist); \n" +
        "_surface.diffuse = mix(originalColour, vec4(0.0), distbasedalpha);"

        pulsePlane.firstMaterial?.shaderModifiers = [SCNShaderModifierEntryPoint.surface:pulseShaderModifier]
        self.addChildNode(pulseNode)
    }
    
    /// Creates A Pulsing Animation On An Infinite Loop
       ///Material blinking
       /// - Parameter duration: TimeInterval
       func highlightNodeWithDurarion(_ duration: TimeInterval){

           //1. Create An SCNAction Which Emmits A Red Colour Over The Passed Duration Parameter
           let highlightAction = SCNAction.customAction(duration: duration) { (node, elapsedTime) in

               let color = UIColor(red: elapsedTime/CGFloat(duration), green: 0, blue: 0, alpha: 1)
               let currentMaterial = self.geometry?.firstMaterial
               currentMaterial?.emission.contents = color

           }

           //2. Create An SCNAction Which Removes The Red Emissio Colour Over The Passed Duration Parameter
           let unHighlightAction = SCNAction.customAction(duration: duration) { (node, elapsedTime) in
               let color = UIColor(red: CGFloat(1) - elapsedTime/CGFloat(duration), green: 0, blue: 0, alpha: 1)
               let currentMaterial = self.geometry?.firstMaterial
               currentMaterial?.emission.contents = color

           }

           //3. Create An SCNAction Sequence Which Runs The Actions
           let pulseSequence = SCNAction.sequence([highlightAction, unHighlightAction])

           //4. Set The Loop As Infinitie
           let infiniteLoop = SCNAction.repeatForever(pulseSequence)

           //5. Run The Action
           self.runAction(infiniteLoop)
       }
    
}

extension SCNText{
    
    func blinkAnim(){
        var blinked = false
          _ = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] timer in
            
            }
    }
    
    
    func animateTextGeometry( withText text: String ){
    //1. Timer To Animate Our Text
    //var animationTimer: Timer?
        
    //2. Variable To Store The Current Time
    var time:Int  = 0
        
    //1. Get All The Characters From The Text
    let characters = Array(text)
    
    //2. Run The Animation
    _ = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] timer in
        
        //a. If The Current Time Doesnt Equal The Count Of Our Characters Then Continue To Animate Our Text
        if time != characters.count {
            let currentText: String = self?.string as! String
            self?.string = currentText + String(characters[(time)])
            time += 1
        }else{
            //b. Invalide The Timer, Reset The Variables & Escape
            //timer.invalidate()
            time = 0
            self?.string = ""
           
        }
    }
}
}
