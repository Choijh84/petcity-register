//
//  FourthInfoTableViewCell.swift
//  petCityRegister
//
//  Created by Ken Choi on 2017. 4. 16..
//  Copyright © 2017년 KenChoi. All rights reserved.
//

import UIKit
import SCLAlertView

protocol FourthInfoCellProtocol: class {
    func actionTapped(tag: Int)
}

class FourthInfoTableViewCell: UITableViewCell {

    weak var delegate: FourthInfoCellProtocol?
    var row: Int?
    
    @IBOutlet weak var number: UILabel!
    
    @IBOutlet weak var imageInfoView: UIImageView!
    
    @IBOutlet weak var urlLabel: UILabel!
    
    @IBOutlet weak var changeImageButton: UIButton!
    
    @IBOutlet weak var changeDBButton: UIButton!
    
    @IBAction func changeImage(_ sender: UIButton) {
        delegate?.actionTapped(tag: sender.tag)
    }
    
    @IBAction func changeDatabase(_ sender: UIButton) {
        delegate?.actionTapped(tag: sender.tag)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        /// Set the gesture recognizer
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(labelTapped(_:)))
        tapGesture.delegate = self
        tapGesture.numberOfTapsRequired = 1
        
        urlLabel.addGestureRecognizer(tapGesture)
    }
    
    func labelTapped(_ tapGesture: UITapGestureRecognizer) {
        delegate?.actionTapped(tag: (tapGesture.view?.tag)!)
    }

}
