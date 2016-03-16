//
//  ProductsTableViewController.swift
//  InAppPurchase
//
//  Created by Christian Otkjær on 16/03/16.
//  Copyright © 2016 Christian Otkjær. All rights reserved.
//

import Foundation
import Notification

// MARK: - Products Table View

// MARK: Cell

public class ProductsTableViewCell: UITableViewCell
{
    // MARK: - Init
    
    required public init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        setup()
    }
    
    override public func awakeFromNib()
    {
        super.awakeFromNib()
        setup()
    }
    
    func setup()
    {
        selectionStyle = .None
    }
    
    override public func setHighlighted(highlighted: Bool, animated: Bool)
    {
        
    }
}

// MARK: Controller

public class ProductsTableViewController: UITableViewController, ProductsViewController
{
    let nhm = NotificationHandlerManager()
    
    public var productManager : ProductManager?
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
    
    
    // MARK: UITableViewDataSource
    
    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return data.count
    }
    
    private let CellReuseIdentifier = "ProductCell"
    
    func cellReuseIdentifierForProduct(product: Product) -> String
    {
        return product.productIdentifier + CellReuseIdentifier
    }
    
    func activityIndicator() -> UIActivityIndicatorView
    {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        activityIndicator.startAnimating()
        
        return activityIndicator
    }
    
    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if let product = productForIndexPath(indexPath)
        {
            let cellReuseIdentifier = cellReuseIdentifierForProduct(product)
            
            if let cell = tableView.dequeueReusableCellWithIdentifier(cellReuseIdentifier, forIndexPath: indexPath) as? ProductsTableViewCell
            {
                cell.textLabel?.text = product.localizedTitle
                cell.detailTextLabel?.text = product.localizedDescription
                
                
                switch product.purchaseStatus
                {
                case .Deferred:
                    cell.accessoryView = activityIndicator()
                    
                case .Failed:
                    cell.accessoryView = UILabel(text: NSLocalizedString("!", comment: "Purchase failed"), color: UIColor.redColor().darkerColor())
                    
                case .Purchased:
                    cell.accessoryType = .Checkmark
                    
                case .Purchasing:
                    cell.accessoryView = activityIndicator()
                    
                case .PendingFetch:
                    cell.accessoryView = activityIndicator()
                    
                case .None:
                    cell.accessoryView = UILabel(text: product.localizedPrice, color: UIColor.darkTextColor())
                }
                
                return cell
            }
            
            fatalError("could not get product or cell with identifier \(cellReuseIdentifierForProduct(product))")
        }
        
        fatalError("could not get product or product for indexPath \(indexPath)")
    }
    
    // MARK: UITableViewDelegate
    
    override public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        if let product = productForIndexPath(indexPath)
        {
            do
            {
                try product.purchase()
            }
            catch let error as NSError
            {
                error.presentAsAlert()
            }
        }
    }
    
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
        refreshTableView(animated: animated)
        refreshRestorePurchasesButton(animated: animated)
    }
    
    func refreshRestorePurchasesButton(animated animated: Bool = false)
    {
        let enabled = productManager?.canRestore == true
        
        restorePurchasesButton?.enabled = enabled
        restorePurchasesBarButton?.enabled = enabled
    }
    
    // TODO: update animated
    func refreshTableView(animated animated: Bool = false)
    {
        self.tableView?.reloadData()
    }
}