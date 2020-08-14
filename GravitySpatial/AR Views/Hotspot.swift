//
//  Hotspot.swift
//  GravityXR
//
//  Created by Avinash Shetty on 5/2/20.
//  Copyright © 2020 GravityXR. All rights reserved.
//

import Foundation
import SceneKit

public class HotspotNode: SCNNode {
    
    var hotspotButton:SCNNode! { didSet { hotspotButton.name = "hotspotButton"}}


    override init() {
        
        super.init()
        
        guard let buttonScn = SCNScene(named: "Art.scnassets/hotspot.scn"),
            let buttonRoot = buttonScn.rootNode.childNode(withName: "RootNode", recursively: false),
            let button = buttonRoot.childNode(withName: "hButton", recursively: false),
            let buttonImage = button.childNode(withName: "hButtonImage", recursively: false)

            else { fatalError("Error getting hotspot scene") }
               
        buttonImage.geometry?.materials.first?.diffuse.contents = UIImage(named: "anchor_added")

        self.hotspotButton = buttonRoot
        
        //Add to hierarchy
        self.addChildNode(buttonRoot)
        
        setConfiguration()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit { flushFromMemory() }
    
    func setConfiguration(){
        
        self.hotspotButton.scale = SCNVector3Make(1.0, 1.0, 1.0)
        
    }
        
    /// Removes All SCNMaterials & Geometries From An SCNNode
    func flushFromMemory(){
        
        print("Cleaning Hotspot Node")
        /*
        if let parentNodes = self.parent?.childNodes{ parentNodes.forEach {
                $0.geometry?.materials.forEach({ (material) in material.diffuse.contents = nil })
                $0.geometry = nil
                $0.removeFromParentNode()
            }
        }
        
        for node in self.childNodes{
                node.geometry?.materials.forEach({ (material) in material.diffuse.contents = nil })
                node.geometry = nil
                node.removeFromParentNode()
        }*/
    }
}
