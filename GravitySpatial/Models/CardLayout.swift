//
//  CardLayout.swift
//  GravityXR
//
//  Created by Avinash Shetty on 4/29/20.
//  Copyright © 2020 GravityXR. All rights reserved.
//

import Foundation

public struct Experience: Decodable{
    
    public let id: Int
    public let name: String
    public let description: String?
    public let location: Location? //Geo-tag info
    public let cards: [Card]
    public let lastModified: String?
    public let status: String?
    public let created_by: String?
}

public struct Card: Decodable{
    public let id: Int
    public let name: String?
    public let description: String?
    public let domainList:[Int]?
    public let status: String?
    public let cardConfig: CardConfig? //UI config parameters for the card
    public let anchorId: String? //AR anchor id
    public let productId: Int //product associated with the card
    public let experienceId: Int //experience where the card is hosted
}

public struct Wall: Decodable{
    public let id: Int
    public let experienceId: Int
    public let anchorId: String? //AR anchor id
    public let units: String?
    public let width: Float
    public let height: Float
}

public struct CardConfig: Decodable {
    let type: String
    let title: String?
    let imgURL: String?
    let background: String?
    let width: Int?
    let height: Int?
    let buttonBgColor:String?
    let buttonHighlightColor:String?
    let labelColor:String?
    let elements: [CardElement]
}

public struct CardElement: Decodable {
    let displayOrder: Int
  //  let id: Int  ignore for now as we had both Int and alphanumneric data in CMS
    let cardElementType: String
    let text: String?
    let url: String
    let action: String?
    let background: String?
    let textColour: String?
    let highlight: String?
    let ctaType: String?
    let x: Float?
    let y: Float?
    let top: Float?
    let left: Float?
    let width: Float?
    let height: Float?
    let cols: Int?
    let rows: Int?
    let fontSize: String?
    let textAlign: String?
    
}

public struct Location: Decodable {
    public let id: Int
    public let name: String?
    public let latitude: Double?
    public let longitude: Double?
    public let rootAnchorId: String?
}

public struct User: Decodable {
    public let email: String?
    public let name: String?
    public let token: String
    public let imageUrl: String?
}

public struct Guest: Decodable {
    let token: String
}


public struct ProductInfo: Decodable{
    let id: Int
    let name: String
    let description: String?
    let url: String?
    let imageUrl: String?
}

public struct Industry: Decodable{
    let id: Int
    let name: String
}



/*
 {
    "type":"Product Card",
    "background":"#f1e2e2",
    "elements":[
       {
          "id":0,
          "cardElementType":"IMAGE",
          "text":"",
          "url":"",
          "action":"",
          "displayOrder":1,
          "x":11,
          "y":50,
          "width":200,
          "height":135
       },
       {
          "id":1,
          "cardElementType":"BUTTON",
          "background":"#d0cff7",
          "textColour":"#111835",
          "text":"Tell Me",
          "url":"http://santacruz.com",
          "action":"",
          "displayOrder":1,
          "x":11,
          "y":185.203125,
          "width":200,
          "height":56,
          "highlight":"#6682db",
          "ctaType":"Tell Me"
       },
       {
          "id":2,
          "cardElementType":"BUTTON",
          "background":"#d0cff7",
          "textColour":"#111835",
          "text":"Show Me",
          "url":"http://livevideo.com/kod",
          "action":"",
          "displayOrder":3,
          "x":11,
          "y":241.203125,
          "width":200,
          "height":56,
          "highlight":"#6682db",
          "ctaType":"postApi"
       }
    ],
    "width":222,
    "height":352,
    "title":"Beach",
    "buttonBgColor":"#d0cff7",
    "buttonHighlightColor":"#6682db",
    "labelColor":"#111835"
 }
 */
