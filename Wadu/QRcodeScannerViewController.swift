//
//  QRcodeScanner.swift
//  Wadu
//
//  Created by Jerry Shi on 2018-06-07.
//  Copyright © 2018 Jerry Shi. All rights reserved.
//

import UIKit
import AVFoundation
import SocketIO

class QRCodeScannerViewController: UIViewController {
    var socketDelegate: socketEvent?
    
    let currentParty = CurrentParty.sharedPartyInfo
    let user = User.sharedUserInfo
    let manager = SocketManager(socketURL: URL(string: User.sharedUserInfo.globalURL)!, config: [.log(true), .compress])
    var socket: SocketIOClient!
    
    var messageLabel: UILabel? = nil
    var dismissButton: UIButton?
    
    var captureSession = AVCaptureSession()
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    
    private let supportedCodeTypes = [AVMetadataObject.ObjectType.upce,
                                      AVMetadataObject.ObjectType.code39,
                                      AVMetadataObject.ObjectType.code39Mod43,
                                      AVMetadataObject.ObjectType.code93,
                                      AVMetadataObject.ObjectType.code128,
                                      AVMetadataObject.ObjectType.ean8,
                                      AVMetadataObject.ObjectType.ean13,
                                      AVMetadataObject.ObjectType.aztec,
                                      AVMetadataObject.ObjectType.pdf417,
                                      AVMetadataObject.ObjectType.itf14,
                                      AVMetadataObject.ObjectType.dataMatrix,
                                      AVMetadataObject.ObjectType.interleaved2of5,
                                      AVMetadataObject.ObjectType.qr]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.black
        createCloseButton()
        createNameLabel()
        
        // Get the back-facing camera for capturing videos
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera], mediaType: AVMediaType.video, position: .back)
        
        guard let captureDevice = deviceDiscoverySession.devices.first else {
            print("Failed to get the camera device")
            return
        }
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Set the input device on the capture session.
            captureSession.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = supportedCodeTypes
            //            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }
        
        // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)
        
        // Start video capture.
        captureSession.startRunning()
        
        // Move the message label and top bar to the front
        view.bringSubview(toFront: messageLabel!)
        view.bringSubview(toFront: dismissButton!)
        
        // Initialize QR Code Frame to highlight the QR code
        qrCodeFrameView = UIView()
        
        if let qrCodeFrameView = qrCodeFrameView {
            qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
            qrCodeFrameView.layer.borderWidth = 2
            view.addSubview(qrCodeFrameView)
            view.bringSubview(toFront: qrCodeFrameView)
        }
    }
    
    func createCloseButton() {
        let y: CGFloat = 39
        let width: CGFloat = 20
        let height: CGFloat = 20
        let x: CGFloat = 16
        
        dismissButton = UIButton(frame: CGRect(x: x, y: y, width: width, height: height))
        dismissButton?.setImage(UIImage(named: "cross"), for: .normal)
        dismissButton?.addTarget(self, action: #selector(self.didCloseButtonTouch), for: .touchUpInside)
        self.view.addSubview(dismissButton!)
    }
    
    @objc func didCloseButtonTouch () {
        self.dismiss(animated: true, completion: nil)
    }
    
    func createNameLabel() {
        let y: CGFloat = 25
        let width: CGFloat = 200
        let height: CGFloat = 50
        let x: CGFloat = (self.view.frame.width - width) / 2.0
        
        self.messageLabel = UILabel(frame: CGRect(x: x, y: y, width: width, height: height))
        self.messageLabel?.textColor = UIColor.white
        self.messageLabel?.backgroundColor = UIColor.clear
        self.messageLabel?.text = "Scan QR code"
        self.messageLabel?.font = UIFont(name: "KohinoorTelugu-Light", size: 17)
        self.messageLabel?.textAlignment = .center
        self.messageLabel?.numberOfLines = 0
        
        self.view.addSubview(self.messageLabel!)
    }
    
    func changeCurrentParty(decodedURL: String) {
        
        if presentedViewController != nil {
            return
        }
        
        let alertPrompt = UIAlertController(title: "Open App", message: "Join \(decodedURL)?", preferredStyle: .actionSheet)
        let confirmAction = UIAlertAction(title: "Confirm", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            print("========================")
            print("decodedURL \(decodedURL)")
            let namespace = "/\(decodedURL)"
            
            let swiftSocket = self.manager.socket(forNamespace: namespace)
            
            swiftSocket.on(clientEvent: .connect) {data, ack in
                swiftSocket.emit("join")

                swiftSocket.emit("current-id")
            }
            
            swiftSocket.on("new-member") {data, ack in
                if let arr = data as? [[String: Any]] {
                    if let partyid = arr[0]["id"] as? String {
                        //print(partyid)
                        self.currentParty.current_party_id = partyid
                        self.user.party_id = partyid
                        print("new party id from the QRscan view: \(self.user.party_id)")
                    }
                    if let partyname = arr[0]["name"] as? String {
                        print(partyname)
                        self.currentParty.current_party_name = partyname
                        self.user.party_name = partyname
                        
                    }
                    if let masterHead = arr[0]["master"] as? [String] {
                        print("master_head")
                        print(masterHead[0])
                        self.currentParty.master = masterHead[0]
                        self.user.masterName = masterHead[0]
                        if masterHead.count > 1 {
                            self.currentParty.memberCount = masterHead.count-1
                        } else {
                            self.currentParty.memberCount = masterHead.count
                        }
                    }
                    
                    if let members = arr[0]["members"] as? [String: AnyObject] {
                        print("members yo")
                        print(members)
//                        self.currentParty.memberCount = members.count
                        print("yo members")
                    }
                }
            }
            
            swiftSocket.on("current-id") { data, ack in
                print("******************************* current-id")
                if let arr = data as? [String] {
                    self.user.user_current_id = arr[0]
                    print(arr[0])
                }
            }
            swiftSocket.connect()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                self.captureSession.stopRunning()
                self.dismissButton?.sendActions(for: .touchUpInside)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "lol"), object: nil)
                CamViewController().socketConnection()
                //CamViewController().shutterEvent()
            })
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        
        alertPrompt.addAction(confirmAction)
        alertPrompt.addAction(cancelAction)
        
        present(alertPrompt, animated: true, completion: nil)
    }
}

extension QRCodeScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            messageLabel?.text = "No QR code is detected"
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if supportedCodeTypes.contains(metadataObj.type) {
            // If the found metadata is equal to the QR code metadata (or barcode) then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil {
                changeCurrentParty(decodedURL: metadataObj.stringValue!)
                messageLabel?.text = metadataObj.stringValue
                //self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
}
