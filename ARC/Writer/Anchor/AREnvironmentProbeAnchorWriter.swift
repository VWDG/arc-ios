//
//  AREnvironmentProbeAnchorWriter.swift
//  ARC
//
//  Created by Tobias Schwandt on 17.05.22.
//

import Foundation
import ARKit

class AREnvironmentProbeAnchorWriter : WriterProtocol, AnchorProtocol {
    typealias T = AREnvironmentProbeAnchor
    
    var path: URL
    
    private var dataArray: [Any] = []
    
    private var stream: OutputStream
    
    private var isStarted: Bool = false
    
    private var textureRing: [MTLTexture?] = []
    
    private var textureRingIndexEnd: Int = 0
    
    private var textureRingIndexBegin: Int = 0
    
    private var isInitialized = false
    
    private var device: MTLDevice?
    
    private var commandQueue: MTLCommandQueue?
    
    private var commandBuffer: MTLCommandBuffer?
    
    private var blitEncoder: MTLBlitCommandEncoder?
    
    private let s_sizeOfRingBuffer: Int = 4
    
    private var dispatchQueue: DispatchQueue
    
    private let s_SaveDataAsRaw:Bool = true
    
    init(outputPath: URL) {
        self.path = outputPath
        
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device?.makeCommandQueue()
        
        dispatchQueue = DispatchQueue(label: "SaveRingBuffer")
        
        let filePath = outputPath.appendingPathComponent("env_probe.json")
        
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
    
    func write(_ data: T, frame: Int, status: AnchorStatus) -> Int {
        if (!isStarted) {
            return 1
        }
        
        // If a texture is available we save it
        // Attention: This is not true if only values are changing or the probe is added.
        if data.environmentTexture != nil {
            let targetTexture = data.environmentTexture!
            
            // On first frame initialize
            if !isInitialized {
                initialize(referenceTexture: targetTexture)
            }

            commandBuffer = commandQueue?.makeCommandBuffer()
            
            // Copy texture to ring
            blitEncoder = commandBuffer?.makeBlitCommandEncoder()
            blitEncoder?.copy(from: targetTexture, to: textureRing[textureRingIndexEnd % self.s_sizeOfRingBuffer]!)
            blitEncoder?.endEncoding()
            
            textureRingIndexEnd = textureRingIndexEnd + 1
            
            assert(textureRingIndexEnd - textureRingIndexBegin < s_sizeOfRingBuffer)
            
            // If copy is completed download data
            commandBuffer?.addCompletedHandler { _ in
                let activeFrame = frame - (self.textureRingIndexEnd - self.textureRingIndexBegin) + 1
                
                var pathToFrame = self.path.appendingPathComponent(activeFrame.description)
                
                pathToFrame.appendPathComponent(data.identifier.uuidString)
                
                self.saveCubemap(cubemap: self.textureRing[self.textureRingIndexBegin % self.s_sizeOfRingBuffer]!, path: pathToFrame)
                
                self.textureRingIndexBegin = (self.textureRingIndexBegin + 1)
            }
            
            commandBuffer?.commit()
        }
        
        // Save information about the probe
        // This is always the case
        do {
            let data: [String: Any] = [
                "frame": frame,
                "name": ((data.name ?? "") as String),
                "identifier": data.identifier.description,
                "transform": data.transform.ToArray(),
                "extent": data.extent.ToArray(),
                "status": status.rawValue,
                "texture_update": data.environmentTexture != nil
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
    
    func initialize(referenceTexture: MTLTexture) {
        textureRing.removeAll()
        
        let textureDescriptor = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: referenceTexture.pixelFormat, size: referenceTexture.width, mipmapped: false)
        
        for _ in 0..<s_sizeOfRingBuffer {
            textureRing.append(device?.makeTexture(descriptor: textureDescriptor))
        }
        
        textureRingIndexBegin = 0
        textureRingIndexEnd   = 0
        
        isInitialized = true
    }
    
    func saveCubemap(cubemap: MTLTexture, path: URL) {
        assert(cubemap.pixelFormat == .rgba16Float)

        // Get bytes of the cubemap
        let width = cubemap.width
        let height = cubemap.height
        let capacity = width * height * 4
        let pixelByteCount = 4 * MemoryLayout<Float16>.size
        let imageBytesPerRow = width * pixelByteCount
        let imageByteCount = imageBytesPerRow * height
        let imageBytes = UnsafeMutableRawPointer.allocate(byteCount: imageByteCount, alignment: pixelByteCount)
        defer {
            imageBytes.deallocate()
        }
        
        // Create sub folder for this environment map
        do {
            try FileManager.default.createDirectory(atPath: path.path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print(error.localizedDescription)
        }

        // Save each face as EXR
        for face in 0..<6 {
            // Get bytes
            cubemap.getBytes(imageBytes,
                             bytesPerRow: imageBytesPerRow,
                             bytesPerImage: imageByteCount,
                             from: MTLRegionMake2D(0, 0, width, height),
                             mipmapLevel: 0,
                             slice: face)
            
            // Rebind
            let unsafePointer = imageBytes.bindMemory(to: Float16.self, capacity: capacity)
            let unsafeBufferPointer = UnsafeMutableBufferPointer(start: unsafePointer, count: capacity)
            let imageData = Data(buffer: unsafeBufferPointer)
            
            if s_SaveDataAsRaw {
                let imageName = "envcubemap_\(face).raw"
                let pathToImage = path.appendingPathComponent(imageName)
                
                // Data
                var data = Data()
                               
                data.append(toByteArray(Int32(width)), count: 4)
                data.append(toByteArray(Int32(height)), count: 4)
                data.append(imageData)
                
                // Save data as file
                dispatchQueue.async { [data, pathToImage] in
                    // Save image as raw
                    do {
                        try data.write(to: pathToImage)
                    }
                    catch {
                        print("Failed writing face of a cubemap.")
                    }
                }
            }
            else {
                let imageName = "envcubemap_\(face).exr"
                let pathToImage = path.appendingPathComponent(imageName)
                
                let exrImg = MDLTexture(data: imageData,
                                        topLeftOrigin: true,
                                        name: imageName,
                                        dimensions: SIMD2<Int32>(Int32(width), Int32(height)),
                                        rowStride: width * MemoryLayout<Float16>.size,
                                        channelCount: 4,
                                        channelEncoding: MDLTextureChannelEncoding.float16,
                                        isCube: false)
                
                dispatchQueue.async { [exrImg, pathToImage] in
                    // Save image as exr
                    let status = exrImg.write(to: pathToImage)
                    
                    if(!status) {
                        print("Failed writing face of a cubemap.")
                    }
                }
            }
        }
    }
}
