//
//  VideoWriter.swift
//  ARC
//
//  Created by Tobias Schwandt on 14.05.22.
//

import AVFoundation
import AssetsLibrary
import os

class PixelBufferVideoWriter : WriterProtocol, FrameProtocol {
    typealias T = CVPixelBuffer
    
    enum Status {
        case initialized
        case writing
        case finished
        case unknown
    }
    
    var isRecording = false;
    var fileWriter: AVAssetWriter!
    var videoWriterInput: AVAssetWriterInput?
    var videoWriterPBAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    var timeScale: Int32!
    var writerStatus: Status = .unknown
    
    private var frameTime: CMTime
    
    init(outputPath: URL, fileName: String, fps: Int32) {
        fileWriter = try? AVAssetWriter(outputURL: outputPath.appendingPathComponent(fileName), fileType: AVFileType.mov)
        timeScale = fps
        frameTime = CMTime.zero
    }
    
    func startWriting() {
    }
    
    func stopWriting() {
        fileWriter.endSession(atSourceTime: frameTime)
        
        fileWriter.finishWriting {
            Logger().info("Finished writing pixel buffer video file.")
            
            self.writerStatus = .finished
        }
    }
    
    func write(_ pixelBuffer: T, frame: Int) -> Int {
        frameTime = CMTimeMake(value: Int64(frame), timescale: timeScale)
        
        if (writerStatus == .unknown || writerStatus == .finished) {
            initAV(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
            fileWriter.startWriting()
                    
            fileWriter.startSession(atSourceTime: frameTime)
        }
            
        videoWriterPBAdaptor?.append(pixelBuffer, withPresentationTime: frameTime);
        
        writerStatus = .writing
        
        return 0;
    }
    
    private func initAV(width: Int, height: Int) {
        let videoSettings: Dictionary<String, AnyObject> = [
            AVVideoCodecKey : AVVideoCodecType.h264 as AnyObject,
            AVVideoWidthKey : width as AnyObject,
            AVVideoHeightKey : height as AnyObject
        ];
        
        videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings);
        
        videoWriterInput?.expectsMediaDataInRealTime = true;
        
        videoWriterPBAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput!)
        
        fileWriter.add(videoWriterInput!);
        
        writerStatus = .initialized
    }
    
    func status() -> Int {
        if writerStatus == .finished {
            return 1
        } else {
            return 0
        }
    }
}
