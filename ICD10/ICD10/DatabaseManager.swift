/*
*  DatabaseManager.swift
*  A class to manage the database connection. Allows for opening and closing of the database so only one connection is open at one time.
*
*  Created by Brandon S Roberts on 6/9/15.
*  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
*/

import UIKit

class DatabaseManager {
    
    var db:COpaquePointer!
    
    /**
    *   Checks that the database file is on the device. If not, copies the database file to the device.
    *   Connects to the database after file is verified to be in the right spot.
    **/
    func checkDatabaseFileAndOpen() -> COpaquePointer{
        let theFileManager = NSFileManager.defaultManager()
        let filePath = dataFilePath()
        if theFileManager.fileExistsAtPath(filePath) {
            db = openDBPath(filePath)
            return db // And then open the DB File
        } else {
            
            let pathToBundledDB = NSBundle.mainBundle().pathForResource("testDML", ofType: "sqlite3")// Copy the file from the Bundle and write it to the Device
            let pathToDevice = dataFilePath()
            var error:NSError?
            
            if (theFileManager.copyItemAtPath(pathToBundledDB!, toPath:pathToDevice, error: nil)) {
                db = openDBPath(pathToDevice)
               return db//get the database open
            } else {
                println("database failure")
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
            println("opened database")
            return db
        }
    }
    
    func closeDB() {
        sqlite3_close(db)
    }
    
    //Adding information to the database*************************************************************************************************************
    
    func addAppointmentToDatabase(patientID:Int, doctorID:Int, date:String, placeID:Int, roomID:Int) -> Int{
        
        var aptID = 0
        
        let insertAPTQuery = "INSERT INTO Appointment (aptID, pID, dID, date, placeID, roomID) VALUES (NULL, '\(patientID)','\(doctorID)', '\(date)', '\(placeID)', '\(roomID)');"
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(db, insertAPTQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                aptID = Int(sqlite3_last_insert_rowid(statement))
                println("Successful Appointment save patientID:\(patientID) doctorID:\(doctorID) date:\(date) placeID:\(placeID) roomID:\(roomID)")
            }else {
                println("Failed appointment save patientID:\(patientID) doctorID:\(doctorID) date:\(date) placeID:\(placeID) roomID:\(roomID)")
            }
            
        }
        return aptID
    }
    
    func addPatientToDatabase(inputPatient:String, dateOfBirth:String){
        
        var (firstName, lastName) = split(inputPatient)
        
        println(dateOfBirth)
        let query = "INSERT INTO Patient (pID,date_of_birth,f_name,l_name, email) VALUES (NULL, '\(dateOfBirth)', '\(firstName)', '\(lastName!)', '')"
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                println("Saved \(firstName) \(lastName!)")
            }else {
                println("Add patient failed")
            }
        }
    }
    
    func addDoctorToDatabase(inputDoctor:String) {
        var (firstName, lastName) = split(inputDoctor)
        
        let query = "INSERT INTO Doctor (dID,f_name,l_name, email) VALUES (NULL,'\(firstName)', '\(lastName!)', '')"
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            var sqliteResult = sqlite3_step(statement)
            println(sqliteResult)
            if sqliteResult == SQLITE_DONE {
                println("Saved \(firstName) \(lastName!)")
            }else if sqliteResult == SQLITE_ERROR{
                println("Add doctor failed for \(firstName) \(lastName!)")
            }
            
        }
    }
    
    func addPlaceOfService(placeInput:String){
        let insertPlaceQuery = "INSERT INTO Place_of_service (placeID, place_description) VALUES (NULL, '\(placeInput)');"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, insertPlaceQuery, -1, &statement, nil) == SQLITE_OK {
            var sqliteResult = sqlite3_step(statement)
            if sqliteResult == SQLITE_DONE {
                println("Saved \(placeInput)")
            }else if sqliteResult == SQLITE_ERROR {
                println("Failed place of service save placeInput:\(placeInput)")
            }
        }
    }
    
    func addRoom(roomInput:String) {
        let insertPlaceQuery = "INSERT INTO Place_of_service (placeID, place_description) VALUES (NULL, '\(roomInput)');"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, insertPlaceQuery, -1, &statement, nil) == SQLITE_OK {
            var sqliteResult = sqlite3_step(statement)
            if sqliteResult == SQLITE_DONE {
                println("Successful room save \(roomInput)")
            }else if sqliteResult == SQLITE_ERROR {
                println("Failed room save \(roomInput)")
            }
        }
    }
    
    func addHasType(aptID:Int, visitCodeText:String) {
        let insertHasType = "INSERT INTO Has_type (aptID,apt_code) VALUES (\(aptID),'\(visitCodeText)')"
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(db, insertHasType, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                println("Successful vist code save:\(visitCodeText)")
            }else {
                println("Failed visit code save:\(visitCodeText)")
            }
        }
    }
    
    func addDiagnosedWith(aptID:Int, ICD10Text:String){
        let diagnosedWith = "INSERT INTO Diagnosed_with (aptID, ICD10_code) VALUES (\(aptID), '\(ICD10Text)')"
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(db, diagnosedWith, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                println("Successful ICD10 Save aptID:\(aptID) ICD10:\(ICD10Text)")
            } else {
                println("Failed ICD10 save aptID:\(aptID) ICD10:\(ICD10Text)")
            }
            
        }

    }
    
    //Retrieve information from the database*************************************************************************************************************
    
    /**
    *   Returns the id of the place of service. Adds place of service if it did not match any in the database.
    **/
    func getPlaceOfServiceID(placeInput:String) -> Int {
        
        var placeID = 0
        let placeQuery = "SELECT placeID FROM Place_of_service WHERE place_description='\(placeInput)'"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, placeQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                placeID = Int(sqlite3_column_int(statement, 0))
            } else {
                self.addPlaceOfService(placeInput)
                placeID = Int(sqlite3_last_insert_rowid(statement))
            }
        }
        return placeID
    }
    
    /**
    *   Returns the id of the room. Adds the room if it did not match any in the database.
    **/
    func getRoomID(roomInput:String) -> Int {
        
        var roomID = 0
        let roomQuery = "SELECT roomID FROM Room WHERE room_description='\(roomInput)'"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, roomQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {                                  //if we found a room grab it's id
                roomID = Int(sqlite3_column_int(statement, 0))
            } else {
                self.addRoom(roomInput)                                                 //input the room and then get the id
                roomID = Int(sqlite3_last_insert_rowid(statement))
            }
        }
        return roomID
    }
    
    
    /**
    *   Returns the id of the doctor. Adds the doctor if it did not match any in the database.
    **/
    func getDoctorID(doctorInput:String) -> Int {
        
        var dID = 0
        let (firstName, lastName) = split(doctorInput)
        let doctorQuery = "SELECT dID FROM Doctor WHERE f_name='\(firstName)' AND l_name='\(lastName!)';"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, doctorQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                dID = Int(sqlite3_column_int(statement, 0))
            }  else {
                self.addDoctorToDatabase(doctorInput)
                dID = Int(sqlite3_last_insert_rowid(statement))
            }
        }
        return dID
    }
    
    /**
    *   Returns the id of the patient. Adds the patient if it did not match any in the database.
    **/
    func getPatientID(patientInput:String, dateOfBirth:String) -> Int {
        
        var pID = 0
        let (firstName, lastName) = split(patientInput)
        let patientQuery = "SELECT pID FROM Patient WHERE f_name='\(firstName)' AND l_name='\(lastName!)'"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, patientQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW{
                pID = Int(sqlite3_column_int(statement, 0))
            } else {
                println("Added \(patientInput)")
                self.addPatientToDatabase(patientInput, dateOfBirth: dateOfBirth)
                pID = Int(sqlite3_last_insert_rowid(statement))
            }
        }
        return pID
    }
    
    //****************************************** Searches ******************************************************************************
    
    /**
    *   Searches for any patients matching the text that was input into the patient textfield.
    *   @return patients, a list of patients matching the user input
    **/
    func patientSearch(inputPatient:String) ->[(String, String)] {
        
        var patients:[(String, String)] = []
        
        let patientSearch = "SELECT * FROM Patient WHERE f_name LIKE '%\(inputPatient)%' OR l_name LIKE '%\(inputPatient)%';"//search and update the patients array
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(db, patientSearch, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                
                let id = sqlite3_column_int(statement, 0)
                
                let patientDOB = sqlite3_column_text(statement, 1)
                let patientDOBString = String.fromCString(UnsafePointer<CChar>(patientDOB))
                
                let patientFName = sqlite3_column_text(statement, 2)
                let patientFNameString = String.fromCString(UnsafePointer<CChar>(patientFName))
                
                let patientLName = sqlite3_column_text(statement, 3)
                let patientLNameString = String.fromCString(UnsafePointer<CChar>(patientLName))
                
                let patientFullName = patientFNameString! + " " + patientLNameString!
                
                let tuple = (patientDOBString!, patientFullName)
                patients.append(tuple)
            }
        }
        return patients
    }
    
    /**
    *   Searches for any doctors matching the text that was input into the doctor textfield.
    *   @return doctors, a list of doctors matching the user input
    **/
    func doctorSearch(inputDoctor:String) -> [String] {
        
        var doctors:[String] = []
        
        let doctorSearch = "SELECT dID, f_name, l_name FROM Doctor WHERE f_name LIKE '%\(inputDoctor)%' OR l_name LIKE '%\(inputDoctor)%';"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, doctorSearch, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = sqlite3_column_int(statement, 0)
                
                let doctorFName = sqlite3_column_text(statement, 1)
                let doctorFNameString = String.fromCString(UnsafePointer<CChar>(doctorFName))
                
                let doctorLName = sqlite3_column_text(statement, 2)
                let doctorLNameString = String.fromCString(UnsafePointer<CChar>(doctorLName))
                
                let doctorFullName = doctorFNameString! + " " + doctorLNameString!
                doctors.append(doctorFullName)
            }
        }
        return doctors
    }
    
    /**
    *   Searches for any code matching the text or code that was input into the visit code textField
    *   @return visitCodes, a list of code tuples (code, description)
    **/
    func codeSearch(codeType:String, cptTextFieldText:String, mcTextFieldText:String, pcTextFieldText:String) -> [(String,String)]{
        
        var visitCodes:[(String,String)] = []
        var inputSearch = ""
        
        switch codeType {
        case "C":inputSearch = cptTextFieldText
        case "M":inputSearch = mcTextFieldText
        case "P":inputSearch = pcTextFieldText
        default:break
        }
        
        let codeSearch = "SELECT apt_code, code_description FROM Apt_type WHERE type_description='\(codeType)' AND (code_description LIKE '%\(inputSearch)%' OR apt_code LIKE '%\(inputSearch)%');"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, codeSearch, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                
                let apt_code = sqlite3_column_text(statement, 0)
                let apt_codeString = String.fromCString(UnsafePointer<CChar>(apt_code))
                
                let code_description = sqlite3_column_text(statement, 1)
                let code_descriptionString = String.fromCString(UnsafePointer<CChar>(code_description))
                
                let tuple = (apt_codeString!, code_descriptionString!)
                visitCodes.append(tuple)
            }
        }
        return visitCodes
    }


    /**
    *   Splits a string with a space delimeter
    **/
    func split(splitString:String) -> (String, String?){
        
        let fullNameArr = splitString.componentsSeparatedByString(" ")
        var firstName: String = fullNameArr[0]
        var lastName: String =  fullNameArr[1]
        return (firstName, lastName)
    }


}
