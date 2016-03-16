//
//  ProductsCollectionViewController.swift
//  InAppPurchase
//
//  Created by Christian Otkjær on 16/03/16.
//  Copyright © 2016 Christian Otkjær. All rights reserved.
//

import UIKit
import Notification

// MARK: - Products Collection View

// MARK: Cell

public class ProductsCollectionViewCell : UICollectionViewCell
{
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var detailLabel: UILabel?
    @IBOutlet weak var statusLabel: UILabel?
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView?
}

public class ProductsCollectionViewController: UICollectionViewController, ProductsViewController
{
    let nhm = NotificationHandlerManager()
    
    public var productManager : ProductManager?//(productIdentifiers: Set())
        {
        didSet
        {
            if oldValue != nil
            {
                nhm.deregisterAll()
            }
            
            if let manager = productManager
            {
                nhm.onAny(from: manager) {
                    self.refreshUI()
                }
            }
            
            productManager?.fetchProducts()
            
            updateData()
            
            refreshUI()
        }
    }
    
    public override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        refreshUI()
    }
    
    // MARK: - data
    
    var data = Array<Array<Product>>()
    
    func updateData()
    {
        if let sortedProducts = productManager?.products.sort( { $0.productIdentifier < $1.productIdentifier } )
        {
            data = [sortedProducts]
        }
        else
        {
            data = []
        }
    }
    
    
    func productForIndexPath(indexPath: NSIndexPath) -> Product?
    {
        return data.get(indexPath.section)?.get(indexPath.item)
    }
    
    
    // MARK: UICollectionViewDataSource
    
    override public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    override public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    private let CellReuseIdentifier = "ProductCell"
    
    func cellReuseIdentifierForProduct(product: Product) -> String
    {
        return product.productIdentifier + CellReuseIdentifier
    }
    
    override public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        if let product = productForIndexPath(indexPath)
        {
            if let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellReuseIdentifierForProduct(product), forIndexPath: indexPath) as? ProductsCollectionViewCell
            {
                cell.titleLabel?.text = product.localizedTitle
                cell.detailLabel?.text = product.localizedDescription
                
                var color = UIColor.darkTextColor()
                
                switch product.purchaseStatus
                {
                case .Deferred:
                    cell.statusLabel?.text = nil//NSLocalizedString("Purchasing", comment:"Purchase deferred")
                    cell.activityIndicatorView?.startAnimating()
                    
                case .Failed:
                    cell.statusLabel?.text = NSLocalizedString("!", comment: "Purchase failed")
                    color = UIColor.redColor().darkerColor()
                    cell.activityIndicatorView?.stopAnimating()
                    
                case .Purchased:
                    cell.statusLabel?.text = NSLocalizedString("✓", comment: "Purchased")
                    color = UIColor.greenColor().darkerColor()
                    cell.activityIndicatorView?.stopAnimating()
                    
                    
                case .Purchasing:
                    cell.statusLabel?.text = nil//NSLocalizedString("Purchasing", comment: "")
                    cell.activityIndicatorView?.startAnimating()
                    
                    
                case .PendingFetch:
                    cell.titleLabel?.text = nil
                    cell.detailLabel?.text = nil
                    cell.statusLabel?.text = nil //NSLocalizedString("Fetching", comment: "")
                    cell.activityIndicatorView?.startAnimating()
                    
                case .None:
                    cell.statusLabel?.text = product.localizedPrice
                    cell.activityIndicatorView?.stopAnimating()
                    
                    color = view.tintColor
                }
                
                //            cell.statusLabel?.textColor = color
                
                cell.layer.borderColor = color.CGColor
                cell.titleLabel?.backgroundColor = color
                cell.titleLabel?.textColor = UIColor.whiteColor()
                cell.statusLabel?.backgroundColor = color
                cell.statusLabel?.textColor = UIColor.whiteColor()
                
                return cell
            }
            
            fatalError("could not get product or cell with identifier \(cellReuseIdentifierForProduct(product))")
        }
        
        fatalError("could not get product or product for indexPath \(indexPath)")
    }
    
    // MARK: UICollectionViewDelegate
    
    override public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
        
        if let product = productForIndexPath(indexPath)
        {
            do
            {
                try product.purchase()
            }
            catch let e as NSError
            {
                e.presentAsAlert()
            }
        }
    }
    
    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
    return true
    }
    */
    
    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
    return true
    }
    */
    
    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
    return false
    }
    
    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
    return false
    }
    
    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */
    
    // MARK: - Cancel Button
    
    @IBOutlet weak var cancelBarButton: UIBarButtonItem?
    @IBOutlet weak var cancelButton: UIButton?
    
    @IBAction func cancelButtonPressed()
    {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // MARK: - Restore Button
    
    @IBOutlet weak var restorePurchasesBarButton: UIBarButtonItem?
    @IBOutlet weak var restorePurchasesButton: UIButton?
    
    @IBAction func restorePurchasesButtonPressed()
    {
        productManager?.restoreProducts()
        refreshRestorePurchasesButton()
    }
    
    // MARK: - UI
    
    func refreshUI(animated animated: Bool = false)
    {
        refreshCollectionView(animated: animated)
        refreshRestorePurchasesButton(animated: animated)
    }
    
    func refreshRestorePurchasesButton(animated animated: Bool = false)
    {
        let enabled = productManager?.canRestore == true
        
        restorePurchasesButton?.enabled = enabled
        restorePurchasesBarButton?.enabled = enabled
    }
    
    // TODO: update animated
    func refreshCollectionView(animated animated: Bool = false)
    {
        self.collectionView?.reloadData()
    }
}