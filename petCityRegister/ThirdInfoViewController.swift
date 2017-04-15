//
//  ThirdInfoViewController.swift
//  petCityRegister
//
//  Created by Ken Choi on 2017. 4. 12..
//  Copyright © 2017년 KenChoi. All rights reserved.
//

import UIKit
import Kingfisher
import SCLAlertView

class ThirdInfoViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var selectedStore: Store!
    
    var selectedImage: UIImage?
    
    var oldImageUrl: String?
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var imageUrlLabel: UILabel!
    
    @IBOutlet weak var imageSelectButton: UIButton!
    
    /// Object that helps selecting an image
    let imagePicker = UIImagePickerController()
    
    // 사진 변경 컨펌
    @IBAction func nextAction(_ sender: Any) {
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton: false
        )
        let alertView = SCLAlertView(appearance: appearance)
        alertView.addButton("사진 변경") {
            
            if let image = self.selectedImage {
                self.saveImage(image)
            } else {
                SCLAlertView().showError("이미지 에러", subTitle: "이미지가 없습니다")
            }
            
        }
        alertView.addButton("다음", action: {
            self.performSegue(withIdentifier: "showMultiPhoto", sender: nil)
        })
        alertView.addButton("취소") {
            // self.navigationController?.popToRootViewController(animated: true)
        }
        alertView.showInfo("정보를 변경하시겠습니까?", subTitle: "다음은 변경 없이 다음 화면으로")
    }
    
    // 사진 변경
    @IBAction func photoChange(_ sender: Any) {
        
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
            presenter.sourceView = self.imageSelectButton
            presenter.sourceRect = self.imageSelectButton.bounds
        }
        
        present(actionsheet, animated: true, completion: nil)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        title = "대표 사진 변경"
        
        // 기존 사진 URL
        if let imageUrl = selectedStore.imageURL {
            
            let url = URL(string: imageUrl)
            // 라벨에 표시
            imageUrlLabel.text = imageUrl
            oldImageUrl = imageUrl
            
            // 사진 보여주기
            imageView.kf.setImage(with: url, placeholder: #imageLiteral(resourceName: "imageplaceholder"), options: [.transition(.fade(0.2))], progressBlock: nil, completionHandler: nil)
            
        } else {
            SCLAlertView().showInfo("대표 사진 없음", subTitle: "확인해주세요")
        }
    }
    
    // 이미지 픽업이 끝나면 이미지 뷰에 이미지를 보여줌, 업로드는 향후 바버튼에서 확인받고 시작
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let chosenImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.image = chosenImage
            self.selectedImage = chosenImage
            // saveImage(chosenImage)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // 업로드 성공과 실패를 알려줌
    func saveImage(_ image: UIImage) {
        // Azure에 업로드
        photoManager().uploadPhoto(selectedFile: image, store: selectedStore) { (success, returnedUrl, error) in
            if error != nil {
                print("I got error on photo: \(String(describing: error))")
            } else {
                print("Store photo has been updated")
                self.imageUrlLabel.text = returnedUrl
                SCLAlertView().showSuccess("사진 변경", subTitle: "완료되었습니다")
                
                let appearance = SCLAlertView.SCLAppearance(
                    showCloseButton: false
                )
                let alertView = SCLAlertView(appearance: appearance)
                alertView.addButton("사진 삭제") {
                    
                    if let oldimageurl = self.oldImageUrl {
                        print(oldimageurl)
                        self.deleteFile(oldimageurl)
                        self.performSegue(withIdentifier: "showMultiPhoto", sender: nil)
                    } else {
                        SCLAlertView().showSuccess("기존 사진 에러", subTitle: "기존 사진이 없습니다")
                    }
                    
                }
                alertView.addButton("사진 유지", action: {
                    self.performSegue(withIdentifier: "showMultiPhoto", sender: nil)
                })
                alertView.showInfo("기존 사진을 삭제하겠습니까?", subTitle: "")
            }
        }
        
        /**
        photoManager().uploadNewPhoto(selectedFile: image, store: selectedStore!) { (success, error) in
            if success {
                print("Store photo has been updated")
                SCLAlertView().showSuccess("사진 변경", subTitle: "완료되었습니다")
                
                let appearance = SCLAlertView.SCLAppearance(
                    showCloseButton: false
                )
                let alertView = SCLAlertView(appearance: appearance)
                alertView.addButton("사진 삭제") {
                    
                    if let oldimageurl = self.oldImageUrl {
                        self.deleteFile(oldimageurl)
                    } else {
                        SCLAlertView().showSuccess("기존 사진 에러", subTitle: "기존 사진이 없습니다")
                    }
                    
                }
                alertView.addButton("사진 유지", action: {
                    self.performSegue(withIdentifier: "showMultiPhoto", sender: nil)
                })
                alertView.showInfo("기존 사진을 삭제하겠습니까?", subTitle: "다음은 삭제 없이 다음 화면으로")
                
                self.performSegue(withIdentifier: "showMultiPhoto", sender: nil)
                
            } else {
                print("I got error on photo: \(String(describing: error))")
            }
        }
        */
    }
    
    // 기존 사진 삭제
    func deleteFile(_ imageUrl: String) {
        // 백엔드리스 파일임을 검사
        let isBackendless = imageUrl.hasPrefix("https://api.backendless.com/6E11C098-5961-1872-FF85-2B0BD0AA0600/v1/files")
        
        // 백엔드리스 파일이면 삭제
        if isBackendless {
            Backendless.sharedInstance().fileService.remove(imageUrl, response: { (response) in
                SCLAlertView().showSuccess("기존 사진 삭제", subTitle: "완료되었습니다")
                
            }, error: { (Fault) in
                print("There is an error to delete the image file in Backendless: \(String(describing: Fault?.description))")
            })
        } else {
            
            if imageUrl.hasPrefix("https://petcity.blob.core.windows.net/store-images") {
                // Blob의 이름은 앞의 Container이름 제외하고
                let selectedUrl = imageUrl.replacingOccurrences(of: "https://petcity.blob.core.windows.net/store-images/", with: "")
                // 제외한 이름을 가지고 삭제 요청
                photoManager().deleteFile(selectedUrl: selectedUrl, completionblock: { (success, error) in
                    if success {
                        SCLAlertView().showSuccess("삭제 완료", subTitle: "삭제되었습니다")
                    } else {
                        print("There is an error to delete the image file in Azure: \(String(describing: error?.description))")
                    }
                })
            } else {
                // 아니면 외부링크임을 알림
                SCLAlertView().showError("이미지 에러", subTitle: "외부링크 이미지입니다")
            }
        }
    
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showMultiPhoto" {
            let destinationVC = segue.destination as! FourthInfoViewController
            destinationVC.selectedStore = self.selectedStore
        }
    }
}
