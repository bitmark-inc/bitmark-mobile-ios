//
//  Observable+Extension.swift
//  BitmarkRegistry
//
//  Created by Thuyen Truong on 8/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxAlamofire

// Reference: http://www.ccheptea.com/2019-03-25-handling-rest-errors-with-rxswift/
extension Observable where Element == (HTTPURLResponse, Data) {
  func expectingObject<T : Decodable>(ofType type: T.Type) -> Observable<T> {
    return self.flatMap { (httpURLResponse, data) -> Observable<T> in
      switch httpURLResponse.statusCode {
      case 200..<300:
        let object = try JSONDecoder().decode(type, from: data)
        return Observable<T>.just(object)
      default:
        do {
          let data = try JSONDecoder().decode(ApiError.self, from: data)
          return Observable<T>.error(data)
        } catch {
          return Observable<T>.error(ApiError(message: "Server Error."))
        }
      }
    }
  }
}

struct ApiError: Decodable, Error {
  let message: String
}
