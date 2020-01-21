//
//  ProfileViewController.swift
//  Wadu
//
//  Created by Jerry Shi on 2018-06-02.
//  Copyright © 2018 Jerry Shi. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    let user = User.sharedUserInfo
    
    var nameLabel: UILabel? = nil
    var profilePic: UIImageView? = nil
    var ChangePicButton: UIButton?
    var takePhotoButton: UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set connection view bg color
        self.view.backgroundColor = UIColor(displayP3Red: 1.0, green: 0.949, blue: 0.831, alpha: 1.0)
        
        createCloseButton()
        createProfilePic()
        createNameLabel()
        if let name = UserDefaults.standard.value(forKey: "nameString") as? String {
            self.nameLabel?.text = name
            user.name = name
        }
        createNameTextField()
        createChangeProfilePicButton()
        if let profileImageData = UserDefaults.standard.value(forKey: "profileImageData") as? NSData {
            self.profilePic?.image = UIImage(data: profileImageData as Data)
            user.imageData = profileImageData
        }
        createTakePhotoButton()
    }
    
    //close connection view
    func createCloseButton() {
        let y: CGFloat = 39
        let width: CGFloat = 25
        let height: CGFloat = 25
        let x: CGFloat = 16
        
        let closeButton = UIButton(frame: CGRect(x: x, y: y, width: width, height: height))
        closeButton.setImage(UIImage(named: "connectionClose"), for: .normal)
        closeButton.addTarget(self, action: #selector(self.didCloseButtonTouch), for: .touchUpInside)
        self.view.addSubview(closeButton)
    }
    
    @objc func didCloseButtonTouch () {
        self.dismiss(animated: true, completion: nil)
    }
    
    func createProfilePic() {
        let y: CGFloat = 100
        let width: CGFloat = 100
        let height: CGFloat = 100
        let x: CGFloat = (self.view.frame.width - width) / 2.0
        
        let profileImage = UIImage(named: "profile")
        self.profilePic = UIImageView(image: profileImage!)
        self.profilePic?.frame = CGRect(x: x, y: y, width: width, height: height)
        self.profilePic?.contentMode = .scaleToFill
        self.view.addSubview(self.profilePic!)
    }
    
    func createNameLabel() {
        let y: CGFloat = 220
        let width: CGFloat = 200
        let height: CGFloat = 50
        let x: CGFloat = (self.view.frame.width - width) / 2.0
        
        self.nameLabel = UILabel(frame: CGRect(x: x, y: y, width: width, height: height))
        self.nameLabel?.textColor = UIColor.black
        self.nameLabel?.backgroundColor = UIColor.clear
        self.nameLabel?.text = "Anonymous"
        self.nameLabel?.font = UIFont(name: "KohinoorTelugu-Light", size: 25)
        self.nameLabel?.numberOfLines = 0
        self.nameLabel?.textAlignment = .center
        self.view.addSubview(self.nameLabel!)
    }
    
    func createNameTextField() {
        let y: CGFloat = 330
        let width: CGFloat = 300
        let height: CGFloat = 33
        let x: CGFloat = (self.view.frame.width - width) / 2.0
        
        let sampleTextField =  UITextField(frame: CGRect(x: x, y: y, width: width, height: height))
        sampleTextField.placeholder = "Enter here"
        sampleTextField.font = UIFont.systemFont(ofSize: 18)
        sampleTextField.borderStyle = UITextBorderStyle.roundedRect
        sampleTextField.autocorrectionType = UITextAutocorrectionType.no
        sampleTextField.keyboardType = UIKeyboardType.default
        sampleTextField.returnKeyType = UIReturnKeyType.done
        sampleTextField.clearButtonMode = UITextFieldViewMode.whileEditing;
        sampleTextField.contentVerticalAlignment = UIControlContentVerticalAlignment.center
        sampleTextField.delegate = self
        self.view.addSubview(sampleTextField)
        
        let label_y: CGFloat = 305
        let label_width: CGFloat = 300
        let label_height: CGFloat = 20
        let label_x: CGFloat = (self.view.frame.width - label_width) / 2.0
        let changeLabel = UILabel(frame: CGRect(x: label_x, y: label_y, width: label_width, height: label_height))
        changeLabel.textColor = UIColor.gray
        changeLabel.backgroundColor = UIColor.clear
        changeLabel.text = "Change name"
        changeLabel.font = UIFont(name: "KohinoorTelugu-Light", size: 15)
        changeLabel.numberOfLines = 0
        changeLabel.textAlignment = .left
        self.view.addSubview(changeLabel)
        
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.nameLabel?.text = textField.text!
        UserDefaults.standard.set(textField.text!, forKey: "nameString")
        return true
    }
    
    func createChangeProfilePicButton() {
        let y: CGFloat = 405
        let width: CGFloat = 300
        let height: CGFloat = 33
        let x: CGFloat = (self.view.frame.width - width) / 2.0
        
        ChangePicButton = UIButton(frame: CGRect(x: x, y: y, width: width, height: height))
        ChangePicButton?.setTitle("Upload", for: .normal)
        ChangePicButton?.titleLabel?.font = UIFont(name: "KohinoorTelugu-Light", size: 17)
        ChangePicButton?.backgroundColor = UIColor.white
        ChangePicButton?.setTitleColor(UIColor.blue, for: .normal)
        ChangePicButton?.layer.cornerRadius = 5
        ChangePicButton?.layer.borderWidth = 1
        ChangePicButton?.layer.borderColor = UIColor.clear.cgColor
        ChangePicButton?.addTarget(self, action: #selector(self.changeProfilePic), for: .touchUpInside)
        self.view.addSubview(ChangePicButton!)
        
        let label_y: CGFloat = 380
        let label_width: CGFloat = 300
        let label_height: CGFloat = 20
        let label_x: CGFloat = (self.view.frame.width - label_width) / 2.0
        let changeLabel = UILabel(frame: CGRect(x: label_x, y: label_y, width: label_width, height: label_height))
        changeLabel.textColor = UIColor.gray
        changeLabel.backgroundColor = UIColor.clear
        changeLabel.text = "Change Profile Picture"
        changeLabel.font = UIFont(name: "KohinoorTelugu-Light", size: 15)
        changeLabel.numberOfLines = 0
        changeLabel.textAlignment = .left
        self.view.addSubview(changeLabel)
    }
    
    func createTakePhotoButton() {
        let y: CGFloat = 443
        let width: CGFloat = 300
        let height: CGFloat = 33
        let x: CGFloat = (self.view.frame.width - width) / 2.0
        
        takePhotoButton = UIButton(frame: CGRect(x: x, y: y, width: width, height: height))
        takePhotoButton?.setTitle("Take Photo", for: .normal)
        takePhotoButton?.titleLabel?.font = UIFont(name: "KohinoorTelugu-Light", size: 17)
        takePhotoButton?.backgroundColor = UIColor.white
        takePhotoButton?.setTitleColor(UIColor.blue, for: .normal)
        takePhotoButton?.layer.cornerRadius = 5
        takePhotoButton?.layer.borderWidth = 1
        takePhotoButton?.layer.borderColor = UIColor.clear.cgColor
        takePhotoButton?.addTarget(self, action: #selector(self.takePhoto), for: .touchUpInside)
        self.view.addSubview(takePhotoButton!)
    }
    
    @objc func takePhoto() {
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerControllerSourceType.camera
        image.allowsEditing = true
        self.present(image, animated: true) {
            //After it is complete
        }
    }
    
    @objc func changeProfilePic() {
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerControllerSourceType.photoLibrary
        image.allowsEditing = true
        self.present(image, animated: true) {
            //After it is complete
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            profilePic?.image = image
            let imageData: NSData = UIImagePNGRepresentation(image)! as NSData
            UserDefaults.standard.set(imageData, forKey: "profileImageData")
        } else {
            //Error message
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
}
