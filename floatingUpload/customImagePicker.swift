//
//  customImagePicker.swift
//  floatingUpload
//
//  Created by Amir on 8/11/2016.
//  Copyright © 2018 uni. All rights reserved.
//

import Foundation
import ImagePicker
import Photos

class customeImagePicker: UIViewController,  ImagePickerDelegate {

    
    var viewObj = ViewController()
    let dispatch = DispatchGroup()
    
     func imagePicker(){
        let config = Configuration()
        config.doneButtonTitle = "Done"
        config.allowVideoSelection = true
        
        let imagePicker = ImagePickerController(configuration: config)
        imagePicker.delegate = self
        
        present(imagePicker,animated: true,completion: nil)
        
    }

    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
    }


    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {

        let assets = imagePicker.stack.assets
        let photoOption = PHContentEditingInputRequestOptions()
        let videoOption = PHVideoRequestOptions()

        for asset in assets{
            dispatch.enter()
            if asset.mediaType ==  .image {

                asset.requestContentEditingInput(with: photoOption, completionHandler: { contentEditingInput, info in
                    let imagePath = contentEditingInput?.fullSizeImageURL
                    let upObj =  uploadClass()
                    upObj.path = imagePath
                    self.viewObj.uploadprogressList.append(upObj)
                    self.dispatch.leave()
                })

            }else if asset.mediaType == .video{

                videoOption.version = .original
                PHImageManager.default().requestAVAsset(forVideo: asset, options: videoOption, resultHandler: { (asset, aucioMix, info) in
                    if let urlAsset = asset as? AVURLAsset {
                        let videPath = urlAsset.url
                        let upObj =  uploadClass()
                        upObj.path = videPath
                        self.viewObj.uploadprogressList.append(upObj)
                        self.dispatch.leave()
                    }
                })
            }
        }

        imagePicker.dismiss(animated: true, completion: nil)
        dispatch.notify(queue: .main) { print("self.uploadprogressList.append(upObj)--->>\(self.viewObj.uploadprogressList.count)");
            DispatchQueue.main.async {self.viewObj.tableView.reloadData()}}
    }

    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        imagePicker.dismiss(animated: true, completion: nil)
    }
}
