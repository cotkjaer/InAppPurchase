//
//  Product.swift
//  InAppPurchase
//
//  Created by Christian Otkjær on 18/02/16.
//  Copyright © 2016 Christian Otkjær. All rights reserved.
//

import StoreKit
import Compare

private var productsCache = Dictionary<String, Product>()

public class Product: Hashable
{
    public enum PurchaseStatus : Int, Comparable
    {
        case None = 0, PendingFetch, Purchasing, Deferred, Failed, Purchased
        
        init(transactionState: SKPaymentTransactionState?)
        {
            if let state = transactionState
            {
                switch state
                {
                case .Deferred : self = .Deferred
                case .Failed : self = .Failed
                case .Purchased, .Restored : self = .Purchased
                case .Purchasing : self = .Purchasing
                }
            }
            else
            {
                self = .None
            }
        }
    }
    
    public let productIdentifier : String
    internal var product: SKProduct?
    public var purchaseStatus : PurchaseStatus
        {
        didSet
        {
            // Only persist permanent status
            if purchaseStatus == .Purchased
            {
                let settings = NSUserDefaults.standardUserDefaults()
                
                settings.setProductPurchaseStatus(purchaseStatus, forKey: productIdentifier)
                settings.synchronize()
            }
        }
    }
    
    internal init(_ productIdentifier: String)
    {
        self.productIdentifier = productIdentifier
        self.purchaseStatus = NSUserDefaults.standardUserDefaults().purchaseStatusForKey(productIdentifier) ?? .PendingFetch// PurchaseStatus(rawValue: NSUserDefaults.standardUserDefaults().integerForKey(productIdentifier)) ?? .PendingFetch
    }
    
    public var localizedTitle : String
        {
            if let localizedTitle = product?.localizedTitle
            {
                if !localizedTitle.isEmpty
                {
                    return localizedTitle
                }
            }
            return NSLocalizedString(productIdentifier, comment: "Product Identifier")
    }
    
    public var localizedDescription : String? { return product?.localizedDescription }
    public var localizedPrice : String? { return product?.localizedPrice }
    
    public func purchase() throws
    {
        switch purchaseStatus
        {
        case .Deferred:
            throw NSError(domain: "In-App Purchase", code: 4, description: "Waiting for purchase to be approved")
            
        case .Purchased:
            throw NSError(domain: "In-App Purchase", code: 3, description: "Already purchased")
            
        case .Purchasing:
            throw NSError(domain: "In-App Purchase", code: 0, description: "Already in the process of purchasing")
            
        default:
            
            if !SKPaymentQueue.canMakePayments()
            {
                purchaseStatus >?= .Failed
                throw NSError(domain: "In-App Purchase", code: 1, description: "Cannot make payment", reason: "Payments are disables in Settings")
            }
            
            if let skProduct = product
            {
                purchaseStatus = .Purchasing
                SKPaymentQueue.defaultQueue().addPayment(SKPayment(product: skProduct))
            }
            else
            {
                purchaseStatus >?= .PendingFetch
            }
        }
    }
    
    //MARK: Hashable
    
    public var hashValue : Int { return productIdentifier.hashValue }
}

//MARK: - Factory
public extension Product
{
    public class func productWithIdentifier(identifier: String) -> Product
    {
        if let product = productsCache[identifier]
        {
            return product
        }
        else
        {
            let product = Product(identifier)
            productsCache[identifier] = product
            return product
        }
    }
}

//MARK: - Equatable

public func ==(lhs: Product, rhs: Product) -> Bool
{
    return lhs.productIdentifier == rhs.productIdentifier
}

// MARK: - Comparable

public func <(lhs: Product.PurchaseStatus, rhs: Product.PurchaseStatus) -> Bool
{
    return lhs.rawValue < rhs.rawValue
}

