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
    
    // 변경된 것으로 저장할 것인지 확인하고 액션 필요
    @IBAction func confirmNext(_ sender: Any) {
        
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton: false
        )
        let alertView = SCLAlertView(appearance: appearance)
        alertView.addButton("변경") {
            // 지오포인트 변경
            self.changeGeoPointAsync()
        }
        alertView.addButton("다음", action: {
            self.performSegue(withIdentifier: "showPhoto", sender: nil)
        })
        alertView.addButton("취소") {
            // self.navigationController?.popToRootViewController(animated: true)
        }
        alertView.showInfo("정보를 변경하시겠습니까?", subTitle: "다음은 변경 없이 다음 화면으로")
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
            self.naverMapCall { (success, error) in
                if success {
                    self.changedLongitudeLabel.text = String(self.newLongitude)
                    self.changedLatitudeLabel.text = String(self.newLatitude)
                } else {
                    print("There is an error to call Naver Map API: \(String(describing: error))")
                }
            }
        } else {
            self.changedAddressLabel.text = "변경 없음"
            self.changedLongitudeLabel.text = "변경 없음"
            self.changedLatitudeLabel.text = "변경 없음"    
        }
    }
    
    // 지오포인트 저장 함수
    func changeGeoPointAsync() {
        let name = selectedStore?.name
        let oldGeopoint = selectedStore.location
        
        let newGeopoint = GeoPoint.geoPoint(
            GEO_POINT(latitude: newLatitude, longitude: newLongitude),
            categories: nil, metadata: ["name": name!]
            ) as! GeoPoint
        
        Backendless.sharedInstance().geoService.save(newGeopoint, response: { (point) in
            print("ASYNC: geo point saved. object ID - \(String(describing: point?.objectId))")
            
            // 여기에서 store와 지오포인트 설정해주면 됨
            let dataStore = Backendless.sharedInstance().persistenceService.of(Store.ofClass())
            self.selectedStore?.location = point
            dataStore?.save(self.selectedStore, response: { (response) in
                print("geo point has linked with store")
            }, error: { (Fault) in
                print("There is a error to link geopoint: \(String(describing: Fault?.description))")
            })
            SCLAlertView().showSuccess("지오 변경", subTitle: "변경되었습니다")
            // 뷰 넘기기
            self.performSegue(withIdentifier: "showPhoto", sender: nil)
            
            // 기존 지오포인트 삭제
            Backendless.sharedInstance().geoService.remove(oldGeopoint, response: { (response) in
                print("기존 지오 삭제")
            }, error: { (Fault) in
                print("There is a error to delete geopoint: \(String(describing: Fault?.description))")
            })
            
        }) { (Fault) in
            print("There is a error to save geopoint: \(String(describing: Fault?.description))")
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
