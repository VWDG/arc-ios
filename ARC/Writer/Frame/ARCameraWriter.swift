//
//  CameraWriter.swift
//  ARC
//
//  Created by Tobias Schwandt on 16.05.22.
//

import Foundation
import ARKit
import Foundation.NSJSONSerialization

class ARCameraWriter : WriterProtocol, FrameProtocol
{
    typealias T = ARCamera
    
    var path: URL
    var name: String
    
    private var dataArray: [Any] = []
    
    private var stream: OutputStream
    
    private var isStarted: Bool = false
    
    init(path: URL, name: String) {
        self.path = path
        self.name = name
        
        let filePath = path.appendingPathComponent(name)
        
        self.stream = OutputStream(toFileAtPath: filePath.path, append: false)!
    }
    
    func startWriting() {
        
        
        isStarted = true
    }
    
    func stopWriting() {
        stream.open()
        
        JSONSerialization.writeJSONObject(dataArray, to: stream, options: JSONSerialization.WritingOptions.prettyPrinted, error: nil)
        
        stream.close()
        
        isStarted = false
    }
    
    func write(_ data: ARCamera, frame: Int) -> Int {
        if (!isStarted) {
            return 1
        }
        
        do {
            let scene = UIApplication.shared.connectedScenes.first
            let windowScene = scene as? UIWindowScene
            
            let orientation = windowScene?.interfaceOrientation
            
            let viewMatrix = data.viewMatrix(for: orientation!)
            let projectionMatrix = data.projectionMatrix
            
            let data: [String: Any] = [
                "frame": frame,
                "viewMatrix": viewMatrix.ToArray(),
                "projectionMatrix": projectionMatrix.ToArray(),
                "transform": data.transform.ToArray(),
                "intrinsics": data.intrinsics.ToArray(),
                "orientation": orientation!.rawValue,
            ]
            
            dataArray.append(data)
        }
        catch {
            return 1
        }
        
        return 0
    }
    
    func status() -> Int {
        return 0
    }
}
