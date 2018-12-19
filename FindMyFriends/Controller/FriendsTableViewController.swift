//
//  FriendsTableViewController.swift
//  FindMyFriends
//
//  Created by HUNG-HSUN LIN on 2018/11/2.
//  Copyright © 2018 Hung Hsun Lin. All rights reserved.
//

import UIKit
import MapKit

class FriendsTableViewController: UITableViewController {
    
    let locationManger = CLLocationManager()
    var coordinate: CLLocationCoordinate2D?
    var locatities = [String]()
    var locatily = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // row的高度
        tableView.rowHeight = UITableView.automaticDimension
        
        // 開啟 Cell 自動列高
        tableView.estimatedRowHeight = 100
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        tableView.reloadData()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return ViewController.allFriends.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! FriendTableViewCell

        // Configure the cell...
        guard let friend = ViewController.allFriends[indexPath.row] else {
            assertionFailure("friend is nil.")
            return cell
        }
        guard let lat = Double(friend.lat), let lon = Double(friend.lon) else {
            return cell
        }
        cell.friend = friend
        cell.locatilyLabel.text = getLocatily(lat: lat, lon: lon)
        cell.distance.text = caculateDistance(lat: lat, lon: lon)
        
        return cell
    }
    
    private func getLocatily(lat: Double, lon: Double) -> String {
        let geocoder = CLGeocoder()
        let friendLocation = CLLocation(latitude: lat, longitude: lon)
        
        geocoder.reverseGeocodeLocation(friendLocation) { (placemarks, error) in
            if let error = error {
                print("geocoderAdressString fail: \(error)")
                return
            }
            guard let placemark = placemarks?[0].locality else {
                self.locatily = ""
                return
            }
            self.locatily = placemark
            print(self.locatily)
            self.tableView.reloadData()
        }
        return locatily
    }
    
    private func caculateDistance(lat: Double, lon: Double) -> String? {
        guard let location = locationManger.location else {
            assertionFailure("Get location fail.")
            return "error"
        }
        var stringDistance: String
        let friendLocation = CLLocation(latitude: lat, longitude: lon)
        var distance = location.distance(from: friendLocation)
        if distance / 1000 > 1 {
            distance = distance / 1000
            stringDistance = String(format: "%.2f", distance)
            stringDistance.append("公里")
        } else {
            stringDistance = String(format: "%.1f", distance)
            stringDistance.append("公尺")
        }
        return stringDistance
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        guard segue.identifier == "moveToFriend" else { return }
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            guard let lat = Double(ViewController.allFriends[selectedIndexPath.row]!.lat), let lon = Double(ViewController.allFriends[selectedIndexPath.row]!.lon) else {
                return
            }
            coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
    }
}
