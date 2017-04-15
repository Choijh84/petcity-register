//
//  FourthInfoViewController.swift
//  petCityRegister
//
//  Created by Ken Choi on 2017. 4. 12..
//  Copyright © 2017년 KenChoi. All rights reserved.
//

import UIKit
import Kingfisher
import SCLAlertView
import DKImagePickerController

class FourthInfoViewController: UIViewController, UIImagePickerControllerDelegate {
    
    /// 해당 스토어
    var selectedStore: Store!
    /// 해당 스토어의 이미지 배열
    var imageArray = [String]()
    /// 테이블뷰
    @IBOutlet weak var tableView: UITableView!
    /// 테이블뷰 편집 버튼
    @IBOutlet weak var editBarButton: UIBarButtonItem!
    /// 백엔드리스
    let dataStore = Backendless.sharedInstance().data.of(Store.ofClass())
    /// Imagepicker by DKImagePickerController
    var pickerController: DKImagePickerController!
    /// 이미지 픽업된 이후 저장하는 배열
    var assets: [DKAsset]?
    /// 업로드할 이미지 배열
    var uploadImageArray = [UIImage()]
    
    /// 이미지 픽업하고 그걸 테이블 뷰 마지막에 추가
    @IBAction func addImage(_ sender: Any) {
        // 이미지 픽업
        let actionsheet = UIAlertController(title: "Choose source", message: nil, preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            actionsheet.addAction(UIAlertAction(title: "Take a picture", style: UIAlertActionStyle.default, handler: { (action) -> Void in
                self.pickerController.sourceType = .camera
                self.showImagePicker()
            }))
        }
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            actionsheet.addAction(UIAlertAction(title: "Choose photo", style: UIAlertActionStyle.default, handler: { (action) -> Void in
                self.pickerController.assetType = .allPhotos
                self.showImagePicker()
                
            }))
        }
        actionsheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionsheet, animated: true, completion: nil)
    }
    
    @IBAction func editTableView(_ sender: Any) {
        if tableView.isEditing {
            tableView.setEditing(false, animated: false)
            editBarButton.style = .plain
            editBarButton.title = "Edit"
        } else {
            tableView.setEditing(true, animated: true)
            editBarButton.style = .done
            editBarButton.title = "Done"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pickerController = DKImagePickerController()
        
        // Do any additional setup after loading the view.
        imageArray = (selectedStore.imageArray?.components(separatedBy: ","))!
        
        tableView.reloadData()
    }
    
    // MARK: DKIMAGE PICKER
    func showImagePicker() {
        
        pickerController.showsCancelButton = true
        
        pickerController.didSelectAssets = { [unowned self] (assets: [DKAsset]) in
            
            self.assets = assets
            self.tableView.reloadData()
            self.fromAssetToImage({ (success, error) in
                if success {
                    photoManager().uploadPhotos(selectedFiles: self.uploadImageArray, store: self.selectedStore, completionBlock: { (success, fileURL, error) in
                        if success {
                            print("This is fileURL: \(String(describing: fileURL))")
                            // imageArray에 추가하자
                            self.imageArray = fileURL!.components(separatedBy: ",")
                            self.tableView.reloadData()
                        } else {
                            print("This is error: \(String(describing: error?.description))")
                        }
                    })
                }
            })
            
        }
        
        if UI_USER_INTERFACE_IDIOM() == .pad {
            pickerController.modalPresentationStyle = .formSheet
        }
        
        present(pickerController, animated: true)
    }
    
    func fromAssetToImage(_ completionBlock: @escaping (_ success: Bool, _ error: String?) -> ()) {
        uploadImageArray.removeAll()
        let myGroup = DispatchGroup()
        
        for asset in self.assets! {
            myGroup.enter()
            asset.fetchOriginalImageWithCompleteBlock({ (image, info) in
                self.uploadImageArray.append(image!.compressImage(image!))
                myGroup.leave()
            })
        }
        myGroup.notify(queue: DispatchQueue.main, execute: {
            print("For loop finished")
            completionBlock(true, nil)
        })
    }

}

extension FourthInfoViewController: UITableViewDelegate, UITableViewDataSource, FourthInfoCellProtocol {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imageArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! FourthInfoTableViewCell
        cell.delegate = self
        
        // 기본 데이터 설정
        cell.number.text = String(indexPath.row+1)
        let imageURL = imageArray[indexPath.row]
        let url = URL(string: imageURL)
        cell.urlLabel.text = imageURL
        
        // 이미지 불러오기
        cell.imageInfoView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: nil, completionHandler: nil)
        cell.imageInfoView.kf.indicatorType = .activity
        
        // 태그 설정
        cell.urlLabel.tag = (indexPath.row*10) + 01
        cell.changeImageButton.tag = (indexPath.row*10) + 02
        cell.changeDBButton.tag = (indexPath.row*10) + 03
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let willDeleteImage = imageArray[indexPath.row]
            imageArray.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            // 변경된 이미지 배열 저장하기
            imageArraySyncToDB()
            // 이미지 삭제하기 - 백엔드리스인지 Azure인지 구분 필요
            photoManager().deleteFile(selectedUrl: willDeleteImage, completionblock: { (success, error) in
                if success {
                    print("Deleted")
                } else {
                    print("There is an error to delete: \(String(describing: error?.description))")
                }
            })
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let image = imageArray[sourceIndexPath.row]
        // 순서 바꾸기
        imageArray.remove(at: sourceIndexPath.row)
        imageArray.insert(image, at: destinationIndexPath.row)
        // 테이블 갱신
        tableView.reloadData()
        // 변경된 이미지 배열 저장하기
        imageArraySyncToDB()
    }
    
    /// 변경된 imageArray 바꿔서 데이터베이스에 저장하기
    func imageArraySyncToDB() {
        let changedImageArray = imageArray
        var totalImageArray = ""
        for changedImage in changedImageArray {
            totalImageArray.append(changedImage+",")
        }
        selectedStore.imageArray = String(totalImageArray.characters.dropLast())
        _ = dataStore?.save(selectedStore)
    }
    
    /// 태그값에 따른 액션
    /// 태그 1: URL 복사, 2: 이미지 변경, 3: 이미지 DB 전환
    func actionTapped(tag: Int) {
        let row = tag/10
        let realTag = tag%10
        
        switch realTag {
            case 1:
                print("URL 라벨")
                copyURL(row)
            case 2:
                changeImage(row)
            case 3:
                changeDatabase(row)
            default:
                print("Some other action")
            
        }
    }
    
    /// URL 복사 기능
    func copyURL(_ row: Int) {
        let pasteboard = UIPasteboard.general
        pasteboard.string = "\(imageArray[row])"
        SCLAlertView().showSuccess("복사 완료", subTitle: "클립 보드에 저장됨")
    }
    
    /// 이미지 변경 함수
    func changeImage(_ row: Int) {
        print("이미지 변경")
    }
    
    /// 이미지 DB 변경 함수 : 백엔드에서 애줘로 
    /// 이미지를 받아서 애줘에 업로드하여 URL을 변경하고, 백엔드리스에서는 삭제한다 
    func changeDatabase(_ row: Int) {
        print("디비 변경")
    }
}
