//
//  upload.swift
//  floatingUpload
//
//  Created by Amir on 8/7/2016.
//  Copyright © 2018 uni. All rights reserved.
//

import Foundation
import Alamofire

class uploadClass{
    var id : IndexPath?
    var progress :Float = 0.0
    var path : URL?
    var upload : Bool = true
    var request :  Request?
    var data: Data?
    var inList : Bool = false
}
