//
//  OcclusionWall.swift
//  GravityXR
//
//  Created by Avinash Shetty on 6/19/20.
//  Copyright © 2020 GravityXR. All rights reserved.
//

import Foundation
import SceneKit

public class OcclusionWall: SCNNode {

    var wallData: Wall!

    init(data: Wall? = nil, debug: Bool = false) {
    
        super.init()
        self.wallData = data

        let plane = SCNPlane(width: CGFloat(self.wallData.width), height: CGFloat(self.wallData.height))
        let planeNode = SCNNode(geometry: plane)
        planeNode.name = "plane"
        planeNode.addChildNode(IDNode(id: self.wallData.id, name: "ID"))
        
        if(debug){
            planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor(red: 40/255, green: 100/255, blue: 250/255, alpha: 0.50)
        }else{
             planeNode.renderingOrder = -100
            planeNode.geometry?.firstMaterial = occlusion()
        }
        
        self.addChildNode(planeNode)

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented in OcclusionWall")
    }

    func occlusion() -> SCNMaterial {
        
        let occlusionMaterial = SCNMaterial()
        occlusionMaterial.isDoubleSided = true
        occlusionMaterial.colorBufferWriteMask = []
        occlusionMaterial.readsFromDepthBuffer = true
        occlusionMaterial.writesToDepthBuffer = true
        
        
        return occlusionMaterial
    }

}
