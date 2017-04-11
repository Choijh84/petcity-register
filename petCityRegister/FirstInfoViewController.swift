//
//  FirstInfoViewController.swift
//  petCityRegister
//
//  Created by Ken Choi on 2017. 4. 12..
//  Copyright © 2017년 KenChoi. All rights reserved.
//

import UIKit
import Eureka
import SCLAlertView

class FirstInfoViewController: FormViewController {

    var selectedStore: Store!
    var selectedStoreCategory = [StoreCategory]()
    var oldAddress = ""
    var oldLongitude: Double = 0.0
    var oldLatitude: Double = 0.0
    
    // 폼에 저장된 값들
    var valueDictionary = [String: AnyObject]()
    
    @IBAction func saveChange(_ sender: Any) {
        // form에서 value 형성
        valueDictionary = form.values(includeHidden: false) as [String : AnyObject]
        dump(valueDictionary)
        
        /// 기초 데이터 입력 여부 체크
        /// 필수 입력: 이름, 서브타이틀, 전화번호, 주소 등
        if valueDictionary["name"] is NSNull || valueDictionary["storeSubtitle"] is NSNull || valueDictionary["storeDescription"] is NSNull || valueDictionary["phoneNumber"] is NSNull || valueDictionary["address"] is NSNull {
            SCLAlertView().showError("입력 에러", subTitle: "필수 정보 입력을 입력해주세요")
        } else {
            /// To ask user to save or not
            /// close 버튼 숨기기
            let appearance = SCLAlertView.SCLAppearance(
                showCloseButton: false
            )
            let alertView = SCLAlertView(appearance: appearance)
            alertView.addButton("변경") {
                /// 스토어 정보 변경하기
                self.updateStore(completionHandler: { (success, store, error) in
                    if success {
                        SCLAlertView().showSuccess("변경 완료", subTitle: "저장되었습니다")
                        self.performSegue(withIdentifier: "SecondCheck", sender: nil)
                    } else {
                        SCLAlertView().showError("에러 발생", subTitle: "다시 시도해주세요")
                    }
                })
            }
            alertView.addButton("취소") {
                self.navigationController?.popToRootViewController(animated: true)
            }
            alertView.showInfo("정보를 변경하시겠습니까?", subTitle: "취소하면 초기화면으로 돌아갑니다")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "정보 편집"

        // 기존 주소 저장
        if let address = selectedStore.address {
            self.oldAddress = address
        } else {
            SCLAlertView().showWarning("주소값 에러", subTitle: "기존에 입력된 주소가 없습니다")
        }
        if let longitude = selectedStore.location?.longitude {
            oldLongitude = Double(longitude)
        } else {
            SCLAlertView().showWarning("지오포인트 에러", subTitle: "기존에 입력된 지오포인트 값이 없습니다")
        }
        if let latitude = selectedStore.location?.latitude {
            oldLatitude = Double(latitude)
        }
        
        // 카테고리 셋 생성
        var Category = Set<String>()
        for storeCategory in selectedStoreCategory {
            Category.insert(storeCategory.name!)
        }
        
        
        form =
            
            Section("필수 정보")
            
            <<< TextRow("name") {
                $0.title = "장소 이름"
                $0.value = selectedStore.name
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
                }.cellUpdate { cell, row in
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                    }
            }
            
            <<< TextAreaRow("storeSubtitle") {
                $0.value = selectedStore.storeSubtitle
                $0.add(rule: RuleRequired())
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 50)
            }
            
            <<< TextAreaRow("storeDescription") {
                $0.value = selectedStore.storeDescription
                $0.add(rule: RuleRequired())
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 50)
            }
            
            <<< PhoneRow("phoneNumber") {
                $0.title = "전화 번호 입력"
                $0.value = selectedStore.phoneNumber
                $0.add(rule: RuleRequired())
            }
            
            <<< TextAreaRow("address") {
                $0.value = selectedStore.address
                $0.add(rule: RuleRequired())
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 25)
            }
            
            <<< TextRow("website") {
                $0.title = "홈페이지"
                $0.value = selectedStore.website
            }
            
            <<< TextAreaRow("operationTime") {
                $0.value = selectedStore.operationTime
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 25)
            }
            
            +++ Section("세부 정보 1")
            
            // 추가 작업 필요
            <<< MultipleSelectorRow<String>("serviceCategory") {
                $0.title = "등록 카테고리 선택하기"
                $0.value = Category
                $0.add(rule: RuleRequired())
                // $0.presentationMode = .show
                $0.options = ["Hospital", "Pet Beauty Shop", "Pet Cafe", "Pet Friendly Cafe", "Pet Friendly Hotel", "Pet Friendly Park", "Pet Friendly Pension", "Pet Friendly Restaurant", "Pet Good Shop", "Pet Hotel", "Pet Shop", "Pet Training", "Pet Playground", "Pet Kindergarden"]
                }
                .onPresent { from, to in
                    to.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: from, action: #selector(FirstInfoViewController.multipleSelectorDone(_:)))
            }
            
            /**
             // 문자열로 입력된 것 - 일치하는지 확인 필요
             <<< TextAreaRow("serviceCategory") {
             $0.value = selectedStore.serviceCategory
             $0.textAreaHeight = .dynamic(initialTextViewHeight: 25)
             }
            */
            
            
            <<< TextAreaRow("serviceablePet") {
                $0.value = selectedStore.serviceablePet
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 25)
            }
            
            <<< TextAreaRow("petSize") {
                $0.value = selectedStore.petSize
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 25)
            }
            
            <<< TextAreaRow("priceInfo") {
                $0.value = selectedStore.priceInfo
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 25)
            }
            
            <<< TextAreaRow("note") {
                $0.value = selectedStore.note
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 25)
            }
            
            +++ Section("세부 정보 2")
            
            <<< SegmentedRow<Bool>("isAdvertising"){
                $0.title = "광고 중인가요?"
                $0.options = [true, false]
                $0.value = selectedStore.isAdvertising
            }
            
            <<< SegmentedRow<Bool>("isAffiliated"){
                $0.title = "제휴했나요?"
                $0.options = [true, false]
                $0.value = selectedStore.isAffiliated
            }
            
            <<< SegmentedRow<Bool>("isVerified"){
                $0.title = "인증했나요?"
                $0.options = [true, false]
                $0.value = selectedStore.isVerified
        }
    }
    
    func updateStore(completionHandler: @escaping (_ success: Bool, _ store: Store?, _ error: String?) -> ()) {
        // let tempStore = Store()
        
        // 이름 저장하기
        selectedStore.name = valueDictionary["name"] as? String
        
        selectedStore.storeSubtitle = valueDictionary["storeSubtitle"] as? String
        
        
        if let storeDescription = valueDictionary["storeDescription"] as? String {
            selectedStore.storeDescription = storeDescription
        }
        
        if let phoneNumber = valueDictionary["phoneNumber"] as? String {
            selectedStore.phoneNumber = phoneNumber
        }
        
        if let address = valueDictionary["address"] as? String {
            selectedStore.address = address
        }
        
        if let website = valueDictionary["website"] as? String {
            // print("This is webiste: \(website)")
            selectedStore.website = website
        }
        
        if let operationTime = valueDictionary["operationTime"] as? String {
            selectedStore.operationTime = operationTime
        }
        
        if let serviceablePet = valueDictionary["serviceablePet"] as? String {
            selectedStore.serviceablePet = serviceablePet
        }
        
        if let petSize = valueDictionary["petSize"] as? String {
            selectedStore.petSize = petSize
        }
        
        if let priceInfo = valueDictionary["priceInfo"] as? String {
            selectedStore.priceInfo = priceInfo
        }
        
        if let note = valueDictionary["note"] as? String {
            selectedStore.note = note
        }
        
        if let isAdvertising = valueDictionary["isAdvertising"] as? Bool {
            selectedStore.isAdvertising = isAdvertising
        }
        
        if let isAffiliated = valueDictionary["isAffiliated"] as? Bool {
            selectedStore.isAffiliated = isAffiliated
        }
        
        if let isVerified = valueDictionary["isVerified"] as? Bool {
            selectedStore.isVerified = isVerified
        }
        
        let dataStore = Backendless.sharedInstance().data.of(Store.ofClass())
        
        dataStore?.save(selectedStore, response: { (response) in
            let responseStore = response as! Store
            
            let serviceCategory = self.valueDictionary["serviceCategory"] as! Set<String>
            let serviceCategoryArray = Array(serviceCategory)
            let myGroup = DispatchGroup()
            var convertedString = ""
            
            for category in serviceCategoryArray {
                
                // 카테고리로 경우에 따라 어떤 문자열로 변환할 것인지 결정
                // ["Hospital", "Pet Beauty Shop", "Pet Cafe", "Pet Friendly Cafe", "Pet Friendly Hotel", "Pet Friendly Park", "Pet Friendly Pension", "Pet Friendly Restaurant", "Pet Good Shop", "Pet Hotel", "Pet Shop" 등 추가됨]
                print("유지되거나 새롭게 업데이트된 카테고리: \(category)")
                
                switch category {
                    
                case "Hospital":
                    convertedString.append("동물병원")
                case "Pet Beauty Shop":
                    convertedString.append("펫 미용샵")
                case "Pet Cafe":
                    convertedString.append("펫카페")
                case "Pet Friendly Cafe":
                    convertedString.append("펫 동반 카페")
                case "Pet Friendly Hotel":
                    convertedString.append("펫 동반 호텔")
                case "Pet Friendly Park":
                    convertedString.append("펫 동반 공원")
                case "Pet Friendly Pension":
                    convertedString.append("펫 동반 펜션")
                case "Pet Friendly Restaurant":
                    convertedString.append("펫 동반 식당")
                case "Pet Good Shop":
                    convertedString.append("펫 용품샵")
                case "Pet Hotel":
                    convertedString.append("펫 호텔")
                case "Pet Shop":
                    convertedString.append("펫 분양샵")
                case "Pet Training":
                    convertedString.append("펫 분양샵")
                case "Pet Kindergarden":
                    convertedString.append("펫 유치원")
                case "Pet Playground":
                    convertedString.append("펫 놀이방")
                    
                default:
                    convertedString = "작업 중입니다"
                }
                
                // 카테고리를 database에서 읽은 후에 거기에 store를 추가함
                let dataStoreCategory = Backendless.sharedInstance().data.of(StoreCategory.ofClass())
                let dataQuery = BackendlessDataQuery()
                dataQuery.whereClause = "name = \'\(category)\'"
                myGroup.enter()
                
                dataStoreCategory?.find(dataQuery, response: { (collection) in
                    let storeCategory = collection?.data.first as! StoreCategory
                    storeCategory.stores.append(responseStore)
                    // print("objectId: \(String(describing: storeCategory.objectId))")
                    
                    dataStoreCategory?.save(storeCategory, response: { (response) in
                        // print("\(storeCategory.name!) 카테고리에 추가되었습니다")
                    }, error: { (Fault) in
                        print("Server reporeted an error to update service category: \(String(describing: Fault?.description))")
                    })
                    
                    myGroup.leave()
                }, error: { (Fault) in
                    print("Server reporeted an error to get the service category: \(String(describing: Fault?.description))")
                })
            }
            
            myGroup.notify(queue: DispatchQueue.main) {
                self.selectedStore.serviceCategory = convertedString
                completionHandler(true, responseStore, nil)
            }
            
        }, error: { (Fault) in
            print("Server reporeted an error to update the store: \(String(describing: Fault?.description))")
            completionHandler(false, nil, Fault?.description)
        })
    }

    func multipleSelectorDone(_ item:UIBarButtonItem) {
        _ = navigationController?.popViewController(animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SecondCheck" {
            let destinationVC = segue.destination as! SecondInfoViewController
            destinationVC.selectedStore = selectedStore
            destinationVC.oldAddress = oldAddress
            destinationVC.oldLatitude = oldLatitude
            destinationVC.oldLongitude = oldLongitude
        }
    }
    
}
