//
//  showResultViewController.swift
//  petCityRegister
//
//  Created by Ken Choi on 2017. 4. 12..
//  Copyright © 2017년 KenChoi. All rights reserved.
//

import UIKit
import SCLAlertView

class showResultViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var storeList = [Store]()
    var selectedStore = Store()
    var selectedStoreCategory = [StoreCategory]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(false, animated: false)

        title = "검색 결과"
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    // MARK: - Tableview method
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return storeList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let store = storeList[indexPath.row]
        
        if let name = store.name {
            cell.textLabel?.text = name
        } else {
            cell.textLabel?.text = "장소 이름 입력 필요"
        }
        if let address = store.address {
            cell.detailTextLabel?.text = address
        } else {
            cell.detailTextLabel?.text = "주소 입력 필요"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Place has selected")
        selectedStore = storeList[indexPath.row]
        findServiceCategory { (success, selectedCategory, error) in
            if success {
                self.selectedStoreCategory = selectedCategory!
                self.performSegue(withIdentifier: "showDetail", sender: indexPath)
            } else {
                SCLAlertView().showError("카테고리 로딩 실패", subTitle: "데이터 확인이 필요합니다")
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            let destinationVC = segue.destination as! FirstInfoViewController
            // let row = (sender as! IndexPath).row
            destinationVC.selectedStore = self.selectedStore
            destinationVC.selectedStoreCategory = self.selectedStoreCategory
        }
    }
    
    // 등록된 카테고리 불러읽어들여오는 함수
    func findServiceCategory(completionBlock: @escaping (_ success: Bool, _ category: [StoreCategory]?, _ errorMessage: String?) -> ()) {
        let dataStore = Backendless.sharedInstance().data.of(StoreCategory.ofClass())
        
        let dataQuery = BackendlessDataQuery()
        dataQuery.whereClause = "stores.objectId = \'\(selectedStore.objectId!)\'"
        
        dataStore?.find(dataQuery, response: { (collection) in
            let categories = collection?.data as! [StoreCategory]
            dump(categories)
            completionBlock(true, categories, nil)
        }, error: { (Fault) in
            print("Error!!!!: \(String(describing: Fault?.description))")
            completionBlock(false, nil, Fault?.description)
        })
    }
    
}
