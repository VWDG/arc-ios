//
//  JSON.swift
//  ARC
//
//  Created by Tobias Schwandt on 16.05.22.
//

import Foundation
import simd

extension Encodable {
    func toJSONString() -> String {
        let jsonData = try! JSONEncoder().encode(self)
        return String(data: jsonData, encoding: .utf8)!
    }
}

func instantiate<T: Decodable>(jsonString: String) -> T? {
    return try? JSONDecoder().decode(T.self, from: jsonString.data(using: .utf8)!)
}

extension simd_float4x4: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        try self.init(container.decode([SIMD4<Float>].self))
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode([columns.0,columns.1, columns.2, columns.3])
    }
    public func ToArray() -> Array<NSNumber> {
        var result: Array<NSNumber> = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]
        
        for i in 0...3 {
            for j in 0...3 {
                let index = j * 4 + i
                
                result[index] = NSNumber(value: self[j][i])
            }
        }
        
        return result
    }
}

extension simd_float3x3: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        try self.init(container.decode([SIMD3<Float>].self))
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode([columns.0,columns.1, columns.2])
    }
    func ToArray() -> Array<NSNumber> {
        var result: Array<NSNumber> = [1, 0, 0, 0, 1, 0, 0, 0, 1]
        
        for i in 0...2 {
            for j in 0...2 {
                let index = j * 3 + i
                
                result[index] = NSNumber(value: self[j][i])
            }
        }
        
        return result
    }
}

extension simd_float3: Codable {
    func ToArray() -> Array<NSNumber> {
        var result: Array<NSNumber> = [1, 0, 0]
        
        result[0] = NSNumber(value: self[0])
        result[1] = NSNumber(value: self[1])
        result[2] = NSNumber(value: self[2])
        
        return result
    }
}
