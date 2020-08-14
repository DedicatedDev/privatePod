//
//  ProductCardData.swift
//  GravityXR
//
//  Created by Avinash Shetty on 4/25/20.
//  Copyright © 2020 GravityXR. All rights reserved.
//

import Foundation
import UIKit

struct CardData {
    var title:String?
    var titleColor:UIColor?
    var cardBackgroundColor:UIColor?
    var image:UIImage?
    var button1:Button?
    var button2:Button?
    var button3:Button?
}

struct Button {
    var title:String?
    var titleColor:UIColor?
    var backgroundColor:UIColor?
    var selectionColor:UIColor?
}

