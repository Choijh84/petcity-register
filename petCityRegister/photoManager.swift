//
//  photoManager.swift
//  petCityRegister
//
//  Created by Ken Choi on 2017. 4. 6..
//  Copyright © 2017년 KenChoi. All rights reserved.
//

import UIKit

class photoManager: NSObject {
    
    let dataStore = Backendless.sharedInstance().data.of(Store.ofClass())
    
    /**
     단수의 이미지를 업로드하는 함수
     */
    func uploadNewPhoto(selectedFile: UIImage?, store: Store, completionBlock: @escaping (_ success: Bool, _ errorMessage: String? ) -> ()) {
        if let selectedFile = selectedFile {
            let fileName = String(format: "uploaded_%0.0f.jpeg", Date().timeIntervalSince1970)
            let filePath = "storeImages/\(fileName)"
            let content = UIImageJPEGRepresentation(selectedFile.compressImage(selectedFile), 1.0)
            
            Backendless.sharedInstance().fileService.saveFile(filePath, content: content, response: { (uploadedFile) in
                
                if let fileURL = uploadedFile?.fileURL {
                    store.imageURL = fileURL
                    self.dataStore?.save(store, response: { (response) in
                        print("Store has been updated")
                        completionBlock(true, nil)
                    }, error: { (Fault) in
                        print("There is an error to update store photo: \(String(describing: Fault?.description))")
                    })
                }
                
            }, error: { (fault) in
                print(fault.debugDescription)
                completionBlock(false, fault?.description)
            })
        }
    }
    
    /**
     복수의 이미지를 업로드하는 함수
     */
    func uploadNewPhotos(selectedFiles: [UIImage]?, store: Store, completionBlock: @escaping (_ success: Bool,_ fileURL: String,_ errorMessage: String? ) -> ()) {
        var totalFileURL = ""
        let myGroup = DispatchGroup()
        
        if let images = selectedFiles {
            for var i in 0..<images.count {
                myGroup.enter()
                let fileName = String(format: "uploaded_%0.0f\(i).jpeg", Date().timeIntervalSince1970)
                let filePath = "storeImages/\(fileName)"
                let content = UIImageJPEGRepresentation(images[i].compressImage(images[i]), 1.0)
                
                Backendless.sharedInstance().fileService.saveFile(filePath, content: content, response: { (uploadedFile) in
                    
                    if let fileURL = uploadedFile?.fileURL {
                        
                        totalFileURL.append(fileURL+",")
                        i = i+1
                        myGroup.leave()
                        
                    }
                    
                }, error: { (fault) in
                    print(fault.debugDescription)
                    completionBlock(false, "", fault?.description)
                })
            }
            
            myGroup.notify(queue: DispatchQueue.main, execute: { 
                let finalURL = String(totalFileURL.characters.dropLast())
                store.imageArray = finalURL
                
                self.dataStore?.save(store, response: { (response) in
                    print("Store photo has been updated")
                    completionBlock(true, finalURL, nil)
                }, error: { (Fault) in
                    print("There is an error to update store photo: \(String(describing: Fault?.description))")
                    completionBlock(false, "", Fault?.description)
                })
            })
        }
    }
}


