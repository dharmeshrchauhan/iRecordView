//
//  ViewController.swift
//  iRecordView
//
//  Created by Devlomi on 08/20/2019.
//  Copyright (c) 2019 Devlomi. All rights reserved.
//

import UIKit
import iRecordView

class ViewController: UIViewController,RecordViewDelegate {
    
    func onStart() {
        stateLabel.text = "onStart"
        print("onStart")
    }
    
    func onCancel() {
        stateLabel.text = "onCancel"
        print("onCancel")
        sendButton.isHidden = true
        recordButton.isHidden = false
    }
    
    func onLock() {
        stateLabel.text = "onLock"
        print("onLock")
        recordButton.isHidden = true
        sendButton.isHidden = false
    }
    
    func onFinished(duration: CGFloat) {
        stateLabel.text = "onFinished duration: \(duration)"
        print("onFinished \(duration)")
        sendButton.isHidden = true
        recordButton.isHidden = false
    }
    
    func onAnimationEnd() {
        stateLabel.text = "onAnimation End"
        print("onAnimationEnd")
    }
    
    
    var recordButton:RecordButton!
    var recordView:RecordView!
    var stateLabel:UILabel!
    var sendButton:UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        recordButton = RecordButton()
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        
        recordView = RecordView()
        recordView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(recordButton)
        view.addSubview(recordView)

        recordButton.widthAnchor.constraint(equalToConstant: 35).isActive = true
        recordButton.heightAnchor.constraint(equalToConstant: 35).isActive = true

        recordButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8).isActive = true
        recordButton.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -16).isActive = true
        

        recordView.trailingAnchor.constraint(equalTo: recordButton.leadingAnchor, constant: -20).isActive = true
        recordView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        recordView.centerYAnchor.constraint(equalTo: recordButton.centerYAnchor).isActive = true
        recordButton.recordView = recordView

        recordView.delegate = self
        
        sendButton = UIButton()
        //sendButton.setTitle("✈", for: .normal)
        view.addSubview(sendButton)
        if #available(iOS 13.0, *) {
            sendButton.setImage(UIImage(systemName: "paperplane.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 35))
                                , for: .normal)
        } else {
            sendButton.setTitle("✈", for: .normal)
        }
        
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.widthAnchor.constraint(equalToConstant: 35).isActive = true
        sendButton.heightAnchor.constraint(equalToConstant: 35).isActive = true

        sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8).isActive = true
        sendButton.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -16).isActive = true
        sendButton.isHidden = true
        sendButton.addTarget(self, action: #selector(sendMessage), for: UIControl.Event.touchUpInside)

        stateLabel = UILabel()
        stateLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stateLabel)
        stateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        stateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        
        
    }
    
    @objc
    func sendMessage() {
        recordView.finishRecording(recordButton: recordButton)
    }

}

