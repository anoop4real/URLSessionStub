//
//  MockURLSession.swift
//  NetWorkTest
//
//  Created by anoop mohanan on 20/08/18.
//  Copyright © 2018 anoop mohanan. All rights reserved.
//

import Foundation

class MockURLSession: NetworkSessionProtocol {
    let json = """
{
"status": "error",
"data": {
"product1": 137,
"product2": 23,
"product3": 77
}
}
"""
    func fetchDataWithUrlRequest(_ urlRequest: URLRequest, completion: @escaping (Result<Data?, Error>) -> Void) {
        let responseData = json.data(using: String.Encoding.utf8)!
        completion(.success(responseData))
    }
}
