//
//  SKProduct.swift
//  InAppPurchase
//
//  Created by Christian Otkjær on 16/03/16.
//  Copyright © 2016 Christian Otkjær. All rights reserved.
//

import Foundation
import StoreKit
import Compare

// MARK: - Defaults

internal let defaults = NSUserDefaults.standardUserDefaults()

// MARK: - Price

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

// MARK: - Fetch

extension SKProduct
{
    // MARK: - Public
    
    public static func fetchProducts<S: SequenceType where S.Generator.Element == String>(productIdentifiers: S, completion: ((Set<SKProduct>, ErrorType?) -> ())? = nil)
    {
        ProductsFetcher(productIdentifiers: productIdentifiers, completion: completion).start()
    }
    
    public static func fetchProduct(productIdentifier: String?, completion: ((Set<SKProduct>, ErrorType?) -> ())? = nil)
    {
        if let id = productIdentifier
        {
            fetchProducts([id], completion: completion)
        }
    }
}

// MARK: - Restore

extension SKProduct
{
    public static func restoreProducts(completion: ((Set<String>, ErrorType?)->())? = nil)
    {
        ProductsRestorer.restoreProducts(completion)
    }
}


// MARK: - Cache

extension SKProduct
{
    public static func productWithIdentifier(identifier: String?) -> SKProduct?
    {
        return ProductsCache.defaultCache().productWithIdentifier(identifier)
    }
}

// MARK: - Purchase

extension SKProduct
{
    public func purchase(completion: (ErrorType?->())?)
    {
        ProductPurchaser.purchase(self, completion: completion)
    }
}

// MARK: - Purchase status

extension SKProduct
{
    public enum PurchaseStatus : Int, Comparable
    {
        // NO 1 for backwards compatability
        case None = 0, Purchasing = 2, Deferred = 3, Failed = 4, Purchased = 5
        
        init(transactionState: SKPaymentTransactionState?)
        {
            switch transactionState
            {
            case .Deferred? :
                self = .Deferred

            case .Failed? :
                self = .Failed
                
            case .Purchased?, .Restored? :
                self = .Purchased
                
            case .Purchasing? :
                self = .Purchasing

            default:
                self = .None
            }
        }
    }
    
    public var purchaseStatus : PurchaseStatus
        {
        get
        {
            return SKProduct.purchaseStatusForProductWithIdentifier(productIdentifier)
        }
        set
        {
            SKProduct.setPurchaseStatus(newValue, forProductWithIdentifier: productIdentifier)
        }
    }

    public func updatePurchaseStatus(status: PurchaseStatus)
    {
        purchaseStatus >?= status
    }
    
    public func updatePurchaseStatus(transactionState: SKPaymentTransactionState)
    {
        updatePurchaseStatus(PurchaseStatus(transactionState: transactionState))
    }
    
    // MARK: - Static
    
    public static func purchaseStatusForProductWithIdentifier(productIdentifier: String?) -> PurchaseStatus
    {
        if let productIdentifier = productIdentifier
        {
            return PurchaseStatus(rawValue: defaults.integerForKey(productIdentifier)) ?? .None
        }
        
        return .None
    }

    public static func setPurchaseStatus(status: PurchaseStatus, forProductWithIdentifier productIdentifier: String?)
    {
        if let productIdentifier = productIdentifier
        {
            defaults.setInteger(status.rawValue, forKey: productIdentifier)
            defaults.synchronize()
        }
    }
}

// MARK: - Statics

extension SKProduct
{
    public static func localizedTitleForProductWithIdentifier(identifier: String?) -> String?
    {
        guard let identifier = identifier else { return nil }
        
        if let product = productWithIdentifier(identifier)
        {
            return product.localizedTitle
        }
        
        return NSLocalizedString("\(identifier)-title", comment: identifier)
    }

    public static func localizedDescriptionForProductWithIdentifier(identifier: String?) -> String?
    {
        guard let identifier = identifier else { return nil }
        
        if let product = productWithIdentifier(identifier)
        {
            return product.localizedDescription
        }
        
        return NSLocalizedString("\(identifier)-description", comment: identifier)
    }

    public static func localizedPriceForProductWithIdentifier(identifier: String?) -> String?
    {
        guard let identifier = identifier else { return nil }
        
        if let product = productWithIdentifier(identifier)
        {
            return product.localizedPrice
        }
        
        return NSLocalizedString("\(identifier)-price", comment: identifier)
    }

    public func localizedInfo() -> ProductInfo
    {
        return (productIdentifier, localizedTitle, localizedDescription, localizedPrice ?? "x", purchaseStatus)
    }
    
    public static func localizedInfoForProdutWithIdentifier(identifier: String?) -> ProductInfo
    {
        if let identifier = identifier
        {
        return (
            identifier,
            localizedTitleForProductWithIdentifier(identifier) ?? "?",
            localizedDescriptionForProductWithIdentifier(identifier) ?? "?",
            localizedPriceForProductWithIdentifier(identifier) ?? "?",
            purchaseStatusForProductWithIdentifier(identifier)
        )
        }
        
        return ("","","","",.None)
    }
}

public typealias ProductInfo = (identifier: String, title: String, description: String, price: String, status: SKProduct.PurchaseStatus)



// MARK: - Comparable

public func < (lhs: SKProduct.PurchaseStatus, rhs: SKProduct.PurchaseStatus) -> Bool
{
    return lhs.rawValue < rhs.rawValue
}