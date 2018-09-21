//
//  ShareViewController.swift
//  sharePhoto
//
//  Created by sahlabadi on 8/27/18.
//  Copyright © 2018 uni. All rights reserved.
//

import UIKit
import Social
import MobileCoreServices
import Alamofire

class ShareViewController: SLComposeServiceViewController {
    
    var sharedId = "group.uni.floatingUpload"
    var selectedImage : UIImage!
    var selectedItemData : [NSData] = []
    var selectedItemPath : [URL] = []
    let serverURL = URL(string: "https://192.168.17.253:443/app_dev.php/ios/test/upload")
    var saveURL : URL?
    let sessionManager = BackgroundCommunicator.shared.manager
    weak var config : SLComposeSheetConfigurationItem?
     let dispatch = DispatchGroup()
    
    override func isContentValid() -> Bool {
        return true
    }

    override func didSelectPost() {
        print("didselect")
        self.dataAtchment()
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    func uploadImage(libraryPath : URL?){
        guard let serverPath = serverURL else { return }
        HttpHandler.upload(serverPath: serverPath, libraryPath: libraryPath, sessionManager: sessionManager, completionHandler: uploadResult )
    }
    
    func uploadResult(result : SessionManager.MultipartFormDataEncodingResult, path : URL){
        
        switch result {
        case .success(let upload,_,_):
           let _ = upload.responseJSON { res in
                print("response --> \(res.result.value as Any)")
            }
            
            upload.uploadProgress { progress in
                print("Upload Progress : \(progress.fractionCompleted)")
                
            }
        case .failure(let error): print("error is -->> \(error)")
            
        }
    }
    
    func dataAtchment(){
        print("POSTTTTTT")
        let content = extensionContext!.inputItems[0] as! NSExtensionItem
        let contentType = kUTTypeImage as String
        
        for attachment in content.attachments as! [NSItemProvider]{
            print("after loop befor if" )
            if attachment.hasItemConformingToTypeIdentifier(contentType){
               dispatch.enter()
                attachment.loadItem(forTypeIdentifier: contentType, options: nil)  { data, error in
                    if error == nil {
                        
                        let url = data as! URL
                        
                        if let imageData = NSData(contentsOf : url) {
                                print("selected Item in loop")
                                self.selectedItemData.append(imageData)
                                print("Image Path --> \(String(describing: url))")
                                self.saveURL = url
                                self.uploadImage(libraryPath : self.saveURL!)
                                self.dispatch.leave()
                            }
                            
                        
                    
                    }else{ print("there is error -- > \(error)");self.dispatch.leave() }
                }
            }
        }
        
        dispatch.notify(queue: .main) {
            print("dispatch notify after loop -- > \(String(describing: self.selectedItemData.count))")
            self.saveDataToUserDefault(suiteName: self.sharedId, dataKey:"Image", dataValue : self.selectedItemData)
        }
    }
    
    func saveDataToUserDefault(suiteName: String, dataKey:String, dataValue : [NSData]?){
    
        if let sharedData = UserDefaults(suiteName: suiteName){
            sharedData.removeObject(forKey: dataKey)
            sharedData.set(dataValue, forKey: dataKey)
            
        }
    }

    override func configurationItems() -> [Any]! {
        return []
    }

}
