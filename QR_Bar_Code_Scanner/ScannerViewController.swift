//
//  ViewController.swift
//  QR_Bar_Code_Scanner
//
//  Created by MunjurAlam on 15/9/25.
//

// Controllers/ScannerViewController.swift
import AVFoundation
import MediaPlayer
import UIKit

/*
 QRCodeScannerController is ViewController which calls up method which presents view with AVCaptureSession and previewLayer
 to scan QR and other codes.
 */

final class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, UITextFieldDelegate {

    private let scannerView = ScannerView()
    private let session = AVCaptureSession()
    private let metadataOutput = AVCaptureMetadataOutput() // ← keep a property
    private var photoOutput = AVCapturePhotoOutput()
    private var isProcessing = false
    private var resetOverlayWorkItem: DispatchWorkItem?
    private var delCnt: Int = 0

    override func loadView() {
        view = scannerView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)

        scannerView.didCloseButtonTap = { [weak self] in
            self?.closeTapped()
        }
        scannerView.didTorchButtonTap = { [weak self] in
            self?.toggleTorch()
        }
        scannerView.manualButton.addTarget(self, action: #selector(typeCodeTapped), for: .touchUpInside)
        scannerView.textField.delegate = self
        
        checkPermissionsAndConfigure()
    }

    // ⚠️ ROI depends on previewLayer frame → update it after layout
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Update the ROI now that layout is ready
        updateRectOfInterestToDefault()

        // Start session only if not already running
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning { session.stopRunning() }
        setTorch(isON: false)
    } 

    // MARK: - Permissions + session

    private func checkPermissionsAndConfigure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: configureSession()
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    DispatchQueue.main.async {
                        granted ? self?.configureSession() : self?.showCameraDenied()
                    }
                }
            default: showCameraDenied()
        }
    }

    // MARK: - Configuration

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return showError("Unable to access the camera.")
        }
        session.addInput(input)

        guard session.canAddOutput(metadataOutput), session.canAddOutput(photoOutput) else {
            session.commitConfiguration()
            return showError("Unable to read codes from camera.")
        }
        session.addOutput(metadataOutput)
        session.addOutput(photoOutput)

        let wanted: [AVMetadataObject.ObjectType] = [
            .qr, .aztec, .dataMatrix, .pdf417,
            .code128, .code39, .code39Mod43, .code93,
            .ean13, .ean8, .interleaved2of5, .itf14, .upce
        ]
        metadataOutput.metadataObjectTypes = wanted.filter { metadataOutput.availableMetadataObjectTypes.contains($0) }
        metadataOutput.setMetadataObjectsDelegate(self, queue: .main)

        scannerView.previewLayer.session = session
        session.commitConfiguration()
    }

    private func updateRectOfInterestToDefault() {
        // Ensure preview layer frame is non-zero
        guard scannerView.previewLayer.bounds.width > 0 else { return }

        let defaultLayerRect = scannerView.overlay.defaultRect
        let interest = scannerView.previewLayer.metadataOutputRectConverted(fromLayerRect: defaultLayerRect)
        metadataOutput.rectOfInterest = interest
    }

    private func showCameraDenied() {
        let a = UIAlertController(
            title: "Camera Access Needed",
            message: "Enable camera access in Settings to scan codes.",
            preferredStyle: .alert
        )
        a.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        a.addAction(UIAlertAction(title: "Open Settings", style: .default, handler: { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
        }))
        present(a, animated: true)
    }

    // MARK: - Delegate

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {

        // Resize overlay to the detected code every frame
        //        if let raw = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
        //           let transformed = scannerView.previewLayer.transformedMetadataObject(for: raw) {
//
        //            let padded = transformed.bounds.insetBy(dx: -16, dy: -16)
        //            let clamped = padded.intersection(scannerView.bounds)
        //            scannerView.overlay.animate(to: clamped, animated: true)
//
        //            // Keep engine focused around same region
        //            let roi = scannerView.previewLayer.metadataOutputRectConverted(fromLayerRect: clamped)
        //            metadataOutput.rectOfInterest = roi
        //        } else {
        //            // Optional: if nothing visible for a while, reset overlay back to default
        //            scheduleOverlayReset(after: 0.6)
        //        }

        Task {
            // Handle successful scan once
            guard !self.isProcessing,
                  let code = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let value = code.stringValue else { return }
            self.isProcessing = true
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            // cancel a pending reset while we show the result
            resetOverlayWorkItem?.cancel()

            // Store last frame
            self.captureLastFrame()

            DispatchQueue.main.async {
                FullscreenLoader.shared.show(on: self.view)
                self.scannerView.setState(.found)
            }

            if true {
                DispatchQueue.main.async {
                    FullscreenLoader.shared.hide()
                    self.scannerView.setState(.result)
                    self.presentQRResultPopup()
                }
            } else {
                DispatchQueue.main.async {
                    FullscreenLoader.shared.hide()
                    self.scannerView.setState(.invalid)
                    self.presentInvalidPopup(message: "Invalid QR code")
                }
            }
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("Return key tapped")

        DispatchQueue.main.async {
            self.scannerView.setState(.result)
            self.presentQRResultPopup()
        }
        textField.resignFirstResponder() // hides keyboard
        return true
    }

    // MARK: - UI

    private func presentInvalidPopup(message: String) {
        
    }

    private func presentQRResultPopup() {
        
    }

    private func showError(_ message: String) {
        let a = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        if scannerView.currentState == .manual {
            scannerView.setState(.idle)
            isProcessing = false
        } else if let nav = navigationController, nav.viewControllers.first != self {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc private func typeCodeTapped() {
        isProcessing = true
        scannerView.setState(.manual)

        // Store the current frame
        captureLastFrame()
    }

    @objc private func toggleTorch() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        setTorch(isON: !device.isTorchActive)
    }

    private func setTorch(isON: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = isON ? .on : .off
            scannerView.torchButton.setImage(image: isON ? UIImage.Quore.icon_flash_on ?? UIImage() : UIImage.Quore.icon_flash_off ?? UIImage())
            device.unlockForConfiguration()
        } catch {}
    }

    // Capture last frame as image when needed (e.g., when the QR code is detected)
    private func captureLastFrame() {
        // Lower the system volume to mute the shutter sound (workaround)
        muteAudioSession(true)

        guard let connection = photoOutput.connection(with: .video) else { return }
        connection.videoOrientation = .portrait

        // Capture the photo
        let settings = AVCapturePhotoSettings()
        setTorch(isON: false)
        scannerView.torchButton.setImage(image: UIImage.Quore.icon_flash_off ?? UIImage())

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // When camera sees no code for a short time, return overlay to default
    private func scheduleOverlayReset(after delay: TimeInterval = 0.6) {
        resetOverlayWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.scannerView.overlay.animate(to: nil, animated: true)
            self.updateRectOfInterestToDefault()
        }
        resetOverlayWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }
}

// mute volume of photo capture
extension ScannerViewController: AVCapturePhotoCaptureDelegate {

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            return
        }
        // Restore volume after photo capture
        muteAudioSession(false)

        // Get the photo as a UIImage
        if let imageData = photo.fileDataRepresentation(),
           let capturedImage = UIImage(data: imageData) {
            // Show the last frame
            scannerView.generatedQRImageView.image = capturedImage
        }
    }

    // Method to mute/unmute the system volume
    func muteAudioSession(_ mute: Bool) {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            if mute {
                try audioSession.setCategory(.playback, mode: .default, options: .duckOthers)
                try audioSession.setActive(true)
            } else {
                try audioSession.setActive(false)
            }
        } catch {
            print("Error setting audio session: \(error.localizedDescription)")
        }
    }
}

///Currently Scanner suppoerts only portrait mode.
///This makes sure orientation is portrait
extension ScannerViewController {
    //Make orientations to portrait
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIInterfaceOrientation.portrait
    }
}
