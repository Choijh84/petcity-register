//
//  SecondViewController.swift
//  petCityRegister
//
//  Created by Ken Choi on 2017. 4. 5..
//  Copyright © 2017년 KenChoi. All rights reserved.
//

import UIKit
import Alamofire
import SCLAlertView

class SecondViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var savingStore: Store?
    
    var isGeoSaved = false
    @IBOutlet weak var pointXfield: UITextField!
    @IBOutlet weak var pointYfield: UITextField!
    
    // 대표 사진
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var uploadButton: UIButton!
    
    /// Object that helps selecting an image
    let imagePicker = UIImagePickerController()
    
    var pointX: Double = 0
    var pointY: Double = 0
    
    // 네이버 지도 API
    let clientId = "TuWS2kCodIxD9zPok6F2"
    let clientSecret = "BwIGo_xV7u"
    
    
    @IBAction func next(_ sender: Any) {
        performSegue(withIdentifier: "uploadPhotos", sender: nil)
    }
    
    @IBAction func uploadPhoto(_ sender: Any) {
        
        let actionsheet = UIAlertController(title: "Choose source", message: nil, preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            actionsheet.addAction(UIAlertAction(title: "Take a picture", style: UIAlertActionStyle.default, handler: { (action) -> Void in
                
                self.imagePicker.sourceType = .camera
                self.present(self.imagePicker, animated: true, completion: nil)
                
            }))
        }
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            actionsheet.addAction(UIAlertAction(title: "Choose photo", style: UIAlertActionStyle.default, handler: { (action) -> Void in
                
                self.imagePicker.sourceType = .photoLibrary
                /**
                self.imagePicker.modalPresentationStyle = .popover
                
                if let presenter = self.imagePicker.popoverPresentationController {
                    presenter.sourceView = self.uploadButton
                    presenter.sourceRect = self.uploadButton.bounds
                    presenter.permittedArrowDirections = .down
                }
                */
                
                self.present(self.imagePicker, animated: true, completion: nil)
                
            }))
        }
        actionsheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if let presenter = actionsheet.popoverPresentationController {
            presenter.sourceView = self.uploadButton
            presenter.sourceRect = self.uploadButton.bounds
        }
        
        present(actionsheet, animated: true, completion: nil)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "지오포인트 & 사진"
        imagePicker.delegate = self
        self.navigationController?.setNavigationBarHidden(false, animated: false)

        print("This is object Id we got from database after first registration: \(String(describing: savingStore?.objectId!))")
        print("This is storeCategoty: \(String(describing: savingStore?.serviceCategory))")
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        if isGeoSaved {
            print("Just Pass the geopoint save")
        } else{
            naverMapCall { (success, error) in
                if success {
                    self.addGeoPointAsync()
                    self.isGeoSaved = true
                } else {
                    print("There is an error to call naver map")
                }
            }
        }
        
        super.viewDidAppear(animated)
    }
    
    // 이미지 픽업이 끝나면 이미지 뷰에 이미지를 보여주고 업로드 시작
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let chosenImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.image = chosenImage
            saveImage(chosenImage)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // 업로드 성공과 실패를 알려줌
    func saveImage(_ image: UIImage) {
        photoManager().uploadNewPhoto(selectedFile: image, store: savingStore!) { (success, error) in
            if success {
                print("Store photo has been updated")
            } else {
                print("I got error on photo: \(String(describing: error))")
            }
        }
    }
    
    // 지오포인트 저장 함수
    func addGeoPointAsync() {
        let name = savingStore?.name
        // let category = savingStore?.serviceCategory
        
        let storePX = GeoPoint.geoPoint(
            GEO_POINT(latitude: pointY, longitude: pointX),
            categories: nil, metadata: ["name": name!]
        ) as! GeoPoint
        
        Backendless.sharedInstance().geoService.save(storePX, response: { (point) in
            print("ASYNC: geo point saved. object ID - \(String(describing: point?.objectId))")
            self.pointXfield.text = String(self.pointX)
            self.pointYfield.text = String(self.pointY)
            
            // 여기에서 store와 지오포인트 설정해주면 됨
            let dataStore = Backendless.sharedInstance().persistenceService.of(Store.ofClass())
            self.savingStore?.location = point
            dataStore?.save(self.savingStore, response: { (response) in
                print("geo point has linked with store")
            }, error: { (Fault) in
                print("There is a error to link geopoint: \(String(describing: Fault?.description))")
            })
            
            
        }) { (Fault) in
            print("There is a error to save geopoint: \(String(describing: Fault?.description))")
        }
    }
    
    // 네이버에서 주소로 검색, 지오포인트 및 주소 구분을 얻어옴
    func naverMapCall(_ completionBlock: @escaping (_ success: Bool, _ error: String?) -> ()) {
        var addr = ""
        if let address = savingStore?.address {
            addr = address
        } else {
            SCLAlertView().showWarning("주소 확인", subTitle: "주소를 콘솔에서 확인해주세요")
        }
        
        let apiURL = "https://openapi.naver.com/v1/map/geocode?query=" + addr.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        print("This is apiURL: \(apiURL)")
        
        let headers: HTTPHeaders = [
            "X-Naver-Client-Id": clientId,
            "X-Naver-Client-Secret": clientSecret
        ]
        
        Alamofire.request(apiURL, headers: headers).responseJSON { response in
            // print(response.request)  // original URL request
            // print(response.response) // HTTP URL response
            // print(response.data)     // server data
            // print(response.result)   // result of response serialization
            
            do {
                if let data = response.data,
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? Dictionary<String, AnyObject> {
                    // print(json)
                    if let result = json["result"] as? [String: AnyObject] {
                        if let jsonResult = result["items"] as? Array<AnyObject> {
                            // print("this is count: \(jsonResult.count)")
                            // for result in jsonResult {
                                //print("this is result: \(result)")
                            // }
                            if let jsonFirstResult = jsonResult[0] as? [String: AnyObject] {
                                //print("this is another Dict: \(jsonFirstResult)")
                                if let detail = jsonFirstResult["addrdetail"] as? [String: AnyObject] {
                                    print("This is detail: \(detail)")
                                    if let sido = detail["sido"] as? String {
                                        print("this is 시 or 도: \(sido)")
                                    }
                                    if let sigugun = detail["sigugun"] as? String {
                                        print("this is 시 or 구 or 군: \(sigugun)")
                                    }
                                }
                                if let point = jsonFirstResult["point"] as? [String: AnyObject] {
                                    print("This is point: \(point)")
                                    if let pointX = point["x"] as? Double {
                                        // longitude 경도
                                        print("This is pointX: \(pointX)")
                                        self.pointX = pointX
                                    }
                                    if let pointY = point["y"] as? Double {
                                        // latitude 위도
                                        print("This is pointY: \(pointY)")
                                        self.pointY = pointY
                                    }
                                }
                                completionBlock(true, nil)
                            } else {
                                print("Sth is wrong again")
                                completionBlock(false, "Sth is wrong")
                            }
                        } else {
                            print("Sth is wrong")
                            completionBlock(false, "Sth is wrong")
                        }
                    }
                }
            } catch {
                print(error.localizedDescription)
                completionBlock(false, error.localizedDescription)
            }
            
        }
    }
    
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "uploadPhotos" {
            let destinationVC = segue.destination as! ThirdViewController
            destinationVC.savingStore = self.savingStore
            print("Segue has done")
        }
        
    }
}

extension UIImage {
    
    /**
     이미지의 실제크기를 보고 최대 너비 800, 최대 높이 600으로 비율을 계산해서 압축해주는 함수
     : param: image
     */
    func compressImage(_ image: UIImage) -> UIImage {
        var actualHeight = image.size.height
        var actualWidth = image.size.width
        
        let data = UIImageJPEGRepresentation(image, 1)
        let imageSize = data?.count
        
        print("This is actual height and width: \(actualHeight) & \(actualWidth)")
        print("size of image in KB: %f , \(imageSize!/1024)")
        
        let maxHeight: CGFloat = 600
        let maxWidth: CGFloat = 800
        
        var imgRatio = actualWidth/actualHeight
        let maxRatio = maxWidth/maxHeight
        
        let compressionQuality: CGFloat = 0.9
        
        if (actualHeight > maxHeight) || (actualWidth > maxWidth) {
            if (imgRatio < maxRatio) {
                // adjust width according to maxHeight
                imgRatio = maxHeight / actualHeight
                actualWidth = imgRatio * actualWidth
                actualHeight = maxHeight
            } else if (imgRatio > maxRatio) {
                //adjust height according to maxWidth
                imgRatio = maxWidth / actualWidth
                actualHeight = imgRatio * actualHeight
                actualWidth = maxWidth
            } else {
                actualHeight = maxHeight
                
                actualWidth = maxWidth
            }
        }
        
        let rect = CGRect(x: 0, y: 0, width: actualWidth, height: actualHeight)
        UIGraphicsBeginImageContext(rect.size)
        image.draw(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        let imageData = UIImageJPEGRepresentation(image!, compressionQuality)
        let compressedSize = imageData?.count
        print("This is compressed height and width: \(maxHeight) & \(maxWidth)")
        print("size of compressed image in KB: %f , \(compressedSize!/1024)")
        UIGraphicsEndImageContext()
        return UIImage(data: imageData!)!
        
    }
    
    func resized(withPercentage percentage: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: size.width * percentage, height: size.height * percentage)
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func resized(toWidth width: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
