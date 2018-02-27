//
//  FlickrImages.swift
//  VirtualTourist
//
//  Created by Yash Rao on 2/22/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation
import UIKit


struct FlickrImages {
    
    var id: String
    var secret: String
    var server: String
    var farm: Int
    
    init(id: String, secret: String, server: String, farm: Int) {
        
        self.id = id
        self.secret = secret
        self.server = server
        self.farm = farm
    }
    
    func downloadImageData() -> String {
        return "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret).jpg"
    }
}
