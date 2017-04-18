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
    
    // 완료 버튼 눌렀을 때 - 초기 화면으로 돌아감
    @IBAction func doneAction(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    
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
        if let imageArray = (selectedStore.imageArray?.components(separatedBy: ",")) {
            self.imageArray = imageArray
        } else {
            SCLAlertView().showWarning("사진 확인", subTitle: "사진이 없습니다")
        }
        
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
    
    /// 테이블 컴포넌트 정의
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
    
    /// 높이 300으로 정의
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300
    }
    
    /// 테이블 편집할 때의 액션을 정의함
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // 진짜 지울건지 물어보자
            let appearance = SCLAlertView.SCLAppearance(
                showCloseButton: false
            )
            let alertView = SCLAlertView(appearance: appearance)
            alertView.addButton("삭제") {
                
                let willDeleteImage = self.imageArray[indexPath.row]
                self.imageArray.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                // 변경된 이미지 배열 저장하기
                self.imageArraySyncToDB()
                // 이미지 삭제하기
                self.deleteFile(willDeleteImage)
            }
            alertView.addButton("취소") {
                print("사진 삭제 취소되었습니다")
            }
            alertView.showInfo("사진을 삭제하시겠습니까?", subTitle: "삭제하면 복원불가능합니다")
        }
    }
    
    /// 셀 움직일 수 있게 정의
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    /// 테이블 셀 움직이고 난 이후의 액션 정의
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
        print("복사 내용: \(imageArray[row])")
        pasteboard.string = imageArray[row]
        SCLAlertView().showSuccess("복사 완료", subTitle: "클립 보드에 저장됨")
    }
    
    /// 이미지 변경 함수
    func changeImage(_ row: Int) {
        print("이미지 변경")
        // 이미지 픽업 - 이미지 1개만 픽업
        let actionsheet = UIAlertController(title: "Choose source", message: nil, preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            actionsheet.addAction(UIAlertAction(title: "Take a picture", style: UIAlertActionStyle.default, handler: { (action) -> Void in
                // 이미지 1개만 픽업되게 설정
                self.pickerController.singleSelect = true
                self.pickerController.sourceType = .camera
                // 이미지를 변경: 업로드해서 url 리턴 받고 그 url을 배열에 집어넣어야 함
                self.showImageChangePicker(row)
            }))
        }
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            actionsheet.addAction(UIAlertAction(title: "Choose photo", style: UIAlertActionStyle.default, handler: { (action) -> Void in
                // 이미지 1개만 픽업되게 설정
                self.pickerController.singleSelect = true
                self.pickerController.assetType = .allPhotos
                // 이미지를 변경: 업로드해서 url 리턴 받고 그 url을 배열에 집어넣어야 함
                 self.showImageChangePicker(row)
                
            }))
        }
        actionsheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionsheet, animated: true, completion: nil)
    }
    
    /// 이미지 변경 피커
    func showImageChangePicker(_ row: Int) {
        
        pickerController.showsCancelButton = true
        // 배열 초기화
        self.assets?.removeAll()
        
        pickerController.didSelectAssets = { [unowned self] (assets: [DKAsset]) in
            // 기존 파일 url 저장
            let selectedUrl = self.imageArray[row]
            self.assets = assets
            self.fromAssetToImage({ (success, error) in
                if success {
                    // 우선 애줘에 업로드
                    photoManager().uploadPhoto(selectedFile: self.uploadImageArray.first!, completionBlock: { (success, fileURL, error) in
                        if success {
                            // 업로드가 완료되면 imageArray를 변경
                            self.imageArray[row] = fileURL!
                            // 이미지 배열 변경
                            self.imageArraySyncToDB()
                            // 백엔드에 저장
                            _ = self.dataStore?.save(self.selectedStore)
                            
                            // 테이블 해당 로우만 리로드
                            let indexPath = IndexPath(row: row, section: 0)
                            self.tableView.reloadRows(at: [indexPath], with: .automatic)
                            
                            // 파일 삭제
                            print("지울 파일: \(selectedUrl)")
                            self.deleteFile(selectedUrl)
                            
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
    
    /// 이미지 삭제하기: url 문자열이 파라미터,
    func deleteFile(_ willDeleteImage: String) {
        // 이미지 삭제하기 - 백엔드리스인지 Azure인지 구분 필요
        if willDeleteImage.hasPrefix("https://petcity.blob.core.windows.net/store-images/") {
            // Azure 파일이면?
            photoManager().deleteFile(selectedUrl: willDeleteImage, completionblock: { (success, error) in
                if success {
                    SCLAlertView().showSuccess("삭제 완료", subTitle: "In Azure")
                } else {
                    print("There is an error to delete: \(String(describing: error?.description))")
                }
            })
        } else if willDeleteImage.hasPrefix("https://api.backendless.com/6E11C098-5961-1872-FF85-2B0BD0AA0600/v1/files") {
            // 백엔드리스 파일
            Backendless.sharedInstance().fileService.remove(willDeleteImage, response: { (response) in
                SCLAlertView().showSuccess("삭제 완료", subTitle: "In Backendless")
            }, error: { (Fault) in
                print("There is an error to delete the image file in Backendless: \(String(describing: Fault?.description))")
            })
        } else {
            // Azure나 백엔드리스가 아닌 경우에는 그냥 링크 제거 후 저장으로 완료
            SCLAlertView().showSuccess("외부 링크 이미지", subTitle: "제거 완료")
        }
    }
    
    /// 이미지 DB 변경 함수 : 백엔드에서 애줘로 변경해줌
    /// 이미지를 받아서 애줘에 업로드하여 URL을 변경하고, 백엔드리스에서는 삭제한다 
    func changeDatabase(_ row: Int) {
        print("디비 변경")
        let selectedUrl = imageArray[row]
        if selectedUrl.hasPrefix("https://api.backendless.com/6E11C098-5961-1872-FF85-2B0BD0AA0600/v1/files") {
            
           SCLAlertView().showNotice("데이터베이스 변경", subTitle: "From Backendless to Azure")
            
            let imageView = UIImageView()
            let url = URL(string: selectedUrl)
            // 이미지 다운 받으면 리턴 받아서
            imageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, returnedURL) in
                if error == nil {
                    // 이미지 한 번 변환해주기
                    let convertedImage = image?.compressImage(image!)
                    // Azure에 업로드
                    photoManager().uploadPhoto(selectedFile: convertedImage!, completionBlock: { (success, fileURL, error) in
                        // 이미지 배열에 대체
                        self.imageArray[row] = fileURL!
                        // 이미지 배열 변경
                        self.imageArraySyncToDB()
                        // 백엔드에 저장
                        _ = self.dataStore?.save(self.selectedStore)
                        
                        // 테이블 해당 로우만 리로드
                        let indexPath = IndexPath(row: row, section: 0)
                        self.tableView.reloadRows(at: [indexPath], with: .automatic)
                        
                        // 백엔드리스에서 파일 삭제
                        print("지울 파일: \(selectedUrl)")
                        let fileName = selectedUrl.replacingOccurrences(of: "https://api.backendless.com/6E11C098-5961-1872-FF85-2B0BD0AA0600/v1/files/", with: "")
                        DispatchQueue.main.sync(execute: {
                            Backendless.sharedInstance().fileService.remove(fileName, response: { (response) in
                                print("백엔드에서 삭제 완료")
                            }, error: { (Fault) in
                                print("Error on delete on Backendless: \(String(describing: Fault?.description))")
                            })
                        })
                    })
                }
            })
        } else {
            SCLAlertView().showNotice("이미지 위치 확인", subTitle: "Backendless 파일이 아닙니다")
        }
    }
}
