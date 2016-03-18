//
//  ProductsFetcher.swift
//  InAppPurchase
//
//  Created by Christian Otkjær on 17/03/16.
//  Copyright © 2016 Christian Otkjær. All rights reserved.
//

import Foundation
import StoreKit
import Collections

private var fetchers = Set<ProductsFetcher>()

public class ProductsFetcher: NSObject, SKProductsRequestDelegate
{
    // MARK: - Public
    
    internal init<S: SequenceType where S.Generator.Element == String>(productIdentifiers: S, completion: ((Set<SKProduct>, ErrorType?) -> ())?)
    {
        super.init()
        
        self.productIdentifiers = Set(productIdentifiers)
        self.completionHandler = { fetchers.remove(self); completion?($0,$1) }
    }

    internal func start()
    {
        fetchers.insert(self)
                
        let productIdentifiers = self.productIdentifiers.sift({ !cache.hasProductWithIdentifier($0) })
        
        if productIdentifiers.isEmpty
        {
            completionHandler(fetchedProducts, nil)
        }
        else
        {
            productsFetchRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
            productsFetchRequest?.delegate = self
            productsFetchRequest?.start()
        }
    }

    // MARK: - Private
    
    private var productIdentifiers = Set<String>()
    
    private var completionHandler : ((Set<SKProduct>, ErrorType?) -> ()) = { _ in }
    
    private var cache = ProductsCache.defaultCache()
    
    //MARK: - Fetching
        
    private var productsFetchRequest : SKProductsRequest?
    
    private var fetchedProducts : Set<SKProduct> { return Set(productIdentifiers.flatMap({ cache.productWithIdentifier($0)})) }
        
    private func stop(error: ErrorType? = nil)
    {
        productsFetchRequest?.delegate = nil
        productsFetchRequest = nil
        
        completionHandler(fetchedProducts, error)
    }

    //MARK: - SKProductsRequestDelegate

    public func fetchRequest(request: SKRequest, didFailWithError error: NSError)
    {
        stop(error)
    }
    
    public func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse)
    {
        response.invalidProductIdentifiers.forEach { debugPrint("Invalid product ID : \($0)") }
        
        response.products.forEach { cache.addProduct($0) }
        
        stop()
    }
}