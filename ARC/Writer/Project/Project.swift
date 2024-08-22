//
//  Project.swift
//  ARC
//
//  Created by Tobias Schwandt on 16.05.22.
//

import Foundation
import CoreGraphics

class Project : Codable {
    public var name: String = ""
    public var description: String = ""
    public var sessionid: String = ""
    public var creationDate: Date = Date()
    public var numberOfFrames: Int = -1
    public var colorSize: CGSize = CGSize.zero
    public var depthSize: CGSize = CGSize.zero
    public var modelName: String = ""
    public var viewportSize: CGSize = CGSize.zero
    
    func path() -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        return documents.appendingPathComponent(uuid())
    }
    
    func uuid() -> String {
        return creationDate.ISO8601Format()
    }
}
