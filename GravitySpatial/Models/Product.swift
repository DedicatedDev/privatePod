//
//  Product.swift
//  GravityXR
//
//  Created by Avinash Shetty on 4/25/20.
//  Copyright © 2020 GravityXR. All rights reserved.
//

import Foundation


public struct Product {
    public let name: String
    public let thumbnails: String?
    public let description: String
    public let tellMeURL:String?
}

public extension Product {
    static func createMockProducts() -> [Product] {
        return [Product(name: "Cisco Vision", thumbnails: "vision.png", description: "Cisco Store - San Jose", tellMeURL: "test"),
                Product(name: "Meraki Camera", thumbnails: "meraki.png", description: "Cisco Store - San Jose", tellMeURL: "test")]
    }
}
