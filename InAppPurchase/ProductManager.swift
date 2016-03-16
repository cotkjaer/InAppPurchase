//
//  ProductManager.swift
//  Silverback
//
//  Created by Christian Otkjær on 16/11/15.
//  Copyright © 2015 Christian Otkjær. All rights reserved.
//

import Foundation
import StoreKit
import Collections
import UserInterface
import Error
import Compare


public let ProductsFetchSuccededNotificationName = "ProductsFetchSuccededNotification"
public let ProductsFetchFailedNotificationName = "ProductsFetchFailedNotification"
public let ProductsStatesUpdatedNotificationName = "ProductsStatesUpdatedNotification"
public let ProductsRestoreSuccededNotificationName = "ProductsRestoreSuccededNotification"
public let ProductsRestoreFailedNotificationName = "ProductsRestoreFailedNotification"

public class ProductManager: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver
{
    public let products : Set<Product>
    
    public required init(productIdentifiers: Set<String>)
    {
        products = productIdentifiers.map( { Product.productWithIdentifier($0) } )
        
        super.init()
        
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
    }
    
    deinit
    {
        SKPaymentQueue.defaultQueue().removeTransactionObserver(self)
    }
    
    //MARK: - Lookup
    
    public func productWithIdentifier(identifier: String) -> Product?
    {
        return products.filter({ $0.productIdentifier == identifier }).first
    }
    
    //MARK: - SKProductsRequestDelegate
    
    private var allFetched : Bool { return products.all { $0.product != nil } }
    
    private var request : SKProductsRequest?
    
    private var fetching : Bool { return request != nil }
    
    public func fetchProducts()
    {
        if !fetching && !allFetched
        {
            let productsToFetch = products.sift { $0.product == nil }
            
            productsToFetch.forEach { $0.purchaseStatus >?= .PendingFetch }
            
            request = SKProductsRequest(productIdentifiers: productsToFetch.map( { $0.productIdentifier }))
            request?.delegate = self
            request?.start()
        }
    }
    
    public func fetchRequest(request: SKRequest, didFailWithError error: NSError)
    {
        self.request = nil
        
        UIApplication.topViewController()?.presentErrorAsAlert(error)
        
        NSNotificationCenter.defaultCenter().postNotificationName(ProductsFetchFailedNotificationName, object: self)
    }
    
    public func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse)
    {
        self.request = nil
        
        if response.products.isEmpty
        {
            fetchRequest(request, didFailWithError: NSError(domain: "In-App Purchase", code: 0, description: "No Products found, invalid identifiers: (" + response.invalidProductIdentifiers.joinWithSeparator(", ") + ")"))
        }
        else
        {
            for product in response.products
            {
                productWithIdentifier(product.productIdentifier)?.product = product
            }
            
            NSNotificationCenter.defaultCenter().postNotificationName(ProductsFetchSuccededNotificationName, object: self)
        }
        
        for product in products.filter( { $0.purchaseStatus == .PendingFetch })
        {
            product.purchaseStatus = .None
            
            do
            {
                try product.purchase()
            }
            catch let e
            {
                debugPrint("Caught error \(e)")
            }
        }
    }
    
    //MARK: - SKPaymentTransactionObserver (restore)
    
    public var canRestore : Bool
        {
            if restored || restoring
            {
                return false
            }
            
            return products.any { $0.purchaseStatus == .None }// !products.filter({ $0.purchaseStatus == .None }).isEmpty
    }
    
    public private(set) var restored = false
    
    public private(set) var restoring = false
    
    public func restoreProducts()
    {
        if canRestore
        {
            restoring = true
            
            SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
        }
    }
    
    public func paymentQueue(queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: NSError)
    {
        restoring = false
        
        NSNotificationCenter.defaultCenter().postNotificationName(ProductsRestoreFailedNotificationName, object: self)
        
        error.presentAsAlert()
    }
    
    public func paymentQueueRestoreCompletedTransactionsFinished(queue: SKPaymentQueue)
    {
        restoring = false
        restored = true
        
        NSNotificationCenter.defaultCenter().postNotificationName(ProductsRestoreSuccededNotificationName, object: self)
    }
    
    //MARK: - SKPaymentTransactionObserver (purchase)
    
    public var purchasing : Bool { return products.any { $0.purchaseStatus == .Purchasing } }// !products.filter({ $0.purchaseStatus == .Purchasing }).isEmpty }
    
    public func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction])
    {
        for transaction in transactions
        {
            let id = transaction.payment.productIdentifier
            
            if let product = productWithIdentifier(id)
            {
                product.purchaseStatus >?= Product.PurchaseStatus(transactionState: transaction.transactionState)
                
                debugPrint("got transaction state \(transaction.transactionState) for product \(transaction.payment.productIdentifier)")
                
                switch transaction.transactionState
                {
                case .Deferred:
                    queue.finishTransaction(transaction)
                    
                case .Failed:
                    transaction.error?.presentAsAlert()
                    product.purchaseStatus = .None
                    queue.finishTransaction(transaction)
                    
                case .Purchased:
                    queue.finishTransaction(transaction)
                    
                case .Purchasing:
                    debugPrint(".Purchasing - not calling 'queue.finishTransaction(transaction)'")
                    
                case .Restored:
                    queue.finishTransaction(transaction)
                }
            }
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(ProductsStatesUpdatedNotificationName, object: self)
    }
    
    public func paymentQueue(queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction])
    {
        debugPrint("Removed transactions \(transactions)")
    }
}

