//
//  LogLocation.swift
//  FindMyFriends
//
//  Created by HUNG-HSUN LIN on 2018/11/8.
//  Copyright © 2018 Hung Hsun Lin. All rights reserved.
//

import Foundation
import SQLite

class LogLocation {
    static let tableName = "locationLog"
    static let locationIdKey = "locationId"
    static let idKey = "id"
    static let nameKey = "name"
    static let lastUpdateDateTimeKey = "lastUpdateDateTime"
    static let latKey = "lat"
    static let lonKey = "lon"
    
    var friendIDs = [Int64]()
    
    // SQLite.swift support.
    
    // Int -> In 64bit CPU's iphone, Int is Int64, In 32bit CPU's iphone, Int is Int32, so if delimit Int64, in 32bit or 64 bit CPU, Int always is Int64.
    
    // In here can assign upside's property, because they use static.
    var db: Connection!
    var logTable = Table(tableName)
    var locationIdColumn = Expression<Int64>(locationIdKey)
    var idColumn = Expression<String>(idKey)
    var nameColumn = Expression<String>(nameKey)
    var lastUpdateDateTimeColumn = Expression<String>(lastUpdateDateTimeKey)
    var latColumn = Expression<String>(latKey)
    var lonColumn = Expression<String>(lonKey)
    
    init() {
        // Prepare DB filename/path.
        let filemanager = FileManager.default
        let documentsURL = filemanager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fullURLPath = documentsURL.appendingPathComponent("log.sqlite").path
        var isNewDB = false
        if !filemanager.fileExists(atPath: fullURLPath) {
            isNewDB = true
        }
        
        // Prepare connection of DB.
        // First check if the new database exists. Otherwise, the DB will always exist.
        do {
            db = try Connection(fullURLPath)
        } catch  {
            assertionFailure("Fail to create connection.")
            return
        }
        
        // Create Table at the first time.
        if isNewDB {
            do {
                let command = logTable.create { (builder) in
                    builder.column(locationIdColumn, primaryKey: true)
                    builder.column(idColumn)
                    builder.column(nameColumn)
                    builder.column(lastUpdateDateTimeColumn)
                    builder.column(latColumn)
                    builder.column(lonColumn)
                }
                try db.run(command)
                print("Log table is creat OK.")
            } catch {
                assertionFailure("Fail to create tabel: \(error).")
            }
        } else {
            // Keep mid into friendIDs.
            do {
                // SELECT * FROM "locationLog";
                for friend in try db.prepare(logTable) {
                    friendIDs.append(friend[locationIdColumn])
                }
            } catch  {
                assertionFailure("Fail to execute prepare command: \(error).")
            }
            print("There are total \(friendIDs.count) messages in DB.")
        }
    }
    
    var count: Int {
        return friendIDs.count
    }
    
    // Insert data to DB.
    func append(_ friend: Friend) {
        let command = logTable.insert(idColumn <- friend.id,
                                      nameColumn <- friend.friendName,
                                      lastUpdateDateTimeColumn <- friend.lastUpdateDateTime,
                                      latColumn <- friend.lat,
                                      lonColumn <- friend.lon)
        do {
            let newFriendID = try db.run(command)
            friendIDs.append(newFriendID)
        } catch {
            assertionFailure("Fail to inser a new message: \(error)")
            return
        }
    }
    
    func getFriend(at: Int) -> Friend? {
        guard at >= 0 && at < count else {
            assertionFailure("Invalid friend index.")
            return nil
        }
        let targetFriendID = friendIDs[at]
        
        // SELECT * FROM "logLocation" WHERE mid == xxxx;
        let results = logTable.filter(locationIdColumn == targetFriendID)
        // Pick the first one.
        do {
            guard let friend = try db.pluck(results) else {
                assertionFailure("Fail to get the only one result.")
                return nil
            }
            return Friend(friendName: friend[nameColumn], id: friend[idColumn], lastUpdateDateTime: friend[lastUpdateDateTimeColumn], lat: friend[latColumn], lon: friend[lonColumn])
        } catch {
            print("Pluck fail: \(error)")
        }
        return nil
    }
    
    // MARK: - Photo cache support.
    func load(image filename: String) -> UIImage? {
        let url = urlFor(filename)
        return UIImage(contentsOfFile: url.path)
        
    }
    
    func save(image data: Data, filename: String) {
        let url = urlFor(filename)
        do {
            try data.write(to: url)
        } catch  {
            assertionFailure("Fail to save image: \(error)")
        }
    }
    
    // Set file path.
    private func urlFor(_ filename: String) -> URL {
        let filemanager = FileManager.default
        let documentsURL = filemanager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsURL.appendingPathComponent(filename)
    }
}
