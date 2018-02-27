//
//  CollectionViewCell.swift
//  VirtualTourist
//
//  Created by Yash Rao on 2/24/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation
import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    func getImage(_ photo: Photo) {
        
        if photo.imageData != nil  {
            
            DispatchQueue.main.async {
                self.imageView.image = UIImage(data: photo.imageData! as Data)
                self.activityIndicator.stopAnimating()
            }
        } else {
            guard let imageURL = photo.imageURL, !(photo.imageURL?.isEmpty)! else {
                print("String is nil or empty")
                return
            }
            URLSession.shared.dataTask(with: URL(string: photo.imageURL!)!) { (data, response, error) in
                    guard (error == nil) else {
                    print("Invalid URL to download image")
                    return
                    }
                
                    DispatchQueue.main.async {
                        self.imageView.image = UIImage(data: data! as Data)
                        self.activityIndicator.stopAnimating()
                        }
                }
            .resume()
    
            }
        }
    
    func accessImageData(_ photo:Photo) -> Data {
        let imageURL = URL(string: photo.imageURL!)
        let imageData = try? Data(contentsOf: imageURL!)
        return imageData!
    }
}
