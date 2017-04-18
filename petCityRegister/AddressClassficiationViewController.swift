//
//  AddressClassficiationViewController.swift
//  petCityRegister
//
//  Created by Ken Choi on 2017. 4. 10..
//  Copyright © 2017년 KenChoi. All rights reserved.
//

import UIKit
import Alamofire
import SCLAlertView

class AddressClassficiationViewController: UIViewController {

    var addressArray = ["서울시 강남구 도곡로 546-6"]
    
    // 네이버 지도 API
    let clientId = "TuWS2kCodIxD9zPok6F2"
    let clientSecret = "BwIGo_xV7u"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        for address in addressArray {
            naverMapCall(address, completionBlock: { (success, district, error) in
                if success {
                    print("This is address: \(address) and district: \(String(describing: district!))")
                } else {
                    print("This is error: \(String(describing: error?.description))")
                }
            })
        }
    }
    
    // 네이버에서 주소로 검색, 지오포인트 및 주소 구분을 얻어옴
    func naverMapCall(_ address: String, completionBlock: @escaping (_ success: Bool, _ district: String?, _ error: String?) -> ()) {
        let addr = address
        var returnDistrict = ""
        
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
                    print(json)
                    if let result = json["result"] as? [String: AnyObject] {
                        if let jsonResult = result["items"] as? Array<AnyObject> {
                            // print("this is count: \(jsonResult.count)")
                            // for result in jsonResult {
                            print("this is result: \(result)")
                            // }
                            if let jsonFirstResult = jsonResult[0] as? [String: AnyObject] {
                                //print("this is another Dict: \(jsonFirstResult)")
                                if let detail = jsonFirstResult["addrdetail"] as? [String: AnyObject] {
                                    // print("This is detail: \(detail)")
                                    if let sido = detail["sido"] as? String {
                                        // print("this is 시 or 도: \(sido)")
                                        returnDistrict.append(sido)
                                    }
                                    if let sigugun = detail["sigugun"] as? String {
                                        // print("this is 시 or 구 or 군: \(sigugun)")
                                        if returnDistrict == "서울특별시" {
                                            returnDistrict.append(" \(sigugun)")
                                        }
                                    }
                                }
                                completionBlock(true, returnDistrict, nil)
                            } else {
                                print("Sth is wrong again")
                                completionBlock(false, nil, "Sth is wrong")
                            }
                        } else {
                            print("Sth is wrong")
                            completionBlock(false, nil, "Sth is wrong")
                        }
                    }
                }
            } catch {
                print(error.localizedDescription)
                completionBlock(false, nil, error.localizedDescription)
            }
            
        }
    }

}
