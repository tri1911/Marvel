//
//  MarvelRequest+CharacterInfo.swift
//  Marvel
//
//  Created by Elliot Ho.
//

import Foundation

struct CharacterInfo: Codable, Identifiable, Hashable {
    let id: Int // The unique ID of the character resource
    let name: String // The name of the character
    let description: String // A short bio or description of the character
    let modified: String // The date the resource was most recently modified
    let urls: [MarvelURL] // A set of public web site URLs for the resource
    let thumbnail: MarvelImage // The representative image for this character
    
    var description_: String { description.isEmpty ? "Default Description for Character" : description }
    
    static func == (lhs: CharacterInfo, rhs: CharacterInfo) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct MarvelURL: Codable, Hashable {
    let type: String // A text identifier for the URL
    let url: String // A full URL (including scheme, domain, and path)
    
    var url_: URL? { URL(string: "https\(url.dropFirst(4))") }
}

struct MarvelImage: Codable, Hashable {
    let path: String // The directory path of to the image
    let `extension`: String // The file extension for the image
    
    var url: URL? { URL(string: "https\(path.dropFirst(4)).\(`extension`)") }
}

// TODO: OrderBy enum
struct CharacterFilter: MarvelFilter {
    typealias Request = CharacterInfoRequest
    typealias CardView = CharacterCardView
    var name: String?
    var nameStartsWith: String? // Searching parameter
    var modifiedSince: String?
    var comicId: Int?
    var seriesId: Int?
    var eventId: Int?
    var storyId: Int?
    var orderBy: String?
}

final class CharacterInfoRequest: MarvelRequest<CharacterFilter, CharacterInfo>, InfoRequest {
    
    static var requests = [CharacterFilter:CharacterInfoRequest]()
    
    override var query: String {
        var request = "characters?"
        request.addMarvelArgument("name", filter?.name)
        request.addMarvelArgument("nameStartsWith", filter?.nameStartsWith)
        request.addMarvelArgument("modifiedSince", filter?.modifiedSince)
        request.addMarvelArgument("comics", filter?.comicId)
        request.addMarvelArgument("series", filter?.seriesId)
        request.addMarvelArgument("events", filter?.eventId)
        request.addMarvelArgument("stories", filter?.storyId)
        request.addMarvelArgument("orderBy", filter?.orderBy)
        request.addMarvelArgument("limit", max(1, min(limit, 100)))
        request.addMarvelArgument("offset", offset)
        return request
    }
}
