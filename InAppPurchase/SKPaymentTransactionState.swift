//
//  SKPaymentTransactionState.swift
//  InAppPurchase
//
//  Created by Christian Otkjær on 18/03/16.
//  Copyright © 2016 Christian Otkjær. All rights reserved.
//

import StoreKit

//MARK: - Comparable

extension SKPaymentTransactionState : Comparable {}

public func < (lhs: SKPaymentTransactionState, rhs:SKPaymentTransactionState) -> Bool
{
    guard lhs != rhs else { return false }
    
    switch lhs
    {
    case .Deferred:
        return true
        
    case .Failed:
        return rhs != .Deferred
        
    case .Purchasing:
        return rhs != .Deferred && rhs != .Failed
        
    case .Restored:
        return rhs != .Deferred && rhs != .Failed && rhs != .Purchasing
        
    case .Purchased:
        return false
    }
}