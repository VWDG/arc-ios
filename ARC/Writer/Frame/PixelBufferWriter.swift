//
//  ImageWriter.swift
//  ARC
//
//  Created by Tobias Schwandt on 16.05.22.
//

import Foundation
import CoreVideo
import CoreImage

class PixelBufferWriter : WriterProtocol, FrameProtocol {
    typealias T = CVPixelBuffer
    
    var path: URL
    var name: String
    
    init(outputPath: URL, name: String) {
        self.path = outputPath
        self.name = name
    }
    
    func startWriting() {
    }
    
    func stopWriting() {
    }
    
    func write(_ image: CVPixelBuffer, frame: Int) -> Int {
        // Create frame folder in project
        let folderPath = path.appendingPathComponent(frame.description)
        
        do {
            try FileManager.default.createDirectory(atPath: folderPath.path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print(error.localizedDescription)
            return 1
        }
        
        // Get data
        let width  = CVPixelBufferGetWidth(image)
        let height = CVPixelBufferGetHeight(image)
        let dataSize = CVPixelBufferGetDataSize(image)
        
        var data = Data()
                       
        data.append(toByteArray(Int32(width)), count: 4)
        data.append(toByteArray(Int32(height)), count: 4)
        
        CVPixelBufferLockBaseAddress(image, CVPixelBufferLockFlags.readOnly)
        
        let pixelData = CVPixelBufferGetBaseAddressOfPlane(image, 0)
        
        data.append(pixelData!.assumingMemoryBound(to: UInt8.self), count: dataSize)
        
        CVPixelBufferUnlockBaseAddress(image, CVPixelBufferLockFlags.readOnly)
        
        // Save data as file
        let filePath = folderPath.appendingPathComponent(name)
        
        do {
            try data.write(to: filePath)
        }
        catch {
            print("Failed saving depth as raw in frame: " + frame.description)
            
            return 1
        }
        
        return 0
    }
    
    func status() -> Int {
        return 0
    }
}
