/*
*  DatabaseManager.swift
*  A class to manage the database connection.
*
*  Created by Brandon S Roberts on 6/9/15.
*  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
*/

import UIKit

struct DatabaseManager {
    
    /**
    *   Checks that the database file is on the device. If not, copies the database file to the device.
    *   Connects to the database after file is verified to be in the right spot.
    **/
    func checkDatabaseFileAndOpen() -> COpaquePointer{
        let theFileManager = NSFileManager.defaultManager()
        let filePath = dataFilePath()
        if theFileManager.fileExistsAtPath(filePath) {
            return openDBPath(filePath) // And then open the DB File
        } else {
            
            let pathToBundledDB = NSBundle.mainBundle().pathForResource("testDML", ofType: "sqlite3")// Copy the file from the Bundle and write it to the Device
            let pathToDevice = dataFilePath()
            var error:NSError?
            
            if (theFileManager.copyItemAtPath(pathToBundledDB!, toPath:pathToDevice, error: nil)) {
               return openDBPath(pathToDevice)//get the database open
            } else {
               return nil // failure
            }
        }
    }
    
    /**
    *   Gets the path of the database file on the device
    **/
    func dataFilePath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentsDirectory = paths[0] as! NSString
        return documentsDirectory.stringByAppendingPathComponent("testDML.sqlite3") as String
    }
    
    /**
    *   Makes a connection to the database file located at the provided filePath
    **/
    func openDBPath(filePath:String) -> COpaquePointer {
        
        var db:COpaquePointer  = nil
        var result = sqlite3_open(filePath, &db)
        if result != SQLITE_OK {
            sqlite3_close(db)
            println("Failed To Open Database")
            return nil
        }else {
            return db
        }
    }

}
