//
//  WriterProtocol.swift
//  ARC
//
//  Created by Tobias Schwandt on 20.05.22.
//

enum AnchorStatus: Int {
    case Add = 0, Remove, Update
}

protocol WriterProtocol {
    func startWriting()
    func stopWriting()
    
    func status() -> Int
}

protocol FrameProtocol {
    associatedtype T
    
    func write(_:T, frame: Int) -> Int
}

protocol AnchorProtocol {
    associatedtype T
    
    func write(_:T, frame: Int, status: AnchorStatus) -> Int
}
