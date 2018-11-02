//
//  ViewController.swift
//  FindMyFriends
//
//  Created by 弘勳 on 2018/10/22.
//  Copyright © 2018 Hung Hsun Lin. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {

    @IBOutlet weak var mainMapView: MKMapView!
    
    let communicator = Communicator.shared
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        guard CLLocationManager.locationServicesEnabled() else {
            // Show alert to user.
            return
        }
        
        // Ask permission.
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self // Important!
        
        
        // 設定精確度
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .fitness
        
        locationManager.startUpdatingLocation()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 開一個 Queue 來 Execute moveAndZoomMap() after 2.0 seconds.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.moveAndZoomMap()
        }
    }
    
    func moveAndZoomMap() {
        // location 可能會拿到 nil，所以用guard let
        guard let location = locationManager.location else {
            print("Location is not ready.")
            return
        }
       
        // Move and zoom the map.
        // 以經度和緯度0.01度的比例來縮放，由於經度和緯度不會剛好 1:1 ，所以蘋果其實會自己幫你計算，所以只要輸入一樣的比例就好
        let span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        
        // 設定地圖的區域
        let region = MKCoordinateRegion(center: location.coordinate
            , span: span)
        
        // 設定地圖的顯示區域
        mainMapView.setRegion(region, animated: true)
    }
    
}

// MARK: -MKMapViewDelegate Methods.
extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let coordinate = mapView.region.center
        print("Map Center: \(coordinate.latitude), \(coordinate.longitude)")
    }
    
    // MKAnnotation 為 protocol ，這裡不限定放得值型別是什麼，但一定要有符合MKAnnotation這個 protocol
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // is 是型別檢查
        if annotation is MKUserLocation {
            return nil
        }
        
        // Cast annotation as StoreAnnotation type.
        guard let annotation = annotation as? StoreAnnotation else {
            assertionFailure("Fail to cast as Store Annotation.")
            return nil
        }
        print("StoreID: \(annotation.storeID)")
        
        // 命名為 identifier 的通常用來作為唯一視別用的，且通常為自定
        let identifier = "store"
        var result = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) // as? MKPinAnnotationView
        // 如果資源回收裡沒有的話，就自己生成一個
        if result == nil {
            //            result = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            result = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        } else {
            result?.annotation = annotation
        }
        result?.canShowCallout = true
        
        return result
    }
}

extension ViewController: CLLocationManagerDelegate {
    
    // MARK: - CLLocationManagerDelegate Methods.
    
    // 位置改變時，才會回報位置 didUpdateLocations
    func  locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else {
            // debug 時，程式執行到這裡，會停在這裡，不需要下中斷點，而且上架的話不影響user使用，user 在用時，到這裡會直接帶過
            assertionFailure("Invalid coordinate or location.")
            return
        }
        let lat = Float(coordinate.latitude)
        let lon = Float(coordinate.longitude)
        communicator.updateLocation(lat: lat, lon: lon) { (result, error) in
            if let error = error {
                print("Update location error \(error)")
                return
            }
            print("Update location OK: \(result!)")
        }
        print("Current Locaton: \(coordinate.latitude),\(coordinate.longitude)")
        
        communicator.queryFriendLocations(completion: { (result, error) in
            if let error = error {
                print("Query friend's locations error \(error)")
                return
            }
            guard let result = result else {
                print("result is nil.")
                return
            }
            print("Query friend's locations OK.")
            
            // Decode as [Friend].
            guard let jsonData = try? JSONSerialization.data(withJSONObject: result, options: .prettyPrinted) else {
                print("Fail to generate jsonData.")
                return
            }
            let decoder = JSONDecoder()
            guard let resultsObject = try? decoder.decode(RetriveResult.self, from: jsonData) else {
                print("Fail to decode jsonData.")
                return
            }
            print("resultObject: \(resultsObject)")
            guard let friends = resultsObject.friends, !friends.isEmpty else {
                print("friends is nil or empty.")
                return
            }
        })
    }
    
    // MARK: - Create myself make annotation.
    
    // 建立自己的 Annotation 的方法
    class StoreAnnotation: NSObject, MKAnnotation {
        // Basic properties.
        var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0, 0)
        var title: String?
        var subtitle: String?
        
        // Store Information.
        var storeID = 10
        // ...
        
        override init() {
            super.init()
        }
        
    }
    
    // MARK: - Retrive result.
    
    struct RetriveResult: Codable {
        var result: Bool
        var friends: [Friend]?
        enum CodingKeys: String, CodingKey {
            case result = "result"
            case friends = "friends"
        }
    }
    
}

