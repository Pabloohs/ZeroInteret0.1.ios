//
//  Profile.swift
//  ZeroInteret0.1
//
//  Created by Vincent Grare on 01/02/2025.
//


import Foundation

struct Profile: Codable, Identifiable {
    let id: UUID
    let firstName: String?
    let lastName: String?
    let email: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email
    }
}
