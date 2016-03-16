//
//  SKProduct.swift
//  InAppPurchase
//
//  Created by Christian Otkjær on 16/03/16.
//  Copyright © 2016 Christian Otkjær. All rights reserved.
//

import Foundation
import StoreKit

extension SKProduct
{
    public var localizedPrice : String?
        {
            let numberFormatter = NSNumberFormatter()
            
            numberFormatter.formatterBehavior = .Behavior10_4
            numberFormatter.numberStyle = .CurrencyStyle
            numberFormatter.locale = priceLocale
            
            return numberFormatter.stringFromNumber(price)
    }
}
