//
//  ProductsCache.swift
//  InAppPurchase
//
//  Created by Christian Otkjær on 17/03/16.
//  Copyright © 2016 Christian Otkjær. All rights reserved.
//

import StoreKit

public class ProductsCache
{
    private static var DefaultProductsCache = ProductsCache()

    public static func defaultCache() -> ProductsCache
    {
        return DefaultProductsCache
    }
    
    private init() { }
    
    private var products = Set<SKProduct>()
    
    public func addProduct(product: SKProduct) -> Bool
    {
        guard !products.contains(product) else { return false }
        
        products.insert(product)
        
        return products.contains(product)
    }
    
    public func productWithIdentifier(identifier: String?) -> SKProduct?
    {
        return products.find { $0.productIdentifier == identifier }
    }
    
    public func hasProductWithIdentifier(identifier: String?) -> Bool
    {
        return productWithIdentifier(identifier) != nil
    }
}