//
//  CameraViewController.swift
//  TestCamera
//
//  Created by Florin Baincescu on 18/02/2020.
//  Copyright © 2020 Florin Baincescu. All rights reserved.
//

import UIKit
import Photos
import CoreMotion

protocol CameraDelegate: class {
    func closeCamera(savePhotos: Bool, photos: [CameraPhoto])
}

class CameraViewController: UIViewController, ModalRotation {
    
    @IBOutlet fileprivate var captureButton: UIButton!
    @IBOutlet fileprivate var capturePreviewView: UIView!
    @IBOutlet fileprivate var toggleCameraButton: UIButton!
    @IBOutlet fileprivate var toggleFlashButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    
    var orientationLast = UIApplication.shared.statusBarOrientation
    var motionManager: CMMotionManager?
    
    let cameraController = CameraController()
    weak var delegate: CameraDelegate?
    var cameraPhotos: [CameraPhoto] = []
    var model: GalleryPhotosModel!
    
    //MARK: - Cycle Life View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        captureButton.layer.borderColor = UIColor.black.cgColor
        captureButton.layer.borderWidth = 2
        captureButton.layer.cornerRadius = min(captureButton.frame.width, captureButton.frame.height) / 2
        
        cameraController.prepare { [weak self] (error) in
            guard let sSelf = self else { return }
            if let error = error {
                print(error)
            }
            try? sSelf.cameraController.displayPreview(on: sSelf.capturePreviewView)
        }
        self.setNeedsStatusBarAppearanceUpdate()
        initializeMotionManager()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { [weak self] (context) -> Void in
            guard let sSelf = self else { return }
            sSelf.cameraController.changeOrientation(on: sSelf.capturePreviewView)
        }, completion: { (context) -> Void in
            
        })
        super.viewWillTransition(to: size, with: coordinator)
        
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
      return .lightContent
    }
    
    //MARK: - IBActions
    
    @IBAction func doneButtonPressed(_ sender: UIButton) {
        delegate?.closeCamera(savePhotos: true, photos: cameraPhotos)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func closeButtonPressed(_ sender: UIButton) {
        delegate?.closeCamera(savePhotos: false, photos: cameraPhotos)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func toggleFlash(_ sender: UIButton) {
        if cameraController.flashMode == .on {
            cameraController.flashMode = .off
            toggleFlashButton.setImage(#imageLiteral(resourceName: "Flash Off Icon"), for: .normal)
        } else {
            cameraController.flashMode = .on
            toggleFlashButton.setImage(#imageLiteral(resourceName: "Flash On Icon"), for: .normal)
        }
    }
    
    @IBAction func switchCameras(_ sender: UIButton) {
        do {
            try cameraController.switchCameras()
        } catch {
            print(error)
        }
        switch cameraController.currentCameraPosition {
        case .some(.front):
            toggleCameraButton.setImage(#imageLiteral(resourceName: "Front Camera Icon"), for: .normal)
        case .some(.rear):
            toggleCameraButton.setImage(#imageLiteral(resourceName: "Rear Camera Icon"), for: .normal)
        case .none:
            return
        }
    }
    
    @IBAction func captureImage(_ sender: UIButton) {
        if model.shouldTakeAnyPhotos(cameraPhotos) == false {
            self.showAlertView()
            return
        }
        self.capturePreviewView.alpha = 0.4
        cameraController.captureImage { [weak self] (photo, error) in
            guard let sSelf = self else { return }
            guard let photo = photo else {
                print(error ?? "Image capture error")
                return
            }
            sSelf.capturePreviewView.alpha = 1.0
            
            if sSelf.cameraController.currentCameraPosition == .front {
                if sSelf.orientationLast == .landscapeRight {
                    sSelf.cameraPhotos.append(CameraPhoto(capture: photo, and: .landscapeLeft))
                } else if sSelf.orientationLast == .landscapeLeft {
                    sSelf.cameraPhotos.append(CameraPhoto(capture: photo, and: .landscapeRight))
                } else {
                    sSelf.cameraPhotos.append(CameraPhoto(capture: photo, and: sSelf.orientationLast))
                }
            } else {
                sSelf.cameraPhotos.append(CameraPhoto(capture: photo, and: sSelf.orientationLast))
            }
        }
    }
    
    //MARK: - Utils
    
    func showAlertView() {
        let alert = UIAlertController(title: "", message: model.warningText, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.dismiss(animated: true, completion: nil)

        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func initializeMotionManager() {
        motionManager = CMMotionManager()
        motionManager?.accelerometerUpdateInterval = 0.2
        motionManager?.gyroUpdateInterval = 0.2
        motionManager?.startAccelerometerUpdates(to: (OperationQueue.current)!, withHandler: { [weak self]
            (accelerometerData, error) -> Void in
            guard let sSelf = self else { return }
            if error == nil {
                sSelf.outputAccelertionData((accelerometerData?.acceleration)!)
            }
            else {
                print("\(error!)")
            }
        })
    }
    
    func outputAccelertionData(_ acceleration: CMAcceleration) {
        var orientationNew: UIInterfaceOrientation
        if acceleration.x >= 0.75 {
            orientationNew = .landscapeLeft
        }
        else if acceleration.x <= -0.75 {
            orientationNew = .landscapeRight
        }
        else if acceleration.y <= -0.75 {
            orientationNew = .portrait

        }
        else if acceleration.y >= 0.75 {
            orientationNew = .portraitUpsideDown
        }
        else {
            return
        }
        if orientationNew == orientationLast {
            return
        }
        orientationLast = orientationNew
    }
}
