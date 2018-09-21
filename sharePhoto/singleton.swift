//
//  singleton.swift
//  sharePhoto
//
//  Created by sahlabadi on 9/10/18.
//  Copyright © 2018 uni. All rights reserved.
//

import Foundation
import Alamofire

struct BackgroundCommunicator {
    
    static let shared = BackgroundCommunicator()
    
    let manager: SessionManager = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "uni.floatingUpload.sharePhoto")
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        configuration.sharedContainerIdentifier = "group.uni.floatingUpload"
        
        return SessionManager(configuration: configuration)
    }()
    
}

