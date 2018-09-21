//
//  floatyButton.swift
//  floatingUpload
//
//  Created by Amir on 8/11/2016.
//  Copyright © 2018 uni. All rights reserved.
//

import Foundation
import Floaty

class floatyButton {
    let pickObj = customeImagePicker()
    
     func floatyButton() -> Floaty{
        let floaty = Floaty()
        floaty.addItem("Photo / Video", icon: UIImage(named:"share.png"),handler:{_ in self.pickObj.imagePicker()})
        return floaty
        //
    }
    
}
