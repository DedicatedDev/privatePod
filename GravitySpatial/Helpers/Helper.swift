//
//  Helper.swift
//  GravityXR
//
//  Created by Avinash Shetty on 5/13/20.
//  Copyright © 2020 GravityXR. All rights reserved.
//

import Foundation
import SceneKit

public class Helper {
    
    public static func lastModifiedTime(_ isoDateStr : String) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let date = dateFormatter.date(from:isoDateStr)!

        let formatter4 = DateFormatter()
        formatter4.dateFormat = "MMM d, HH:mm E"
        return formatter4.string(from: date)

    }
    
}


extension SCNVector3 {
    static func distanceFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> Float {
        let x0 = vector1.x
        let x1 = vector2.x
        let y0 = vector1.y
        let y1 = vector2.y
        let z0 = vector1.z
        let z1 = vector2.z

        return sqrtf(powf(x1-x0, 2) + powf(y1-y0, 2) + powf(z1-z0, 2))
    }
}


extension Helper{
    
    static func getRotationY(_ transform:simd_float4x4?)->Float{
        
        guard let transform = transform else {return 0.0}
        
        let tNode = SCNNode()
        tNode.transform = SCNMatrix4(transform)
        return tNode.rotation.y * tNode.rotation.w
    }

    static func getRotationX(_ transform:simd_float4x4?)->Float{
        
        guard let transform = transform else {return 0.0}
        
        let tNode = SCNNode()
        tNode.transform = SCNMatrix4(transform)
        return tNode.rotation.x * tNode.rotation.w
    }
        
    static func getRotationZ(_ transform:simd_float4x4?)->Float{
        
        guard let transform = transform else {return 0.0}
        
        let tNode = SCNNode()
        tNode.transform = SCNMatrix4(transform)
        return tNode.rotation.z * tNode.rotation.w
    }
    
    static func getPosition(_ transform:simd_float4x4?)->SCNVector3{
        
        guard let transform = transform else {return SCNVector3(0,0,0)}
        
        let tNode = SCNNode()
        tNode.transform = SCNMatrix4(transform)
        return tNode.position
    }
    

}

extension Float {
    
    /// Convert degrees to radians
    func asRadians() -> Float {
    return self *  Float.pi / 180
    }
}

