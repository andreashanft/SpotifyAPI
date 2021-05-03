import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Logging

#if canImport(Combine)
import Combine
#else
import OpenCombine
import OpenCombineDispatch
import OpenCombineFoundation
#endif

/**
 Communicates *directly* with the Spotify web API in order to retrieve the
 authoriation information and refresh the access token using the [Authorization
 Code Flow with Proof Key for Code Exchange][1].

 Compare with `AuthorizationCodeFlowPKCEProxyBackend`.

 Usually you should not need to create instances of this type directly.
 `AuthorizationCodeFlowPKCEManager` uses this type internally by inheriting from
 `AuthorizationCodeFlowPKCEBackendManager<AuthorizationCodeFlowPKCEClientBackend>`.
 
 [1]: https://developer.spotify.com/documentation/general/guides/authorization-guide/#authorization-code-flow-with-proof-key-for-code-exchange-pkce
 */
public struct  AuthorizationCodeFlowPKCEClientBackend: AuthorizationCodeFlowPKCEBackend {
    
    /// The logger for this struct.
    public static var logger = Logger(
        label: "AuthorizationCodeFlowClientBackend", level: .critical
    )

    /**
     The client id that you received when you [registered your application][1].
     
     [1]: https://developer.spotify.com/documentation/general/guides/app-settings/#register-your-app
     */
    public let clientId: String
    
    /**
     Creates an instance that manages the authorization process for the
     [Authorization Code Flow with Proof Key for Code Exchange][1] by
     communicating *directly* with the Spotify web API.
     
     - Parameters:
       - clientId: The client id that you received when you [registered your
             application][1].
     
     [1]: https://developer.spotify.com/documentation/general/guides/app-settings/#register-your-app
     */
    public init(clientId: String) {
        self.clientId = clientId
    }

    /**
     Exchanges an authorization code for the access and refresh tokens.
     
     After validing the `redirectURIWithQuery`,
     `AuthorizationCodeFlowPKCEBackendManager.requestAccessAndRefreshTokens(redirectURIWithQuery:codeVerifier:state:)`,
     calls this method in order to retrieve the authorization information.
     
     If the `redirectURIWithQuery` contains an error parameter or the value for
     the state parameter doesn't match the value passed in as an argument to the
     above method, then an error will be thrown *before* this method is called.
     
     This method returns the authorization information as JSON data that can
     be decoded into `AuthInfo`. The `accessToken`, `refreshToken`, and
     `expirationDate` (which can be decoded from the "expires_in" JSON key)
     properties should be non-`nil`. For example:
     
     ```
     {
         "access_token": "NgCXRK...MzYjw",
         "token_type": "Bearer",
         "scope": "user-read-private user-read-email",
         "expires_in": 3600,
         "refresh_token": "NgAagA...Um_SHo"
     }
     ```
     
     - Parameters:
       - code: The authorization code, which will also be present in
             `redirectURIWithQuery`.
       - codeVerifier: The code verifier that you generated before creating the
             authorization URL.
       - redirectURIWithQuery: The URL that spotify redirected to after the user
             logged in to their Spotify account, with query parameters appended
             to it.
     */
    public func makePKCETokensRequest(
        code: String,
        codeVerifier: String,
        redirectURIWithQuery: URL
    ) -> AnyPublisher<(data: Data, response: HTTPURLResponse), Error> {
        
        // This must match the redirectURI provided when making the
        // authorization URL.
        let baseRedirectURI = redirectURIWithQuery
            .removingQueryItems()
            .removingTrailingSlashInPath()
                
        let body = PKCETokensRequest(
            code: code,
            redirectURI: baseRedirectURI,
            clientId: self.clientId,
            codeVerifier: codeVerifier
        )
        .formURLEncoded()
        
        let bodyString = String(data: body, encoding: .utf8) ?? "nil"
        
        Self.logger.trace(
            """
            POST request to "\(Endpoints.getTokens)" \
            (URL for requesting access and refresh tokens); body:
            \(bodyString)
            """
        )
        
        var tokensRequest = URLRequest(url: Endpoints.getTokens)
        tokensRequest.httpMethod = "POST"
        tokensRequest.allHTTPHeaderFields = Headers.formURLEncoded
        tokensRequest.httpBody = body
        
        return URLSession.defaultNetworkAdaptor(
            request: tokensRequest
        )
        
    }

    /**
     Refreshes an access token using the refresh token.

     Access tokens expire after an hour, after which they must be refreshed
     using this method. This method will be called by
     `AuthorizationCodeFlowPKCEBackendManager.refreshTokens(onlyIfExpired:tolerance:)`.

     This method returns the authorization information as JSON data that can be
     decoded into `AuthInfo`. The `accessToken`, `refreshToken`, and
     `expirationDate` (which can be decoded from the "expires_in" JSON key)
     properties should be non-`nil`. For example:

     ```
     {
         "access_token": "9Cysa896...Ps4BgEHw",
         "token_type": "Bearer",
         "expires_in": 3600,
         "refresh_token": "PoO04alC_...fKyMaP6zl6g",
         "scope": "user-follow-modify"
     }
     ```
     
     - Parameter refreshToken: The refresh token, which can be exchanged for a
           new access token.
     */
    public func makePKCERefreshTokenRequest(
        refreshToken: String
    ) -> AnyPublisher<(data: Data, response: HTTPURLResponse), Error> {
        
        let body = PKCERefreshAccessTokenRequest(
            refreshToken: refreshToken,
            clientId: self.clientId
        )
        .formURLEncoded()
        
        let bodyString = String(data: body, encoding: .utf8) ?? "nil"
        
        Self.logger.trace(
            """
            POST request to "\(Endpoints.getTokens)" \
            (URL for refreshing access token); body:
            \(bodyString)
            """
        )
                
        var refreshTokensRequest = URLRequest(
            url: Endpoints.getTokens
        )
        refreshTokensRequest.httpMethod = "POST"
        refreshTokensRequest.allHTTPHeaderFields = Headers.formURLEncoded
        refreshTokensRequest.httpBody = body
        
        return URLSession.defaultNetworkAdaptor(
            request: refreshTokensRequest
        )
        
    }
}

extension AuthorizationCodeFlowPKCEClientBackend: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
    }

}

extension AuthorizationCodeFlowPKCEClientBackend: CustomStringConvertible {
    
    public var description: String {
        return """
            AuthorizationCodeFlowPKCEClientBackend(
                clientId: "\(self.clientId)"
            )
            """
    }

}
