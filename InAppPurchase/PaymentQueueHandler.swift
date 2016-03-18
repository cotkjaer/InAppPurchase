//
//  PaymentTransactionObserver.swift
//  InAppPurchase
//
//  Created by Christian Otkjær on 17/03/16.
//  Copyright © 2016 Christian Otkjær. All rights reserved.
//

import StoreKit
import Compare

internal protocol PaymentQueueHandlerObserver : class
{
    func handlerWillUpdateTransactions(handler: PaymentQueueHandler)
    
    func handlerDidUpdateTransactions(handler: PaymentQueueHandler)
    
    func handleTransaction(transaction: SKPaymentTransaction) -> Bool
}

internal protocol PaymentQueueHandlerRestoreObserver : PaymentQueueHandlerObserver
{
    func handlerDidRestoreCompletedTransactions(error: ErrorType?)
}

private var DefaultPaymentQueueHandler : PaymentQueueHandler?

internal class PaymentQueueHandler: NSObject, SKPaymentTransactionObserver
{
    static func defaultHandler() -> PaymentQueueHandler
    {
        if DefaultPaymentQueueHandler == nil
        {
            DefaultPaymentQueueHandler = PaymentQueueHandler()
        }
        
        if let d = DefaultPaymentQueueHandler
        {
            return d
        }
        else
        {
            fatalError("Could not set up default Payment Queue Handler")
        }
    }
    
    var queue: SKPaymentQueue = SKPaymentQueue.defaultQueue()
    
    required init(queue: SKPaymentQueue? = nil)
    {
        super.init()
        
        if let queue = queue
        {
            self.queue !?= queue
        }

        self.queue.addTransactionObserver(self)
    }
    
    deinit
    {
        queue.removeTransactionObserver(self)
    }
    
    // MARK: - observers
    
    var observers = Array<PaymentQueueHandlerObserver>()
    
    func addObserver(observer: PaymentQueueHandlerObserver) -> Bool
    {
        guard !observers.contains({ $0 === observer }) else { return false }
        
        observers.append(observer)
        
        return true
    }

    func removeObserver(observer: PaymentQueueHandlerObserver) -> Bool
    {
        guard let index = observers.indexOf({ $0 === observer }) else { return false }
        
        observers.removeAtIndex(index)
        
        return true
    }
    
    //MARK: - SKPaymentTransactionObserver (restore)
    
    func paymentQueueRestoreCompletedTransactionsFinished(queue: SKPaymentQueue)
    {
        observers.cast(PaymentQueueHandlerRestoreObserver).forEach{ $0.handlerDidRestoreCompletedTransactions(nil) }
    }
    
    func paymentQueue(queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: NSError)
    {
        observers.cast(PaymentQueueHandlerRestoreObserver).forEach{ $0.handlerDidRestoreCompletedTransactions(error) }
    }
    
    func productWithIdentifier(id: String?) -> SKProduct?
    {
        return ProductsCache.defaultCache().productWithIdentifier(id)
    }
    
    //MARK: - SKPaymentTransactionObserver (transactions)
    
    internal func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction])
    {
        observers.forEach { $0.handlerWillUpdateTransactions(self) }
        
        for transaction in transactions
        {
            let id = transaction.payment.productIdentifier
            
            if let product = productWithIdentifier(id)
            {
                product.updatePurchaseStatus(transaction.transactionState)
            }
            
            let handled = observers.map { $0.handleTransaction(transaction) }.any { $0 }
            
            if handled && transaction.transactionState != .Purchasing
            {
                queue.finishTransaction(transaction)
            }
            
            debugPrint("got transaction state \(transaction.transactionState) for product \(transaction.payment.productIdentifier)")
        }
        
        observers.forEach { $0.handlerDidUpdateTransactions(self) }
    }
}