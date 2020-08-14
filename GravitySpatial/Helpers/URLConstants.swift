//
//  URLConstants.swift
//  GravityXR
//
//  Created by Avinash Shetty on 5/10/20.
//  Copyright © 2020 GravityXR. All rights reserved.
//

import Foundation
import Alamofire


private extension String {
    static func makeForEndpoint(_ endpoint: String) -> String {
        #if DEV
            return "https://apis-dev.gravityxr.com/api/v1/\(endpoint)"
        #elseif STAGING
            return "https://apis-staging.gravityxr.com/api/v1/\(endpoint)"
        #else
            return "https://apis.gravityxr.com/api/v1/\(endpoint)"
        #endif

    }
}


public enum Endpoint {
    case experiences
    case experienceDetails(id: String)
    case experienceAnchor(id: String)
    case cards(id: String)
    case allCards(id: String)
    case cardDetails(id: String)
    case cardAnchor(id: String)
    case walls(id: String)
    case createWall
    case deleteWall(id: String)
    case favorites
    case allProducts
    case markAsFavorite(user: String)
    case productDetails(id: String)
    case industry
    case login
    case guestToken

}

public extension Endpoint {
    var urlStr: String {
        switch self {
            case .experiences:
                return .makeForEndpoint("experiences")
            case .experienceDetails(let id):
                return .makeForEndpoint("experiences/\(id)")
            case .experienceAnchor(let id):
                return .makeForEndpoint("experiences/\(id)/anchor")
            case .cards(let id):
                return .makeForEndpoint("cards/?experienceId=\(id)")
            case .allCards(let id):
                return .makeForEndpoint("all-cards/?experienceId=\(id)")
            case .cardDetails(let id):
                return .makeForEndpoint("cards/\(id)")
            case .cardAnchor(let id):
                return .makeForEndpoint("cards/\(id)/anchor")
            case .walls(let id):
                return .makeForEndpoint("arwall?experienceId=\(id)")
            case .createWall:
                return .makeForEndpoint("arwall")
            case .deleteWall(let id):
                return .makeForEndpoint("arwall?arWallId=\(id)")
            case .favorites:
                return .makeForEndpoint("favorite/")
            case .markAsFavorite(let user):
                return .makeForEndpoint("favorite/\(user)")
            case .allProducts:
                return .makeForEndpoint("products")
            case .productDetails(let id):
                return .makeForEndpoint("products/\(id)")
            case .industry:
                return .makeForEndpoint("domains")
            case .login:
                return .makeForEndpoint("login")
            case .guestToken:
                return .makeForEndpoint("guest-token")
        }
    }
    
    var headers: HTTPHeaders {

        //#if GRAVITY
            let tenantID = "Z3Jhdml0eQ=="
        /*#elseif XRAYVISION
            let tenantID = "Y2lzY28="
        #endif8*/

         switch self {
            case .login:
                let headers: HTTPHeaders = [
                    "tenant-id": tenantID
                ]
                return headers
            case .guestToken:
                let headers: HTTPHeaders = [
                    "tenant-id": tenantID
                ]
                return headers
            default:
                guard let authToken = UserDefaults.standard.string(forKey: "userToken") else {return []}

                let headers: HTTPHeaders = [
                    "Authorization": "Bearer "+authToken,
                    "tenant-id": tenantID
                ]
                return headers
        }
    }
        
}


public final class RequestInterceptor: Alamofire.RequestInterceptor {

    private typealias RefreshCompletion = (_ succeeded: Bool, _ accessToken: String?) -> Void

    public func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        
        if (urlRequest.url?.absoluteString.hasSuffix("login") == true ||
               urlRequest.url?.absoluteString.hasSuffix("guest-token") == true) {
            /// If the request does not require authentication, we can directly return it as unmodified.
            return completion(.success(urlRequest))
        }
        var urlRequest = urlRequest

        guard let authToken = UserDefaults.standard.string(forKey: "userToken") else {return}

        /// Set the Authorization header value using the access token.
        urlRequest.setValue("Bearer " + authToken, forHTTPHeaderField: "Authorization")

        completion(.success(urlRequest))
    
    }
    
    
    public func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        
        guard let response = request.task?.response as? HTTPURLResponse, response.statusCode == 403 else {
            /// The request did not fail due to a 403 Unauthorized response.
            /// Return the original error and don't retry the request.
            return completion(.doNotRetryWithError(error))
        }
        
        refreshTokens { [weak self] succeeded, accessToken in

            if succeeded {
                if let accessToken = accessToken {
                    UserDefaults.standard.set(accessToken, forKey: "userToken")
                }
                /// After updating the token we can safely retry the original request.
                completion(.retry)
            }else{
                completion(.doNotRetryWithError(error))
            }
        }

        
    }
    
    private func refreshTokens(completion: @escaping RefreshCompletion) {

        let guestAccessURL = Endpoint.guestToken.urlStr
        
        //If the user had logged in before, logOut and login as Guest
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "userEmail")

         AF.request(guestAccessURL, method: .get, headers: Endpoint.guestToken.headers)
               .responseDecodable(of: Guest.self) { [weak self] response in

            switch response.result {
            case .success:
                guard let guest:Guest = response.value else { return }
                UserDefaults.standard.set(guest.token, forKey:"userToken")

                /// After updating the token we can safely retry the original request.
                completion(true, guest.token)
            case .failure:
                completion(false, nil)
            }
        }
    }


}

