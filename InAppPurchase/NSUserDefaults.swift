//
//  NSUserDefaults.swift
//  InAppPurchase
//
//  Created by Christian Otkjær on 16/03/16.
//  Copyright © 2016 Christian Otkjær. All rights reserved.
//

import Foundation

//MARK: - Products

extension NSUserDefaults
{
    public func setProductPurchaseStatus(purchaseStatus: Product.PurchaseStatus, forKey key: String)
    {
        setInteger(purchaseStatus.rawValue, forKey: key)
    }
    
    public func purchaseStatusForKey(key: String) -> Product.PurchaseStatus
    {
        return Product.PurchaseStatus(rawValue: integerForKey(key)) ?? Product.PurchaseStatus.None
    }
}
