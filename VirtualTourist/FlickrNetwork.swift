//
//  FlickrNetwork.swift
//  VirtualTourist
//
//  Created by Yash Rao on 2/21/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation

class FlickrNetwork {
    
    
    func getImages(lat:Double, long: Double, completion: @escaping (_ success: Bool, _ images:[FlickrImages]?, _ error: Bool) -> Void) {
       
        let searchPhotoURL =  "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=e7c877e10a405dea49e55ff43d49a6ed&lat=\(lat)&lon=\(long)&radius=10&radius_units=km&format=json&nojsoncallback=1"
        
        let request = NSMutableURLRequest(url: URL(string: searchPhotoURL)!)
        let session = URLSession.shared
        
        let task = session.dataTask(with: request as URLRequest) { data, response, error in
            
            guard (error == nil) else {
                print("Error with your request")
                completion(false, nil, true)
                return
            }
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                print("HTTP Error")
                return
            }
            guard let data = data else {
                print("issue with data")
                return
            }
            var parsedResult: [String:AnyObject]
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String : AnyObject]
            } catch {
                print("Could not parse data as JSON: \(data)")
                return
            }
            
            guard let photoDictionary = parsedResult["photos"] as? [String:AnyObject], let photoArray = photoDictionary["photo"] as? [[String:AnyObject]] else {
                print("Cannot properly parse")
                return
            }
            var images : [FlickrImages] = []
            
            for photo in photoArray {
                if let image = photo as? [String:Any],
                    let id = image["id"] as? String,
                    let secret = image["secret"] as? String,
                    let farm = image["farm"] as? Int,
                    let server = image["server"] as? String {
                    images.append(FlickrImages(id: id, secret: secret, server: server, farm: farm))
                    }
            }
            completion(true, images, false)
        }
        task.resume()
    }
    
    class func sharedInstance() -> FlickrNetwork {
        struct Singleton {
            static var sharedInstance = FlickrNetwork()
        }
        return Singleton.sharedInstance
    }
    
}
