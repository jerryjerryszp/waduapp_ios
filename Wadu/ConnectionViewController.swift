//
//  ConnectionViewController.swift
//  Wadu
//
//  Created by Jerry Shi on 2018-06-01.
//  Copyright © 2018 Jerry Shi. All rights reserved.
//

import UIKit
import SocketIO

class ConnectionViewController: UIViewController, UIViewControllerTransitioningDelegate{
    
    let user = User.sharedUserInfo
    let currentParty = CurrentParty.sharedPartyInfo
    
    let manager = SocketManager(socketURL: URL(string: User.sharedUserInfo.globalURL)!, config: [.log(true), .compress])
    var socket: SocketIOClient!
    
    var nameLabel: UILabel? = nil
    var orLabel: UILabel? = nil
    var QRcode: UIImageView? = nil
    var filter:CIFilter!
    var joinButton: UIButton?
    var BeMaButton: UIButton?
    var memberCount: UILabel? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set connection view bg color
        self.view.backgroundColor = UIColor(displayP3Red: 1.0, green: 0.949, blue: 0.831, alpha: 1.0)
        
        createCloseButton()
        createNameLabel()
        
        self.nameLabel?.text = currentParty.current_party_name
        
        socketConnection()
        
        createQRcode()
        createOr()
        createJoinButton()
        createBecomeMasterButton()
        createMemberCountLabel()
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.didCloseButtonTouch), name: NSNotification.Name(rawValue: "lol"), object: nil)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        createQRcode()
        self.nameLabel?.text = currentParty.current_party_name
    }
    
    func socketConnection() {
        let namespace = "/\(self.user.party_id!)"
        
        socket = self.manager.socket(forNamespace: namespace)
        
        socket.on(clientEvent: .connect) {data, ack in
            //self.socket.emit("join")
            
            //self.socket.emit("current-id")
        }
        
        socket.on("request-master") { data, ack in
            print("yoooooooo change master")
            //data here is the socket id of the user thats requesting
            
            
            self.socket.emit("change-master", self.user.user_current_id!)
        }
        
        socket.on("change-master") { data, ack in
            if let arr = data as? [[String: Any]] {
                if let partyid = arr[0]["id"] as? String {
                    print(partyid)
                    self.currentParty.current_party_id = partyid
                }
                if let partyname = arr[0]["name"] as? String {
                    print(partyname)
                    self.currentParty.current_party_name = partyname
                }
                if let masterHead = arr[0]["master"] as? [String] {
                    print("master_head")
                    print(masterHead[0])
                    self.currentParty.master = masterHead[0]
                    //self.currentParty.memberCount = masterHead.count
                    if masterHead.count > 1 {
                        self.currentParty.memberCount = masterHead.count-1
                    } else {
                        self.currentParty.memberCount = masterHead.count
                    }

                }
                
                if let members = arr[0]["members"] as? [String: AnyObject] {
                    print("members yo")
                    print(members)
                    print("yo members")

                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    self.didCloseButtonTouch()
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "masterchanged"), object: nil)

                })
            }
        }
        socket.connect()
    }
    
    //close connection view
    func createCloseButton() {
        let y: CGFloat = 32
        let width: CGFloat = 45
        let height: CGFloat = 45
        let x: CGFloat = (self.view.frame.width - width) / 2.0
        
        let closeButton = UIButton(frame: CGRect(x: x, y: y, width: width, height: height))
        closeButton.setImage(UIImage(named: "connectionClose"), for: .normal)
        closeButton.addTarget(self, action: #selector(self.didCloseButtonTouch), for: .touchUpInside)
        self.view.addSubview(closeButton)
    }
    
    @objc func didCloseButtonTouch () {
        self.dismiss(animated: true, completion: nil)
    }
    
    func createNameLabel() {
        let y: CGFloat = 100
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
    
    func createQRcode() {
        let y: CGFloat = 165
        let width: CGFloat = 200
        let height: CGFloat = 200
        let x: CGFloat = (self.view.frame.width - width) / 2.0
        
        let text = self.currentParty.current_party_id
        let data = text?.data(using: .ascii, allowLossyConversion: false)
        filter = CIFilter(name: "CIQRCodeGenerator")
        filter.setValue(data, forKey: "inputMessage")
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let image = UIImage(ciImage: filter.outputImage!.transformed(by: transform))
        self.QRcode = UIImageView(image: image)
        self.QRcode?.frame = CGRect(x: x, y: y, width: width, height: height)
        self.QRcode?.contentMode = .scaleToFill
        self.view.addSubview(self.QRcode!)
    }
    
    func createOr() {
        let y: CGFloat = 377
        let width: CGFloat = 50
        let height: CGFloat = 25
        let x: CGFloat = (self.view.frame.width - width) / 2.0
        
        self.orLabel = UILabel(frame: CGRect(x: x, y: y, width: width, height: height))
        self.orLabel?.textColor = UIColor.black
        self.orLabel?.backgroundColor = UIColor.clear
        self.orLabel?.text = "OR"
        self.orLabel?.font = UIFont(name: "KohinoorTelugu-Light", size: 17)
        self.orLabel?.numberOfLines = 0
        self.orLabel?.textAlignment = .center
        self.view.addSubview(self.orLabel!)
    }
    
    func createJoinButton() {
        let y: CGFloat = 415
        let width: CGFloat = 200
        let height: CGFloat = 50
        let x: CGFloat = (self.view.frame.width - width) / 2.0
        
        self.joinButton = UIButton(frame: CGRect(x: x, y: y, width: width, height: height))
        joinButton?.setTitle("Join Party", for: .normal)
        joinButton?.titleLabel?.font = UIFont(name: "KohinoorTelugu-Light", size: 20)
        joinButton?.backgroundColor = UIColor.clear
        joinButton?.setTitleColor(UIColor.black, for: .normal)
        joinButton?.layer.cornerRadius = 5
        joinButton?.layer.borderWidth = 1
        joinButton?.layer.borderColor = UIColor.black.cgColor
        joinButton?.addTarget(self, action: #selector(self.joinParty), for: .touchUpInside)
        self.view.addSubview(joinButton!)
    }
    
    @objc func joinParty() {
        let controller = QRCodeScannerViewController()
        controller.modalPresentationStyle = UIModalPresentationStyle.overFullScreen

        self.present(controller, animated: true, completion: nil)
    }
    
    func createBecomeMasterButton() {
        let y: CGFloat = 475
        let width: CGFloat = 200
        let height: CGFloat = 50
        let x: CGFloat = (self.view.frame.width - width) / 2.0
        
        self.BeMaButton = UIButton(frame: CGRect(x: x, y: y, width: width, height: height))
        BeMaButton?.setTitle("Become Host", for: .normal)
        BeMaButton?.titleLabel?.font = UIFont(name: "KohinoorTelugu-Light", size: 20)
        BeMaButton?.backgroundColor = UIColor.clear
        BeMaButton?.setTitleColor(UIColor.black, for: .normal)
        BeMaButton?.layer.cornerRadius = 5
        BeMaButton?.layer.borderWidth = 1
        BeMaButton?.layer.borderColor = UIColor.black.cgColor
        BeMaButton?.addTarget(self, action: #selector(self.becomeMaster), for: .touchUpInside)
        self.view.addSubview(BeMaButton!)
    }
    
    @objc func becomeMaster() {
        if let currentuserid = self.user.user_current_id {
            if let currentmaster = self.currentParty.master {
                if currentuserid == currentmaster {
                    let alert = UIAlertController(title: "You are already the host", message: "Only clients can request to be the host", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    print("huahua")
                    self.socket.emit("request-master")
                }
            }
        }
    }
    
    func createMemberCountLabel() {
        let y: CGFloat = 540
        let width: CGFloat = 200
        let height: CGFloat = 50
        let x: CGFloat = (self.view.frame.width - width) / 2.0
        
        self.memberCount = UILabel(frame: CGRect(x: x, y: y, width: width, height: height))
        self.memberCount?.textColor = UIColor.black
        self.memberCount?.backgroundColor = UIColor.clear
        self.memberCount?.text = "Number of members in the party: \(self.currentParty.memberCount!)"
        self.memberCount?.font = UIFont(name: "KohinoorTelugu-Light", size: 17)
        self.memberCount?.numberOfLines = 0
        self.memberCount?.textAlignment = .center
        self.view.addSubview(self.memberCount!)
    }

}
