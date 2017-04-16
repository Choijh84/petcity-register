//
//  photoManager.swift
//  petCityRegister
//
//  Created by Ken Choi on 2017. 4. 6..
//  Copyright © 2017년 KenChoi. All rights reserved.
//

import UIKit
import AZSClient
import Kingfisher

class photoManager: NSObject {
    
    // Azure Setting 
    var connectionString = "DefaultEndpointsProtocol=https;AccountName=petcity;AccountKey=7qApXooL3qi1iEitYXG/Ie996we0PRZO00ZwMYRsOjnVEOJKRnU2tR6kxkB8NF9pWTeG1Dv2Z3efqT9GQXZbHw==;EndpointSuffix=core.windows.net"
    var containerName = "store-images"
    var usingSAS = false
    
    // MARK: Azure Properties
    var blobs = [AZSCloudBlob]()
    var container : AZSCloudBlobContainer!
    var continuationToken : AZSContinuationToken?
    
    let dataStore = Backendless.sharedInstance().data.of(Store.ofClass())
    
    // MARK: Initializer
    override init() {
        if !usingSAS {
            let storageAccount : AZSCloudStorageAccount
            try! storageAccount = AZSCloudStorageAccount(fromConnectionString: connectionString)
            
            let blobClient = storageAccount.getBlobClient()
            self.container = blobClient?.containerReference(fromName: containerName)
            
            let condition = NSCondition()
            var containerCreated = false
            
            self.container.createContainerIfNotExists { (error, created) in
                condition.lock()
                containerCreated = true
                condition.signal()
                condition.unlock()
            }
            
            condition.lock()
            while (!containerCreated) {
                condition.wait()
            }
            condition.unlock()
        }
        self.continuationToken = nil
        super.init()
    }
    
    /**
     Azure Storage에 지정된 파일 url을 삭제하는 함수
     */
    
    func deleteFile(selectedUrl: String, completionblock: @escaping (_ success: Bool, _ errorMessage: String?) -> ()) {
        let account = try! AZSCloudStorageAccount(fromConnectionString: connectionString)
        
        let blobClient : AZSCloudBlobClient = account.getBlobClient()
        let blobContainer : AZSCloudBlobContainer = blobClient.containerReference(fromName: containerName)
        
        let fileName = selectedUrl.replacingOccurrences(of: "https://petcity.blob.core.windows.net/store-images/", with: "")
        print("지울 파일 경로: \(selectedUrl)")
        print("지울 파일 이름: \(fileName)")
        let blockBlob : AZSCloudBlockBlob = blobContainer.blockBlobReference(fromName: fileName)
        
        blockBlob.delete { (error) in
            if error != nil {
                print("Error in delete blob: \(String(describing: error?.localizedDescription))")
            } else {
                print("Delete success")
            }
        }
    }
    
    /**
     Azure Storage에 사진 1개를 업로드하고 지정된 Store의 대표 사진으로 지정하는 함수
    */
    func uploadPhoto(selectedFile: UIImage, store: Store, completionBlock: @escaping (_ success: Bool, _ fileURL: String?, _ errorMessage: String? ) -> ()) {
        let account = try! AZSCloudStorageAccount(fromConnectionString: connectionString)
        
        let blobClient : AZSCloudBlobClient = account.getBlobClient()
        let blobContainer : AZSCloudBlobContainer = blobClient.containerReference(fromName: containerName)
        blobContainer.createContainerIfNotExists(with: .blob, requestOptions: nil, operationContext: nil) { (error, success) in
            if error != nil {
                print("There is an error in creating container")
                completionBlock(false, nil, error?.localizedDescription)
            } else {
                // 여기서 이름 정하고
                let fileName = String(format: "uploaded_%0.0f.png", Date().timeIntervalSince1970)
                let blob : AZSCloudBlockBlob = blobContainer.blockBlobReference(fromName: fileName)
                // 이미지 데이터를 생성
                let imageData = UIImagePNGRepresentation(selectedFile.compressImage(selectedFile))

                // 블롭에 데이터를 업로드, 파일 이름은 우리가 정한대로 들어간다
                blob.upload(from: imageData!, completionHandler: { (error) in
                    if error != nil {
                        print("Upload Error: \(error.localizedDescription)")
                        completionBlock(false, nil, error.localizedDescription)
                    } else {
                        print("Upload Success to Azure")
                        let url = "https://petcity.blob.core.windows.net/store-images/\(fileName)"
                        
                        store.imageURL = url
                        DispatchQueue.main.sync(execute: { 
                            _ = self.dataStore?.save(store) as? Store
                            print("Store has been updated")
                            completionBlock(true, url, nil)
                        })
                    }
                })
            }
        }
    }
    
    
    /**
    Azure Storage에 사진 1개를 업로드하고 그 URL을 completionBlock으로 리턴
    */
    func uploadPhoto(selectedFile: UIImage, completionBlock: @escaping (_ success: Bool, _ fileURL: String?, _ errorMessage: String? ) -> ()) {
        let account = try! AZSCloudStorageAccount(fromConnectionString: connectionString)
        
        let blobClient : AZSCloudBlobClient = account.getBlobClient()
        let blobContainer : AZSCloudBlobContainer = blobClient.containerReference(fromName: containerName)
        blobContainer.createContainerIfNotExists(with: .blob, requestOptions: nil, operationContext: nil) { (error, success) in
            if error != nil {
                print("There is an error in creating container")
                completionBlock(false, nil, error?.localizedDescription)
            } else {
                // 여기서 이름 정하고
                let fileName = String(format: "uploaded_%0.0f.png", Date().timeIntervalSince1970)
                let blob : AZSCloudBlockBlob = blobContainer.blockBlobReference(fromName: fileName)
                // 이미지 데이터를 생성
                let imageData = UIImagePNGRepresentation(selectedFile.compressImage(selectedFile))
                
                // 블롭에 데이터를 업로드, 파일 이름은 우리가 정한대로 들어간다
                blob.upload(from: imageData!, completionHandler: { (error) in
                    if error != nil {
                        print("Upload Error: \(error.localizedDescription)")
                        completionBlock(false, nil, error.localizedDescription)
                    } else {
                        print("Upload Success to Azure")
                        let url = "https://petcity.blob.core.windows.net/store-images/\(fileName)"
                        completionBlock(true, url, nil)
                    }
                })
            }
        }
    }
    
    
    
    /**
     Azure Storage에 사진 복수를 업로드하고 지정된 Store의 사진 배열로 추가하는 함수
     */
    func uploadPhotos(selectedFiles: [UIImage]?, store: Store, completionBlock: @escaping (_ succuess: Bool,_ fileURL: String?,_ errorMessage: String?) -> ()) {
        var totalFileURL = ""
        let myGroup = DispatchGroup()
        let account = try! AZSCloudStorageAccount(fromConnectionString: connectionString)
        
        let blobClient : AZSCloudBlobClient = account.getBlobClient()
        let blobContainer : AZSCloudBlobContainer = blobClient.containerReference(fromName: containerName)
        
        if let images = selectedFiles {
            for var i in 0..<images.count {
                myGroup.enter()
                blobContainer.createContainerIfNotExists(with: .blob, requestOptions: nil, operationContext: nil) { (error, success) in
                    // 여기서 이름 정하고
                    let fileName = String(format: "uploaded_%0.0f\(i).png", Date().timeIntervalSince1970)
                    let blob : AZSCloudBlockBlob = blobContainer.blockBlobReference(fromName: fileName)
                    // 이미지 데이터를 생성
                    let imageData = UIImagePNGRepresentation(images[i].compressImage(images[i]))
                    
                    blob.upload(from: imageData!, completionHandler: { (error) in
                        if error != nil {
                            print("Upload Error on \(i): \(error.localizedDescription)")
                            completionBlock(false, nil, error.localizedDescription)
                        } else {
                            print("Upload Success to Azure")
                            let url = "https://petcity.blob.core.windows.net/store-images/\(fileName),"
                            
                            totalFileURL.append(url)
                            i = i+1
                            print("totalFileURL: \(totalFileURL)")
                            myGroup.leave()
                        }
                    })
                }
            }
            
            myGroup.notify(queue: DispatchQueue.main, execute: {
                let finalURL = String(totalFileURL.characters.dropLast())
                store.imageArray = store.imageArray! + "," + finalURL
                
                _ = self.dataStore?.save(store)
                print("Store has been updated")
                completionBlock(true, store.imageArray, nil)
                
            })
            
        }
    }
    
    /**
     복수의 이미지를 업로드하는 함수 - to Backendless
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
    
    /**
     단수의 이미지를 업로드하는 함수 - to Backendless
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
    

}


