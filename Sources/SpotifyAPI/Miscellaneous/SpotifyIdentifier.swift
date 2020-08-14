import Foundation
import RegularExpressions
import Logger

/// A type that can convert itself to a Spotify URI.
public protocol SpotifyURIConvertible {

    /// The unique resource identifier for the
    /// Spotify content.
    var uri: String { get }

}


extension String: SpotifyURIConvertible {

    @inlinable @inline(__always)
    public var uri: Self { self }

}


/**
 The Identifiers that appear near the beginning of a Spotify
 URI.

 In this URI:
 ```
 "spotify:track:6rqhFgbbKwnb9MLmUQDhG6"
 ```
 "track" is the id category.

 See the [web API reference][1].

 [1]: https://developer.spotify.com/documentation/web-api/#spotify-uris-and-ids:~:text=Spotify%20URIs%20and%20IDs,will%20frequently%20encounter%20the%20following%20parameters%3A
 - tag: IDCategory
 */
public enum IDCategory: String, CaseIterable, CustomCodable, Hashable {

    case artist
    case album
    case track
    case playlist
    case show
    case episode
    /// See [Identifying Local Files][1].
    ///
    /// [1]: https://developer.spotify.com/documentation/general/guides/local-files-spotify-playlists/
    case local

}


/// Encapsulates the various formats that Spotify
/// uses to uniquely identify content.
///
/// This struct provides a convientent way to convert between
/// the different formats, which include the id, the uri, and the url.
public struct SpotifyIdentifier: CustomCodable, Hashable {

    /// Creates a comma separated string of ids from a sequence
    /// of uris. Throws an error if the ids could not be parsed
    /// from the uris.
    /// - Parameter uris: A sequence of Spotify uris.
    static func commaSeparatedIdsString<S: Sequence>(
        _ uris: S
    ) throws -> String where S.Element: SpotifyURIConvertible {
        
        return try uris.map { uri in
            return try Self(uri: uri.uri).id
        }
        .joined(separator: ",")
    }
    
    
    /// The id for the Spotify content.
    public var id: String

    /// The id category for the Spotify content.
    public var idCategory: IDCategory

    /// The unique resource identifier for the
    /// Spotify content.
    @inlinable @inline(__always)
    public var uri: String {
        "spotify:\(idCategory.rawValue):\(id.strip())"
    }

    /// Use this URL to open the content in the web player.
    public var url: URL {
        guard let url =  URL(
            scheme: "https",
            host: "open.spotify.com",
            path: "/\(idCategory.rawValue)/\(id)"
        )
        else {
            fatalError(
                """
                couldn't make url:
                scheme: 'https'
                host: 'open.spotify.com'
                path: '/\(idCategory.rawValue)/\(id)'
                """
            )
        }
        return url
    }

    public init(id: String, idCategory: IDCategory) {
        self.id = id.strip()
        self.idCategory = idCategory
    }

    public init(uri: String) throws {
        
        guard let captureGroups = try! uri
                .regexMatch("spotify:(.*):(.*)")?.groups,
                let categoryString = captureGroups[safe: 0]??.match,
                let category = IDCategory(rawValue: categoryString),
                let id = captureGroups[safe: 1]??.match
        else {
            throw SpotifyLocalError.identifierParsingError(
                "could not parse spotify id from uri: '\(uri)'"
            )
        }

        self.id = id.strip()
        self.idCategory = category

    }

    public init(url: URL) throws {
        
        let paths = url.pathComponents
        guard let id = paths[backSafe: 1],
                let categoryString = paths[backSafe: 2],
                let category = IDCategory(rawValue: categoryString)
        else {
            throw SpotifyLocalError.identifierParsingError(
                "could not parse spotify id from url: '\(url)'"
            )
        }
        
        self.id = id
        self.idCategory = category
        
    }

}

