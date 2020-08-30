import Foundation


/// A Spotify [track link][1] object.
/// See also the [Track relinking Guide][2].
///
/// [1]: https://developer.spotify.com/documentation/web-api/reference/object-model/#track-link
/// [2]: https://developer.spotify.com/documentation/general/guides/track-relinking-guide/
public struct TrackLink: SpotifyURIConvertible, Hashable {
    
    /**
     Known [external urls][1] for this track.

     - key: The type of the URL, for example:
           "spotify" - The [Spotify URL][2] for the object.
     - value: An external, public URL to the object.

     [1]: https://developer.spotify.com/documentation/web-api/reference/object-model/#external-url-object
     [2]: https://developer.spotify.com/documentation/web-api/#spotify-uris-and-ids
     */
    public let externalURLs: [String: String]?
    
    /**
     A link to the Spotify web API endpoint
     providing the full track object.
     
     Use `getHref(_:responseType:)` to retrieve the results.
     */
    public let href: String
    
    /// The [Spotify URI][1] for the track.
    ///
    /// [1]: https://developer.spotify.com/documentation/web-api/#spotify-uris-and-ids
    public let uri: String
    
    /// The [Spotify ID] for the track.
    ///
    /// [1]: https://developer.spotify.com/documentation/web-api/#spotify-uris-and-ids
    public let id: String
    
    /// The object type. Always `track`.
    public let type: IDCategory
    
}

extension TrackLink: Codable {
    
    public enum CodingKeys: String, CodingKey {
        case externalURLs = "external_urls"
        case href
        case uri
        case id
        case type
    }
    
}
