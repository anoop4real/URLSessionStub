//
//  DataManager.swift
//  NetWorkTest
//
//  Created by anoop mohanan on 20/08/18.
//  Copyright © 2018 anoop mohanan. All rights reserved.
//

import Foundation

enum Result<T, Error> {
    case success(T)
    case error(Error)
}

protocol NetworkSessionProtocol {
    
    typealias Completion = (Result<Any, Error>) -> ()
    
    // Method to fetch data from URL
    func fetchDataWithUrlRequest(_ urlRequest: URLRequest, completion:@escaping (Result<Data?, Error>) -> Void)
}
extension URLSession: NetworkSessionProtocol{
    
    func fetchDataWithUrlRequest(_ urlRequest: URLRequest, completion: @escaping (Result<Data?, Error>) -> Void) {
        
        let task = self.dataTask(with: urlRequest, completionHandler: { (data, response, error) -> Void in
            if error != nil {
                print(error!.localizedDescription)
                completion(.error(error!))
            } else {
                completion(.success(data))
            }
        })
        task.resume()
    }
}

class DataManger{
    
    private let session: NetworkSessionProtocol
    
    init(session: NetworkSessionProtocol = URLSession.shared) {
        self.session = session
    }
    
    let forecastAPI = "http://myserver.com/api/forecast/"
    let fetchOrdersAPI = "http://myserver.com/api/orders/"
    let dispatch_group = DispatchGroup()
    var foreCastResponse = [String: Int]()
    var foreCastErrorResponse: String!
    var orderErrorResponse: String!
    var orderResponse = [String: Int]()
    
    
    func outofstock(year: String, handler: ([String]) -> Void) {
        // Find all products for which
        // the forecast for `year` is lower than the
        // actual orders for the same `year`
        // Create an array of strings containing
        // the names of these products,
        // and call `handler(array)` with this array
        
        fetchAndValidateForecastAndOrdersFor(year: "2014") { (result) in
            
            print(result)
        }
    }
    func fetchAndValidateForecastAndOrdersFor(year: String, callBack:@escaping ([String]) -> Void){
        
        fetchForecast(with: year)
        fetchOrders(with: year)
        
        dispatch_group.notify(queue: .main) {
            if (self.foreCastErrorResponse != nil) || (self.orderErrorResponse != nil) {
                callBack(["Server Error"])
                return
            }
            if (self.foreCastResponse != self.orderResponse){
                callBack(["Product Error"])
                return
            }
            
            let filtered = self.foreCastResponse.filter{ $0.value < self.orderResponse[$0.key]!
                
            }
            // retun the product names
            callBack(Array(filtered.keys))
        }
    }
    func fetchForecast(with year:String){
        let APIPath = "\(forecastAPI)/\(year)/"
        let urlRequest = URLRequest(url: URL(string: APIPath)!)
        let backgroundQ = DispatchQueue.global()
        dispatch_group.enter()
        
        backgroundQ.async(group: dispatch_group, execute: {[weak self] in
            self?.session.fetchDataWithUrlRequest(urlRequest) { (result) in
                switch (result){
                    
                case .success(let data):
                    do {
                        let someDictionaryFromJSON = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String: Any]
                        if let status = someDictionaryFromJSON["status"] as? String{
                            switch (status){
                            case "success":
                                self?.foreCastResponse = someDictionaryFromJSON["data"] as! [String : Int]
                            case "error":
                                self?.foreCastErrorResponse = "Server Error"
                            default:
                                break
                            }
                        }
                    } catch let error {
                        self?.foreCastErrorResponse = "Server Error"
                        print(error.localizedDescription)
                        
                    }
                case .error(let error):
                    self?.foreCastErrorResponse = "Server Error"
                    print(error.localizedDescription)
                    
                }
                self?.dispatch_group.leave()
            }
        })

    }
    
    func fetchOrders(with year:String){
        let APIPath = "\(fetchOrdersAPI)/\(year)/"
        let urlRequest = URLRequest(url: URL(string: APIPath)!)
        let backgroundQ = DispatchQueue.global()
        dispatch_group.enter()
        backgroundQ.async(group: dispatch_group, execute: {[weak self] in
            self?.session.fetchDataWithUrlRequest(urlRequest) { (result) in
                switch (result){
                    
                case .success(let data):
                    do {
                        let someDictionaryFromJSON = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String: Any]
                        if let status = someDictionaryFromJSON["status"] as? String{
                            switch (status){
                            case "success":
                                self?.orderResponse = someDictionaryFromJSON["data"] as! [String : Int]
                            case "error":
                                self?.orderErrorResponse = "Server Error"
                            default:
                                break
                            }
                        }
                    } catch let error {
                        self?.orderErrorResponse = "Server Error"
                        print(error.localizedDescription)
                        
                    }
                case .error(let error):
                    self?.orderErrorResponse = "Server Error"
                    print(error.localizedDescription)
                    
                }
                self?.dispatch_group.leave()
            }
        })
    }
 
}
