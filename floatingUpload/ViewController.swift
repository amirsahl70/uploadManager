//
//  ViewController.swift
//  floatingUpload
//
//  Created by Amir on 8/4/2016.
//  Copyright © 2018 uni. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Floaty
import ImagePicker
import Photos

class ViewController: UIViewController,  UITableViewDelegate, UITableViewDataSource, ImagePickerDelegate {

    var sharedId = "group.uni.floatingUpload"
    
    var imagePath : URL?
    var sessionManager = SessionManager()
    let serverURL = URL(string: "https://192.168.17.253:443/app_dev.php/ios/test/upload")
    var libraryPathList :[URL] = []
    var uploadprogressList : [uploadClass] = []
    var prgressReport : Float?
    
    let dispatch = DispatchGroup()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        floatyButton()
        print("HI from view did load ")
        self.displayShareMedia()
    }
    
    func floatyButton(){
        let floaty = Floaty()
        floaty.addItem("Photo / Video", icon: UIImage(named:"share.png"),handler:{_ in self.imagePicker()})
        self.view.addSubview(floaty)
    }
    
// IMAGE PICKER
    func imagePicker(){
        
        let config = Configuration()
        config.doneButtonTitle = "Done"
        config.allowVideoSelection = true
        
        let imagePicker = ImagePickerController(configuration: config)
        imagePicker.delegate = self as ImagePickerDelegate
        
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
                    self.uploadprogressList.append(upObj)
                       self.dispatch.leave()
                })
                
            }else if asset.mediaType == .video{
                
                videoOption.version = .original
                PHImageManager.default().requestAVAsset(forVideo: asset, options: videoOption, resultHandler: { (asset, aucioMix, info) in
                    if let urlAsset = asset as? AVURLAsset {
                        let videPath = urlAsset.url
                        let upObj =  uploadClass()
                        upObj.path = videPath
                        self.uploadprogressList.append(upObj)
                        self.dispatch.leave()
                    }
                })
            }

        }

        dispatch.notify(queue: .main) { print("self.uploadprogressList.append(upObj)--->>\(self.uploadprogressList.count)");
            DispatchQueue.main.async {self.tableView.reloadData()}
             imagePicker.dismiss(animated: true, completion: nil)
        }
    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        imagePicker.dismiss(animated: true, completion: nil)
    }
    

// UPLOAD PART
    func uploadResult(result : SessionManager.MultipartFormDataEncodingResult, path : URL, index : IndexPath){
    
        let cell = self.tableView.cellForRow(at: index) as? customTableViewCell
        switch result {
        case .success(let upload,_,_):
            let request = upload.responseJSON { res in
                print("response --> \(res.result.value as Any)")
                //self.uploadprogressList.removeAll()
            }
            self.uploadprogressList[index.row].request = request

            upload.uploadProgress { progress in
                print("Upload Progress : \(progress.fractionCompleted)")
                self.prgressReport = Float(progress.fractionCompleted)
                cell?.progrssBar.progress = Float(progress.fractionCompleted)
                let progressPercent = Int(progress.fractionCompleted * 100)
                cell?.progressLable.text = "\(progressPercent)%"

            }
        case .failure(let error): print("error is -->> \(error)")
            
        }
    }
    
    func uploadImage(libraryPath : URL?, index: IndexPath){
       guard let serverPath = serverURL else { return }
        HttpHandler.upload(serverPath: serverPath, libraryPath: libraryPath, index: index,
                           sessionManager: sessionManager, completionHandler: uploadResult )
       }

    
// TableView DElegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.uploadprogressList.count
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 122
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellView = tableView.dequeueReusableCell(withIdentifier: "customCell", for: indexPath) as! customTableViewCell
        let idx: Int = indexPath.row
        
            if idx % 2 == 0 {
                cellView.backgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
            }
        uploadprogressList[idx].id = indexPath
        cellView.progrssBar.progress = uploadprogressList[idx].progress
        let  path = uploadprogressList[idx].path
        
        if  !uploadprogressList[idx].inList {
            print("before inlist -- > \(uploadprogressList[idx].inList)")
            uploadprogressList[idx].inList = true
            print("after inlist -- > \(uploadprogressList[idx].inList)")
            displayImage(idx, photoCell: cellView)
            if let path = path{
                print("display")
                self.uploadImage(libraryPath : path, index :  indexPath)
            }
            
        }
        
        cellView.pauseBtn.addTarget(self, action: #selector(ViewController.pauseUpload(sender:)), for: .touchUpInside)
        cellView.startBtn.addTarget(self, action: #selector(ViewController.startUpload(sender:)), for: .touchUpInside)
        
        return cellView
    }
    
    @objc func pauseUpload(sender: AnyObject){
        
        let taskCell = sender.superview!!.superview! as! customTableViewCell
        let cellIndexPath = self.tableView.indexPath(for: taskCell)
        let uploadInfo = self.uploadprogressList[cellIndexPath!.row]
        
        if uploadInfo.upload == true {
            uploadInfo.upload = false
            uploadInfo.request!.suspend()
        }
    }
    
    @objc func startUpload(sender: AnyObject){

        let taskCell = sender.superview!!.superview! as! customTableViewCell
        let cellIndexPath = self.tableView.indexPath(for: taskCell)
        let uploadInfo = self.uploadprogressList[cellIndexPath!.row]

        if uploadInfo.upload == false {
            uploadInfo.upload = true
            uploadInfo.request!.resume()
        }
    }
    
    func displayImage(_ row: Int, photoCell: customTableViewCell) {
        
        if let url = uploadprogressList[row].path {
            let data = try? Data(contentsOf : url)
            if let image = UIImage(data: data!){
                DispatchQueue.main.async {
                    photoCell.photoImageView.image = image
                }
            }
        }else{
            let data = uploadprogressList[row].data
            if let image = UIImage(data: data!){
                DispatchQueue.main.async {
                    photoCell.photoImageView.image = image
                    photoCell.progrssBar.progress = 1
                    photoCell.progressLable.text = "\(100)%"
                }
            }
        }
        
    }
    func displayShareMedia(){
        
        if let shareData = UserDefaults(suiteName: sharedId){
            if let imageArray = shareData.object(forKey: "Image") as? [Data]{
            
                for imageData in imageArray {
                    let upObj =  uploadClass()
                    upObj.data = imageData
                    self.uploadprogressList.append(upObj)
                    
                }
            }
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }

}

