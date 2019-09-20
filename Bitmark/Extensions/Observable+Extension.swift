//
//  Observable+Extension.swift
//  Bitmark
//
//  Created by Thuyen Truong on 8/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxAlamofire

// Reference: http://www.ccheptea.com/2019-03-25-handling-rest-errors-with-rxswift/
extension Observable where Element == (HTTPURLResponse, Data) {
  func expectingObject<T: Decodable>(ofType type: T.Type) -> Observable<T> {
    return self.flatMap { (httpURLResponse, data) -> Observable<T> in
      switch httpURLResponse.statusCode {
      case 200..<300:
        do {
          let object = try JSONDecoder().decode(type, from: data)
          return Observable<T>.just(object)
        } catch {
          Global.log.info("type(\(type)")
          Global.log.info("data(\(data.hexEncodedString)")
          throw error
        }
      default:
        do {
          let data = try JSONDecoder().decode(ApiError.self, from: data)
          return Observable<T>.error(data)
        } catch {
          Global.log.info("Api Error - data(\(data.hexEncodedString)")
          return Observable<T>.error(ApiError(message: "Server Error."))
        }
      }
    }
  }
}

struct ApiError: Decodable, Error {
  let message: String
}
