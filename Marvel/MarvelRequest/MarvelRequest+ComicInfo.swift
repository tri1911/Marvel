//
//  MarvelRequest+ComicInfo.swift
//  Marvel
//
//  Created by Elliot Ho.
//

import Foundation

struct ComicInfo: Codable, Identifiable, Hashable {
    let id: Int // The unique ID of the comic resource
    let title: String // The canonical title of the comic
    let description: String? // The preferred description of the comic
    let modified: String // The date the resource was most recently modified
    let isbn: String // The ISBN for the comic (generally only populated for collection formats)
    let format: String // The publication format of the comic e.g. comic, hardcover, trade paperback
    let pageCount: Int // The number of story pages in the comic
    let urls: [MarvelURL] // A set of public web site URLs for the resource
    let thumbnail: MarvelImage // The representative image for this comic
    let images: [MarvelImage] // A list of promotional images associated with this comic
    
    // MARK: - Syntactic Sugar
    
    var description_: String { description != nil ? description! : "Default Description for Comic" }
    
    static func == (lhs: ComicInfo, rhs: ComicInfo) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct ComicFilter: MarvelFilter {
    typealias Request = ComicInfoRequest
    typealias CardView = ComicCardView
    var format: Format?
    var formatType: FormatType?
    var dateDescriptor: DateDescriptor?
    var title: String?
    var titleStartsWith: String? // Searching parameter
    var startYear: Int?
    var isbn: String?
    var hasDigitalIssue: Bool?
    var modifiedSince: String?
    var creatorId: Int?
    var characterId: Int?
    var seriesId: Int?
    var eventId: Int?
    var storyId: Int?
    var orderBy: String?
    
    enum Format: String, CaseIterable, Identifiable {
        case comic
        case magazine
        case tradePaperback = "trade%20paperback"
        case hardcover
        case digest
        case graphicNovel = "graphic%20novel"
        case digitalComic = "digital%20comic"
        case infiniteComic = "infinite%20comic"
        var id: String { self.rawValue }
        var title: String { self.rawValue.capitalized.replacingOccurrences(of: "%20", with: " ") }
    }
    
    enum FormatType: String, CaseIterable {
        case comic, collection
    }
    
    enum DateDescriptor: String {
        case lastWeek, thisWeek, nextWeek, thisMonth
    }
    
    enum OrderBy: String {
        case focDate, _focDate = "-focDate"
        case onsaleDate, _onsaleDate = "-onsaleDate"
        case title, _title = "-title"
        case issueNumber, _issueNumber = "-issueNumber"
    }
}

final class ComicInfoRequest: MarvelRequest<ComicFilter, ComicInfo>, InfoRequest {
    
    static var requests = [ComicFilter:ComicInfoRequest]()
    
    override var query: String {
        var request = "comics?"
        request.addMarvelArgument("format", filter?.format?.rawValue)
        request.addMarvelArgument("formatType", filter?.formatType?.rawValue)
        request.addMarvelArgument("dateDescriptor", filter?.dateDescriptor?.rawValue)
        request.addMarvelArgument("title", filter?.title)
        request.addMarvelArgument("titleStartsWith", filter?.titleStartsWith)
        request.addMarvelArgument("startYear", filter?.startYear)
        request.addMarvelArgument("isbn", filter?.isbn)
        if let hasDigitalIssue = filter?.hasDigitalIssue {
            request.addMarvelArgument("hasDigitalIssue", String(hasDigitalIssue))
        }
        request.addMarvelArgument("modifiedSince", filter?.modifiedSince)
        request.addMarvelArgument("creators", filter?.creatorId)
        request.addMarvelArgument("characters", filter?.characterId)
        request.addMarvelArgument("series", filter?.seriesId)
        request.addMarvelArgument("events", filter?.eventId)
        request.addMarvelArgument("stories", filter?.storyId)
        request.addMarvelArgument("orderBy", filter?.orderBy)
        request.addMarvelArgument("limit", max(1, min(limit, 100)))
        request.addMarvelArgument("offset", offset)
        return request
    }
}
