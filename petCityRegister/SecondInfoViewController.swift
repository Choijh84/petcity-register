//
//  SecondInfoViewController.swift
//  petCityRegister
//
//  Created by Ken Choi on 2017. 4. 12..
//  Copyright © 2017년 KenChoi. All rights reserved.
//

import UIKit
import Alamofire
import SCLAlertView

class SecondInfoViewController: UIViewController {

    var selectedStore: Store!
    
    var oldAddress: String = ""
    var oldLongitude: Double = 0.0
    var oldLatitude: Double = 0.0
    
    var newLongitude: Double = 0
    var newLatitude: Double = 0
    
    @IBOutlet weak var oldAddressLabel: UILabel!
    
    @IBOutlet weak var oldLongitudeLabel: UILabel!
    
    @IBOutlet weak var oldLatitudeLabel: UILabel!
    
    @IBOutlet weak var changedAddressLabel: UILabel!
    
    @IBOutlet weak var changedLongitudeLabel: UILabel!
    
    @IBOutlet weak var changedLatitudeLabel: UILabel!
    
    // 네이버 지도 API
    let clientId = "TuWS2kCodIxD9zPok6F2"
    let clientSecret = "BwIGo_xV7u"
    
    @IBAction func confirmNext(_ sender: Any) {
        performSegue(withIdentifier: "showPhoto", sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "주소 정보 확인"
        
        // 주소 변경을 어떻게 확인할 것인가
        // 어떻게 보여줄 것인가
        // 기존 주소값이나 지오가 없는 경우는?
        oldAddressLabel.text = oldAddress
        oldLongitudeLabel.text = String(oldLongitude)
        oldLatitudeLabel.text = String(oldLatitude)
        
        
        // 새롭게 입력한 주소는 무조건 있음, 없으면 미리 한 번 걸러냄
        if let address = selectedStore.address {
            changedAddressLabel.text = address
        }
        naverMapCall { (success, error) in
            if success {
                self.changedLongitudeLabel.text = String(self.newLongitude)
                self.changedLatitudeLabel.text = String(self.newLatitude)
            } else {
                print("There is an error to call Naver Map API: \(String(describing: error))")
            }
        }
    }

    // 네이버에서 주소로 검색, 지오포인트 및 주소 구분을 얻어옴
    func naverMapCall(_ completionBlock: @escaping (_ success: Bool, _ error: String?) -> ()) {
        var addr = ""
        if let address = selectedStore?.address {
            addr = address
        } else {
            SCLAlertView().showWarning("주소 에러", subTitle: "주소를 확인해주세요")
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
                                        self.newLongitude = pointX
                                    }
                                    if let pointY = point["y"] as? Double {
                                        // latitude 위도
                                        print("This is pointY: \(pointY)")
                                        self.newLatitude = pointY
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPhoto" {
            let destinationVC = segue.destination as! ThirdInfoViewController
            destinationVC.selectedStore = self.selectedStore
        }
    }
}
