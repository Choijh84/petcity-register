//
//  ViewController.swift
//  petCityRegister
//
//  Created by Ken Choi on 2017. 4. 5..
//  Copyright © 2017년 KenChoi. All rights reserved.
//

import UIKit
import Eureka
import SCLAlertView

class ViewController: FormViewController {

    let dataStore = Backendless.sharedInstance().data.of(Store.ofClass())
    
    /// value of all rows in the form
    var valueDictionary = [String: AnyObject]()
    
    // 저장
    @IBAction func saveStore(_ sender: Any) {
        valueDictionary = form.values(includeHidden: false) as [String: AnyObject]
        dump(valueDictionary)
        
        // 저장하고 다음으로 넘어갈지 
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton: false
        )
        let alertView = SCLAlertView(appearance: appearance)
        alertView.addButton("Yes") {
            self.setupStore(completionHandler: { (success, store, error) in
                if success {
                    self.performSegue(withIdentifier: "nextSegue", sender: store)
                } else {
                    SCLAlertView().showError("에러 발생", subTitle: "\(String(describing: error))")
                }
            })
        }
        alertView.addButton("No") {
            print("User says no")
            SCLAlertView().showInfo("취소", subTitle: "저장이 취소되었습니다")
        }
        alertView.showInfo("장소 저장", subTitle: "위치 설정 및 사진 업로드로 이동합니다")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "장소 등록"
        form =
            
            Section("필수 정보")
        
                <<< TextRow("name") {
                    $0.title = "장소 이름"
                    $0.add(rule: RuleRequired())
                    $0.validationOptions = .validatesOnChange
                    }.cellUpdate { cell, row in
                        if !row.isValid {
                            cell.titleLabel?.textColor = .red
                        }
                }
            
                <<< TextAreaRow("storeSubtitle") {
                    $0.placeholder = "바로 들어가자 보이는 소개글(이미지 위)"
                    $0.add(rule: RuleRequired())
                    $0.textAreaHeight = .dynamic(initialTextViewHeight: 50)
                }
            
                <<< TextAreaRow("storeDescription") {
                    $0.placeholder = "장소 소개"
                    $0.add(rule: RuleRequired())
                    $0.textAreaHeight = .dynamic(initialTextViewHeight: 50)
                }
            
                <<< PhoneRow("phoneNumber") {
                    $0.title = "전화 번호 입력"
                    $0.add(rule: RuleRequired())
                }
            
                <<< TextAreaRow("address") {
                    $0.placeholder = "주소 입력"
                    $0.add(rule: RuleRequired())
                    $0.textAreaHeight = .dynamic(initialTextViewHeight: 25)
                }
            
                <<< TextRow("website") {
                    $0.title = "홈페이지"
                }
            
                <<< TextAreaRow("operationTime") {
                    $0.placeholder = "영업시간 입력"
                    $0.textAreaHeight = .dynamic(initialTextViewHeight: 25)
                }
            
            +++ Section("세부 정보 1")
        
                <<< MultipleSelectorRow<String>("serviceCategory") {
                    $0.title = "등록 카테고리 선택하기"
                    $0.add(rule: RuleRequired())
                    // $0.presentationMode = .show
                    $0.options = ["Hospital", "Pet Beauty Shop", "Pet Cafe", "Pet Friendly Cafe", "Pet Friendly Hotel", "Pet Friendly Park", "Pet Friendly Pension", "Pet Friendly Restaurant", "Pet Good Shop", "Pet Hotel", "Pet Shop", "Pet Training", "Pet Playground", "Pet Kindergarden"]
                    }
                    .onPresent { from, to in
                        to.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: from, action: #selector(ViewController.multipleSelectorDone(_:)))
                }
            
                /**
                <<< TextAreaRow("serviceCategory") {
                    $0.placeholder = "카테고리 입력"
                    $0.textAreaHeight = .dynamic(initialTextViewHeight: 25)
                }
                */
                
                <<< TextAreaRow("serviceablePet") {
                    $0.placeholder = "가능한 반려동물 입력"
                    $0.textAreaHeight = .dynamic(initialTextViewHeight: 25)
                }
                
                <<< TextAreaRow("petSize") {
                    $0.placeholder = "가능한 반려동물 크기 입력"
                    $0.textAreaHeight = .dynamic(initialTextViewHeight: 25)
                }
                
                <<< TextAreaRow("priceInfo") {
                    $0.placeholder = "가격정보 입력"
                    $0.textAreaHeight = .dynamic(initialTextViewHeight: 25)
                }
                
                <<< TextAreaRow("note") {
                    $0.placeholder = "유의사항 입력"
                    $0.textAreaHeight = .dynamic(initialTextViewHeight: 25)
                }
        
            +++ Section("세부 정보 2")
        
                <<< SegmentedRow<Bool>("isAdvertising"){
                    $0.title = "광고 중인가요?"
                    $0.options = [true, false]
                    $0.value = false
                }
                
                <<< SegmentedRow<Bool>("isAffiliated"){
                    $0.title = "제휴했나요?"
                    $0.options = [true, false]
                    $0.value = false
                }
                
                <<< SegmentedRow<Bool>("isVerified"){
                    $0.title = "인증했나요?"
                    $0.options = [true, false]
                    $0.value = false
                }
        
        
    }
    
    func setupStore(completionHandler: @escaping (_ success: Bool, _ store: Store?, _ error: String?) -> ()) {
        let tempStore = Store()
        
        // 이름 저장하기
        tempStore.name = valueDictionary["name"] as? String
        
        tempStore.storeSubtitle = valueDictionary["storeSubtitle"] as? String
        
        
        if let storeDescription = valueDictionary["storeDescription"] as? String {
            tempStore.storeDescription = storeDescription
        }
        
        if let phoneNumber = valueDictionary["phoneNumber"] as? String {
            tempStore.phoneNumber = phoneNumber
        }
        
        if let address = valueDictionary["address"] as? String {
            tempStore.address = address
        }
        
        if let website = valueDictionary["website"] as? String {
            print("This is webiste: \(website)")
            tempStore.website = website
        }
        
        if let operationTime = valueDictionary["operationTime"] as? String {
            tempStore.operationTime = operationTime
        }
        
        if let serviceablePet = valueDictionary["serviceablePet"] as? String {
            tempStore.serviceablePet = serviceablePet
        }
        
        if let petSize = valueDictionary["petSize"] as? String {
            tempStore.petSize = petSize
        }
        
        if let priceInfo = valueDictionary["priceInfo"] as? String {
            tempStore.priceInfo = priceInfo
        }
        
        if let note = valueDictionary["note"] as? String {
            tempStore.note = note
        }
        
        if let isAdvertising = valueDictionary["isAdvertising"] as? Bool {
            tempStore.isAdvertising = isAdvertising
        }
        
        if let isAffiliated = valueDictionary["isAffiliated"] as? Bool {
            tempStore.isAffiliated = isAffiliated
        }
        
        if let isVerified = valueDictionary["isVerified"] as? Bool {
            tempStore.isVerified = isVerified
        }
        
        dataStore?.save(tempStore, response: { (response) in
            let responseStore = response as! Store
            
            let serviceCategory = self.valueDictionary["serviceCategory"] as! Set<String>
            let serviceCategoryArray = Array(serviceCategory)
            let myGroup = DispatchGroup()
            var convertedString = ""
            
            for category in serviceCategoryArray {
                
                // 카테고리로 경우에 따라 어떤 문자열로 변환할 것인지 결정
                // ["Hospital", "Pet Beauty Shop", "Pet Cafe", "Pet Friendly Cafe", "Pet Friendly Hotel", "Pet Friendly Park", "Pet Friendly Pension", "Pet Friendly Restaurant", "Pet Good Shop", "Pet Hotel", "Pet Shop", "Test", "Another Test"]
                print("This is category: \(category)")
                
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
                    print("objectId: \(String(describing: storeCategory.objectId))")
                    
                    dataStoreCategory?.save(storeCategory, response: { (response) in
                        print("\(storeCategory.name!) 카테고리에 추가되었습니다")
                    }, error: { (Fault) in
                        print("Server reporeted an error to update service category: \(String(describing: Fault?.description))")
                    })
                    
                    myGroup.leave()
                }, error: { (Fault) in
                    print("Server reporeted an error to get the service category: \(String(describing: Fault?.description))")
                })
            }
            
            myGroup.notify(queue: DispatchQueue.main) {
                tempStore.serviceCategory = convertedString
                completionHandler(true, responseStore, nil)
            }
            
        }, error: { (Fault) in
            print("Server reporeted an error to save the store: \(String(describing: Fault?.description))")
            completionHandler(false, nil, Fault?.description)
        })

        
    }
    
    func multipleSelectorDone(_ item:UIBarButtonItem) {
        _ = navigationController?.popViewController(animated: true)
    }
    
    // 카테고리에 추가, 먼저 스토어에 추가가 되고 해야됨, 중복을 피하기 위해 오브젝트 아이디 읽어오기
    /**
    func addStoreIntoCategory(_ storeCategory: String, _ store: Store) {
        
        let tempStoreCategory = StoreCategory()
        tempStoreCategory.name = storeCategory
        tempStoreCategory.stores.append(store)
        
        let dataStore = Backendless.sharedInstance().data.of(StoreCategory.ofClass())
        dataStore?.save(tempStoreCategory, response: { (response) in
            print("카테고리 저장 완료: \(tempStoreCategory.name!)")
        }, error: { (Fault) in
            print("Server reporeted an error to save the store: \(String(describing: Fault?.description))")

        })
    }
    */
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "nextSegue" {
            let store = sender as! Store
            let destinationVC = segue.destination as! SecondViewController
            destinationVC.savingStore = store
            print("Segue has done")
        }
    }

}

