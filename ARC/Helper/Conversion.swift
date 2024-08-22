//
//  Conversion.swift
//  ARC
//
//  Created by Tobias Schwandt on 16.05.22.
//

func toByteArray<T>(_ value: T) -> [UInt8] {
    var value = value
    return withUnsafePointer(to: &value) {
        $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<T>.size) {
            Array(UnsafeBufferPointer(start: $0, count: MemoryLayout<T>.size))
        }
    }
}
