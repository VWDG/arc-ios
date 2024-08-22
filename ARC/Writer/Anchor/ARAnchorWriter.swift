//
//  ARAnchorWriter.swift
//  ARC
//
//  Created by Tobias Schwandt on 23.05.22.
//

import Foundation
import ARKit
import Foundation.NSJSONSerialization

class ARAnchorWriter : WriterProtocol, AnchorProtocol {
    typealias T = ARAnchor
    
    private var dataArray: [Any] = []
    
    private var stream: OutputStream
    
    private var isStarted: Bool = false
    
    init(outputPath: URL) {
        let filePath = outputPath.appendingPathComponent("anchor.json")
        
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
                "status": status.rawValue
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
