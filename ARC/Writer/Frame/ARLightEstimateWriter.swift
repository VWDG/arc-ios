//
//  LightEstimateWriter.swift
//  ARC
//
//  Created by Tobias Schwandt on 16.05.22.
//

import Foundation
import ARKit
import Foundation.NSJSONSerialization

class ARLightEstimateWriter : WriterProtocol, FrameProtocol
{
    typealias T = ARLightEstimate
    
    var path: URL
    var name: String
    
    private var dataArray: [Any] = []
    
    private var stream: OutputStream
    
    private var isStarted: Bool = false
    
    init(outputPath: URL, name: String) {
        self.path = outputPath
        self.name = name
        
        let filePath = outputPath.appendingPathComponent(name)
        
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
    
    func write(_ data: ARLightEstimate, frame: Int) -> Int {
        if (!isStarted) {
            return 1
        }
        
        let data: [String: Any] = [
            "frame": frame,
            "ambientIntensity": data.ambientIntensity,
            "ambientColorTemperature": data.ambientColorTemperature
        ]
        
        dataArray.append(data)
        
        return 0
    }
    
    func status() -> Int {
        return 0
    }
}
