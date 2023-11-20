// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SwiftyJSON

public class Weather {
    public var city: String
    public var condition: String?
    public var temperature: String?
    private let baseURL = URL(string: "http://www.metaweather.com/api/location/")
    private let dispatchGroup = DispatchGroup()
    
    
    // MARK: init ----------------------------------------
    public init(forCity city: String) {
        self.city = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city.lowercased()
        let _ = try? getCurrentConditions()
    }
    
    // MARK: fetchJSON ----------------------------------------
    internal func fetchJSON(path: String, completion: @escaping(Result<JSON, Error>) -> Void) {
        enum fetchJSONError: Error {
            case invalidURL
            case missingData
        }
        
        guard let url = URL(string: path, relativeTo: baseURL) else {
            completion(.failure(fetchJSONError.invalidURL))
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: url) { (data, urlResponses, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(fetchJSONError.missingData))
                return
            }
            
            do {
                let jsonResult = try JSON(data: data)
                completion(.success(jsonResult))
            } catch {
                completion(.failure(error))
            }
        }
        
        dataTask.resume()
    }
    
    // MARK: getLocationId ----------------------------------------
    internal func getLocationId() throws -> Int? {
        var locationId: Int?
        var fetchError: Error?
        
        dispatchGroup.enter()
        fetchJSON(path: "search/?query=\(self.city)") { result in
            switch result {
            case .success(let json):
                locationId = json[0]["woeid"].int
                self.dispatchGroup.leave()
            case .failure(let error):
                print("Request failed with error: \(error)")
                locationId = nil
                fetchError = error
                self.dispatchGroup.leave()
            }
        }
        
        dispatchGroup.wait()
        if let fetchError = fetchError {
            throw fetchError
        }
        return locationId
    }
    
    // MARK: getCurrentConditions ----------------------------------------
    public func getCurrentConditions() throws -> [String : String]? {
        var weatherInfo: [String: String] = [:]
        var fetchError: Error?
        
        guard let locationId = try getLocationId() else {
            return nil
        }
        
        dispatchGroup.enter()
            fetchJSON(path: "\(locationId)") { [unowned self] result in
                switch result {
                case .success(let json):
                    let consolidatedWeatherInfo = json["consolidated_weather"][0]
                    weatherInfo["condition"] = consolidatedWeatherInfo["weather_state_name"].string
                    weatherInfo["temperature"] = "\(convertCelToFar(celsiusTemp: consolidatedWeatherInfo["the_temp"].doubleValue)) °F"
                    condition = weatherInfo["condition"]
                    temperature = weatherInfo["temperature"]
                    dispatchGroup.leave()
                case .failure(let error):
                    fetchError = error
                    dispatchGroup.leave()
                }
            }
        
            dispatchGroup.wait()
            if let fetchError = fetchError {
                throw fetchError
            }
        
        return weatherInfo
    }
    
    // MARK: convertCelToFar ----------------------------------------
    internal func convertCelToFar(celsiusTemp: Double) -> Int {
        return Int((celsiusTemp * 9/5)) + 32
    }
}
