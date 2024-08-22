//
//  DataWriter.swift
//  ARC
//
//  Created by Tobias Schwandt on 16.05.22.
//

import Foundation
import ARKit
import Foundation.NSJSONSerialization

class LightEstimateWriter
{
    var path: URL
    var name: String
    
    private var frame: Int = 0
    
    private var dataArray: [Any] = []
    
    private var stream: OutputStream
    
    private var isStarted: Bool = false
    
    init(path: URL, name: String) {
        self.path = path
        self.name = name
        
        let filePath = path.appendingPathComponent(name)
        
        self.stream = OutputStream(toFileAtPath: filePath.path, append: false)!
    }
    
    func start() {
        frame = 0
        
        stream.open()
        
        isStarted = true
    }
    
    func stop() {
        stream.close()
        
        isStarted = false
    }
    
    func frame(data: ARLightEstimate) {
        if (!isStarted) {
            return
        }
        
        let data: [Any] = [[
            "frame": frame,
            "ambientIntensity": data.ambientIntensity,
            "ambientColorTemperature": data.ambientColorTemperature
        ]]
        
        JSONSerialization.writeJSONObject(data, to: stream, options: JSONSerialization.WritingOptions.prettyPrinted, error: nil)
        
        frame = frame + 1
    }
}
