//
//  WeatherModel.swift
//  Clima
//
//  Created by Taneem Ahmed on 17/10/24.

struct WeatherModel{
    let conditionId: Int
    let cityName: String
    let temperature: Double
    
    //computed properties
    var temperatureString: String {
        return String(format: "%.1f", temperature)
    }
    
    //computed properties
    var conditionName:String{
        switch conditionId {
        case 200...232:
            return "cloud.bolt"
        case 300...321:
            return "cloud.drizzle"
        case 500...531:
            return "cloud.rain"
        case 600...622:
            return "cloud.snow"
        case 701...781:
            return "cloud.fog"
        case 800:
            return "sun.max"
        case 801...804:
            return "cloud.bolt"
        default:
            return "cloud"
        }
    }
}

