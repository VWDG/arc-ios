//
//  Helper.swift
//  ARC
//
//  Created by Tobias Schwandt on 14.05.22.
//

import Foundation

extension URL {
    static var documents: URL {
        return FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
