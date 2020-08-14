//
//  ExploreViewController+Favorite.swift
//  GravityXR
//
//  Created by Avinash Shetty on 6/22/20.
//  Copyright © 2020 GravityXR. All rights reserved.
//

import Foundation
import Alamofire

extension ExploreViewController{
    
    func markCardAsFavorite(cardId: Int){
        
        guard let userID = UserDefaults.standard.object(forKey: "userEmail") else {return}

        let favoriteURL = Endpoint.markAsFavorite(user: userID as! String).urlStr
        let cardInfo : [String:Any] = ["cardId": cardId, "username": userID as! String]

        AF.request(favoriteURL, method: .post, parameters: cardInfo as Parameters, encoding: JSONEncoding.default, headers: Endpoint.experiences.headers)
          .responseJSON { response in
            print("@@@@@@@@@@@@@@@@  $$$$$$$$$$ \(response)")
        }
        
    }
    
}
