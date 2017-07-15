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
    //var stillImageOutput: AVCaptureStillImageOutput! //### not used...
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let session = AVCaptureSession()
        session.sessionPreset = .medium
        
        let captureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        captureVideoPreviewLayer.videoGravity = .resizeAspectFill
        captureVideoPreviewLayer.frame = self.imagePreviewView.bounds
        print(self.imagePreviewView.bounds)
        self.imagePreviewView.layer.addSublayer(captureVideoPreviewLayer)
        
        let device = AVCaptureDevice.default(for: .video)
        let input: AVCaptureDeviceInput!
        do {
            input = try AVCaptureDeviceInput(device: device!)
        } catch let error as NSError {
            fatalError("ERROR: trying to open camera: \(error)")
        }
        session.addInput(input)
        session.startRunning()

        let metaOutput = AVCaptureMetadataOutput()
        metaOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        session.addOutput(metaOutput)
        metaOutput.metadataObjectTypes = [.qr]
        
        self.updatable = true
        self.openButton.isEnabled = false
        
    }
    
    func metadataOutput(_ captureOutput: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {

        if !updatable {
            return
        }
        
        for metadata in metadataObjects {
            if
                let readableCode = metadata as? AVMetadataMachineReadableCodeObject,
                readableCode.type == .qr
            {
                let strValue = readableCode.stringValue
                self.textField.text = strValue
                if regex.numberOfMatches(in: strValue!, options: [], range: NSRange(0..<(strValue?.utf16.count)!)) > 0 {
                    self.openButton.isEnabled = true
                    self.updatable = false
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(INSENSITIVE_NANOS) / Double(NSEC_PER_SEC)) {
                        self.updatable = true
                    }
                } else {
                    self.openButton.isEnabled = false
                }
            }
        }
    }

    @IBAction func openURL(_: Any) {
        let urlStr = textField.text
        if
            let url = URL(string: urlStr!),
            UIApplication.shared.canOpenURL(url)
        {
            UIApplication.shared.openURL(url)
        }
    }
}

