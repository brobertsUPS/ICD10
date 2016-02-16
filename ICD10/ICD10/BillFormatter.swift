//
//  BillFormatter.swift
//  ICD10
//
//  Created by Administrator on 2/16/16.
//  Copyright © 2016 Brandon S Roberts. All rights reserved.
//

import UIKit

class BillFormatter {
    
    var dbManager:DatabaseManager!
    
    init(){
        dbManager = DatabaseManager()
    }
    
    func formatBill(date:String) -> String{
        
        dbManager.checkDatabaseFileAndOpen()
        
        let (patientsInfo, IDs, codeTypes, _, submitted) = dbManager.getBills(date)
        
        
        
        var htmlLine = "<!DOCTYPE html> <html> <head> <meta charset='UTF-8'> <title>Bills:\(date)</title> </head> <body> <table border='1' style='width:100%; '> <tr><td> Admin Doc </td><td> Date </td><td> Patient Name </td><td> Patient Date of Birth </td><td> Referring Doctor </td><td> Place of Service </td><td> Room </td><td> Visit Code </td><td> ICD10 </td><td> ICD9 </td> </tr>"
        
        var previousAdminDoc = ""
        
        for var i = 0; i<patientsInfo.count; i++ { //for every bill in the list get the information needed to submit
            
            if(submitted[i] == 0){
                
                let (_, dob, patientName) = patientsInfo[i]
                let (aptID, placeID, roomID) = IDs[i]
                let codeType = codeTypes[i]
                
                var (adminDoc, referDoc) = dbManager.getDoctorForBill(aptID)//doctor
                let place = dbManager.getPlaceForBill(placeID)//place
                let room = dbManager.getRoomForBill(roomID)//room
                
                if previousAdminDoc == adminDoc {
                    
                    adminDoc = ""
                } else {
                    previousAdminDoc = adminDoc
                }
                
                let (codesForBill, visitCodePriorityFromDatbase) = dbManager.getVisitCodesForBill(aptID)
                let modifiersForBill = dbManager.getModifiersForBill(aptID)
                
                htmlLine = htmlLine + makeHTMLLine(adminDoc,date: date, patientName: patientName, dob: dob, doctorName: referDoc, place: place, room: room, codesForBill: codesForBill, codeType: codeType, visitCodePriorityFromDatbase: visitCodePriorityFromDatbase, modifiers:modifiersForBill)
            }
        }
        
        htmlLine = htmlLine + "</table></body> </html>"
        
        dbManager.closeDB()
        
        return htmlLine
        
    }
    
    func makeHTMLLine(adminDoc:String, date:String, patientName:String, dob:String, doctorName:String, place:String, room:String, codesForBill:[String:[(icd10:String, icd9:String, icd10id:Int, extensionCode:String)]], codeType:Int, visitCodePriorityFromDatbase: [String], modifiers:[String:Int]) -> String {
        
        var htmlLine = ""
        
        var firstVisitCode = visitCodePriorityFromDatbase[0]
        
        var icdCodesForFirstVisitCode:[(icd10:String, icd9:String, icd10id:Int, extensionCode:String)] = codesForBill[firstVisitCode]!
        
        var (firstICD10, firstICD9, _, extensionCode) = icdCodesForFirstVisitCode[0]
        
        if extensionCode != "" {
            firstICD10 = extensionCode           //if the extensionCode is available make sure to bill it
        }
        
        if modifiers[firstVisitCode] != nil {
            
            firstVisitCode = firstVisitCode + dbManager.getModifierWithID(modifiers[firstVisitCode]!)
        }
        
        htmlLine = htmlLine + "<tr><td> \(adminDoc) </td><td> \(date) </td><td> \(patientName) </td><td> \(dob) </td><td> \(doctorName) </td><td> \(place) </td><td> \(room) </td><td> \(firstVisitCode) </td><td> \(firstICD10) </td><td> \(firstICD9) </td> </tr>"
        
        
        for var k=1; k<icdCodesForFirstVisitCode.count; k++ { //get the rest of the codes from the first visit code
            
            var (icd10, icd9, _, extensionCode) = icdCodesForFirstVisitCode[k]
            
            if extensionCode != "" {
                icd10 = extensionCode           //if the extensionCode is available make sure to bill it
            }
            
            htmlLine = htmlLine + "<tr> <td>  </td><td>  </td><td>  </td><td> </td><td> </td><td> </td><td> </td><td>  </td><td> \(icd10) </td><td> \(icd9) </td> </tr>"
        }
        
        for var i=1; i<visitCodePriorityFromDatbase.count; i++ {                    //go through the rest of the visit codes
            
            var visitCode = visitCodePriorityFromDatbase[i]
            
            var icdCodes:[(icd10:String, icd9:String, icd10id:Int, extensionCode:String)] = codesForBill[visitCode]!
            
            for var j=0; j<icdCodes.count; j++ { //icdCodes
                
                var (icd10, icd9, _, extensionCode) = icdCodes[j]
                
                if extensionCode != "" {
                    icd10 = extensionCode           //if the extensionCode is available make sure to bill it
                }
                
                if modifiers[visitCode] != nil {

                    visitCode = visitCode + dbManager.getModifierWithID(modifiers[visitCode]!)
                }
                
                htmlLine = htmlLine + "<tr> <td>  </td><td>  </td><td>  </td><td> </td><td> </td><td> </td><td> </td><td> \(visitCode) </td><td> \(icd10) </td><td> \(icd9) </td> </tr>"
                visitCode = ""
            }
        }
        return htmlLine
    }
    

}
