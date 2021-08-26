//
//  UtilityViews.swift
//  Marvel
//
//  Created by Elliot Ho on 2021-08-20.
//

import SwiftUI
import Combine
import CoreData

protocol MarvelCardView: View {
    associatedtype Info
    init(_ info: Info)
}

protocol MarvelFilter: Hashable {
    associatedtype Request: InfoRequest where Self == Request.Filter
    associatedtype CardView: MarvelCardView where CardView.Info == Request.Info
}

protocol InfoRequest {
    associatedtype Filter: MarvelFilter
    associatedtype Info: Identifiable, Hashable
    
    static var requests: [Filter:Self] { get set }
    var results: CurrentValueSubject<[Info], Never> { get }
    init(_ filter: Filter, limit: Int?)
    func fetch(useCache: Bool)
}

extension InfoRequest {
    // A shared function that creates and saves a request class based on a specified filter.
    // If the request does not exist, we create a new request and save it into `requests` for the next reference.
    // Otherwise, it just returns the saved request (in `requests` dictionary)
    static func create(_ filter: Filter, limit: Int? = nil, saveRequest: Bool) -> Self {
        print("Go there...")
        if let request = requests[filter] {
            return request
        } else {
            let request = Self(filter, limit: limit)
            request.fetch(useCache: true)
            if saveRequest { requests[filter] = request }
            return request
        }
    }
}

struct MarvelSectionView<Filter>: View where Filter: MarvelFilter {
    
    // MARK: - Request
    
    let request: Filter.Request
    
    // MARK: - Header
    
    let title: String
    let subtitle: String?
    let showsSeeAll: Bool
    
    // MARK: - Content
    
    let rowCount: Int?
    let itemWidth: CGFloat?
    let itemHeight: CGFloat?
    let verticalDirection: Bool
    
    @State private var infos = [Filter.Request.Info]()
    
    init(_ filter: Filter, saveRequest: Bool = true, title: String, subtitle: String? = nil, showsSeeAll: Bool = true, rowCount: Int? = nil, itemWidth: CGFloat? = nil, itemHeight: CGFloat? = nil, verticalDirection: Bool = false) {
        self.request = Filter.Request.create(filter, saveRequest: saveRequest)
        self.title = title
        self.subtitle = subtitle
        self.showsSeeAll = showsSeeAll
        self.rowCount = rowCount
        self.itemWidth = itemWidth
        self.itemHeight = itemHeight
        self.verticalDirection = verticalDirection
    }
    
    var body: some View {
        VStack {
            Divider().padding(.horizontal)
            
            StandardHeaderView(title: title, subtitle: subtitle, seeAllDestination: showsSeeAll && !infos.isEmpty ? seeAllDestination : nil)
                .padding(.horizontal)
            
            if verticalDirection {
                VStack {
                    ForEach(infos) { info in
                        Filter.CardView(info)
                            .frame(width: itemWidth, height: itemHeight)
                        if let index = infos.firstIndex { $0.id == info.id }, index != infos.count - 1 {
                            Divider()
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                if let rowCount = rowCount {
                    StandardSectionView(infos.dividesToGroup(of: rowCount), id: \.self) { group in
                        VStack(alignment: .leading, spacing: 15) {
                            ForEach(group) { info in
                                Filter.CardView(info)
                                    .frame(width: itemWidth, height: itemHeight)
                                if let index = group.firstIndex { $0.id == info.id }, index != group.count - 1 {
                                    Divider()
                                }
                            }
                        }
                    }
                } else {
                    StandardSectionView(infos) { info in
                        Filter.CardView(info)
                            .frame(width: itemWidth, height: itemHeight)
                    }
                }
            }
        }
        .onReceive(request.results) { results in
            infos = results
        }
    }
    
    @ViewBuilder
    var seeAllDestination: some View {
        let cardType = Filter.CardView.self
        if (cardType == EventCardView.self) || (cardType == SeriesCardView.self) {
            ScrollView {
                StandardVerticalStackView(items: infos) { info in
                    Filter.CardView(info)
                }
            }
        } else {
            ScrollView {
                StandardGridView(items: infos) { Filter.CardView($0) }
            }
        }
    }
}

// MARK: - Extension(s)

extension Image {
    static func soobinThumbnail(width: CGFloat? = nil, height: CGFloat? = nil) -> some View {
        Image("soobin\(Int.random(in: 0..<14))")
            .resizable()
            .scaledToFill()
            .frame(width: width, height: height)
            .cornerRadius(10.0)
    }
}

// MARK: - Standard View(s)

struct StandardHeaderView<Destination>: View where Destination: View {
    var title: String
    var subtitle: String?
    var seeAllDestination: Destination?
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            if let destination = seeAllDestination {
                NavigationLink(destination: destination
                                .navigationTitle(title)
                                .navigationBarTitleDisplayMode(.inline)
                ) {
                    Text("See All")
                }
            }
        }
    }
}

struct StandardSectionView<Item, ID, ItemView>: View where ID: Hashable, ItemView: View {
    var items: [Item]?
    var id: KeyPath<Item, ID>
    var viewForItem: (Item) -> ItemView
    
    init(_ items: [Item]?, id: KeyPath<Item, ID>, viewForItem: @escaping (Item) -> ItemView) {
        self.items = items
        self.id = id
        self.viewForItem = viewForItem
    }
    
    var body: some View {
        if let items = items {
            if items.isEmpty {
                Text("Empty Results")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 15) {
                        ForEach(items, id: id) { item in
                            viewForItem(item)
                        }
                    }
                    .padding(.horizontal)
                }
                .buttonStyle(PlainButtonStyle())
            }
        } else {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
        }
    }
}

extension StandardSectionView where Item: Identifiable, Item.ID == ID {
    init(_ items: [Item]?, viewForItem: @escaping (Item) -> ItemView) {
        self.init(items, id: \.id, viewForItem: viewForItem)
    }
}

struct StandardGridView<Item, ItemView>: View where Item: Identifiable, ItemView: View {
    var items: [Item]
    var columnsCount = 2
    @ViewBuilder var viewForItem: (Item) -> ItemView
    
    var columns: [GridItem] { Array(repeating: GridItem(.flexible(), spacing: 10), count: columnsCount) }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(items) { item in
                viewForItem(item)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding()
    }
}

struct StandardVerticalStackView<Item, ItemView>: View where Item: Identifiable, ItemView: View {
    var items: [Item]
    @ViewBuilder var viewForItem: (Item) -> ItemView
    
    var body: some View {
        VStack {
            ForEach(items) { item in
                viewForItem(item)
                if let index = items.firstIndex { $0.id == item.id }, index != items.count - 1 {
                    Divider()
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical)
    }
}

// MARK: - Card View(s)

struct CharacterCardView: MarvelCardView {
    @Environment(\.managedObjectContext) var context: NSManagedObjectContext
    let characterInfo: CharacterInfo
    
    init(_ info: CharacterInfo) {
        self.characterInfo = info
    }
    
    // Property used to indicate the favourite status
    @State private var isFavourited = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink(destination: CharacterDetailsView(character: characterInfo)) {
                VStack(alignment: .leading, spacing: 10) {
                    GeometryReader { geometry in
                        Image.soobinThumbnail(width: geometry.size.width, height: geometry.size.height)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(characterInfo.modified_.uppercased())
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.gray)
                        Text(characterInfo.name)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                        Text(characterInfo.description.isEmpty ? "Get hooked on a hearty helping of heroes and villains from the humble House of Ideas!" : characterInfo.description) // description_?????
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                }
                .aspectRatio(0.75, contentMode: .fit)
                .onAppear { // Every time the card view appear, it will check whether it is favourited or not.
                    isFavourited = Character.contains(characterInfo, in: context)
                }
            }
            favourite
        }
    }
    
    var favourite: some View {
        Button {
            if isFavourited {
                context.perform {
                    withAnimation {
                        Character.delete(characterInfo, in: context) // Delete from favourite list
                    }
                }
            } else {
                context.perform {
                    withAnimation {
                        Character.update(from: characterInfo, in: context) // Add to favourite list
                    }
                }
            }
            isFavourited.toggle() // Reflex the change
        } label: {
            Image(systemName: isFavourited ? "heart.fill" : "heart")
                .imageScale(.large)
                .foregroundColor(.red)
                .padding(10)
        }
    }
}

struct ComicCardView: MarvelCardView {
    @Environment(\.managedObjectContext) var context: NSManagedObjectContext
    let comicInfo: ComicInfo
    
    init(_ info: ComicInfo) {
        self.comicInfo = info
    }
    
    // Property used to indicate the favourite status
    @State private var isFavourited = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink(destination: ComicDetailsView(comic: comicInfo)) {
                VStack(alignment: .leading, spacing: 10) {
                    GeometryReader { geometry in
                        Image.soobinThumbnail(width: geometry.size.width, height: geometry.size.height)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(comicInfo.modified_.uppercased())
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.gray)
                        Text(comicInfo.title)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                        Text(comicInfo.description_)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                }
                .aspectRatio(0.75, contentMode: .fit)
                .onAppear { // Update favourite status
                    isFavourited = Comic.contains(comicInfo, in: context)
                }
            }
            favourite // Favourite Button
        }
    }
    
    var favourite: some View {
        Button {
            if isFavourited {
                context.perform {
                    withAnimation {
                        Comic.delete(comicInfo, in: context) // Delete from favourite list
                    }
                }
            } else {
                context.perform {
                    withAnimation {
                        Comic.update(from: comicInfo, in: context) // Add to favourite list
                    }
                }
            }
            isFavourited.toggle() // Reflex the change
        } label: {
            Image(systemName: isFavourited ? "heart.fill" : "heart")
                .imageScale(.large)
                .foregroundColor(.red)
                .padding(10)
        }
    }
}

struct EventCardView: MarvelCardView {
    private let defaultSize: CGFloat = 70
    let event: EventInfo
    
    init(_ info: EventInfo) {
        self.event = info
    }
    
    var body: some View {
        NavigationLink(destination: EventDetailsView(event: event)) {
            HStack(spacing: 15) {
                Image.soobinThumbnail(width: defaultSize, height: defaultSize)
                Text("1")
                    .font(.callout)
                    .fontWeight(.bold)
                VStack(alignment: .leading, spacing: 5) {
                    Text(event.title)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(event.description_)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(3)
                }
                .padding(.trailing)
                Spacer()
            }
            .frame(width: UIScreen.main.bounds.width * 0.9)
        }
    }
}

struct SeriesCardView: MarvelCardView {
    @Environment(\.managedObjectContext) var context: NSManagedObjectContext
    let seriesInfo: SeriesInfo
    
    init(_ info: SeriesInfo) {
        self.seriesInfo = info
    }
    
    // Property used to indicate the favourite status
    @State private var isFavourited = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink(destination: SeriesDetailsView(series: seriesInfo)) {
                HStack(alignment: .top) {
                    Image.soobinThumbnail(width: 100, height: 100)
                    VStack(alignment: .leading) {
                        Text(seriesInfo.modified_.uppercased())
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.gray)
                        Spacer()
                        Text(seriesInfo.title)
                            .font(.callout)
                            .fontWeight(.medium)
                            .lineLimit(/*@START_MENU_TOKEN@*/2/*@END_MENU_TOKEN@*/)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        HStack {
                            Text("Series")
                            Image(systemName: "circlebadge.fill").font(.system(size: 5))
                            Text(verbatim: "\(seriesInfo.startYear)")
                            Image(systemName: "circlebadge.fill").font(.system(size: 5))
                            Text("\(seriesInfo.rating.isEmpty ? "90%" : seriesInfo.rating) Rating")
                        }
                        .font(.caption)
                        .foregroundColor(.purple)
                    }
                    Spacer()
                }
                .frame(width: UIScreen.main.bounds.width * 0.9, height: 110)
                .onAppear { // Update favourite status
                    isFavourited = Series.contains(seriesInfo, in: context)
                }
            }
            favourite // Favourite Button
        }
    }
    
    var favourite: some View {
        Button {
            if isFavourited {
                context.perform {
                    withAnimation {
                        Series.delete(seriesInfo, in: context) // Delete from favourite list
                    }
                }
            } else {
                context.perform {
                    withAnimation {
                        Series.update(from: seriesInfo, in: context) // Add to favourite list
                    }
                }
            }
            isFavourited.toggle() // Reflex the change
        } label: {
            Image(systemName: isFavourited ? "heart.fill" : "heart")
                .imageScale(.large)
                .foregroundColor(.red)
                .padding(10)
        }
    }
}

struct StoryCardView: MarvelCardView {
    var defaultSize: (CGFloat, CGFloat) {
        let width = UIScreen.main.bounds.width * 0.6
        let height = width * 1.3
        return (width, height)
    }
    
    let story: StoryInfo
    
    init(_ info: StoryInfo) {
        self.story = info
    }
    
    var body: some View {
        Image.soobinThumbnail(width: defaultSize.0, height: defaultSize.1)
            .overlay(banner, alignment: .bottom)
            .cornerRadius(10.0)
    }
    
    var banner: some View {
        ZStack {
            Rectangle()
                .frame(height: defaultSize.0 * 0.3)
                .foregroundColor(.black.opacity(0.9))
            Text(story.title)
                .font(.footnote)
                .lineLimit(3)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.horizontal)
        }
    }
}

struct CreatorCardView: MarvelCardView {
    let creator: CreatorInfo
    
    init(_ info: CreatorInfo) {
        self.creator = info
    }
    
    var body: some View {
        NavigationLink(destination: CreatorDetailsView(creator: creator)) {
            VStack {
                Image.soobinThumbnail(width: 100, height: 100).clipShape(Circle())
                Text(creator.fullName)
            }
            .frame(maxWidth: 100)
        }
    }
}

struct CategoryCardView: View {
    let category: String
    
    var body: some View {
        ZStack(alignment: .leading) {
            RadialGradient(gradient: Gradient(colors: [.purple, .blue]), center: .topLeading, startRadius: 5, endRadius: 500)
            Text(category)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: 130)
        }
        .cornerRadius(5.0)
        .aspectRatio(2.2, contentMode: .fit)
        .frame(width: 220)
    }
}

// Introduction Card on very top (Custom section view)
struct CardView5: View {
    var body: some View {
        VStack(alignment: .leading) {
            Divider()
            Text("New Release".uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.purple)
            Text("The Grand Scheme")
                .font(.title2)
            Text("Hosted by John Stamos.")
                .font(.title3)
                .foregroundColor(.gray)
            Image.soobinThumbnail(width: UIScreen.main.bounds.width * 0.9, height: 150)
        }
    }
}


// MARK: - Default Search Result View (Categories)

struct DefaultSearchResultsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider().padding(.horizontal)
            StandardHeaderView<AnyView>(title: "Search Categories").padding(.horizontal)
                .padding(.horizontal)
            
            StandardGridView(items: Category.allCases) { category in
                GeometryReader { geometry in
                    Image.soobinThumbnail(width: geometry.size.width, height: geometry.size.height)
                        .overlay(text, alignment: .bottomLeading)
                }
                .aspectRatio(1.5, contentMode: .fill)
            }
        }
    }
    
    var text: some View {
        Text("Soobin")
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.white)
            .padding(5)
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(2)
                Text("Loading")
                    .font(.system(size: 25, weight: .medium, design: .rounded))
            }
            Color.primary.opacity(0.05)
        }
        .frame(width: 150, height: 150)
        .cornerRadius(15.0)
    }
}
