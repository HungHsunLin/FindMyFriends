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

class ViewController: UIViewController  {

    @IBOutlet weak var mainMapView: MKMapView!
    @IBOutlet weak var updateSwitch: UISwitch!

    
    let communicator = Communicator.shared
    let logManager = LogLocation()
    
    static var allFriends = [Friend?]()
    let locationManager = CLLocationManager()
    var timer: Timer?
    var oldCoordinate: CLLocationCoordinate2D? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        guard CLLocationManager.locationServicesEnabled() else {
            // Show alert to user.
            return
        }
        
        // Ask permission.
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self  // Important!
        mainMapView.delegate = self  // Important!
        
        mainMapView.mapType = .standard
        mainMapView.userTrackingMode = .followWithHeading
        
        // 設定精確度
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .fitness
        locationManager.startUpdatingLocation()
        
        downloadFriendsLocation()
        // 開一個 Queue 來 Execute moveAndZoomMap() after 2.0 seconds.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.moveAndZoomMap()
            self.putAnnotation()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
    }
    
    private func moveAndZoomMap() {
        // location 可能會拿到 nil，所以用guard let
        guard let location = locationManager.location else {
            print("Location is not ready.")
            return
        }
       
        // Move and zoom the map.
        
        // 設定地圖的區域
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        
        // 設定地圖的顯示區域
        mainMapView.setRegion(region, animated: true)
    }

    private func putAnnotation() {
        mainMapView.removeAnnotations(mainMapView.annotations)
        for friend in ViewController.allFriends {
            let annotation = MKPointAnnotation()
            guard let lat = Double(friend!.lat), let lon = Double(friend!.lon) else {
                continue
            }
            annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            annotation.title = friend!.friendName
            self.mainMapView.addAnnotation(annotation)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if timer != nil {
            timer?.invalidate()
        }
    }
    
    @objc private func timerAction() {
        if updateSwitch.isOn {
            updateCurrentLocation()
            downloadFriendsLocation()
        } else {
            downloadFriendsLocation()
        }
    }
    
    private func updateCurrentLocation() {
        guard let coordinate = locationManager.location?.coordinate else {
            print("Location is not ready.")
            return
        }
        self.communicator.updateLocation(lat: coordinate.latitude, lon: coordinate.longitude) { (result, error) in
            if let error = error {
                print("Update location error \(error)")
                return
            }
            print("Update location OK: \(result!)")
        }
        print("Current Locaton: \(coordinate.latitude),\(coordinate.longitude)")
    
    }
    
    private func downloadFriendsLocation() {
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
            ViewController.allFriends.removeAll()
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
            for friend in friends {
                self.logManager.append(friend)
                if friend.friendName == "Tony" {
                    continue
                }
                ViewController.allFriends.append(friend)
            }
            
        })
    }
    
    @IBAction func unwindToMap(segue: UIStoryboardSegue) {
        guard segue.identifier == "moveToFriend" else { return }
        let source = segue.source as! FriendsTableViewController
        
        let coordinate = source.coordinate
        
        // 設定地圖的區域
        let region = MKCoordinateRegion(center: coordinate!, latitudinalMeters: 1000, longitudinalMeters: 1000)
        
        // 設定地圖的顯示區域
        mainMapView.setRegion(region, animated: true)
    }
    
    @IBAction func findMyself(_ sender: UIButton) {
        moveAndZoomMap()
    }
    
    @IBAction func changeMyName(_ sender: Any) {
        let title = "請輸入您的名字"
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            // The string that is displayed when there is no other text in the text field.
            textField.placeholder = "名字"
        }
        let cancel = UIAlertAction(title: "取消", style: .default)
        let ok = UIAlertAction(title: "修改", style: .default) {(action: UIAlertAction!) -> Void in
            let name = (alert.textFields?.first)! as UITextField
            Communicator.MY_NAME = name.text ?? "Tony"
        }
        alert.addAction(cancel)
        alert.addAction(ok)
        self.present(alert, animated: true)
    }
    
}

extension ViewController: MKMapViewDelegate {

    // MARK: - CLLocationManagerDelegate Methods.
    
    // 位置改變時，才會回報位置 didUpdateLocations
    func  locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if #available(iOS 9.0, *) {
            locationManager.allowsBackgroundLocationUpdates = true
        }
        guard let newCoordinate = locations.last?.coordinate else {
            // debug 時，程式執行到這裡，會停在這裡，不需要下中斷點，而且上架的話不影響user使用，user 在用時，到這裡會直接帶過
            assertionFailure("Invalid coordinate or location.")
            return
        }
        guard let oldCoordinate = oldCoordinate else {
            self.oldCoordinate = newCoordinate
            return
        }
        let area = [oldCoordinate, newCoordinate]
        let polyline = MKPolyline(coordinates: area, count: area.count)
            mainMapView.addOverlay(polyline)
        self.oldCoordinate = newCoordinate
        print("newCoordinate: \(newCoordinate), oldCoordinate: \(oldCoordinate)")
    }
    
     func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        polylineRenderer.strokeColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
        polylineRenderer.lineWidth = 5
        return polylineRenderer
    }
}

extension ViewController: CLLocationManagerDelegate {
    // MARK: - MKMapViewDelegate Methods.
    
    private func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let coordinate = mapView.region.center
        print("Map Center: \(coordinate.latitude), \(coordinate.longitude)")
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
