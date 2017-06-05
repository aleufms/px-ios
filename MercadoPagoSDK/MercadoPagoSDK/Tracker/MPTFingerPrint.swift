//
//  MPTDevice.swift
//  MercadoPagoSDK
//
//  Created by Demian Tejo on 6/1/17.
//  Copyright © 2017 MercadoPago. All rights reserved.
//

import UIKit

/*
class MPTFingerPrint: NSObject{
    var clientId : String!

    init(publicKey : String, checkoutVersion: String, platform: String) {
        self.clientId = UIDevice.current.identifierForVendor!.uuidString
    }
    
    open func toJSON() -> [String:Any] {
        let exclusionPattern : Any = String.isNullOrEmpty(self.exclusionPattern) ?  JSONHandler.null : self.exclusionPattern!
        let installmentsPattern : Any = self.installmentsPattern == nil ?  JSONHandler.null : self.installmentsPattern
        let pattern : Any = self.pattern == nil ? JSONHandler.null : self.pattern
        
        let obj: [String:Any] = [
            "pattern": pattern,
            "installments_pattern": installmentsPattern,
            "exclusion_pattern": exclusionPattern
        ]
        return obj
    }
    
    open func toJSONString() -> String {
        return JSONHandler.jsonCoding(self.toJSON())
    }
    
}
 */

class MPTDevice : NSObject {
    
    var model : String
    var os : String
    var systemVersion : String
    var screenSize : String
    var resolution : String
    
    override init() {
        self.model = UIDevice.current.model
        self.os =  "iOS"
        self.systemVersion = UIDevice.current.systemVersion
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        self.screenSize = String(describing: screenWidth) + "x" + String(describing: screenHeight)
        self.resolution = String(describing: UIScreen.main.scale)
    }
    
    
    open func toJSON() -> [String:Any] {
        let obj: [String:Any] = [
            "model": model,
            "os": os,
            "system_version": systemVersion,
            "screen_size": screenSize,
            "resolution": resolution
        ]
        return obj
    }
    
    open func toJSONString() -> String {
        return JSONHandler.jsonCoding(self.toJSON())
    }
    
}

class MPTApplication : NSObject {
    var publicKey : String
    var checkoutVersion : String
    var platform : String
    
    init(publicKey : String, checkoutVersion: String, platform : String) {
        self.publicKey = publicKey
        self.checkoutVersion = checkoutVersion
        self.platform = platform
    }
    
    open func toJSON() -> [String:Any] {
        let obj: [String:Any] = [
            "public_key": publicKey,
            "checkout_version": checkoutVersion,
            "platform": platform
        ]
        return obj
    }
    
    open func toJSONString() -> String {
        return JSONHandler.jsonCoding(self.toJSON())
    }
    
}
