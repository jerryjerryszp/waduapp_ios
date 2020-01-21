//
//  ImageViewController.swift
//  Wadu
//
//  Created by Jerry Shi on 2018-05-30.
//  Copyright © 2018 Jerry Shi. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import AWSS3

class ImageViewController: UIViewController {
    
    let currentParty = CurrentParty.sharedPartyInfo
    let user = User.sharedUserInfo
    
    @IBOutlet weak var imageView: UIImageView!
    
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = image
        //upload()
        // Do any additional setup after loading the view.
    }

    @IBAction func dismissButton(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func saveButton(_ sender: Any) {
        guard let imageToSave = image else { return }
        UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil)
    }
    
    func uploadButtonPressed() {
        if self.image == nil {
            // Do something to wake up user :)
        } else {
            let image = self.image!
            let fileManager = FileManager.default
            let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("test3.jpeg")
            let imageData = UIImageJPEGRepresentation(image, 0)
            fileManager.createFile(atPath: path as String, contents: imageData, attributes: nil)
            
            let fileUrl = NSURL(fileURLWithPath: path)
            let uploadRequest = AWSS3TransferManagerUploadRequest()
            uploadRequest?.bucket = "<Your Bucket Name>"
            uploadRequest?.key = "<Image Name>"
            uploadRequest?.contentType = "image/jpeg"
            uploadRequest?.body = fileUrl as URL!
            uploadRequest?.serverSideEncryption = AWSS3ServerSideEncryption.awsKms
            uploadRequest?.uploadProgress = { (bytesSent, totalBytesSent, totalBytesExpectedToSend) -> Void in
                DispatchQueue.main.async(execute: {
                    //                    print("totalBytesSent",totalBytesSent)
                    //                    print("totalBytesExpectedToSend",totalBytesExpectedToSend)
                    
                    //                    self.amountUploaded = totalBytesSent // To show the updating data status in label.
                    //                    self.fileSize = totalBytesExpectedToSend
                })
            }
            
            let transferManager = AWSS3TransferManager.default()
            transferManager.upload(uploadRequest!).continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask<AnyObject>) -> Any? in
                if task.error != nil {
                    // Error.
                    print("error")
                } else {
                    // Do something with your result.
                    print("No error Upload Done")
                }
                return nil
            })
        }
    }
    
    func upload() {
        let imageData = UIImageJPEGRepresentation(self.image!, 0.001)
        if (imageData == nil) {
            print("UIImageJPEGRepresentation return nil")
            return
        }
        
        
        
        let strBase64 = imageData?.base64EncodedString(options: .endLineWithCarriageReturn)
        let fullBase64String = "data:image/jpg;base64,\(strBase64!)"
        //print(fullBase64String)
        
        print("\(strBase64)")
        
        let position = self.user.user_position
        let partyId = self.currentParty.current_party_id
        
        print("\(partyId!)-\(position!).jpg")
        //print("\(fullBase64String)")
        print("\(partyId!)")
        
        let url = URL(string: "\(self.user.globalURL)/upload")
    
        let parameters = ["fileName": "\(partyId!)-\(position!).jpg", "file":"\(strBase64!)", "partyId":"\(partyId!)"]
        
        //Alamofire.request(url: URL(string:"\(self.user.globalURL)/upload"), method: .POST, parameters: parameters, encoding: .JSON, headers: nil)
        
        Alamofire.request(url!, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil)
        

//        Alamofire.upload(multipartFormData: { multipartFormData in
//            if let data = UIImageJPEGRepresentation(self.image!, 0.1)?.base64EncodedData() {
//                multipartFormData.append(data, withName: "file")
//            }
//            //multipartFormData.append(imageData!, withName: "\(partyId!)-\(position!).jpg")
//            for (key,value) in parameters {
//                multipartFormData.append(value.data(using: .utf8)!, withName: key)
//            }
//        },
//            to: "\(self.user.globalURL)/upload",
//            encodingCompletion: { encodingResult in
//                switch encodingResult {
//                case .success(let upload, _, _):
//                    upload.responseJSON { response in
//                        debugPrint(response)
//                    }
//                case .failure(let encodingError):
//                    print(encodingError)
//                }
//        }
//        )
        
    }
}
