//
//  ViewController.swift
//  ARC
//
//  Created by Tobias Schwandt on 13.05.22.
//

import UIKit
import RealityKit
import ARKit
import SwiftUI
import AVFoundation
import AssetsLibrary

protocol RecordViewControllerDelegate : AnyObject {
    func didDismissViewController(vc: UIViewController?)
}

class RecordViewController: UIViewController, ARSessionDelegate {
    
    weak var delegate: RecordViewControllerDelegate?
    
    // MARK: - Outlets
    
    @IBOutlet var arView: ARView!
    @IBOutlet var recordButton : UIButton!
    @IBOutlet var restartButton: UIButton!
    
    // MARK: - Settings

    @AppStorage("hideDebugViewOnRecord") var hideDebugViewOnRecord = false
    @AppStorage("showDebug") var showDebugVisualization = false
    @AppStorage("showFeaturePoints") var showFeaturePoints = false
    @AppStorage("showAnchorOrigins") var showAnchorOrigins = false
    @AppStorage("showAnchorGeometry") var showAnchorGeometry = false
    @AppStorage("showWorldOrigin") var showWorldOrigin = false
    @AppStorage("showStatistics") var showStatistics = false
    @AppStorage("hideDebugViewOnPlaceAnchor") var hideDebugViewOnPlaceAnchor = false
    @AppStorage("heightOfObjectAboveAnchor") var heightOfObjectAboveAnchor = 0.0
    
    // MARK: - Vars
    
    var colorStreamWriter: PixelBufferVideoWriter!
    var depthStreamWriter: PixelBufferWriter!
    var smoothDepthStreamWriter: PixelBufferWriter!
    var confidenceDepthStreamWriter: PixelBufferWriter!
    var confidenceSmoothDepthStreamWriter: PixelBufferWriter!
    var lightEstimationWriter: ARLightEstimateWriter!
    var cameraWriter: ARCameraWriter!
    var envProbeWriter: AREnvironmentProbeAnchorWriter!
    var planeAnchorWriter: ARPlaneAnchorWriter!
    var anchorWriter: ARAnchorWriter!
    
    var activeProject: Project!
    
    var frameCounter: Int = 0
    
    var isFirstRecordFrame: Bool = true
    
    // MARK: - Var functions
  
    var isRecording: Bool = false {
        didSet {
            if isRecording {
                recordButton.setImage(UIImage(systemName: "stop"), for: UIControl.State.normal)
                restartButton.isEnabled = false
                
                if hideDebugViewOnRecord {
                    hideDebugView()
                }
            }
            else {
                recordButton.setImage(UIImage(systemName: "record.circle"), for: UIControl.State.normal)
                restartButton.isEnabled = true
                
                showDebugView()
            }
        }
    }
    
    // MARK: - UI View Controller functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print ("Value = \(Float(heightOfObjectAboveAnchor))")
        
        // Set delegate to this class
        arView.session.delegate = self
        
        // Configuration by reseting session
        restartSession()
        
        // Add coaching overlay
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.center = view.center
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.activatesAutomatically = true
        view.addSubview(coachingOverlay)
        
        // Set debug options
        isRecording = false
        isFirstRecordFrame = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if isRecording {
            stopRecording()
        }
        
        delegate?.didDismissViewController(vc: self)
    }
    
    // MARK: - AR functions
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if !isRecording {
            return
        }
        
        if !isValid(frame: frame) {
            if isRecording {
                print("Abort recording because of invalid frame.")
                stopRecording()
            }
            return
        }
        
        var check: Int = 0
        
        check += colorStreamWriter.write(frame.capturedImage, frame: frameCounter)
        
        check += depthStreamWriter.write(frame.sceneDepth!.depthMap, frame: frameCounter)
        
        check += smoothDepthStreamWriter.write(frame.smoothedSceneDepth!.depthMap, frame: frameCounter)
        
        check += confidenceDepthStreamWriter.write(frame.sceneDepth!.confidenceMap.unsafelyUnwrapped, frame: frameCounter)
        
        check += confidenceSmoothDepthStreamWriter.write(frame.smoothedSceneDepth!.confidenceMap.unsafelyUnwrapped, frame: frameCounter)
        
        check += lightEstimationWriter.write(frame.lightEstimate!, frame: frameCounter)
        
        check += cameraWriter.write(frame.camera, frame: frameCounter)
        
        if check != 0 {
            stopRecording()
            
            print("Error while capturing frame \(frameCounter). Recording stopped.")
            
            return
        }
        
        if isFirstRecordFrame {
            activeProject.colorSize = CGSize(
                width: CVPixelBufferGetWidth(frame.capturedImage),
                height: CVPixelBufferGetHeight(frame.capturedImage)
            )
            activeProject.depthSize = CGSize(
                width: CVPixelBufferGetWidth(frame.smoothedSceneDepth!.depthMap),
                height: CVPixelBufferGetHeight(frame.smoothedSceneDepth!.depthMap)
            )
        }
        
        isFirstRecordFrame = false
        
        frameCounter = frameCounter + 1
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        writeAnchor(anchors: anchors, frameCounter: frameCounter, status: .Add)
        
        for anchor in anchors where anchor.name ==  "Touch anchor"{
            let touchAnchor = AnchorEntity(anchor: anchor)
            
            touchAnchor.name = "Object"
            
            // Create metallic box
            let box      = MeshResource.generateBox(size: 0.2, cornerRadius: 0.0)
            let material = SimpleMaterial(color: .white, isMetallic: true)
            let entity   = ModelEntity(mesh: box, materials: [material])
            entity.transform.translation.y = Float(heightOfObjectAboveAnchor)
            
            touchAnchor.addChild(entity)
            
            // Add the box anchor to the scene
            arView.scene.anchors.append(touchAnchor)
            
            if hideDebugViewOnPlaceAnchor {
                hideDebugView()
            }
        }
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        writeAnchor(anchors: anchors, frameCounter: frameCounter, status: .Remove)
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        writeAnchor(anchors: anchors, frameCounter: frameCounter, status: .Update)
    }
    
    func writeAnchor(anchors: [ARAnchor], frameCounter: Int, status: AnchorStatus) {
        if !isRecording {
            return
        }
            
        for anchor in anchors {
            var check = 0
            
            if anchor is AREnvironmentProbeAnchor {
                check = envProbeWriter.write(anchor as! AREnvironmentProbeAnchor, frame: frameCounter, status: status)
            }
            else if anchor is ARPlaneAnchor {
                check = planeAnchorWriter.write(anchor as! ARPlaneAnchor, frame: frameCounter, status: status)
            }
            else {
                check = anchorWriter.write(anchor, frame: frameCounter, status: status)
            }
            
            if check != 0 {
                print("Error saving anchor \(anchor.debugDescription) in frame \(frameCounter). Recording stopped.")
                
                stopRecording()
                
                break
            }
        }
    }
    
    // MARK: - Logic
    
    func startRecording() {
        if isRecording {
            return
        }
        
        print("Start record.")
        
        // Load project
        activeProject = ProjectManager.shared.allocate()
        
        if activeProject == nil {
            print("Error creating project for recording.")
            return
        }
        
        // Save session information
        activeProject.sessionid = arView.session.identifier.uuidString
        
        // File
        let projectOutputPath = activeProject.path()
        
        // Frame writer
        colorStreamWriter = PixelBufferVideoWriter(outputPath: projectOutputPath, fileName: "color.mov", fps: 60)
        
        depthStreamWriter = PixelBufferWriter(outputPath: projectOutputPath, name: "depth.raw")
        
        smoothDepthStreamWriter = PixelBufferWriter(outputPath: projectOutputPath, name: "smooth_depth.raw")
        
        confidenceDepthStreamWriter = PixelBufferWriter(outputPath: projectOutputPath, name: "depth_conf.raw")
        
        confidenceSmoothDepthStreamWriter = PixelBufferWriter(outputPath: projectOutputPath, name: "smooth_depth_conf.raw")
        
        lightEstimationWriter = ARLightEstimateWriter(outputPath: projectOutputPath, name: "lightestimation.json")
        
        cameraWriter = ARCameraWriter(path: projectOutputPath, name: "camera.json")
        
        colorStreamWriter.startWriting()
        depthStreamWriter.startWriting()
        lightEstimationWriter.startWriting()
        cameraWriter.startWriting()
        
        // Anchor writer
        envProbeWriter = AREnvironmentProbeAnchorWriter(outputPath: projectOutputPath)
        
        planeAnchorWriter = ARPlaneAnchorWriter(outputPath: projectOutputPath)
        
        anchorWriter = ARAnchorWriter(outputPath: projectOutputPath)

        envProbeWriter.startWriting()
        planeAnchorWriter.startWriting()
        anchorWriter.startWriting()
        
        // Other
        frameCounter = 0
        
        isRecording = true
        isFirstRecordFrame = true
    }
    
    func stopRecording() {
        if !isRecording {
            return;
        }
        
        // Stop writer
        colorStreamWriter.stopWriting()
        depthStreamWriter.stopWriting()
        smoothDepthStreamWriter.stopWriting()
        confidenceDepthStreamWriter.stopWriting()
        confidenceSmoothDepthStreamWriter.stopWriting()
        lightEstimationWriter.stopWriting()
        cameraWriter.stopWriting()
        envProbeWriter.stopWriting()
        planeAnchorWriter.stopWriting()
        anchorWriter.stopWriting()
        
        // Save project information
        activeProject.numberOfFrames = frameCounter
        
        let check = ProjectManager.shared.save(project: activeProject)
        
        if check {
            print("Finished recording.")
        }
        
        isRecording = false
        
        // Close view
        navigationController?.popViewController(animated: true)

        dismiss(animated: true, completion: nil)
    }
    
    func restartSession() {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        
        if ARWorldTrackingConfiguration.supportsFrameSemantics(ARConfiguration.FrameSemantics.smoothedSceneDepth) {
            config.frameSemantics = [.smoothedSceneDepth, .sceneDepth]
        }
        
        config.environmentTexturing = .automatic
        
        config.worldAlignment = .gravityAndHeading
        
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors, .resetSceneReconstruction])
    }
    
    func isValid(frame: ARFrame) -> Bool {
        if frame.smoothedSceneDepth == nil {
            return false
        }
        
        if frame.sceneDepth == nil {
            return false
        }
        
        if frame.lightEstimate == nil {
            return false
        }
        
        return true
    }
    
    func hideDebugView() {
        arView.debugOptions = []
    }
    
    func showDebugView() {
        arView.debugOptions = []
        
        if showDebugVisualization {
            if showFeaturePoints {
                arView.debugOptions.insert(.showFeaturePoints)
            }
            if showAnchorOrigins {
                arView.debugOptions.insert(.showAnchorOrigins)
            }
            if showAnchorGeometry {
                arView.debugOptions.insert(.showAnchorGeometry)
            }
            if showWorldOrigin {
                arView.debugOptions.insert(.showWorldOrigin)
            }
        }
    }
    
    // MARK: - Interactions
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Get touch
        guard let touch = touches.first?.location(in: arView) else { return }
        
        // Create raycast
        guard let rayCast = arView.makeRaycastQuery(from: touch, allowing: .estimatedPlane, alignment: .horizontal) else { return }
        
        guard let result = arView.session.raycast(rayCast).first else { return }
        
        let newAnchor = ARAnchor(name: "Touch anchor", transform: result.worldTransform)
        
        arView.session.add(anchor: newAnchor)
    }
    
    // MARK: - Interface actions
    
    @IBAction func pressRecord(_ sender: UIButton) {
        if !isRecording {
            startRecording()
        }
        else {
            stopRecording()
        }
    }
    
    @IBAction func restartSessionAction(_ sender: UIButton) {
        restartSession()
    }
}
