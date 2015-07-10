//
//  ViewController.swift
//  QRCodeReader
//
//  Created by OOPer in cooperation with shlab.jp, on 2015/4/29.
//  Copyright (c) 2015 OOPer. All rights reserved. See LICENSE.txt .
//

import UIKit
import AVFoundation
import ImageIO

//rewrite this for your purpose
private let pattern = "^https?://(www\\.)?(oopers\\.com|shlab\\.jp)(/.*)?$"
private let INSENSITIVE_NANOS: Int64 = 3_000_000_000 //3 seconds

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    private let regex = try! NSRegularExpression(pattern: pattern, options: [])
    
    @IBOutlet var imagePreviewView: UIView!
    var stillImageOutput: AVCaptureStillImageOutput!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var openButton: UIButton!
    var updatable: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetMedium
        
        let captureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        captureVideoPreviewLayer.frame = self.imagePreviewView.bounds
        print(self.imagePreviewView.bounds)
        self.imagePreviewView.layer.addSublayer(captureVideoPreviewLayer)
        
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        let input: AVCaptureDeviceInput!
        do {
            input = try AVCaptureDeviceInput(device: device)
        } catch let error as NSError {
            fatalError("ERROR: trying to open camera: \(error)")
        }
        session.addInput(input)
        session.startRunning()

        let metaOutput = AVCaptureMetadataOutput()
        metaOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        session.addOutput(metaOutput)
        metaOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        
        self.updatable = true
        self.openButton.enabled = false
        
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {

        if !updatable {
            return
        }
        
        for metadata in metadataObjects {
            if let readableCode = metadata as? AVMetadataMachineReadableCodeObject
            where readableCode.type == AVMetadataObjectTypeQRCode {
                let strValue = readableCode.stringValue
                self.textField.text = strValue
                if regex.numberOfMatchesInString(strValue, options: [], range: NSRange(0..<strValue.utf16.count)) > 0 {
                    self.openButton.enabled = true
                    self.updatable = false
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, INSENSITIVE_NANOS), dispatch_get_main_queue()) {
                        self.updatable = true
                    }
                } else {
                    self.openButton.enabled = false
                }
            }
        }
    }

    @IBAction func openURL(_: AnyObject) {
        let urlStr = textField.text
        if let url = NSURL(string: urlStr!)
        where UIApplication.sharedApplication().canOpenURL(url) {
            UIApplication.sharedApplication().openURL(url)
        }
    }
}

