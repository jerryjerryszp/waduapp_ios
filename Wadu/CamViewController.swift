//
//  CamViewController.swift
//  Wadu
//
//  Created by Jerry Shi on 2018-05-25.
//  Copyright © 2018 Jerry Shi. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import JTMaterialTransition
import Alamofire
import SocketIO
import Starscream

struct Party {
    let id: String
    var master = [String]()
    var members = [String]()
    let name: String
    
    init(json: [String: Any]){
        id = json["id"] as? String ?? ""
        master = [json["master"] as? String ?? ""]
        members = [json["members"] as? String ?? ""]
        name = json["name"] as? String ?? ""
    }
}

protocol socketEvent {
    func socketConnection()
}

class CamViewController: UIViewController, UIViewControllerTransitioningDelegate, socketEvent {
    
    //global object
    let user = User.sharedUserInfo
    let currentParty = CurrentParty.sharedPartyInfo
    
    let manager = SocketManager(socketURL: URL(string: User.sharedUserInfo.globalURL)!, config: [.log(true), .compress])
    var socket: SocketIOClient!
    
    var captureSession = AVCaptureSession()
    
    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    var currentDevice: AVCaptureDevice?
    
    var photoOutput: AVCapturePhotoOutput?
    var cameraPreviewLayer:AVCaptureVideoPreviewLayer?
    
    var image: UIImage?
    
    var toggleCameraGestureRecognizer = UISwipeGestureRecognizer()
    
    var zoomInGestureRecognizer = UIPinchGestureRecognizer()
    var zoomOutGestureRecognizer = UISwipeGestureRecognizer()
    
    //user profile button setup

    weak var profileButton: UIButton?
    var transition_profile: JTMaterialTransition?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCaptureSession()
        setupDevice()
        setupInputOutput()
        setupPreviewLayer()
        captureSession.startRunning()
        
        //double tap to switch camera
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.switchCamera))
        tap.numberOfTapsRequired = 2
        view.addGestureRecognizer(tap)
        
        // Zoom In recognizer
        zoomInGestureRecognizer.scale = 0.5
        zoomInGestureRecognizer.addTarget(self, action: #selector(pinch(_:)))
        view.addGestureRecognizer(zoomInGestureRecognizer)
        
        //profile transition
        createProfileButton()
        self.transition_profile = JTMaterialTransition(animatedView: self.profileButton!)
        
        //connection transition
        createConnectionButton()
        self.transition_connection = JTMaterialTransition(animatedView: self.connectionButton!)
        
        becomeHost()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
            print(self.user.party_id!)
            self.socketConnection()
        })
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.promptChange), name: NSNotification.Name(rawValue: "masterchanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.captureYO), name: NSNotification.Name(rawValue: "takephoto"), object: nil)

        
        //takepicbutton?.addTarget(self, action: #selector(takepicbuttonaction), for: .touchUpInside)
    }
    
//    @objc func takepicbuttonaction(sender: UIButton!) {
//        captureYO()
//    }
    
    @objc func promptChange() {
        let alert = UIAlertController(title: "Master Changed", message: "master is \(self.user.masterName!)", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func createProfileButton () {
        
        let width: CGFloat = 25
        let height: CGFloat = 25
        let y: CGFloat = 39
        let x: CGFloat = 16
        
        let profileButton = UIButton(frame: CGRect(x: x, y: y, width: width, height: height))
        profileButton.layer.cornerRadius = width / 2.0
        profileButton.backgroundColor = UIColor.clear
        profileButton.setImage(UIImage(named: "profile"), for: .normal)
        profileButton.addTarget(self, action: #selector(self.bringUpProfileView), for: .touchUpInside)
        
        self.view.addSubview(profileButton)
        self.profileButton = profileButton
    }
    
    @objc func bringUpProfileView() {
        let controller = ProfileViewController()
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = self.transition_profile
        self.present(controller, animated: true, completion: nil)
    }
    
    
    
    //Connection Button setup
    weak var connectionButton: UIButton?
    var transition_connection: JTMaterialTransition?
    
    func createConnectionButton () {
        
        let width: CGFloat = 45
        let height: CGFloat = 45
        let y: CGFloat = 32
        let x: CGFloat = (self.view.frame.width - width) / 2.0
        
        let connectionButton = UIButton(frame: CGRect(x: x, y: y, width: width, height: height))
        connectionButton.layer.cornerRadius = width / 2.0
        connectionButton.backgroundColor = UIColor.clear
        connectionButton.setImage(UIImage(named: "connection"), for: .normal)
        connectionButton.addTarget(self, action: #selector(self.bringUpConnectionView), for: .touchUpInside)
        
        self.view.addSubview(connectionButton)
        self.connectionButton = connectionButton
    }
    
    @objc func bringUpConnectionView() {
        let controller = ConnectionViewController()
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = self.transition_connection
        self.present(controller, animated: true, completion: nil)
    }
    
    
    
    //camera button setup
    @IBOutlet weak var cameraButton: UIButton!
    
    @IBAction func captureButtonPress(_ sender: Any) {
        
        //self.socket.emit("shutter")
        
        if let currentuserid = self.user.user_current_id {
            if let currentmaster = self.currentParty.master {
                if currentuserid == currentmaster {
                    self.socket.emit("shutter")
                } else {
                    let alert = UIAlertController(title: "Can't take photo", message: "Only master can initiate capture event", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    @IBAction func switchCamButton(_ sender: Any) {
        self.switchCamera()
    }
    
    func becomeHost() {
        guard let url = URL(string: self.user.globalURL) else { return }
        let session = URLSession.shared
        session.dataTask(with: url) { (data, response, error) in
            if let response = response {
                print(response)
            }
            if let data = data {
                print(data)
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { return }
                    let party = Party(json: json)
                    self.user.party_id = party.id
                    self.user.party_name = party.name
                    
                    self.currentParty.current_party_id = party.id
                    self.currentParty.current_party_name = party.name
                    
                    print(party.id)
                    print(party.name)
                } catch {
                    print(error)
                }
            }
        }.resume()
    }
    
    //socket stuff for joining
    func socketConnection() {
        let namespace = "/\(self.user.party_id!)"
        print(namespace)
        
        socket = manager.socket(forNamespace: namespace)

        socket.on(clientEvent: .connect) {data, ack in
            print("socket connected")
            self.socket.emit("join")
            self.socket.emit("current-id")
        }
        socket.on("new-member") {data, ack in
            print("******************************* new-member")
            print(data)
            if let arr = data as? [[String: Any]] {
                if let partyid = arr[0]["id"] as? String {
                    print(partyid)
                    self.currentParty.current_party_id = partyid
                    self.user.party_id = partyid
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
                    //self.currentParty.memberCount = members.count
                    print("yo members")
                }
            }
        }
        
        socket.on("current-id") { data, ack in
            print("******************************* current-id")
            if let arr = data as? [String] {
                self.user.user_current_id = arr[0]
                print(arr[0])
            }
        }
        
        socket.on("onShutter") { data, ack in
            print("whatever")
            
            //self.captureYO()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "takephoto"), object: nil)

            //self.takepicbutton?.sendActions(for: .touchUpInside)

            
            
//            ImageViewController().image = UIApplication.shared.screenShot
//            self.performSegue(withIdentifier: "Preview_Segue", sender: self)
        }
        
        socket.connect()

    }
    
    @objc func captureYO() {
        let settings = AVCapturePhotoSettings()
        //self.photoOutput?.isLivePhotoCaptureEnabled = true
        if self.photoOutput != nil {
            self.photoOutput?.capturePhoto(with: settings, delegate: self as AVCapturePhotoCaptureDelegate)
        }
    }
    
    func styleCaptureButton() {
        cameraButton.layer.borderColor = UIColor.white.cgColor
        cameraButton.layer.borderWidth = 5
        cameraButton.clipsToBounds = true
        cameraButton.layer.cornerRadius = min(cameraButton.frame.width, cameraButton.frame.height) / 2
    }
    
    func setupCaptureSession() {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
    }
    
    func setupDevice() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        let devices = deviceDiscoverySession.devices
        
        for device in devices {
            if device.position == AVCaptureDevice.Position.back {
                backCamera = device
            } else if device.position == AVCaptureDevice.Position.front {
                frontCamera = device
            }
        }
        currentDevice = backCamera
    }
    
    func setupInputOutput() {
        do {
            
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentDevice!)
            captureSession.addInput(captureDeviceInput)
            photoOutput = AVCapturePhotoOutput()
            photoOutput?.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])], completionHandler: nil)
            captureSession.addOutput(photoOutput!)
            
            
        } catch {
            print(error)
        }
    }
    
    func setupPreviewLayer() {
        self.cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        self.cameraPreviewLayer?.frame = view.frame
        
        self.view.layer.insertSublayer(self.cameraPreviewLayer!, at: 0)
    }
    
    @objc func switchCamera() {
        //remove input and then add input
        captureSession.beginConfiguration()
        
        let newDevice = (currentDevice?.position == AVCaptureDevice.Position.back) ? frontCamera : backCamera
        
        for input in captureSession.inputs {
            captureSession.removeInput(input as! AVCaptureDeviceInput)
        }
        
        let cameraInput:AVCaptureDeviceInput
        do {
            cameraInput = try AVCaptureDeviceInput(device: newDevice!)
        } catch {
            print(error)
            return
        }
        
        if captureSession.canAddInput(cameraInput) {
            captureSession.addInput(cameraInput)
        }
        
        currentDevice = newDevice
        captureSession.commitConfiguration()
    }
    
    
    //pinch to zoom code
    let minimumZoom: CGFloat = 1.0
    let maximumZoom: CGFloat = 3.0
    var lastZoomFactor: CGFloat = 1.0
    
    @objc func pinch(_ pinch: UIPinchGestureRecognizer) {
        func minMaxZoom(_ factor: CGFloat) -> CGFloat {
            return min(min(max(factor, minimumZoom), maximumZoom), currentDevice!.activeFormat.videoMaxZoomFactor)
        }
        
        func update(scale factor: CGFloat) {
            do {
                try currentDevice?.lockForConfiguration()
                defer { currentDevice?.unlockForConfiguration() }
                currentDevice?.videoZoomFactor = factor
            } catch {
                print("\(error.localizedDescription)")
            }
        }
        
        let newScaleFactor = minMaxZoom(pinch.scale * lastZoomFactor)
        
        switch pinch.state {
        case .began: fallthrough
        case .changed: update(scale: newScaleFactor)
        case .ended:
            lastZoomFactor = minMaxZoom(newScaleFactor)
            update(scale: lastZoomFactor)
        default: break
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Preview_Segue" {
            let previewViewController = segue.destination as! ImageViewController
            previewViewController.image = self.image
            //self.upload()
        }
    }
    
    func upload() {
        let imageData = UIImageJPEGRepresentation(self.image!, 0.00001)
        if (imageData == nil) {
            print("UIImageJPEGRepresentation return nil")
            return
        }
        
        let strBase64 = imageData!.base64EncodedString(options: .endLineWithCarriageReturn)
        //let fullBase64String = "data:image/jpg;base64,\(strBase64)"
        
        let newDoto = strBase64.fromBase64()
        let position = self.user.user_position
        let partyId = self.currentParty.current_party_id
        
        let url = URL(string: "\(self.user.globalURL)/upload")
//
        let parameters = ["fileName": "\(partyId!)-\(position!).jpg", "file":"\(newDoto!)", "partyId":"\(partyId!)"]
//
        Alamofire.request(url!, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension CamViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation() {
            self.image = UIImage(data: imageData)
            performSegue(withIdentifier: "Preview_Segue", sender: nil)
        }
    }
}

extension UIApplication {
    var screenShot: UIImage? {
        return keyWindow?.layer.screenShot
    }
}

extension CALayer {
    
    var screenShot: UIImage?  {
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContext(frame.size)
        //UIGraphicsBeginImageCon
        if let context = UIGraphicsGetCurrentContext() {
            render(in: context)
            let screenshot = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return screenshot
        }
        return nil
    }
}

extension String {
    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
}

