//
//  Request.swift
//  Sword
//
//  Created by Alejandro Alonso
//  Copyright © 2017 Alejandro Alonso. All rights reserved.
//

#if os(Linux)
import FoundationNetworking
#endif
import Foundation
import Dispatch

extension Encodable {
    var dictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
    }
}

/// HTTP Handler
extension SwiftcordClient {

    /**
     Actual HTTP Request

     - parameter url: URL to request
     - parameter params: Optional URL Query Parameters to send
     - parameter body: Optional Data to send to server
     - parameter file: Optional for when files
     - parameter authorization: Whether or not the Authorization header is required by Discord
     - parameter method: Type of HTTP Method
     - parameter rateLimited: Whether or not the HTTP request needs to be rate limited
     - parameter returnJSONData: If true, data returned is raw JSON data, rather than JSONSerialization of JSON string
     - parameter reason: Optional for when user wants to specify audit-log reason
     */
    func request(
        _ endpoint: Endpoint,
        params: [String: Any]? = nil,
        body: [String: Any]? = nil,
        files: [AttachmentBuilder]? = nil,
        authorization: Bool = true,
        rateLimited: Bool = true,
        returnJSONData: Bool = false,
        reason: String? = nil
    ) async throws -> Any? {
        let endpointInfo = endpoint.httpInfo

        var route = self.getRoute(for: endpointInfo.url)

        if route.hasSuffix("/messages/:id") && endpointInfo.method == .delete {
            route += ".delete"
        }

        var urlString = "https://discord.com/api/v9\(endpointInfo.url)"

        if let params = params {
            urlString += "?"
            urlString += params.map({ key, value in "\(key)=\(value)" }
            ).joined(separator: "&")
        }

        guard let url = URL(string: urlString) else {
            self.error(
                "Used an invalid URL: \"\(urlString)\". Please report this."
            )
            return nil
        }

        var request = URLRequest(url: url)

        request.httpMethod = endpointInfo.method.rawValue

        if authorization {
            if self.options.isBot {
                request.addValue("Bot \(token)", forHTTPHeaderField: "Authorization")
            } else {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }

        if let reason = reason {
            request.addValue(
                reason.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!,
                forHTTPHeaderField: "X-Audit-Log-Reason"
            )
        }

        request.addValue(
            "DiscordBot (https://github.com/SketchMaster2001/Swiftcord, 1.0.0)",
            forHTTPHeaderField: "User-Agent"
        )

        if let body = body {
            if let array = body["array"] as? [Any] {
                request.httpBody = array.createBody()
            } else {
                request.httpBody = body.createBody()
            }

            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        #if os(macOS)
        if let file = files {
            let boundary = createBoundary()

            let payloadJson: String?

            if let array = body?["array"] as? [Any] {
                payloadJson = array.encode()
            } else {
                payloadJson = body?.encode()
            }

            request.httpBody = self.createMultipartBody(with: payloadJson, fileData: file, boundary: boundary)
            request.addValue(
                "multipart/form-data; boundary=\(boundary)",
                forHTTPHeaderField: "Content-Type"
            )
        }
        #endif

        var returnData: Any?
        returnData = try await withCheckedThrowingContinuation({ continuation in
            self.baseRequest(
                request,
                endpoint,
                route: route,
                params: params,
                body: body,
                files: files,
                authorization: authorization,
                rateLimited: rateLimited,
                reason: reason,
                returnJSONData: returnJSONData
            ) { data, err in
                if let err = err {
                    continuation.resume(throwing: err)
                } else {
					continuation.resume(returning: data)
				}
            }
        })

        return returnData
    }

    /**
     Actual HTTP Request

     - parameter url: URL to request
     - parameter params: Optional URL Query Parameters to send
     - parameter body: Optional Data to send to server
     - parameter file: Optional for when files
     - parameter authorization: Whether or not the Authorization header is required by Discord
     - parameter method: Type of HTTP Method
     - parameter rateLimited: Whether or not the HTTP request needs to be rate limited
     - parameter returnJSONData: If true, data returned is raw JSON data, rather than JSONSerialization of JSON string
     - parameter reason: Optional for when user wants to specify audit-log reason
     */
    func requestWithBodyAsData(
        _ endpoint: Endpoint,
        params: [String: Any]? = nil,
        body: Data? = nil,
        files: [AttachmentBuilder]? = nil,
        authorization: Bool = true,
        rateLimited: Bool = true,
        returnJSONData: Bool = false,
        reason: String? = nil
    ) async throws -> Any? {
        let endpointInfo = endpoint.httpInfo

        var route = self.getRoute(for: endpointInfo.url)

        if route.hasSuffix("/messages/:id") && endpointInfo.method == .delete {
            route += ".delete"
        }

        var urlString = "https://discord.com/api/v9\(endpointInfo.url)"

        if let params = params {
            urlString += "?"
            urlString += params.map({ key, value in "\(key)=\(value)" }
            ).joined(separator: "&")
        }

        guard let url = URL(string: urlString) else {
            self.error(
                "Used an invalid URL: \"\(urlString)\". Please report this."
            )
            return nil
        }

        var request = URLRequest(url: url)

        request.httpMethod = endpointInfo.method.rawValue

        if authorization {
            if self.options.isBot {
                request.addValue("Bot \(token)", forHTTPHeaderField: "Authorization")
            } else {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }

        if let reason = reason {
            request.addValue(
                reason.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!,
                forHTTPHeaderField: "X-Audit-Log-Reason"
            )
        }

        request.addValue(
            "DiscordBot (https://github.com/SketchMaster2001/Swiftcord, 1.0.0)",
            forHTTPHeaderField: "User-Agent"
        )

        if let body = body {
            request.httpBody = body

            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        if let file = files {
            let boundary = createBoundary()

            request.httpBody = self.createMultipartBody(with: body, fileData: file, boundary: boundary)
            
            request.setValue(
                "multipart/form-data; boundary=\(boundary)",
                forHTTPHeaderField: "Content-Type"
            )
        }


        var returnData: Any?
        returnData = try await withCheckedThrowingContinuation({ continuation in
            self.baseRequestWithData(
                request,
                endpoint,
                route: route,
                params: params,
                body: body,
                files: files,
                authorization: authorization,
                rateLimited: rateLimited,
                reason: reason,
                returnJSONData: returnJSONData                
            ) { data, err in
                if let err = err {
                    continuation.resume(throwing: err)
                } else {
                    continuation.resume(returning: data)
                }
            }
        })

        return returnData
    }

    private func baseRequest
    (
        _ request: URLRequest,
        _ endpoint: Endpoint,
        route: String,
        params: [String: Any]? = nil,
        body: [String: Any]? = nil,
        files: [AttachmentBuilder]? = nil,
        authorization: Bool = true,
        rateLimited: Bool = true,
        reason: String? = nil,
        returnJSONData: Bool = false,
        completion: @escaping (Any?, ResponseError?) -> Void
    ) {
        let sema = DispatchSemaphore(value: 0)

        let task = self.session.dataTask(with: request) {
          [unowned self, unowned sema] data, response, error in

            if error != nil {
              #if !os(Linux)
              completion(nil, ResponseError.nonSuccessfulRequest(RequestError(error! as NSError)))
              #else
              completion(nil, ResponseError.nonSuccessfulRequest(RequestError(error as! NSError)))
              #endif
              sema.signal()
              return
            }
            
          let response = response as! HTTPURLResponse
          let headers = response.allHeaderFields

            if response.statusCode == 401 {
                self.error("Bot token invalid.")
                completion(nil, ResponseError.nonSuccessfulRequest(RequestError("Bot Token Invalid.")))
                return
            }

          if rateLimited {
            self.handleRateLimitHeaders(
              headers["x-ratelimit-limit"],
              headers["x-ratelimit-reset"],
              (headers["Date"] as! String).httpDate.timeIntervalSince1970,
              route
            )
          }

          if response.statusCode == 204 {
            completion(nil, nil)
            sema.signal()
            return
          }

			let returnedData: Any?
          
			if returnJSONData {
				returnedData = data
			} else {
				returnedData = try? JSONSerialization.jsonObject(
					with: data!,
					options: .allowFragments
				)
			}
          if response.statusCode != 200 && response.statusCode != 201 {

            if response.statusCode == 429 {
                self.warn("You're being rate limited. (This shouldn't happen, check your system clock)")

              let retryAfter = Int(headers["retry-after"] as! String)!
              let global = headers["x-ratelimit-global"] as? Bool

              guard global == nil else {
                self.isGloballyLocked = true
                self.globalQueue.asyncAfter(
                  deadline: DispatchTime.now() + .seconds(retryAfter)
                ) { [unowned self] in
                  self.globalUnlock()
                }

                sema.signal()
                return
              }

              self.globalQueue.asyncAfter(
                deadline: DispatchTime.now() + .seconds(retryAfter)
              ) { [unowned self] in
                  Task {
                      try! await self.request(
                        endpoint,
                        body: body,
                        files: files,
                        authorization: authorization,
                        rateLimited: rateLimited,
                        returnJSONData: returnJSONData
                      )
                  }
              }
            }

            if response.statusCode >= 500 {
              self.globalQueue.asyncAfter(
                deadline: DispatchTime.now() + .seconds(3)
              ) { [unowned self] in
                  Task {
                      try! await self.request(
                        endpoint,
                        body: body,
                        files: files,
                        authorization: authorization,
                        rateLimited: rateLimited,
                        returnJSONData: returnJSONData
                      )
                  }
              }

              sema.signal()
              return
            }

            completion(nil, ResponseError.nonSuccessfulRequest(RequestError(response.statusCode, returnedData!)))
            sema.signal()
            return
          }

          completion(returnedData, nil)

          sema.signal()
        }

        let apiCall = { [unowned self] in
          guard rateLimited, self.rateLimits[route] != nil else {
            task.resume()

            sema.wait()
            return
          }

          let item = DispatchWorkItem {
            task.resume()

            sema.wait()
          }

          self.rateLimits[route]!.queue(item)
        }

        if !self.isGloballyLocked {
          apiCall()
        } else {
          self.globalRequestQueue.append(apiCall)
        }

    }

    private func baseRequestWithData
    (
        _ request: URLRequest,
        _ endpoint: Endpoint,
        route: String,
        params: [String: Any]? = nil,
        body: Data? = nil,
        files: [AttachmentBuilder]? = nil,
        authorization: Bool = true,
        rateLimited: Bool = true,
        reason: String? = nil,
        returnJSONData: Bool = false,
        completion: @escaping (Any?, ResponseError?) -> Void
    ) {
        let sema = DispatchSemaphore(value: 0)

        let task = self.session.dataTask(with: request) {
          [unowned self, unowned sema] data, response, error in

          let response = response as! HTTPURLResponse
          let headers = response.allHeaderFields

          if error != nil {
            #if !os(Linux)
            completion(nil, ResponseError.nonSuccessfulRequest(RequestError(error! as NSError)))
            #else
            completion(nil, ResponseError.nonSuccessfulRequest(RequestError(error as! NSError)))
            #endif
            sema.signal()
            return
          }

          if rateLimited {
            self.handleRateLimitHeaders(
              headers["x-ratelimit-limit"],
              headers["x-ratelimit-reset"],
              (headers["Date"] as! String).httpDate.timeIntervalSince1970,
              route
            )
          }

          if response.statusCode == 204 {
            completion(nil, nil)
            sema.signal()
            return
          }

          let returnedData: Any?
          
			if returnJSONData {
				returnedData = data
			} else {
				returnedData = try? JSONSerialization.jsonObject(
					with: data!,
					options: .allowFragments
				)
			}

          if response.statusCode != 200 && response.statusCode != 201 {

            if response.statusCode == 429 {
                self.warn("You're being rate limited. (This shouldn't happen, check your system clock)")

              let retryAfter = Int(headers["retry-after"] as! String)!
              let global = headers["x-ratelimit-global"] as? Bool

              guard global == nil else {
                self.isGloballyLocked = true
                self.globalQueue.asyncAfter(
                  deadline: DispatchTime.now() + .seconds(retryAfter)
                ) { [unowned self] in
                  self.globalUnlock()
                }

                sema.signal()
                return
              }

              self.globalQueue.asyncAfter(
                deadline: DispatchTime.now() + .seconds(retryAfter)
              ) { [unowned self] in
                  Task {
                      try! await self.requestWithBodyAsData(
                        endpoint,
                        body: body,
                        files: files,
                        authorization: authorization,
                        rateLimited: rateLimited,
                        returnJSONData: returnJSONData
                      )
                  }
              }
            }

            if response.statusCode >= 500 {
              self.globalQueue.asyncAfter(
                deadline: DispatchTime.now() + .seconds(3)
              ) { [unowned self] in
                  Task {
                      try! await self.requestWithBodyAsData(
                        endpoint,
                        body: body,
                        files: files,
                        authorization: authorization,
                        rateLimited: rateLimited,
                        returnJSONData: returnJSONData
                      )
                  }
              }

              sema.signal()
              return
            }

            completion(nil, ResponseError.nonSuccessfulRequest(RequestError(response.statusCode, returnedData!)))
            sema.signal()
            return
          }

          completion(returnedData, nil)

          sema.signal()
        }

        let apiCall = { [unowned self] in
          guard rateLimited, self.rateLimits[route] != nil else {
            task.resume()

            sema.wait()
            return
          }

          let item = DispatchWorkItem {
            task.resume()

            sema.wait()
          }

          self.rateLimits[route]!.queue(item)
        }

        if !self.isGloballyLocked {
          apiCall()
        } else {
          self.globalRequestQueue.append(apiCall)
        }

    }
}
