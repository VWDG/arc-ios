//
//  ARPlaneAnchorWriter.swift
//  ARC
//
//  Created by Tobias Schwandt on 05.09.22.
//


import Foundation
import ARKit
import Foundation.NSJSONSerialization

class ARPlaneAnchorWriter : WriterProtocol, AnchorProtocol {
    typealias T = ARPlaneAnchor
    
    private var dataArray: [Any] = []
    
    private var stream: OutputStream
    
    private var isStarted: Bool = false
    
    init(outputPath: URL) {
        let filePath = outputPath.appendingPathComponent("plane_anchor.json")
        
        self.stream = OutputStream(toFileAtPath: filePath.path, append: false)!
    }
    
    func startWriting() {
        stream.open()
        
        isStarted = true
    }
    
    func stopWriting() {
        stream.open()
        
        JSONSerialization.writeJSONObject(dataArray, to: stream, options: JSONSerialization.WritingOptions.prettyPrinted, error: nil)
        
        stream.close()
        
        isStarted = false
    }
    
    func write(_ anchor: T, frame: Int, status: AnchorStatus) -> Int {
        if (!isStarted) {
            return 1
        }
        
        do {            
            let data: [String: Any] = [
                "frame": frame,
                "name": anchor.name ?? "",
                "identifier": anchor.identifier.uuidString,
                "transform": anchor.transform.ToArray(),
                "center": anchor.center.ToArray(),
                "extent": anchor.extent.ToArray(),
                "alignment": anchor.alignment.rawValue,
                "classification": String(describing: anchor.classification),
                "status": status.rawValue
            ]
            
            // TODO: Save geometry
            // Can we do it in JSON? Might be an additional file like the env probe.
            
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

