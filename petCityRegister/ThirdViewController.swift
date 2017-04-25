//
//  ThirdViewController
//  petCityRegister
//
//  Created by Ken Choi on 2017. 4. 7..
//  Copyright © 2017년 KenChoi. All rights reserved.
//

import UIKit
import DKImagePickerController
import SCLAlertView

class ThirdViewController: UIViewController, UIImagePickerControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource {

    var savingStore: Store?
    
    /// Imagepicker by DKImagePickerController
    var pickerController: DKImagePickerController!
    /// 이미지 픽업된 이후 저장하는 배열
    var assets: [DKAsset]?
    var imageArray = [UIImage]()
    
    /// 오버레이 뷰
    lazy var overlayView: OverlayView = {
        let overlayView = OverlayView()
        return overlayView
    }()
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    // 세이브 버튼 누르면 업로드
    @IBAction func saveImageDB(_ sender: Any) {
        print("사진 개수: \(imageArray.count)")
        
        
        /// Azure에 업로드
        photoManager().uploadPhotos(selectedFiles: imageArray, store: savingStore!) { (success, returnedURL, error) in
            if success {
                print("This is imagearray url: \(String(describing: returnedURL))")
                SCLAlertView().showSuccess("업로드 완료", subTitle: "앱에서 확인해보세요")
                // 처음으로 돌아가기
                self.navigationController?.popToRootViewController(animated: true)
            } else {
                print("There is an error to save photos: \(String(describing: error?.description))")
            }
        }
        
        /**
        photoManager().uploadNewPhotos(selectedFiles: imageArray, store: savingStore!) { (success, returnedURL, error) in
            if success {
                print("This is imagearray url: \(returnedURL)")
                SCLAlertView().showSuccess("업로드 완료", subTitle: "앱에서 확인해보세요")
                // 처음으로 돌아가기
                self.navigationController?.popToRootViewController(animated: true)
            } else {
                print("There is an error to save photos: \(String(describing: error?.description))")
            }
        }
         */
    }
    
    // 사진 고르기
    @IBAction func uploadImages(_ sender: Any) {
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

    
    override func viewDidLoad() {
        super.viewDidLoad()

        pickerController = DKImagePickerController()
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    // MARK: DKIMAGE PICKER
    func showImagePicker() {
        
        pickerController.showsCancelButton = true
        
        pickerController.didSelectAssets = { [unowned self] (assets: [DKAsset]) in
            
            self.assets = assets
            self.collectionView.reloadData()
            self.fromAssetToImage()
            
        }
        
        if UI_USER_INTERFACE_IDIOM() == .pad {
            pickerController.modalPresentationStyle = .formSheet
        }
        
        present(pickerController, animated: true)
    }
    
    func fromAssetToImage() {
        imageArray.removeAll()
        for asset in self.assets! {
            asset.fetchOriginalImageWithCompleteBlock({ (image, info) in
                self.imageArray.append(image!.compressImage(image!))
            })
        }
    }
    

    // MARK: - CollectionView Methods
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("Item number: \(String(describing: self.assets?.count))")
        return self.assets?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let asset = self.assets![indexPath.row]
        var cell: UICollectionViewCell?
        var imageView: UIImageView?
        
        cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        cell?.layer.cornerRadius = 4.5
        cell?.layer.borderColor = UIColor.lightGray.cgColor
        cell?.layer.borderWidth = CGFloat(1.0)
        
        // 태그 - 이미지뷰에 해야 함
        imageView = cell?.contentView.viewWithTag(1) as? UIImageView

        if let cell = cell, let imageView = imageView {
            let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
            let tag = indexPath.row + 1
            cell.tag = tag
            asset.fetchImageWithSize(layout.itemSize.toPixel(), completeBlock: { (image, info) in
                if cell.tag == tag {
                    imageView.image = image
                }
            })
        }
        return cell!
    }

}

