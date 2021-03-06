/**						
	
					INSTRUCTIONS :
	
	How to install the Rendition Database

	1.  Create your database.
	2.  Replace #NEW_DATABASE_NAME# (below) with your database name.
	3.  Execute this script to install the Rendition database on your new database.

*/
USE [#NEW_DATABASE_NAME#]

GO
/****** Object:  Table [dbo].[itemDetail]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[itemDetail](
	[itemDetailID] [uniqueidentifier] NOT NULL,
	[itemNumber] [varchar](50) NOT NULL,
	[subItemNumber] [char](50) NOT NULL,
	[qty] [int] NOT NULL,
	[depth] [int] NOT NULL,
	[itemQty] [int] NOT NULL,
	[kitStock] [int] NOT NULL,
	[showAsSeperateLineOnInvoice] [bit] NULL,
	[onlyWhenSelectedOnForm] [bit] NULL,
	[itemComponetType] [varchar](50) NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_ItemDetail] PRIMARY KEY CLUSTERED 
(
	[itemDetailID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE NONCLUSTERED INDEX [IX_ItemDetail] ON [dbo].[itemDetail] 
(
	[itemNumber] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[vendorItems]    Script Date: 03/11/2011 19:45:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[vendorItems](
	[vendorItemId] [uniqueidentifier] NOT NULL,
	[vendorId] [int] NOT NULL,
	[itemNumber] [char](50) NOT NULL,
	[price] [money] NOT NULL,
	[description] [char](100) NOT NULL,
	[qtyOnHand] [int] NOT NULL,
	[qtyReceived] [int] NOT NULL,
	[qtyOrdered] [int] NOT NULL,
	[orderedOn] [datetime] NOT NULL,
	[recievedOn] [datetime] NULL,
	[estimatedRecieveDate] [datetime] NOT NULL,
	[addedBy] [int] NULL,
	[addedOn] [date] NULL,
	[depletionOrder] [int] NULL,
	[poNumber] [varchar](100) NULL,
	[orderId] [int] NULL,
	[cartId] [uniqueidentifier] NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_vendorItems] PRIMARY KEY CLUSTERED 
(
	[vendorItemId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE NONCLUSTERED INDEX [idx_vendorItems_orderedOn] ON [dbo].[vendorItems] 
(
	[orderedOn] ASC
)
INCLUDE ( [qtyOrdered]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_vendorItems_recievedOn] ON [dbo].[vendorItems] 
(
	[recievedOn] ASC
)
INCLUDE ( [qtyOrdered]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_vendorItemsOrderedOn] ON [dbo].[vendorItems] 
(
	[orderedOn] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_vendorItemsRecievedOn] ON [dbo].[vendorItems] 
(
	[recievedOn] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
/****** Object:  StoredProcedure [dbo].[kitList]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[kitList] (@itemnumber varchar(50),@qty int) as
--This is a non-recursive preorder traversal.
 SET NOCOUNT ON
 DECLARE @lvl int
 DECLARE @line varchar(50)
 DECLARE @itemQty int
 DECLARE @baseItemnumber varchar(50)
 set @baseItemnumber = @itemnumber
 CREATE TABLE #stack (itemnumber varchar(50), lvl int,qty int)	--Create a tempory stack.
 CREATE TABLE #out (itemnumber varchar(50), lvl int,qty int,itemQty int,kitStock int)
 INSERT INTO #stack VALUES (@itemnumber, 1,@qty)	--Insert current node to the stack.
 SELECT @lvl = 1				
 WHILE @lvl > 0					--From the top level going down.
	BEGIN
	    IF EXISTS (SELECT * FROM #stack WHERE lvl = @lvl)
	        BEGIN
	            SELECT @itemnumber = itemnumber,@qty = qty	--Find the first node that matches current node's name.
	            FROM #stack with (nolock)
	            WHERE lvl = @lvl
	            SET @line = @itemnumber --@lvl - 1 s spaces before the node name.
				SET @itemQty = (select sum(qtyOnHand) from dbo.vendorItems with (nolock) where itemnumber = @itemnumber and qtyOnHand >= 1)
				IF(@itemQty is null)
				BEGIN
					SET @itemQty = 0
				END
				insert #out (itemnumber,lvl,qty,itemQty,kitStock) values (@line,@lvl,@qty,@itemQty,@itemQty/@qty) -- Insert it into the output table.
	            DELETE FROM #stack
	            WHERE lvl = @lvl
	                AND itemnumber = @itemnumber	--Remove the current node from the stack.
	            INSERT #stack		--Insert the childnodes of the current node into the stack.
	                SELECT subitemnumber, @lvl + 1,qty*@qty
	                FROM itemdetail with (nolock)
	                WHERE itemnumber = @itemnumber
	            IF @@ROWCOUNT > 0		--If the previous statement added one or more nodes, go down for its first child.
                        SELECT @lvl = @lvl + 1	--If no nodes are added, check its brother nodes.
		END
    	    ELSE
	      	SELECT @lvl = @lvl - 1		--Back to the level immediately above.
       END 
-- select populated stack
if exists(select * from #out where lvl > 1)
BEGIN
	select UPPER(@baseItemnumber) as itemnumber,itemnumber as subItemnumber,lvl,qty,itemQty,kitStock from #out where lvl > 1
END
ELSE
BEGIN
	select UPPER(@baseItemnumber) as itemnumber,itemnumber as subItemnumber,lvl,qty,itemQty,kitStock from #out
END
SET NOCOUNT off
GO
/****** Object:  Table [dbo].[itemOnHandTemp]    Script Date: 03/11/2011 19:45:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[itemOnHandTemp](
	[itemnumber] [varchar](50) NOT NULL,
	[volume] [int] NOT NULL,
	[prebook] [int] NOT NULL,
	[wip] [int] NOT NULL,
	[ats] [int] NOT NULL,
	[consumed] [int] NOT NULL,
	[addedOn] [datetime] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_itemOnHandTemp_1] PRIMARY KEY CLUSTERED 
(
	[itemnumber] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE NONCLUSTERED INDEX [idx_itemOnHandTemp_itemNumber] ON [dbo].[itemOnHandTemp] 
(
	[itemnumber] ASC
)
INCLUDE ( [ats],
[wip],
[volume],
[prebook]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[orders]    Script Date: 03/11/2011 19:45:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[orders](
	[orderId] [int] NOT NULL,
	[orderDate] [datetime] NOT NULL,
	[grandTotal] [money] NOT NULL,
	[taxTotal] [money] NOT NULL,
	[subTotal] [money] NOT NULL,
	[shippingTotal] [money] NOT NULL,
	[service1] [money] NOT NULL,
	[service2] [money] NOT NULL,
	[manifest] [varchar](120) NOT NULL,
	[purchaseOrder] [varchar](120) NOT NULL,
	[discount] [money] NOT NULL,
	[comment] [varchar](max) NOT NULL,
	[paid] [money] NOT NULL,
	[billToAddressId] [uniqueidentifier] NOT NULL,
	[closed] [bit] NOT NULL,
	[canceled] [bit] NOT NULL,
	[termId] [int] NOT NULL,
	[userId] [int] NOT NULL,
	[orderNumber] [char](50) NOT NULL,
	[creditMemo] [bit] NOT NULL,
	[scanned_order_image] [varchar](max) NOT NULL,
	[readyForExport] [datetime] NOT NULL,
	[recalculatedOn] [datetime] NOT NULL,
	[sessionId] [uniqueidentifier] NOT NULL,
	[soldBy] [int] NOT NULL,
	[requisitionedBy] [int] NOT NULL,
	[approvedBy] [int] NOT NULL,
	[deliverBy] [datetime] NOT NULL,
	[vendor_accountNo] [varchar](50) NOT NULL,
	[FOB] [varchar](50) NOT NULL,
	[parentOrderId] [int] NOT NULL,
	[discountPct] [float] NOT NULL,
	[discountCode] [varchar](50) NOT NULL,
	[avgTaxRate] [float] NOT NULL,
	[instantiationSession] [uniqueidentifier] NOT NULL,
	[exported] [bit] NOT NULL,
	[unique_siteId] [uniqueidentifier] NOT NULL,
	[generalLedgerInsertId] [uniqueidentifier] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_orders] PRIMARY KEY CLUSTERED 
(
	[orderId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE NONCLUSTERED INDEX [date_index] ON [dbo].[orders] 
(
	[orderDate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[kitAllocation]    Script Date: 03/11/2011 19:45:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[kitAllocation](
	[kitAllocationId] [int] IDENTITY(1,1) NOT NULL,
	[cartId] [uniqueidentifier] NOT NULL,
	[itemNumber] [varchar](50) NOT NULL,
	[qty] [int] NOT NULL,
	[vendorItemKitAssignmentId] [uniqueidentifier] NULL,
	[itemConsumed] [bit] NULL,
	[allowPreorders] [bit] NULL,
	[showAsSeperateLineOnInvoice] [bit] NULL,
	[valueCostTotal] [money] NULL,
	[noTaxValueCostTotal] [money] NULL,
	[inventoryItem] [bit] NULL,
	[generalLedgerId] [uniqueidentifier] NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_kitAllocation] PRIMARY KEY CLUSTERED 
(
	[kitAllocationId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE NONCLUSTERED INDEX [idx_kitAllocationitemConsumed] ON [dbo].[kitAllocation] 
(
	[itemConsumed] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_kitAllocationItemnumber] ON [dbo].[kitAllocation] 
(
	[itemNumber] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_kitAllocationVendorItemKitAssignmentId] ON [dbo].[kitAllocation] 
(
	[vendorItemKitAssignmentId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_kitalocation_itemnumber] ON [dbo].[kitAllocation] 
(
	[itemNumber] ASC
)
INCLUDE ( [qty]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_kitAllocation] ON [dbo].[kitAllocation] 
(
	[itemNumber] ASC,
	[cartId] ASC,
	[kitAllocationId] ASC,
	[vendorItemKitAssignmentId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[cart]    Script Date: 03/11/2011 19:45:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[cart](
	[cartId] [uniqueidentifier] NOT NULL,
	[sessionId] [uniqueidentifier] NOT NULL,
	[qty] [int] NOT NULL,
	[itemNumber] [varchar](50) NOT NULL,
	[price] [money] NOT NULL,
	[addTime] [datetime] NOT NULL,
	[orderId] [int] NOT NULL,
	[serialId] [int] NOT NULL,
	[orderNumber] [varchar](10) NOT NULL,
	[serialNumber] [varchar](10) NOT NULL,
	[userId] [int] NOT NULL,
	[addressId] [uniqueidentifier] NOT NULL,
	[shipmentId] [int] NOT NULL,
	[shipmentNumber] [varchar](10) NOT NULL,
	[lineNumber] [int] NOT NULL,
	[epsmmcsOutput] [varchar](100) NOT NULL,
	[epsmmcsAIFilename] [varchar](50) NOT NULL,
	[termId] [int] NOT NULL,
	[valueCostTotal] [money] NOT NULL,
	[noTaxValueCostTotal] [money] NOT NULL,
	[fulfillmentDate] [datetime] NOT NULL,
	[estimatedFulfillmentDate] [datetime] NOT NULL,
	[parentCartId] [uniqueidentifier] NOT NULL,
	[backorderedQty] [int] NOT NULL,
	[canceledQty] [int] NOT NULL,
	[returnToStock] [int] NOT NULL,
	[customerLineNumber] [varchar](50) NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_Cart] PRIMARY KEY CLUSTERED 
(
	[cartId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 95) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE NONCLUSTERED INDEX [idx_cartEstFillDate] ON [dbo].[cart] 
(
	[estimatedFulfillmentDate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_cartFillDate] ON [dbo].[cart] 
(
	[fulfillmentDate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [index_extra_lookup_fields] ON [dbo].[cart] 
(
	[orderNumber] ASC,
	[serialNumber] ASC,
	[shipmentNumber] ASC,
	[itemNumber] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 95) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [index_lookup_fields] ON [dbo].[cart] 
(
	[sessionId] ASC,
	[orderId] ASC,
	[serialId] ASC,
	[userId] ASC,
	[addressId] ASC,
	[shipmentId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[users]    Script Date: 03/11/2011 19:45:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[users](
	[userId] [int] NOT NULL,
	[userLevel] [int] NOT NULL,
	[handle] [varchar](50) NOT NULL,
	[email] [varchar](50) NOT NULL,
	[wholeSaleDealer] [bit] NOT NULL,
	[lastVisit] [datetime] NOT NULL,
	[comments] [varchar](max) NOT NULL,
	[password] [varchar](50) NOT NULL,
	[administrator] [bit] NOT NULL,
	[wouldLikeEmail] [bit] NOT NULL,
	[createDate] [datetime] NOT NULL,
	[sessionId] [uniqueidentifier] NOT NULL,
	[quotaWholesale] [bit] NOT NULL,
	[quotaComplete] [bit] NOT NULL,
	[quota] [int] NOT NULL,
	[credit] [money] NOT NULL,
	[loggedIn] [bit] NOT NULL,
	[purchaseAccount] [varchar](50) NOT NULL,
	[creditLimit] [money] NOT NULL,
	[contact] [varchar](255) NOT NULL,
	[address1] [varchar](25) NOT NULL,
	[address2] [varchar](25) NOT NULL,
	[zip] [varchar](15) NOT NULL,
	[state] [varchar](50) NOT NULL,
	[country] [varchar](50) NOT NULL,
	[city] [varchar](50) NOT NULL,
	[homePhone] [varchar](50) NOT NULL,
	[companyEmail] [varchar](100) NOT NULL,
	[fax] [varchar](50) NOT NULL,
	[www] [varchar](100) NOT NULL,
	[firstName] [varchar](100) NOT NULL,
	[lastName] [varchar](100) NOT NULL,
	[termId] [int] NOT NULL,
	[usesTerms] [bit] NOT NULL,
	[accountType] [int] NOT NULL,
	[noTax] [bit] NOT NULL,
	[allowPreorders] [bit] NOT NULL,
	[FOB] [varchar](100) NOT NULL,
	[packingSlip] [varchar](255) NOT NULL,
	[quote] [varchar](255) NOT NULL,
	[invoice] [varchar](255) NOT NULL,
	[logon_redirect] [varchar](255) NOT NULL,
	[admin_script] [varchar](50) NOT NULL,
	[rateId] [int] NOT NULL,
	[workPhone] [varchar](50) NOT NULL,
	[sendShipmentUpdates] [bit] NOT NULL,
	[autoFillOrderForm] [bit] NOT NULL,
	[estTransitTime] [int] NOT NULL,
	[estLeadTime] [int] NOT NULL,
	[UI_JSON] [varchar](max) NOT NULL,
	[assetAccount] [int] NULL,
	[defaultPrinterPath] [varchar](255) NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK__Users__2C3393D0] PRIMARY KEY CLUSTERED 
(
	[userId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 99) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE NONCLUSTERED INDEX [idx_users_notax] ON [dbo].[users] 
(
	[noTax] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_usersAccounttype] ON [dbo].[users] 
(
	[accountType] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_usersEmail] ON [dbo].[users] 
(
	[email] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_usersPassword] ON [dbo].[users] 
(
	[password] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [index_email] ON [dbo].[users] 
(
	[email] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
GO
INSERT [dbo].[users] ([userId], [userLevel], [handle], [email], [wholeSaleDealer], [lastVisit], [comments], [password], [administrator], [wouldLikeEmail], [createDate], [sessionId], [quotaWholesale], [quotaComplete], [quota], [credit], [loggedIn], [purchaseAccount], [creditLimit], [contact], [address1], [address2], [zip], [state], [country], [city], [homePhone], [companyEmail], [fax], [www], [firstName], [lastName], [termId], [usesTerms], [accountType], [noTax], [allowPreorders], [FOB], [packingSlip], [quote], [invoice], [logon_redirect], [admin_script], [rateId], [workPhone], [sendShipmentUpdates], [autoFillOrderForm], [estTransitTime], [estLeadTime], [UI_JSON], [assetAccount], [defaultPrinterPath]) VALUES (0, 0, N'Nobody', N'', 0, CAST(0x00009E5E00000000 AS DateTime), N'This account represents the system', N'', 0, 0, CAST(0x00009E5E00000000 AS DateTime), N'00000000-0000-0000-0000-000000000000', 0, 0, 0, 0.0000, 0, N'', 0.0000, N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', 0, 0, 0, 0, 0, N'', N'', N'', N'', N'', N'', 6, N'', 0, 0, 0, 0, N'', 1020000, N'')
INSERT [dbo].[users] ([userId], [userLevel], [handle], [email], [wholeSaleDealer], [lastVisit], [comments], [password], [administrator], [wouldLikeEmail], [createDate], [sessionId], [quotaWholesale], [quotaComplete], [quota], [credit], [loggedIn], [purchaseAccount], [creditLimit], [contact], [address1], [address2], [zip], [state], [country], [city], [homePhone], [companyEmail], [fax], [www], [firstName], [lastName], [termId], [usesTerms], [accountType], [noTax], [allowPreorders], [FOB], [packingSlip], [quote], [invoice], [logon_redirect], [admin_script], [rateId], [workPhone], [sendShipmentUpdates], [autoFillOrderForm], [estTransitTime], [estLeadTime], [UI_JSON], [assetAccount], [defaultPrinterPath]) VALUES (1000000, 0, N'Cash asset', N'', 0, CAST(0x00009E5E00000000 AS DateTime), N'Default cash asset account', N'', 0, 0, CAST(0x00009E5E00000000 AS DateTime), N'00000000-0000-0000-0000-000000000000', 0, 0, 0, 0.0000, 0, N' ', 0.0000, N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', 0, 0, 3, 0, 0, N' ', N' ', N' ', N' ', N' ', N' ', -1, N' ', 0, 0, 0, 0, N' ', 1020000, N'')
INSERT [dbo].[users] ([userId], [userLevel], [handle], [email], [wholeSaleDealer], [lastVisit], [comments], [password], [administrator], [wouldLikeEmail], [createDate], [sessionId], [quotaWholesale], [quotaComplete], [quota], [credit], [loggedIn], [purchaseAccount], [creditLimit], [contact], [address1], [address2], [zip], [state], [country], [city], [homePhone], [companyEmail], [fax], [www], [firstName], [lastName], [termId], [usesTerms], [accountType], [noTax], [allowPreorders], [FOB], [packingSlip], [quote], [invoice], [logon_redirect], [admin_script], [rateId], [workPhone], [sendShipmentUpdates], [autoFillOrderForm], [estTransitTime], [estLeadTime], [UI_JSON], [assetAccount], [defaultPrinterPath]) VALUES (1020000, 0, N'Checking', N'', 0, CAST(0x00009E5E00000000 AS DateTime), N'Default checking account', N'', 0, 0, CAST(0x00009E5E00000000 AS DateTime), N'00000000-0000-0000-0000-000000000000', 0, 0, 0, 0.0000, 0, N' ', 0.0000, N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', 0, 0, 3, 0, 0, N' ', N' ', N' ', N' ', N' ', N' ', -1, N' ', 0, 0, 0, 0, N' ', 1020000, N'')
INSERT [dbo].[users] ([userId], [userLevel], [handle], [email], [wholeSaleDealer], [lastVisit], [comments], [password], [administrator], [wouldLikeEmail], [createDate], [sessionId], [quotaWholesale], [quotaComplete], [quota], [credit], [loggedIn], [purchaseAccount], [creditLimit], [contact], [address1], [address2], [zip], [state], [country], [city], [homePhone], [companyEmail], [fax], [www], [firstName], [lastName], [termId], [usesTerms], [accountType], [noTax], [allowPreorders], [FOB], [packingSlip], [quote], [invoice], [logon_redirect], [admin_script], [rateId], [workPhone], [sendShipmentUpdates], [autoFillOrderForm], [estTransitTime], [estLeadTime], [UI_JSON], [assetAccount], [defaultPrinterPath]) VALUES (1030000, 0, N'Inventory asset', N'', 0, CAST(0x00009E5E00000000 AS DateTime), N'Default inventory asset', N'', 0, 0, CAST(0x00009E5E00000000 AS DateTime), N'00000000-0000-0000-0000-000000000000', 0, 0, 0, 0.0000, 0, N' ', 0.0000, N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', 0, 0, 3, 0, 0, N' ', N' ', N' ', N' ', N' ', N' ', -1, N' ', 0, 0, 0, 0, N' ', 1020000, N'')
INSERT [dbo].[users] ([userId], [userLevel], [handle], [email], [wholeSaleDealer], [lastVisit], [comments], [password], [administrator], [wouldLikeEmail], [createDate], [sessionId], [quotaWholesale], [quotaComplete], [quota], [credit], [loggedIn], [purchaseAccount], [creditLimit], [contact], [address1], [address2], [zip], [state], [country], [city], [homePhone], [companyEmail], [fax], [www], [firstName], [lastName], [termId], [usesTerms], [accountType], [noTax], [allowPreorders], [FOB], [packingSlip], [quote], [invoice], [logon_redirect], [admin_script], [rateId], [workPhone], [sendShipmentUpdates], [autoFillOrderForm], [estTransitTime], [estLeadTime], [UI_JSON], [assetAccount], [defaultPrinterPath]) VALUES (1100000, 0, N'Accounts receivable', N'', 0, CAST(0x00009E5E00000000 AS DateTime), N'Default accounts receivable', N'', 0, 0, CAST(0x00009E5E00000000 AS DateTime), N'00000000-0000-0000-0000-000000000000', 0, 0, 0, 0.0000, 0, N' ', 0.0000, N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', 0, 0, 3, 0, 0, N' ', N' ', N' ', N' ', N' ', N' ', -1, N' ', 0, 0, 0, 0, N' ', 1020000, N'')
INSERT [dbo].[users] ([userId], [userLevel], [handle], [email], [wholeSaleDealer], [lastVisit], [comments], [password], [administrator], [wouldLikeEmail], [createDate], [sessionId], [quotaWholesale], [quotaComplete], [quota], [credit], [loggedIn], [purchaseAccount], [creditLimit], [contact], [address1], [address2], [zip], [state], [country], [city], [homePhone], [companyEmail], [fax], [www], [firstName], [lastName], [termId], [usesTerms], [accountType], [noTax], [allowPreorders], [FOB], [packingSlip], [quote], [invoice], [logon_redirect], [admin_script], [rateId], [workPhone], [sendShipmentUpdates], [autoFillOrderForm], [estTransitTime], [estLeadTime], [UI_JSON], [assetAccount], [defaultPrinterPath]) VALUES (2000000, 0, N'Accounts payable', N'', 0, CAST(0x00009E5E00000000 AS DateTime), N'Default accounts payable', N'', 0, 0, CAST(0x00009E5E00000000 AS DateTime), N'00000000-0000-0000-0000-000000000000', 0, 0, 0, 0.0000, 0, N' ', 0.0000, N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', 0, 0, 4, 0, 0, N' ', N' ', N' ', N' ', N' ', N' ', -1, N' ', 0, 0, 0, 0, N' ', 1020000, N'')
INSERT [dbo].[users] ([userId], [userLevel], [handle], [email], [wholeSaleDealer], [lastVisit], [comments], [password], [administrator], [wouldLikeEmail], [createDate], [sessionId], [quotaWholesale], [quotaComplete], [quota], [credit], [loggedIn], [purchaseAccount], [creditLimit], [contact], [address1], [address2], [zip], [state], [country], [city], [homePhone], [companyEmail], [fax], [www], [firstName], [lastName], [termId], [usesTerms], [accountType], [noTax], [allowPreorders], [FOB], [packingSlip], [quote], [invoice], [logon_redirect], [admin_script], [rateId], [workPhone], [sendShipmentUpdates], [autoFillOrderForm], [estTransitTime], [estLeadTime], [UI_JSON], [assetAccount], [defaultPrinterPath]) VALUES (2110000, 0, N'Discount liability', N'', 0, CAST(0x00009E5E00000000 AS DateTime), N'Default discount liability', N'', 0, 0, CAST(0x00009E5E00000000 AS DateTime), N'00000000-0000-0000-0000-000000000000', 0, 0, 0, 0.0000, 0, N' ', 0.0000, N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', 0, 0, 4, 0, 0, N' ', N' ', N' ', N' ', N' ', N' ', -1, N' ', 0, 0, 0, 0, N' ', 1020000, N'')
INSERT [dbo].[users] ([userId], [userLevel], [handle], [email], [wholeSaleDealer], [lastVisit], [comments], [password], [administrator], [wouldLikeEmail], [createDate], [sessionId], [quotaWholesale], [quotaComplete], [quota], [credit], [loggedIn], [purchaseAccount], [creditLimit], [contact], [address1], [address2], [zip], [state], [country], [city], [homePhone], [companyEmail], [fax], [www], [firstName], [lastName], [termId], [usesTerms], [accountType], [noTax], [allowPreorders], [FOB], [packingSlip], [quote], [invoice], [logon_redirect], [admin_script], [rateId], [workPhone], [sendShipmentUpdates], [autoFillOrderForm], [estTransitTime], [estLeadTime], [UI_JSON], [assetAccount], [defaultPrinterPath]) VALUES (2310000, 0, N'Sales tax payable', N'', 0, CAST(0x00009E5E00000000 AS DateTime), N'Default sales tax payable', N'', 0, 0, CAST(0x00009E5E00000000 AS DateTime), N'00000000-0000-0000-0000-000000000000', 0, 0, 0, 0.0000, 0, N' ', 0.0000, N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', 0, 0, 4, 0, 0, N' ', N' ', N' ', N' ', N' ', N' ', -1, N' ', 0, 0, 0, 0, N' ', 1020000, N'')
INSERT [dbo].[users] ([userId], [userLevel], [handle], [email], [wholeSaleDealer], [lastVisit], [comments], [password], [administrator], [wouldLikeEmail], [createDate], [sessionId], [quotaWholesale], [quotaComplete], [quota], [credit], [loggedIn], [purchaseAccount], [creditLimit], [contact], [address1], [address2], [zip], [state], [country], [city], [homePhone], [companyEmail], [fax], [www], [firstName], [lastName], [termId], [usesTerms], [accountType], [noTax], [allowPreorders], [FOB], [packingSlip], [quote], [invoice], [logon_redirect], [admin_script], [rateId], [workPhone], [sendShipmentUpdates], [autoFillOrderForm], [estTransitTime], [estLeadTime], [UI_JSON], [assetAccount], [defaultPrinterPath]) VALUES (3000000, 0, N'Equity', N'', 0, CAST(0x00009E5E00000000 AS DateTime), N'Default equity', N'', 0, 0, CAST(0x00009E5E00000000 AS DateTime), N'00000000-0000-0000-0000-000000000000', 0, 0, 0, 0.0000, 0, N' ', 0.0000, N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', 0, 0, 5, 0, 0, N' ', N' ', N' ', N' ', N' ', N' ', -1, N' ', 0, 0, 0, 0, N' ', 1020000, N'')
INSERT [dbo].[users] ([userId], [userLevel], [handle], [email], [wholeSaleDealer], [lastVisit], [comments], [password], [administrator], [wouldLikeEmail], [createDate], [sessionId], [quotaWholesale], [quotaComplete], [quota], [credit], [loggedIn], [purchaseAccount], [creditLimit], [contact], [address1], [address2], [zip], [state], [country], [city], [homePhone], [companyEmail], [fax], [www], [firstName], [lastName], [termId], [usesTerms], [accountType], [noTax], [allowPreorders], [FOB], [packingSlip], [quote], [invoice], [logon_redirect], [admin_script], [rateId], [workPhone], [sendShipmentUpdates], [autoFillOrderForm], [estTransitTime], [estLeadTime], [UI_JSON], [assetAccount], [defaultPrinterPath]) VALUES (4000000, 0, N'Revenue', N'', 0, CAST(0x00009E5E00000000 AS DateTime), N'Default sales revenue account', N'', 0, 0, CAST(0x00009E5E00000000 AS DateTime), N'00000000-0000-0000-0000-000000000000', 0, 0, 0, 0.0000, 0, N' ', 0.0000, N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', 0, 0, 6, 0, 0, N' ', N' ', N' ', N' ', N' ', N' ', -1, N' ', 0, 0, 0, 0, N' ', 1020000, N'')
INSERT [dbo].[users] ([userId], [userLevel], [handle], [email], [wholeSaleDealer], [lastVisit], [comments], [password], [administrator], [wouldLikeEmail], [createDate], [sessionId], [quotaWholesale], [quotaComplete], [quota], [credit], [loggedIn], [purchaseAccount], [creditLimit], [contact], [address1], [address2], [zip], [state], [country], [city], [homePhone], [companyEmail], [fax], [www], [firstName], [lastName], [termId], [usesTerms], [accountType], [noTax], [allowPreorders], [FOB], [packingSlip], [quote], [invoice], [logon_redirect], [admin_script], [rateId], [workPhone], [sendShipmentUpdates], [autoFillOrderForm], [estTransitTime], [estLeadTime], [UI_JSON], [assetAccount], [defaultPrinterPath]) VALUES (4550000, 0, N'Shipping revenue', N'', 0, CAST(0x00009E5E00000000 AS DateTime), N'Default shipping revenue account', N'', 0, 0, CAST(0x00009E5E00000000 AS DateTime), N'00000000-0000-0000-0000-000000000000', 0, 0, 0, 0.0000, 0, N' ', 0.0000, N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', 0, 0, 6, 0, 0, N' ', N' ', N' ', N' ', N' ', N' ', -1, N' ', 0, 0, 0, 0, N' ', 1020000, N'')
INSERT [dbo].[users] ([userId], [userLevel], [handle], [email], [wholeSaleDealer], [lastVisit], [comments], [password], [administrator], [wouldLikeEmail], [createDate], [sessionId], [quotaWholesale], [quotaComplete], [quota], [credit], [loggedIn], [purchaseAccount], [creditLimit], [contact], [address1], [address2], [zip], [state], [country], [city], [homePhone], [companyEmail], [fax], [www], [firstName], [lastName], [termId], [usesTerms], [accountType], [noTax], [allowPreorders], [FOB], [packingSlip], [quote], [invoice], [logon_redirect], [admin_script], [rateId], [workPhone], [sendShipmentUpdates], [autoFillOrderForm], [estTransitTime], [estLeadTime], [UI_JSON], [assetAccount], [defaultPrinterPath]) VALUES (5000000, 0, N'Cost of goods sold', N'', 0, CAST(0x00009E5E00000000 AS DateTime), N'Default Cost of Goods Sold', N'', 0, 0, CAST(0x00009E5E00000000 AS DateTime), N'00000000-0000-0000-0000-000000000000', 0, 0, 0, 0.0000, 0, N' ', 0.0000, N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', 0, 0, 7, 0, 0, N' ', N' ', N' ', N' ', N' ', N' ', -1, N' ', 0, 0, 0, 0, N' ', 1020000, N'')
INSERT [dbo].[users] ([userId], [userLevel], [handle], [email], [wholeSaleDealer], [lastVisit], [comments], [password], [administrator], [wouldLikeEmail], [createDate], [sessionId], [quotaWholesale], [quotaComplete], [quota], [credit], [loggedIn], [purchaseAccount], [creditLimit], [contact], [address1], [address2], [zip], [state], [country], [city], [homePhone], [companyEmail], [fax], [www], [firstName], [lastName], [termId], [usesTerms], [accountType], [noTax], [allowPreorders], [FOB], [packingSlip], [quote], [invoice], [logon_redirect], [admin_script], [rateId], [workPhone], [sendShipmentUpdates], [autoFillOrderForm], [estTransitTime], [estLeadTime], [UI_JSON], [assetAccount], [defaultPrinterPath]) VALUES (6000000, 0, N'Expense', N'', 0, CAST(0x00009E5E00000000 AS DateTime), N'Default Expense', N'', 0, 0, CAST(0x00009E5E00000000 AS DateTime), N'00000000-0000-0000-0000-000000000000', 0, 0, 0, 0.0000, 0, N' ', 0.0000, N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', 0, 0, 8, 0, 0, N' ', N' ', N' ', N' ', N' ', N' ', -1, N' ', 0, 0, 0, 0, N' ', 1020000, N'')
INSERT [dbo].[users] ([userId], [userLevel], [handle], [email], [wholeSaleDealer], [lastVisit], [comments], [password], [administrator], [wouldLikeEmail], [createDate], [sessionId], [quotaWholesale], [quotaComplete], [quota], [credit], [loggedIn], [purchaseAccount], [creditLimit], [contact], [address1], [address2], [zip], [state], [country], [city], [homePhone], [companyEmail], [fax], [www], [firstName], [lastName], [termId], [usesTerms], [accountType], [noTax], [allowPreorders], [FOB], [packingSlip], [quote], [invoice], [logon_redirect], [admin_script], [rateId], [workPhone], [sendShipmentUpdates], [autoFillOrderForm], [estTransitTime], [estLeadTime], [UI_JSON], [assetAccount], [defaultPrinterPath]) VALUES (7000000, 0, N'Other revenue', N'', 0, CAST(0x00009E5E00000000 AS DateTime), N'Default other revenue', N'', 0, 0, CAST(0x00009E5E00000000 AS DateTime), N'00000000-0000-0000-0000-000000000000', 0, 0, 0, 0.0000, 0, N' ', 0.0000, N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', 0, 0, 9, 0, 0, N' ', N' ', N' ', N' ', N' ', N' ', -1, N' ', 0, 0, 0, 0, N' ', 1020000, N'')
INSERT [dbo].[users] ([userId], [userLevel], [handle], [email], [wholeSaleDealer], [lastVisit], [comments], [password], [administrator], [wouldLikeEmail], [createDate], [sessionId], [quotaWholesale], [quotaComplete], [quota], [credit], [loggedIn], [purchaseAccount], [creditLimit], [contact], [address1], [address2], [zip], [state], [country], [city], [homePhone], [companyEmail], [fax], [www], [firstName], [lastName], [termId], [usesTerms], [accountType], [noTax], [allowPreorders], [FOB], [packingSlip], [quote], [invoice], [logon_redirect], [admin_script], [rateId], [workPhone], [sendShipmentUpdates], [autoFillOrderForm], [estTransitTime], [estLeadTime], [UI_JSON], [assetAccount], [defaultPrinterPath]) VALUES (8000000, 0, N'Other expense', N'', 0, CAST(0x00009E5E00000000 AS DateTime), N'Default other expense', N'', 0, 0, CAST(0x00009E5E00000000 AS DateTime), N'00000000-0000-0000-0000-000000000000', 0, 0, 0, 0.0000, 0, N' ', 0.0000, N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', 0, 0, 10, 0, 0, N' ', N' ', N' ', N' ', N' ', N' ', -1, N' ', 0, 0, 0, 0, N' ', 1020000, N'')
INSERT [dbo].[users] ([userId], [userLevel], [handle], [email], [wholeSaleDealer], [lastVisit], [comments], [password], [administrator], [wouldLikeEmail], [createDate], [sessionId], [quotaWholesale], [quotaComplete], [quota], [credit], [loggedIn], [purchaseAccount], [creditLimit], [contact], [address1], [address2], [zip], [state], [country], [city], [homePhone], [companyEmail], [fax], [www], [firstName], [lastName], [termId], [usesTerms], [accountType], [noTax], [allowPreorders], [FOB], [packingSlip], [quote], [invoice], [logon_redirect], [admin_script], [rateId], [workPhone], [sendShipmentUpdates], [autoFillOrderForm], [estTransitTime], [estLeadTime], [UI_JSON], [assetAccount], [defaultPrinterPath]) VALUES (9000000, 0, N'Gain/loss on sale of assets', N'', 0, CAST(0x00009E5E00000000 AS DateTime), N'Default gain/loss on sale of assets', N'', 0, 0, CAST(0x00009E5E00000000 AS DateTime), N'00000000-0000-0000-0000-000000000000', 0, 0, 0, 0.0000, 0, N' ', 0.0000, N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', N' ', 0, 0, 11, 0, 0, N' ', N' ', N' ', N' ', N' ', N' ', -1, N' ', 0, 0, 0, 0, N' ', 1020000, N'')
INSERT [dbo].[users] ([userId], [userLevel], [handle], [email], [wholeSaleDealer], [lastVisit], [comments], [password], [administrator], [wouldLikeEmail], [createDate], [sessionId], [quotaWholesale], [quotaComplete], [quota], [credit], [loggedIn], [purchaseAccount], [creditLimit], [contact], [address1], [address2], [zip], [state], [country], [city], [homePhone], [companyEmail], [fax], [www], [firstName], [lastName], [termId], [usesTerms], [accountType], [noTax], [allowPreorders], [FOB], [packingSlip], [quote], [invoice], [logon_redirect], [admin_script], [rateId], [workPhone], [sendShipmentUpdates], [autoFillOrderForm], [estTransitTime], [estLeadTime], [UI_JSON], [assetAccount], [defaultPrinterPath]) VALUES (10000000, 0, N'Default web user', N'', 0, CAST(0x00009E5E00000000 AS DateTime), N'Default Web Account.  Values in this account will become defaults for all new anonymous web accounts', N'', 0, 0, CAST(0x00009E5E00000000 AS DateTime), N'00000000-0000-0000-0000-000000000000', 0, 0, 0, 0.0000, 0, N'', 0.0000, N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', 0, 0, 0, 0, 0, N'', N'', N'', N'', N'', N'', -1, N'', 0, 0, 0, 0, N'', 1020000, N'')
INSERT [dbo].[users] ([userId], [userLevel], [handle], [email], [wholeSaleDealer], [lastVisit], [comments], [password], [administrator], [wouldLikeEmail], [createDate], [sessionId], [quotaWholesale], [quotaComplete], [quota], [credit], [loggedIn], [purchaseAccount], [creditLimit], [contact], [address1], [address2], [zip], [state], [country], [city], [homePhone], [companyEmail], [fax], [www], [firstName], [lastName], [termId], [usesTerms], [accountType], [noTax], [allowPreorders], [FOB], [packingSlip], [quote], [invoice], [logon_redirect], [admin_script], [rateId], [workPhone], [sendShipmentUpdates], [autoFillOrderForm], [estTransitTime], [estLeadTime], [UI_JSON], [assetAccount], [defaultPrinterPath]) VALUES (20000000, 9, N'Administrator', N'admin', 0, CAST(0x00009E5E00000000 AS DateTime), N'Default Operator Account', N'0a7ZRJmBz7WrHEPdxsP+DPKx9Kw=', 1, 1, CAST(0x00009E5E00000000 AS DateTime), N'00000000-0000-0000-0000-000000000000', 0, 0, 0, 0.0000, 0, N'', 0.0000, N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', 0, 0, 2, 0, 0, N'', N'', N'', N'', N'', N'', -1, N'', 0, 0, 0, 0, N'', 1020000, N'')
/****** Object:  StoredProcedure [dbo].[itemInventoryManager]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[itemInventoryManager](@itemnumber varchar(50), @dayFrom datetime, @dayTo datetime, @update bit) as
begin
	/* itemInventoryManager version 0.1.0 */
	set nocount on
	declare @days table(days datetime);
	declare @itemOnHandTemp table(itemNumber varchar(50),ats int,wip int,prebook int,volume int,consumed int, qtyDate datetime)
	declare @todate int;
	declare @fromdate int;
	declare @r datetime;/*running loop date */
	declare @emptyGUID uniqueidentifier = '00000000-0000-0000-0000-000000000000';
	if @dayTo = '' or @update = 1 begin
		set @dayTo = getdate()
	end
	if @dayFrom = '' or @update = 1 begin
		set @dayFrom = getdate()
	end
	set @todate = (DATEDIFF(D,@dayTo,GETDATE()))*-1;
	set @fromdate = (DATEDIFF(D,@dayFrom,GETDATE()))*-1;
	while (@todate>=@fromdate)
	begin 
		set @r = DATEADD(dd,@todate,cast(convert(varchar(20),getDate(),1) as datetime));
		insert into @days (days) values (@r);
		insert into @itemOnHandTemp (itemNumber,ats,wip,prebook,volume,qtyDate) values (@itemnumber,0,0,0,0,@r)
		set @todate = @todate -1;
	end
	
	/* ats */
	update @itemOnHandTemp set ats = qty
	from 
	(
		select case when (qtyIn-qtyOut) is null then 0 else (qtyIn-qtyOut) end as qty, ia.days as days from ( 
				select case when ga.qty is null then 0 else ga.qty end as qtyIn, case when ha.qty is null then 0 else ha.qty end as qtyOut, ga.days from ( 
					select sum(qty) as qty,days
					from ( 
						select sum(vendorItems.qtyReceived) as qty, qa.days as days from @days qa
						inner join vendorItems with (nolock) on recievedOn <= qa.days and itemnumber = @itemnumber 
						group by days 
					) fa group by days
				) ga 
				left join  
				( 
					select SUM(kitAllocation.qty) as qty,days
					from @days qa
					inner join Cart with (nolock) on fulfillmentDate <= qa.days and cart.orderId > 0
					inner join Users with (nolock) on users.userId = cart.userId and users.accountType = 0
					inner join orders with (nolock) on orders.orderId = cart.orderId
					inner join kitAllocation with (nolock) on kitAllocation.itemnumber = @itemnumber and cart.cartid = kitAllocation.cartid 
					group by days 
				) ha on ha.days = ga.days 
			) ia 
	) ats where days = qtyDate
	
	/* wip */
	update @itemOnHandTemp set wip = qty
	from
	(
		select case when (qtyIn-qtyOut) is null then 0 else (qtyIn-qtyOut) end as qty, iw.days as days from (
			select case when gw.qty is null then 0 else gw.qty end as qtyIn, case when hw.qty is null then 0 else hw.qty end as qtyOut, gw.days from ( 
				select sum(qty) as qty,days from ( 
					select sum(cart.qty) as qty, qw.days as days
					from @days qw
					inner join cart with (nolock) on cart.estimatedFulfillmentDate <= qw.days and itemnumber = @itemnumber
						and cart.fulfillmentDate = '1/1/1900 00:00:00.000'
						and not cart.estimatedFulfillmentDate = cart.fulfillmentDate
					inner join users with (nolock) on users.userId = cart.userId and users.accountType = 1
					inner join orders with (nolock) on orders.orderId = cart.orderId
					group by days 
				) fw group by days 
			) gw 
			left join  
			( 
				select sum(qty) as qty,days from ( 
					select sum(qty) as qty, qwi.days as days
					from @days qwi
					inner join cart with (nolock) on cart.fulfillmentDate <= qwi.days and itemnumber = @itemnumber
						and not cart.fulfillmentDate = '1/1/1900 00:00:00.000'
						and not cart.estimatedFulfillmentDate = cart.fulfillmentDate
					inner join users with (nolock) on users.userId = cart.userId and users.accountType = 1
					inner join orders with (nolock) on orders.orderId = cart.orderId
					group by days  
				) jw group by days 
			) hw on hw.days = gw.days 
		) iw
	) wip where days = qtyDate
	
	/* allocated */
	update @itemOnHandTemp set volume = qty
	from 
	(
		select (filled_qty-ordred_qty)*-1 as qty,days as days from 
		( 
 			select case when gp.qty is null then 0 else gp.qty end as filled_qty,
 			case when fp.qty is null then 0 else fp.qty end as ordred_qty, qp.days as days 
 			from @days qp
 			left join
 			(
 			select case when sum(kitAllocation.qty) is null then 0 else sum(kitAllocation.qty) end as qty, days as days from @days qpf
 			inner join orders with (nolock) on orders.orderDate <= cast(convert(varchar(100), days,101)+' 23:59:59.99' as datetime)
 			inner join cart with (nolock) on cart.orderId = orders.orderId
 			inner join Users with (nolock) on users.userId = orders.userId and users.accounttype = 0
			inner join kitAllocation with (nolock) on kitAllocation.itemnumber = @itemnumber
				and cart.cartid = kitAllocation.cartid
				and not kitAllocation.vendorItemKitAssignmentId = @emptyGUID and kitAllocation.itemConsumed = 0
 			group by days 
 			) fp on qp.days = fp.days
			left join
 			(
 			select case when sum(kitAllocation.qty) is null then 0 else sum(kitAllocation.qty) end as qty, days as days from @days qpg
 			inner join orders with (nolock) on orders.orderDate <= cast(convert(varchar(100), days,101)+' 23:59:59.99' as datetime)
 			inner join cart with (nolock) on cart.orderId = orders.orderId
 			inner join Users with (nolock) on users.userId = orders.userId and users.accounttype = 0
			inner join kitAllocation with (nolock) on kitAllocation.itemnumber = @itemnumber
				and cart.cartid = kitAllocation.cartid
				and kitAllocation.itemConsumed = 1
				and kitAllocation.vendorItemKitAssignmentId = @emptyGUID and kitAllocation.itemConsumed = 0
 			group by days
 			) gp on qp.days = gp.days
		) tp
	) volume where days = qtyDate
	
	/* consumed */
	update @itemOnHandTemp set consumed = qty
	from 
	(
		select (filled_qty-ordred_qty)*-1 as qty,days as days from 
		( 
 			select case when gp.qty is null then 0 else gp.qty end as filled_qty,
 			case when fp.qty is null then 0 else fp.qty end as ordred_qty, qp.days as days 
 			from @days qp
 			left join
 			(
 			select case when sum(kitAllocation.qty) is null then 0 else sum(kitAllocation.qty) end as qty, days as days from @days qpf
 			inner join orders with (nolock) on orders.orderDate <= cast(convert(varchar(100), days,101)+' 23:59:59.99' as datetime)
 			inner join cart with (nolock) on cart.orderId = orders.orderId
 			inner join Users with (nolock) on users.userId = orders.userId and users.accounttype = 0
			inner join kitAllocation with (nolock) on kitAllocation.itemnumber = @itemnumber
				and cart.cartid = kitAllocation.cartid
				and not kitAllocation.vendorItemKitAssignmentId = @emptyGUID and kitAllocation.itemConsumed = 1
 			group by days 
 			) fp on qp.days = fp.days
			left join
 			(
 			select case when sum(kitAllocation.qty) is null then 0 else sum(kitAllocation.qty) end as qty, days as days from @days qpg
 			inner join orders with (nolock) on orders.orderDate <= cast(convert(varchar(100), days,101)+' 23:59:59.99' as datetime)
 			inner join cart with (nolock) on cart.orderId = orders.orderId
 			inner join Users with (nolock) on users.userId = orders.userId and users.accounttype = 0
			inner join kitAllocation with (nolock) on kitAllocation.itemnumber = @itemnumber
				and cart.cartid = kitAllocation.cartid
				and kitAllocation.itemConsumed = 1
				and kitAllocation.vendorItemKitAssignmentId = @emptyGUID and kitAllocation.itemConsumed = 1
 			group by days
 			) gp on qp.days = gp.days
		) tp
	) volume where days = qtyDate
	
	
	
	/* Prebook */
	update @itemOnHandTemp set prebook = qty
	from 
	(
		select ordred_qty-filled_qty as qty,days as days from 
		( 
 			select case when gp.qty is null then 0 else gp.qty end as filled_qty,
 			case when fp.qty is null then 0 else fp.qty end as ordred_qty, qp.days as days 
 			from @days qp
 			left join
 			(
 			select case when sum(kitAllocation.qty) is null then 0 else sum(kitAllocation.qty) end as qty, days as days
 			from @days qpf
 			inner join orders with (nolock) on orders.orderDate <= cast(convert(varchar(100), days,101)+' 23:59:59.99' as datetime)
 			inner join cart with (nolock) on cart.orderId = orders.orderId
 			inner join Users with (nolock) on users.userId = orders.userId and users.accounttype = 0
			inner join kitAllocation with (nolock) on kitAllocation.itemnumber = @itemnumber and cart.cartid = kitAllocation.cartid
				and cart.cartid = kitAllocation.cartid
 			group by days 
 			) fp on qp.days = fp.days
			left join
 			(
 			select case when sum(kitAllocation.qty) is null then 0 else sum(kitAllocation.qty) end as qty, days as days
 			from @days qpg
 			
 			inner join cart with (nolock) on cart.fulfillmentDate <= cast(convert(varchar(100), days,101)+' 23:59:59.99' as datetime)
 				and not cart.fulfillmentDate = '1/1/1900 00:00:00.000'
 			inner join orders with (nolock) on cart.orderId = orders.orderId 
 			inner join Users with (nolock) on users.userId = orders.userId and users.accounttype = 0
			inner join kitAllocation with (nolock) on kitAllocation.itemnumber = @itemnumber
				and cart.cartid = kitAllocation.cartid and not kitAllocation.vendorItemKitAssignmentId = @emptyGUID
 			group by days
 			) gp on qp.days = gp.days
		) tp
	) prebook where days = qtyDate
	
	
	
	if @update = 0 begin
		/* trying to make a plot of activity */
		select @itemnumber, ats, volume,wip, prebook, consumed, qtyDate from @itemOnHandTemp order by qtyDate desc
	end else begin
		/* just updating the real time qtys */
		declare @ats int, @volume int, @wip int, @prebook int, @consumed int;
		select top 1 @ats = ats, @volume = volume, @wip = wip, @prebook = prebook, @consumed = consumed from @itemOnHandTemp
		update itemOnHandTemp set
		ats = @ats,
		wip = @wip,
		volume = @volume,
		prebook = @prebook,
		consumed = @consumed,
		itemOnHandTemp.addedOn = GETDATE()
		where itemOnHandTemp.itemnumber = @itemnumber
	end
end
GO
/****** Object:  Table [dbo].[items]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[items](
	[itemNumber] [varchar](50) NOT NULL,
	[displayPrice] [varchar](255) NOT NULL,
	[reorderPoint] [int] NOT NULL,
	[BOMOnly] [bit] NOT NULL,
	[itemHTML] [varchar](max) NOT NULL,
	[price] [money] NOT NULL,
	[salePrice] [money] NOT NULL,
	[wholeSalePrice] [money] NOT NULL,
	[isOnSale] [bit] NOT NULL,
	[description] [varchar](255) NOT NULL,
	[shortCopy] [varchar](max) NOT NULL,
	[productCopy] [varchar](max) NOT NULL,
	[homeCategory] [uniqueidentifier] NOT NULL,
	[homeAltCategory] [uniqueidentifier] NOT NULL,
	[weight] [float] NOT NULL,
	[quantifier] [varchar](50) NOT NULL,
	[shortDescription] [varchar](50) NOT NULL,
	[freeShipping] [bit] NOT NULL,
	[formName] [varchar](50) NOT NULL,
	[m] [uniqueidentifier] NOT NULL,
	[c] [uniqueidentifier] NOT NULL,
	[f] [uniqueidentifier] NOT NULL,
	[t] [uniqueidentifier] NOT NULL,
	[a] [uniqueidentifier] NOT NULL,
	[x] [uniqueidentifier] NOT NULL,
	[y] [uniqueidentifier] NOT NULL,
	[z] [uniqueidentifier] NOT NULL,
	[b] [uniqueidentifier] NOT NULL,
	[d] [uniqueidentifier] NOT NULL,
	[keywords] [varchar](max) NOT NULL,
	[searchPriority] [int] NOT NULL,
	[workCreditValue] [money] NOT NULL,
	[noTax] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[removeAfterPurchase] [bit] NOT NULL,
	[parentItemNumber] [varchar](50) NOT NULL,
	[swatchId] [uniqueidentifier] NOT NULL,
	[allowPreorders] [bit] NOT NULL,
	[inventoryOperator] [int] NOT NULL,
	[inventoryDepletesOnFlagId] [int] NOT NULL,
	[inventoryRestockOnFlagId] [int] NOT NULL,
	[itemIsConsumedOnFlagId] [int] NOT NULL,
	[revenueAccount] [int] NOT NULL,
	[sizeId] [uniqueidentifier] NOT NULL,
	[ratio] [float] NOT NULL,
	[divisionId] [uniqueidentifier] NOT NULL,
	[highThreshold] [int] NOT NULL,
	[expenseAccount] [int] NOT NULL,
	[inventoryAccount] [int] NULL,
	[COGSAccount] [int] NULL,
	[SKU] [varchar](50) NULL,
	[itemType] [int] NULL,
	[averageCost] [money] NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK__Items__35BCFE0A] PRIMARY KEY CLUSTERED 
(
	[itemNumber] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE NONCLUSTERED INDEX [idx_item_parentItem] ON [dbo].[items] 
(
	[parentItemNumber] ASC
)
INCLUDE ( [itemNumber]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
/****** Object:  StoredProcedure [dbo].[refreshItemOnHandTemp]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[refreshItemOnHandTemp](@refreshIfOlderThan datetime,@onlyItemNumber varchar(50)) as
	begin
		/* refreshItemOnHandTemp version 2 */
		set nocount on
		declare @today datetime;
		set @today = GETDATE();
		if not exists(select 0 from Items inner join itemOnHandTemp on itemOnHandTemp.itemnumber = Items.itemnumber)
		begin
			insert into dbo.itemOnHandTemp
			select itemnumber, 0 as volume, 0 as prebook, 0 as wip, 0 as ats, 0 as consumed, @today, null as VerCol from items
			where Itemnumber not in (select Itemnumber from itemOnHandTemp with (nolock))
		end
		declare @itemnumber varchar(50)
		declare @parentItemnumber varchar(50)
		declare @itemKits table(itemnumber varchar(50), subitemnumber varchar(50), depth int, qty int, itemQty int, kitStock int)
		DECLARE item_cursor CURSOR FORWARD_ONLY STATIC FOR
		SELECT items.itemnumber
		FROM items with (nolock)
		inner join dbo.itemOnHandTemp with (nolock) on dbo.itemOnHandTemp.Itemnumber = items.Itemnumber and (@onlyItemNumber = items.Itemnumber or len(@onlyItemNumber) = 0)
		where dbo.itemOnHandTemp.addedOn < @refreshIfOlderThan 
		OPEN item_cursor;
		FETCH NEXT FROM item_cursor
		INTO @itemnumber
		WHILE @@FETCH_STATUS = 0
		BEGIN
			insert into @itemKits execute kitlist @itemnumber,1
			update itemOnHandTemp set volume = 0, prebook = 0,wip = 0,ats = 0 where itemNumber = @itemnumber;
			/* actually calculate the inventory */
			exec itemInventoryManager @itemnumber,'','',1;
			FETCH NEXT FROM item_cursor
			INTO @itemnumber
		END
		CLOSE item_cursor;
		DEALLOCATE item_cursor;
		/* updates parent virtual item (non inventory) to refelct the sums of it's children (just for looks) */
		update itemOnHandTemp set 
		itemOnHandTemp.volume = f.volume, 
		itemOnHandTemp.prebook = f.prebook, 
		itemOnHandTemp.wip = f.wip,
		itemOnHandTemp.ats = f.ats
		from (select sum(q.volume) as volume, sum(q.prebook) as prebook, sum(q.wip) as wip, sum(q.ats) as ats,items.parentitemnumber as parentitemnumber
		from itemOnHandTemp q 
		inner join Items with (nolock) on q.itemnumber = Items.Itemnumber
		group by items.parentitemnumber
		) f where itemOnHandTemp.itemnumber = f.parentitemnumber
		/* update the temp table to show kit's data */
		update itemOnHandTemp set itemonhandtemp.ats = itemQty
		from (select MIN(itemQty) as itemQty,itemnumber from @itemKits group by itemnumber) g
		where g.itemnumber = itemOnHandTemp.itemnumber
	end
GO
/****** Object:  Table [dbo].[serial_order]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[serial_order](
	[orderId] [int] IDENTITY(1,1) NOT NULL,
	[sessionId] [uniqueidentifier] NOT NULL,
	[lastFlagId] [uniqueidentifier] NOT NULL,
	[lastFlagStatus] [int] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_serial_order] PRIMARY KEY CLUSTERED 
(
	[orderId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[serial_shipment]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[serial_shipment](
	[shipmentid] [int] IDENTITY(1,1) NOT NULL,
	[orderId] [int] NOT NULL,
	[sessionId] [uniqueidentifier] NOT NULL,
	[lastFlagId] [uniqueidentifier] NOT NULL,
	[lastFlagStatus] [int] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_serial_shipment] PRIMARY KEY CLUSTERED 
(
	[shipmentid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[site_configuration]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[site_configuration](
	[unique_siteId] [uniqueidentifier] NOT NULL,
	[siteAddress] [varchar](50) NULL,
	[friendlySiteName] [varchar](25) NULL,
	[days_until_session_expires] [int] NULL,
	[days_meta_expires] [int] NULL,
	[default_meta_keywords] [varchar](max) NULL,
	[default_meta_description] [varchar](max) NULL,
	[default_page_title] [varchar](255) NULL,
	[default_search_text] [varchar](25) NULL,
	[local_country] [varchar](25) NULL,
	[per_retail_shipment_handling] [money] NULL,
	[free_ship_threshold] [money] NULL,
	[default_access_denied_page] [varchar](25) NULL,
	[elevated_security_userId] [varchar](25) NULL,
	[elevated_security_password] [varchar](25) NULL,
	[elevated_security_domain] [varchar](25) NULL,
	[enable_file_version_tracking] [bit] NULL,
	[default_empty_cart_page] [varchar](25) NULL,
	[default_records_per_page] [int] NULL,
	[default_rateId] [int] NULL,
	[default_zip] [varchar](10) NULL,
	[default_intresting_page] [varchar](25) NULL,
	[default_listmode] [int] NULL,
	[default_orderby] [int] NULL,
	[cookie_name] [varchar](25) NULL,
	[default_style_path] [varchar](25) NULL,
	[default_form_detail_directory] [varchar](50) NULL,
	[default_form_invoice_directory] [varchar](50) NULL,
	[add_to_cart_redirect] [varchar](25) NULL,
	[serializationbase] [int] NULL,
	[validation_fails_querystring] [varchar](25) NULL,
	[empty_cart_redirect] [varchar](25) NULL,
	[update_cart_redirect] [varchar](25) NULL,
	[max_retail_cart_quantity] [int] NULL,
	[default_ship_country] [varchar](25) NULL,
	[use_ssl] [bit] NULL,
	[checkout_page_redirect] [varchar](25) NULL,
	[default_form_misc_directory] [varchar](50) NULL,
	[place_order_redirect] [varchar](35) NULL,
	[checkout_remember_credit_card] [varchar](25) NULL,
	[checkout_card_billtoaddressid] [varchar](25) NULL,
	[merchant_auth_type] [varchar](25) NULL,
	[merchant_auth_name] [varchar](50) NULL,
	[merchant_auth_password] [varchar](50) NULL,
	[smtp_server] [varchar](15) NULL,
	[smtp_username] [varchar](50) NULL,
	[smtp_password] [varchar](25) NULL,
	[smtp_port] [varchar](6) NULL,
	[smtp_authenticate] [bit] NULL,
	[site_operator_email] [varchar](100) NULL,
	[site_send_order_email] [bit] NULL,
	[site_send_shipment_update_email] [bit] NULL,
	[site_send_import_export_log_email] [bit] NULL,
	[site_log_email] [varchar](100) NULL,
	[site_order_email_from] [varchar](100) NULL,
	[site_order_email_bcc] [varchar](100) NULL,
	[logon_redirect] [varchar](50) NULL,
	[m_imagingTemplate] [uniqueidentifier] NULL,
	[c_imagingTemplate] [uniqueidentifier] NULL,
	[f_imagingTemplate] [uniqueidentifier] NULL,
	[t_imagingTemplate] [uniqueidentifier] NULL,
	[a_imagingTemplate] [uniqueidentifier] NULL,
	[x_imagingTemplate] [uniqueidentifier] NULL,
	[y_imagingTemplate] [uniqueidentifier] NULL,
	[z_imagingTemplate] [uniqueidentifier] NULL,
	[b_imagingTemplate] [uniqueidentifier] NULL,
	[d_imagingTemplate] [uniqueidentifier] NULL,
	[administrator_user_level] [int] NULL,
	[new_user_level] [int] NULL,
	[disabled_user_level] [int] NULL,
	[banned_user_level] [int] NULL,
	[test_mode] [bit] NULL,
	[orders_export_on_flagId] [int] NULL,
	[orders_closed_on_flagId] [int] NULL,
	[site_specific_item_images] [bit] NULL,
	[defaultPackingSlip] [varchar](75) NULL,
	[defaultQuote] [varchar](75) NULL,
	[defaultInvoice] [varchar](75) NULL,
	[admin_site_user_level] [int] NULL,
	[item_admin_user_level] [int] NULL,
	[user_admin_user_level] [int] NULL,
	[default_new_user_allow_preorder] [bit] NULL,
	[site_allow_preorder] [bit] NULL,
	[company_name] [varchar](50) NULL,
	[company_co] [varchar](25) NULL,
	[company_address1] [varchar](25) NULL,
	[company_address2] [varchar](25) NULL,
	[company_city] [varchar](25) NULL,
	[company_state] [varchar](2) NULL,
	[company_zip] [varchar](25) NULL,
	[company_country] [varchar](25) NULL,
	[company_phone] [varchar](25) NULL,
	[company_fax] [varchar](25) NULL,
	[company_email] [varchar](100) NULL,
	[site_order_email_url] [varchar](50) NULL,
	[site_order_email_subject] [varchar](50) NULL,
	[never_keep_creditcard_info] [bit] NULL,
	[scanned_image_path] [varchar](50) NULL,
	[export_to_account_catch_all] [varchar](50) NULL,
	[shipment_email_url] [varchar](50) NULL,
	[shipment_email_subject] [varchar](50) NULL,
	[shipment_email_bcc] [varchar](100) NULL,
	[shipment_email_from] [varchar](100) NULL,
	[main_site] [bit] NULL,
	[timezone] [int] NULL,
	[company_HTML_subHeader] [varchar](max) NULL,
	[site_server_500_page] [varchar](100) NULL,
	[site_server_404_page] [varchar](100) NULL,
	[merchant_auth_url] [varchar](max) NULL,
	[merchant_sucsess_match] [varchar](100) NULL,
	[merchant_message_match] [varchar](100) NULL,
	[merchant_message_match_index] [varchar](10) NULL,
	[default_inventoryDepletesOnFlagId] [int] NULL,
	[default_inventoryRestockOnFlagId] [int] NULL,
	[default_itemIsConsumedOnFlagId] [int] NULL,
	[default_revenueAccount] [int] NULL,
	[default_inventoryOperator] [int] NULL,
	[new_item_allowPreorders] [bit] NULL,
	[lost_password_email_URL] [varchar](100) NULL,
	[inappropriateHideThreshold] [int] NULL,
	[shippingGLAccount] [int] NULL,
	[taxGLAccount] [int] NULL,
	[discountGLAccount] [int] NULL,
	[accountsReceivableGLAccount] [int] NULL,
	[checkingGLAccount] [int] NULL,
	[accountsPayableGLAccount] [int] NULL,
	[default_expenseAccount] [int] NULL,
	[default_inventoryAccount] [int] NULL,
	[default_inventoryCOGSAccount] [int] NULL,
	[emailQueueRefreshInterval] [int] NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_site_configuration] PRIMARY KEY CLUSTERED 
(
	[unique_siteId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
INSERT [dbo].[site_configuration] ([unique_siteId], [siteAddress], [friendlySiteName], [days_until_session_expires], [days_meta_expires], [default_meta_keywords], [default_meta_description], [default_page_title], [default_search_text], [local_country], [per_retail_shipment_handling], [free_ship_threshold], [default_access_denied_page], [elevated_security_userId], [elevated_security_password], [elevated_security_domain], [enable_file_version_tracking], [default_empty_cart_page], [default_records_per_page], [default_rateId], [default_zip], [default_intresting_page], [default_listmode], [default_orderby], [cookie_name], [default_style_path], [default_form_detail_directory], [default_form_invoice_directory], [add_to_cart_redirect], [serializationbase], [validation_fails_querystring], [empty_cart_redirect], [update_cart_redirect], [max_retail_cart_quantity], [default_ship_country], [use_ssl], [checkout_page_redirect], [default_form_misc_directory], [place_order_redirect], [checkout_remember_credit_card], [checkout_card_billtoaddressid], [merchant_auth_type], [merchant_auth_name], [merchant_auth_password], [smtp_server], [smtp_username], [smtp_password], [smtp_port], [smtp_authenticate], [site_operator_email], [site_send_order_email], [site_send_shipment_update_email], [site_send_import_export_log_email], [site_log_email], [site_order_email_from], [site_order_email_bcc], [logon_redirect], [m_imagingTemplate], [c_imagingTemplate], [f_imagingTemplate], [t_imagingTemplate], [a_imagingTemplate], [x_imagingTemplate], [y_imagingTemplate], [z_imagingTemplate], [b_imagingTemplate], [d_imagingTemplate], [administrator_user_level], [new_user_level], [disabled_user_level], [banned_user_level], [test_mode], [orders_export_on_flagId], [orders_closed_on_flagId], [site_specific_item_images], [defaultPackingSlip], [defaultQuote], [defaultInvoice], [admin_site_user_level], [item_admin_user_level], [user_admin_user_level], [default_new_user_allow_preorder], [site_allow_preorder], [company_name], [company_co], [company_address1], [company_address2], [company_city], [company_state], [company_zip], [company_country], [company_phone], [company_fax], [company_email], [site_order_email_url], [site_order_email_subject], [never_keep_creditcard_info], [scanned_image_path], [export_to_account_catch_all], [shipment_email_url], [shipment_email_subject], [shipment_email_bcc], [shipment_email_from], [main_site], [timezone], [company_HTML_subHeader], [site_server_500_page], [site_server_404_page], [merchant_auth_url], [merchant_sucsess_match], [merchant_message_match], [merchant_message_match_index], [default_inventoryDepletesOnFlagId], [default_inventoryRestockOnFlagId], [default_itemIsConsumedOnFlagId], [default_revenueAccount], [default_inventoryOperator], [new_item_allowPreorders], [lost_password_email_URL], [inappropriateHideThreshold], [shippingGLAccount], [taxGLAccount], [discountGLAccount], [accountsReceivableGLAccount], [checkingGLAccount], [accountsPayableGLAccount], [default_expenseAccount], [default_inventoryAccount], [default_inventoryCOGSAccount], [emailQueueRefreshInterval]) VALUES (N'00000000-0000-0000-0000-000000000000', N'www.yourSiteAddress.com', N'Site Name', 100, 30, N'', N'', N'Site Title', N'Search', N'U.S.A.', 0.0000, 10000000.0000, N'/default.aspx?logon=<ref>', N'userName', N'password', N'localhost', 1, N'/', 12, 1, N'90803', N'/', 0, 0, N'sessionid', N'', N'~/forms/', N'~/forms/', N'/cart.aspx', 31, N'f', N'/', N'', 10000, N'U.S.A.', 0, N'/checkout.aspx', N'~/forms/', N'/default.aspx', N'remembercard', N'billtoaddressid', N'', N'0x0x0x0x0x0x0x', N'0x0x0x0x0x0x0x', N'192.168.3.20', N'', N'', N'25', 0, N'operator@site.com', 1, 1, 1, N'operator@site.com', N'operator@site.com', N'operator@site.com', N'logon.aspx', N'865bb238-daaa-4436-a405-215edb9da797', N'd5d0254d-fbbe-45d5-ae32-2920b16b186a', N'cc9a830a-cb14-47e7-84de-59ec8f983ad6', N'59ece4f8-0524-4496-a991-cacb6478fb1f', N'865bb238-daaa-4436-a405-215edb9da797', N'865bb238-daaa-4436-a405-215edb9da797', N'865bb238-daaa-4436-a405-215edb9da797', N'865bb238-daaa-4436-a405-215edb9da797', N'865bb238-daaa-4436-a405-215edb9da797', N'6024424c-141d-423d-8973-535248bfb968', 9, 0, -2, -3, 0, 10, 10, 1, N'PDFs\reference_packing_slip.pdf', N'PDFs\reference_quote.pdf', N'PDFs\reference_invoice.pdf', 3, 6, 8, 1, 1, N'', N' ', N'', N' ', N'', N'', N'90814', N'U.S.A.', N'', N'', N'operator@site.com', N'~\emails\newOrder.cs', N'Thanks for your order', 0, N'~/scan_source/', N'websiteorders', N'~\emails\shipConfirm.cs', N'Your order has been shipped', N'operator@site.com', N'', 1, 0, N'', N'/internal_server_error.aspx', N'/file_not_found.aspx', N'https://test.authorize.net/gateway/transact.dll?x_login={merchant_auth_name}&x_tran_key={merchant_auth_password}&x_version=3.1&x_test_request=true&x_delim_data=true&x_delim_char=|&x_relay_response=&x_first_name={billToFirstName}&x_last_name={billToLastName}&x_company={billToCompany}&x_address={billToAddress}%20{billToAddress2}&x_city={billToCity}&x_state={billToState}&x_zip={billToZip}&x_country={billToCountry}&x_ship_to_first_name={shipToFirstName}&x_ship_to_last_name={shipToLastName}&x_ship_to_company={x_ship_to_company}&x_ship_to_address={shipToAddress}%20{shipToAddress2}&x_ship_to_city={shipToCity}&x_ship_to_state={shipToState}&x_ship_to_zip={shipToZip}&x_ship_to_country={shipToCountry}&x_amount={grandTotal}&x_card_num={cardNumber}&x_exp_date={experationMonth}{experationYear}&x_card_code={securityCode}', N'approved', N'[^\|]+\|[^\|]+\|[^\|]+\|([^\|]+)', N'0,1', 11, 5, 10, 4000000, 20000000, 1, N'~\emails\lostPassword.cs', 100, 4550000, 2310000, 2110000, 1100000, 1020000, 2000000, 6000000, 1030000, 5000000, 30)
/****** Object:  Table [dbo].[objectFlags]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[objectFlags](
	[flagId] [uniqueidentifier] NOT NULL,
	[serialId] [int] NULL,
	[cartDetailId] [uniqueidentifier] NULL,
	[fuserId] [int] NULL,
	[shipmentId] [int] NULL,
	[orderId] [int] NULL,
	[flagType] [int] NULL,
	[comments] [varchar](max) NULL,
	[userId] [int] NULL,
	[addTime] [datetime] NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_objectFlags] PRIMARY KEY CLUSTERED 
(
	[flagId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[flagTypes]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[flagTypes](
	[flagTypeId] [int] NOT NULL,
	[flagTypeName] [char](20) NOT NULL,
	[flagTypeDesc] [char](50) NULL,
	[userLevel] [int] NULL,
	[shipmentFlag] [bit] NULL,
	[userFlag] [bit] NULL,
	[orderFlag] [bit] NULL,
	[lineFlag] [bit] NULL,
	[lineDetailFlag] [bit] NULL,
	[customerReadable] [char](50) NULL,
	[agingDaysStatus1] [int] NULL,
	[agingDaysStatus2] [int] NULL,
	[agingDaysStatus3] [int] NULL,
	[agingDaysStatus4] [int] NULL,
	[agingDaysStatus5] [int] NULL,
	[showInProductionAgingReport] [bit] NULL,
	[productionAgingReportOrder] [int] NULL,
	[cannotOccurBeforeFlagId] [int] NULL,
	[cannotOccurAfterFlagId] [int] NULL,
	[purchaseOrderFlag] [bit] NULL,
	[purchaseShipmentFlag] [bit] NULL,
	[purchaseLineFlag] [bit] NULL,
	[createsNewPurchaseOrder] [bit] NULL,
	[finishedPurchaseOrderFlag] [bit] NULL,
	[cancelsOrder] [bit] NULL,
	[closesOrder] [bit] NULL,
	[color] [varchar](50) NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_flagTypes] PRIMARY KEY CLUSTERED 
(
	[flagTypeId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
INSERT [dbo].[flagTypes] ([flagTypeId], [flagTypeName], [flagTypeDesc], [userLevel], [shipmentFlag], [userFlag], [orderFlag], [lineFlag], [lineDetailFlag], [customerReadable], [agingDaysStatus1], [agingDaysStatus2], [agingDaysStatus3], [agingDaysStatus4], [agingDaysStatus5], [showInProductionAgingReport], [productionAgingReportOrder], [cannotOccurBeforeFlagId], [cannotOccurAfterFlagId], [purchaseOrderFlag], [purchaseShipmentFlag], [purchaseLineFlag], [createsNewPurchaseOrder], [finishedPurchaseOrderFlag], [cancelsOrder], [closesOrder], [color]) VALUES (-4, N'Unconsume Inventory ', N'Unconsume Inventory                               ', 0, 0, 0, 0, 0, 0, N'Unconsume Inventory                               ', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, N'Red')
INSERT [dbo].[flagTypes] ([flagTypeId], [flagTypeName], [flagTypeDesc], [userLevel], [shipmentFlag], [userFlag], [orderFlag], [lineFlag], [lineDetailFlag], [customerReadable], [agingDaysStatus1], [agingDaysStatus2], [agingDaysStatus3], [agingDaysStatus4], [agingDaysStatus5], [showInProductionAgingReport], [productionAgingReportOrder], [cannotOccurBeforeFlagId], [cannotOccurAfterFlagId], [purchaseOrderFlag], [purchaseShipmentFlag], [purchaseLineFlag], [createsNewPurchaseOrder], [finishedPurchaseOrderFlag], [cancelsOrder], [closesOrder], [color]) VALUES (-3, N'Deplete Inventory   ', N'Deplete Inventory                                 ', 0, 0, 0, 0, 0, 0, N'Deplete Inventory                                 ', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, N'Red')
INSERT [dbo].[flagTypes] ([flagTypeId], [flagTypeName], [flagTypeDesc], [userLevel], [shipmentFlag], [userFlag], [orderFlag], [lineFlag], [lineDetailFlag], [customerReadable], [agingDaysStatus1], [agingDaysStatus2], [agingDaysStatus3], [agingDaysStatus4], [agingDaysStatus5], [showInProductionAgingReport], [productionAgingReportOrder], [cannotOccurBeforeFlagId], [cannotOccurAfterFlagId], [purchaseOrderFlag], [purchaseShipmentFlag], [purchaseLineFlag], [createsNewPurchaseOrder], [finishedPurchaseOrderFlag], [cancelsOrder], [closesOrder], [color]) VALUES (-2, N'Consume Inventory   ', N'Consume Inventory                                 ', 0, 0, 0, 0, 0, 0, N'Consume Inventory                                 ', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, N'Red')
INSERT [dbo].[flagTypes] ([flagTypeId], [flagTypeName], [flagTypeDesc], [userLevel], [shipmentFlag], [userFlag], [orderFlag], [lineFlag], [lineDetailFlag], [customerReadable], [agingDaysStatus1], [agingDaysStatus2], [agingDaysStatus3], [agingDaysStatus4], [agingDaysStatus5], [showInProductionAgingReport], [productionAgingReportOrder], [cannotOccurBeforeFlagId], [cannotOccurAfterFlagId], [purchaseOrderFlag], [purchaseShipmentFlag], [purchaseLineFlag], [createsNewPurchaseOrder], [finishedPurchaseOrderFlag], [cancelsOrder], [closesOrder], [color]) VALUES (-1, N'Open                ', N'New                                               ', 0, 0, 0, 0, 0, 0, N'New Order                                         ', 5, 10, 15, 20, 25, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, N'Aqua')
INSERT [dbo].[flagTypes] ([flagTypeId], [flagTypeName], [flagTypeDesc], [userLevel], [shipmentFlag], [userFlag], [orderFlag], [lineFlag], [lineDetailFlag], [customerReadable], [agingDaysStatus1], [agingDaysStatus2], [agingDaysStatus3], [agingDaysStatus4], [agingDaysStatus5], [showInProductionAgingReport], [productionAgingReportOrder], [cannotOccurBeforeFlagId], [cannotOccurAfterFlagId], [purchaseOrderFlag], [purchaseShipmentFlag], [purchaseLineFlag], [createsNewPurchaseOrder], [finishedPurchaseOrderFlag], [cancelsOrder], [closesOrder], [color]) VALUES (0, N'Comment             ', N'Comment                                           ', 0, 1, 0, 1, 1, 1, N'Comment                                           ', 0, 5, 8, 12, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, N'Azure')
INSERT [dbo].[flagTypes] ([flagTypeId], [flagTypeName], [flagTypeDesc], [userLevel], [shipmentFlag], [userFlag], [orderFlag], [lineFlag], [lineDetailFlag], [customerReadable], [agingDaysStatus1], [agingDaysStatus2], [agingDaysStatus3], [agingDaysStatus4], [agingDaysStatus5], [showInProductionAgingReport], [productionAgingReportOrder], [cannotOccurBeforeFlagId], [cannotOccurAfterFlagId], [purchaseOrderFlag], [purchaseShipmentFlag], [purchaseLineFlag], [createsNewPurchaseOrder], [finishedPurchaseOrderFlag], [cancelsOrder], [closesOrder], [color]) VALUES (1, N'Decoration QC       ', N'Decoration QC                                     ', 0, 0, 0, 0, 0, 0, N'Decoration QC                                     ', 3, 5, 8, 12, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, N'Beige')
INSERT [dbo].[flagTypes] ([flagTypeId], [flagTypeName], [flagTypeDesc], [userLevel], [shipmentFlag], [userFlag], [orderFlag], [lineFlag], [lineDetailFlag], [customerReadable], [agingDaysStatus1], [agingDaysStatus2], [agingDaysStatus3], [agingDaysStatus4], [agingDaysStatus5], [showInProductionAgingReport], [productionAgingReportOrder], [cannotOccurBeforeFlagId], [cannotOccurAfterFlagId], [purchaseOrderFlag], [purchaseShipmentFlag], [purchaseLineFlag], [createsNewPurchaseOrder], [finishedPurchaseOrderFlag], [cancelsOrder], [closesOrder], [color]) VALUES (2, N'Decorated           ', N'Decorated                                         ', 0, 0, 0, 0, 1, 0, N'Decorated                                         ', 3, 5, 8, 12, 15, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, N'Coral')
INSERT [dbo].[flagTypes] ([flagTypeId], [flagTypeName], [flagTypeDesc], [userLevel], [shipmentFlag], [userFlag], [orderFlag], [lineFlag], [lineDetailFlag], [customerReadable], [agingDaysStatus1], [agingDaysStatus2], [agingDaysStatus3], [agingDaysStatus4], [agingDaysStatus5], [showInProductionAgingReport], [productionAgingReportOrder], [cannotOccurBeforeFlagId], [cannotOccurAfterFlagId], [purchaseOrderFlag], [purchaseShipmentFlag], [purchaseLineFlag], [createsNewPurchaseOrder], [finishedPurchaseOrderFlag], [cancelsOrder], [closesOrder], [color]) VALUES (3, N'Staged              ', N'Staged                                            ', 0, 1, 0, 0, 0, 0, N'Staged                                            ', 3, 5, 8, 12, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, N'Crimson')
INSERT [dbo].[flagTypes] ([flagTypeId], [flagTypeName], [flagTypeDesc], [userLevel], [shipmentFlag], [userFlag], [orderFlag], [lineFlag], [lineDetailFlag], [customerReadable], [agingDaysStatus1], [agingDaysStatus2], [agingDaysStatus3], [agingDaysStatus4], [agingDaysStatus5], [showInProductionAgingReport], [productionAgingReportOrder], [cannotOccurBeforeFlagId], [cannotOccurAfterFlagId], [purchaseOrderFlag], [purchaseShipmentFlag], [purchaseLineFlag], [createsNewPurchaseOrder], [finishedPurchaseOrderFlag], [cancelsOrder], [closesOrder], [color]) VALUES (4, N'Remake              ', N'Remake                                            ', 0, 0, 0, 0, 1, 0, N'Remake                                            ', 3, 5, 8, 12, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, N'Cyan')
INSERT [dbo].[flagTypes] ([flagTypeId], [flagTypeName], [flagTypeDesc], [userLevel], [shipmentFlag], [userFlag], [orderFlag], [lineFlag], [lineDetailFlag], [customerReadable], [agingDaysStatus1], [agingDaysStatus2], [agingDaysStatus3], [agingDaysStatus4], [agingDaysStatus5], [showInProductionAgingReport], [productionAgingReportOrder], [cannotOccurBeforeFlagId], [cannotOccurAfterFlagId], [purchaseOrderFlag], [purchaseShipmentFlag], [purchaseLineFlag], [createsNewPurchaseOrder], [finishedPurchaseOrderFlag], [cancelsOrder], [closesOrder], [color]) VALUES (5, N'Canceled            ', N'Canceled                                          ', 9, 0, 0, 1, 0, 0, N'Canceled                                          ', 0, 0, 0, 0, 0, 1, 6, 0, 0, 0, 0, 0, 0, 0, 1, 0, N'DarkBlue')
INSERT [dbo].[flagTypes] ([flagTypeId], [flagTypeName], [flagTypeDesc], [userLevel], [shipmentFlag], [userFlag], [orderFlag], [lineFlag], [lineDetailFlag], [customerReadable], [agingDaysStatus1], [agingDaysStatus2], [agingDaysStatus3], [agingDaysStatus4], [agingDaysStatus5], [showInProductionAgingReport], [productionAgingReportOrder], [cannotOccurBeforeFlagId], [cannotOccurAfterFlagId], [purchaseOrderFlag], [purchaseShipmentFlag], [purchaseLineFlag], [createsNewPurchaseOrder], [finishedPurchaseOrderFlag], [cancelsOrder], [closesOrder], [color]) VALUES (7, N'Decal Cut           ', N'Decal Cut                                         ', 0, 0, 0, 0, 1, 0, N'Decoration Cut                                    ', 3, 5, 8, 12, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, N'DarkGreen')
INSERT [dbo].[flagTypes] ([flagTypeId], [flagTypeName], [flagTypeDesc], [userLevel], [shipmentFlag], [userFlag], [orderFlag], [lineFlag], [lineDetailFlag], [customerReadable], [agingDaysStatus1], [agingDaysStatus2], [agingDaysStatus3], [agingDaysStatus4], [agingDaysStatus5], [showInProductionAgingReport], [productionAgingReportOrder], [cannotOccurBeforeFlagId], [cannotOccurAfterFlagId], [purchaseOrderFlag], [purchaseShipmentFlag], [purchaseLineFlag], [createsNewPurchaseOrder], [finishedPurchaseOrderFlag], [cancelsOrder], [closesOrder], [color]) VALUES (8, N'Decal Output        ', N'EPSMM Output                                      ', 0, 0, 0, 0, 1, 0, N'EPSMM Output                                      ', 3, 5, 8, 12, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, N'DarkOrange')
INSERT [dbo].[flagTypes] ([flagTypeId], [flagTypeName], [flagTypeDesc], [userLevel], [shipmentFlag], [userFlag], [orderFlag], [lineFlag], [lineDetailFlag], [customerReadable], [agingDaysStatus1], [agingDaysStatus2], [agingDaysStatus3], [agingDaysStatus4], [agingDaysStatus5], [showInProductionAgingReport], [productionAgingReportOrder], [cannotOccurBeforeFlagId], [cannotOccurAfterFlagId], [purchaseOrderFlag], [purchaseShipmentFlag], [purchaseLineFlag], [createsNewPurchaseOrder], [finishedPurchaseOrderFlag], [cancelsOrder], [closesOrder], [color]) VALUES (10, N'Invoiced            ', N'Invoice                                           ', 0, 0, 0, 1, 0, 0, N'Invoice                                           ', 0, 0, 0, 0, 0, 1, 4, 0, 0, 0, 0, 0, 0, 0, 0, 1, N'DarkSlateGray')
INSERT [dbo].[flagTypes] ([flagTypeId], [flagTypeName], [flagTypeDesc], [userLevel], [shipmentFlag], [userFlag], [orderFlag], [lineFlag], [lineDetailFlag], [customerReadable], [agingDaysStatus1], [agingDaysStatus2], [agingDaysStatus3], [agingDaysStatus4], [agingDaysStatus5], [showInProductionAgingReport], [productionAgingReportOrder], [cannotOccurBeforeFlagId], [cannotOccurAfterFlagId], [purchaseOrderFlag], [purchaseShipmentFlag], [purchaseLineFlag], [createsNewPurchaseOrder], [finishedPurchaseOrderFlag], [cancelsOrder], [closesOrder], [color]) VALUES (11, N'Shipped             ', N'Shipped                                           ', 0, 1, 0, 0, 0, 0, N'Shipped                                           ', 10, 20, 30, 37, 45, 1, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, N'DarkViolet')
INSERT [dbo].[flagTypes] ([flagTypeId], [flagTypeName], [flagTypeDesc], [userLevel], [shipmentFlag], [userFlag], [orderFlag], [lineFlag], [lineDetailFlag], [customerReadable], [agingDaysStatus1], [agingDaysStatus2], [agingDaysStatus3], [agingDaysStatus4], [agingDaysStatus5], [showInProductionAgingReport], [productionAgingReportOrder], [cannotOccurBeforeFlagId], [cannotOccurAfterFlagId], [purchaseOrderFlag], [purchaseShipmentFlag], [purchaseLineFlag], [createsNewPurchaseOrder], [finishedPurchaseOrderFlag], [cancelsOrder], [closesOrder], [color]) VALUES (12, N'Printed             ', N'Printed                                           ', 0, 0, 0, 1, 0, 0, N'Printed                                           ', 3, 5, 8, 12, 15, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, N'DeepSkyBlue')
INSERT [dbo].[flagTypes] ([flagTypeId], [flagTypeName], [flagTypeDesc], [userLevel], [shipmentFlag], [userFlag], [orderFlag], [lineFlag], [lineDetailFlag], [customerReadable], [agingDaysStatus1], [agingDaysStatus2], [agingDaysStatus3], [agingDaysStatus4], [agingDaysStatus5], [showInProductionAgingReport], [productionAgingReportOrder], [cannotOccurBeforeFlagId], [cannotOccurAfterFlagId], [purchaseOrderFlag], [purchaseShipmentFlag], [purchaseLineFlag], [createsNewPurchaseOrder], [finishedPurchaseOrderFlag], [cancelsOrder], [closesOrder], [color]) VALUES (13, N'Decal Reprint       ', N'Decal Reprint                                     ', 0, 0, 0, 0, 1, 0, N'Decal Reprint                                     ', 3, 5, 8, 12, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, N'DodgerBlue')
INSERT [dbo].[flagTypes] ([flagTypeId], [flagTypeName], [flagTypeDesc], [userLevel], [shipmentFlag], [userFlag], [orderFlag], [lineFlag], [lineDetailFlag], [customerReadable], [agingDaysStatus1], [agingDaysStatus2], [agingDaysStatus3], [agingDaysStatus4], [agingDaysStatus5], [showInProductionAgingReport], [productionAgingReportOrder], [cannotOccurBeforeFlagId], [cannotOccurAfterFlagId], [purchaseOrderFlag], [purchaseShipmentFlag], [purchaseLineFlag], [createsNewPurchaseOrder], [finishedPurchaseOrderFlag], [cancelsOrder], [closesOrder], [color]) VALUES (14, N'Inquiry             ', N'Needs Reply From Customer                         ', 0, 1, 0, 1, 1, 0, N'Awating your reply                                ', 0, 0, 0, 0, 0, 1, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, N'Firebrick')
INSERT [dbo].[flagTypes] ([flagTypeId], [flagTypeName], [flagTypeDesc], [userLevel], [shipmentFlag], [userFlag], [orderFlag], [lineFlag], [lineDetailFlag], [customerReadable], [agingDaysStatus1], [agingDaysStatus2], [agingDaysStatus3], [agingDaysStatus4], [agingDaysStatus5], [showInProductionAgingReport], [productionAgingReportOrder], [cannotOccurBeforeFlagId], [cannotOccurAfterFlagId], [purchaseOrderFlag], [purchaseShipmentFlag], [purchaseLineFlag], [createsNewPurchaseOrder], [finishedPurchaseOrderFlag], [cancelsOrder], [closesOrder], [color]) VALUES (15, N'Paid                ', N'Paid                                              ', 0, 0, 0, 0, 0, 0, N'Paid                                              ', 3, 5, 8, 12, 15, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, N'ForestGreen')
INSERT [dbo].[flagTypes] ([flagTypeId], [flagTypeName], [flagTypeDesc], [userLevel], [shipmentFlag], [userFlag], [orderFlag], [lineFlag], [lineDetailFlag], [customerReadable], [agingDaysStatus1], [agingDaysStatus2], [agingDaysStatus3], [agingDaysStatus4], [agingDaysStatus5], [showInProductionAgingReport], [productionAgingReportOrder], [cannotOccurBeforeFlagId], [cannotOccurAfterFlagId], [purchaseOrderFlag], [purchaseShipmentFlag], [purchaseLineFlag], [createsNewPurchaseOrder], [finishedPurchaseOrderFlag], [cancelsOrder], [closesOrder], [color]) VALUES (16, N'Backordered         ', N'Backordered                                       ', 0, 0, 0, 0, 0, 0, N'Backordered                                       ', 3, 5, 8, 12, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, N'Gainsboro')
INSERT [dbo].[flagTypes] ([flagTypeId], [flagTypeName], [flagTypeDesc], [userLevel], [shipmentFlag], [userFlag], [orderFlag], [lineFlag], [lineDetailFlag], [customerReadable], [agingDaysStatus1], [agingDaysStatus2], [agingDaysStatus3], [agingDaysStatus4], [agingDaysStatus5], [showInProductionAgingReport], [productionAgingReportOrder], [cannotOccurBeforeFlagId], [cannotOccurAfterFlagId], [purchaseOrderFlag], [purchaseShipmentFlag], [purchaseLineFlag], [createsNewPurchaseOrder], [finishedPurchaseOrderFlag], [cancelsOrder], [closesOrder], [color]) VALUES (17, N'Pick Ticket         ', N'Pick Ticket                                       ', 0, 1, 0, 1, 1, 0, N'Hunting down your items                           ', 7, 13, 18, 22, 30, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, N'Gold')
INSERT [dbo].[flagTypes] ([flagTypeId], [flagTypeName], [flagTypeDesc], [userLevel], [shipmentFlag], [userFlag], [orderFlag], [lineFlag], [lineDetailFlag], [customerReadable], [agingDaysStatus1], [agingDaysStatus2], [agingDaysStatus3], [agingDaysStatus4], [agingDaysStatus5], [showInProductionAgingReport], [productionAgingReportOrder], [cannotOccurBeforeFlagId], [cannotOccurAfterFlagId], [purchaseOrderFlag], [purchaseShipmentFlag], [purchaseLineFlag], [createsNewPurchaseOrder], [finishedPurchaseOrderFlag], [cancelsOrder], [closesOrder], [color]) VALUES (18, N'Received            ', N'Received                                          ', 0, 0, 0, 1, 0, 0, N'Received PO                                       ', 0, 5, 8, 12, 15, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, N'GreenYellow')
INSERT [dbo].[flagTypes] ([flagTypeId], [flagTypeName], [flagTypeDesc], [userLevel], [shipmentFlag], [userFlag], [orderFlag], [lineFlag], [lineDetailFlag], [customerReadable], [agingDaysStatus1], [agingDaysStatus2], [agingDaysStatus3], [agingDaysStatus4], [agingDaysStatus5], [showInProductionAgingReport], [productionAgingReportOrder], [cannotOccurBeforeFlagId], [cannotOccurAfterFlagId], [purchaseOrderFlag], [purchaseShipmentFlag], [purchaseLineFlag], [createsNewPurchaseOrder], [finishedPurchaseOrderFlag], [cancelsOrder], [closesOrder], [color]) VALUES (20, N'Chained             ', N'Chained into another Purchase Order               ', 0, 0, 0, 0, 0, 0, N'Chained PO                                        ', 0, 5, 8, 12, 15, 0, 0, 0, 20, 0, 0, 0, 0, 0, 0, 0, N'Indigo')
INSERT [dbo].[flagTypes] ([flagTypeId], [flagTypeName], [flagTypeDesc], [userLevel], [shipmentFlag], [userFlag], [orderFlag], [lineFlag], [lineDetailFlag], [customerReadable], [agingDaysStatus1], [agingDaysStatus2], [agingDaysStatus3], [agingDaysStatus4], [agingDaysStatus5], [showInProductionAgingReport], [productionAgingReportOrder], [cannotOccurBeforeFlagId], [cannotOccurAfterFlagId], [purchaseOrderFlag], [purchaseShipmentFlag], [purchaseLineFlag], [createsNewPurchaseOrder], [finishedPurchaseOrderFlag], [cancelsOrder], [closesOrder], [color]) VALUES (21, N'Screen 1            ', N'Screen 1 color                                    ', 0, 0, 0, 0, 0, 0, N'Scrren 1                                          ', 0, 5, 8, 12, 15, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, N'Lavender')
INSERT [dbo].[flagTypes] ([flagTypeId], [flagTypeName], [flagTypeDesc], [userLevel], [shipmentFlag], [userFlag], [orderFlag], [lineFlag], [lineDetailFlag], [customerReadable], [agingDaysStatus1], [agingDaysStatus2], [agingDaysStatus3], [agingDaysStatus4], [agingDaysStatus5], [showInProductionAgingReport], [productionAgingReportOrder], [cannotOccurBeforeFlagId], [cannotOccurAfterFlagId], [purchaseOrderFlag], [purchaseShipmentFlag], [purchaseLineFlag], [createsNewPurchaseOrder], [finishedPurchaseOrderFlag], [cancelsOrder], [closesOrder], [color]) VALUES (22, N'Billed              ', N'Billed                                            ', 0, 0, 0, 0, 0, 0, N'Billed                                            ', 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, N'Gold')
/****** Object:  Table [dbo].[emails]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[emails](
	[emailId] [uniqueidentifier] NOT NULL,
	[textBody] [varchar](max) NOT NULL,
	[HTMLBody] [varchar](max) NOT NULL,
	[mailTo] [char](100) NOT NULL,
	[mailFrom] [char](100) NOT NULL,
	[sender] [char](100) NOT NULL,
	[subject] [varchar](max) NOT NULL,
	[bcc] [char](100) NOT NULL,
	[messageSentOn] [datetime] NOT NULL,
	[addedOn] [datetime] NOT NULL,
	[errorDesc] [varchar](max) NOT NULL,
	[errorId] [int] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_emails] PRIMARY KEY CLUSTERED 
(
	[emailId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE NONCLUSTERED INDEX [idx_emailSentOn] ON [dbo].[emails] 
(
	[messageSentOn] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[vendorItemKitAssignment]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[vendorItemKitAssignment](
	[vendorItemKitAssignmentId] [uniqueidentifier] NOT NULL,
	[cartId] [uniqueidentifier] NULL,
	[serialId] [int] NOT NULL,
	[vendorItemId] [uniqueidentifier] NOT NULL,
	[qty] [int] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_vendorItemKitAssignment] PRIMARY KEY CLUSTERED 
(
	[vendorItemKitAssignmentId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[getSubWeight]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[getSubWeight](
	@itemnumber varchar(100),
	@qty int
)
RETURNS FLOAT
AS
BEGIN
	DECLARE @weight float
	DECLARE @subitem char(100)
	DECLARE @subqty int
	DECLARE subitems CURSOR FOR
	SELECT subitemnumber,qty 
	FROM itemdetail with (nolock)
	WHERE itemnumber = @itemnumber;
	--Set this items weight
	SET @weight = 0
	SET @weight = @weight + (select case when freeShipping = 1 then 0 else weight end from items with (nolock) where itemnumber = @itemnumber)*@qty
	OPEN subitems;
	FETCH NEXT FROM subitems
	INTO @subitem, @subqty
	WHILE @@FETCH_STATUS = 0
	BEGIN
		--Add addtional weight from BOM items
		SET @weight = @weight + dbo.getSubWeight(@subitem, @qty)
		FETCH NEXT FROM subitems
		INTO @subitem, @qty
	END;
	CLOSE subitems;
	DEALLOCATE subitems;
	RETURN(@weight)
END
GO
/****** Object:  UserDefinedFunction [dbo].[getContactWeight]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[getContactWeight](
	-- Add the parameters for the stored procedure here
	@contactid uniqueidentifier, 
	@sessionid uniqueidentifier
)
RETURNS FLOAT
AS
BEGIN
	DECLARE @weighttotal float
			BEGIN
				SET @weighttotal = (SELECT SUM(dbo.getSubWeight(itemnumber,qty)) from cart with (nolock) where addressid = @contactid and sessionID = @sessionid)
			END
	RETURN(@weighttotal)
END
GO
/****** Object:  UserDefinedFunction [dbo].[getContactSubtotal]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[getContactSubtotal](
@contactID uniqueidentifier,
@sessionID uniqueidentifier
)
RETURNS money
AS
BEGIN
DECLARE @contactSubTotal money
	set @contactSubTotal = (select sum((price+valueCostTotal)*qty) as price from cart with (nolock) where addressid = @contactid and sessionID = @sessionID)
RETURN(@contactSubTotal)

END
GO
/****** Object:  UserDefinedFunction [dbo].[getDiscountedContactWeight]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[getDiscountedContactWeight](
@currentaddressid uniqueidentifier,
@sessionid uniqueidentifier
)
RETURNS FLOAT
AS
BEGIN
	DECLARE @discountedweight float
	DECLARE @freeshipthreshold money
	set @freeshipthreshold = (select top 1 free_ship_threshold from site_configuration)
	SET @discountedweight = (
		SELECT case when @freeshipthreshold > dbo.getContactSubtotal(@currentaddressid,@sessionid) then (0) else (select dbo.getContactWeight(@currentaddressid,@sessionid)) end
		)
	RETURN(@discountedweight)

END
GO
/****** Object:  Table [dbo].[shippingType]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[shippingType](
	[shippingName] [varchar](50) NULL,
	[rate] [int] NOT NULL,
	[menuOrder] [int] NULL,
	[international] [bit] NULL,
	[enabled] [bit] NULL,
	[rateType] [int] NULL,
	[zoneCarrierId] [int] NULL,
	[zoneServiceClass] [int] NULL,
	[discountRate] [bit] NULL,
	[trackingLink] [char](200) NULL,
	[cmrAreaSurch] [money] NULL,
	[resAreaSurchg] [money] NULL,
	[groundFuelSurchgPct] [float] NULL,
	[airFuelSurchgPct] [float] NULL,
	[showsUpInRetailCart] [bit] NULL,
	[showsUpInWholesaleCart] [bit] NULL,
	[showsUpInOrderEntry] [bit] NULL,
	[addCharge] [money] NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK__ShippingType__1B0907CE] PRIMARY KEY CLUSTERED 
(
	[rate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[shipZone]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[shipZone](
	[zoneId] [uniqueidentifier] NOT NULL,
	[rate] [int] NOT NULL,
	[weight] [float] NOT NULL,
	[shipzone] [int] NOT NULL,
	[cost] [money] NOT NULL,
	[VerCol] [timestamp] NOT NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [IX_shipzone_3] ON [dbo].[shipZone] 
(
	[shipzone] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_shipZone_rate] ON [dbo].[shipZone] 
(
	[rate] ASC
)
INCLUDE ( [weight],
[shipzone],
[cost]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_shipzone] ON [dbo].[shipZone] 
(
	[weight] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_shipzone_1] ON [dbo].[shipZone] 
(
	[rate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[zipToZone]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[zipToZone](
	[zipToZoneId] [uniqueidentifier] NOT NULL,
	[carrier] [int] NOT NULL,
	[sourceZip] [int] NOT NULL,
	[service] [int] NOT NULL,
	[fromZip] [int] NOT NULL,
	[toZip] [int] NOT NULL,
	[shipZone] [int] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_ziptozone] PRIMARY KEY CLUSTERED 
(
	[zipToZoneId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[shipping_services]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[shipping_services] 
as
	select rateId as rateId, name, Enabled, International, discountable, ZoneCarrierID, ZoneServiceClass, cmrAreaSurch,
	resAreaSurchg, groundFuelSurchgPct, airFuelSurchgPct, showsUpInOrderEntry, showsUpInWholesaleCart, showsUpInRetailCart, shipzone, shippingCost,
	carrier, sourceZip, service, fromzip, tozip, weight, addCharge
	from (
		SELECT
		shippingtype.rate as rateId, ShippingName as name, Enabled, International, discountRate as discountable, ZoneCarrierID, ZoneServiceClass, cmrAreaSurch,
		resAreaSurchg, groundFuelSurchgPct, airFuelSurchgPct, showsUpInOrderEntry, showsUpInWholesaleCart, showsUpInRetailCart, shipzone.shipzone, cost as shippingCost,
		carrier, sourceZip, service, fromzip, tozip, weight, addCharge
		FROM shippingtype
		inner join ziptozone on ShippingType.ZoneServiceClass = ziptozone.service and ShippingType.ZoneCarrierID = ziptozone.carrier
		inner join shipzone on shipzone.rate = shippingtype.rate and shipzone.shipzone = ziptozone.shipzone
	) f union all
	(
	SELECT
	-1 as rateId, 'No suitable rate' as name, 1 as Enabled, 1 as International, 1 as discountable, -1 as zoneCarrierId, -1 as zoneServiceClass, 0 as cmrAreaSurch,
	0 as resAreaSurchg, 0 as groundFuelSurchgPct, 0 as airFuelSurchgPct, 0 as showsUpInOrderEntry, 0 as showsUpInWholesaleCart, 0 as showsUpInRetailCart, -1 shipZone, 0 shippingCost,
	-1 as carrier, -1 as sourceZip, -1 as service, 0 as fromzip, 999999 as tozip, -1 as weight, 0 as addCharge
	)
GO
/****** Object:  Table [dbo].[areaSurcharge]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[areaSurcharge](
	[areaSurchargeId] [uniqueidentifier] NOT NULL,
	[deliveryArea] [int] NOT NULL,
	[carrier] [int] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_areaSurcharge] PRIMARY KEY CLUSTERED 
(
	[areaSurchargeId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[getShippingSurcharge]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[getShippingSurcharge](@rateId int, @zip int, @shippingCost money,
@serviceClass int, @airFuelPct float, @groundFuelPct float, @wholesale bit, @cmrAreaSurchg money, @resAreaSurchg money)
returns money
as
begin
	declare @total money = case /* when an address is in a rural area */
	when exists(
		select 1 from
		areaSurcharge with (nolock)
		where carrier = (
			select zoneCarrierId
			from shippingType with (nolock)
			where rate = @rateID
		)
		and deliveryArea = @zip
	) then 
		(/* add the rural area surcharge to the shipment */
			@shippingCost+(
				case when @wholesale = 1 then 
					/* commercial rural area surcharge for wholesale users */
					@cmrAreaSurchg 
				else
					/* residential rural area surcharge for wholesale users */ 
					@resAreaSurchg 
				end
			)
		)* /* multiplied by 1.<fuel surcharge> */
		(1+(
				case 
					/* when a service is class 2 or higher use air fuel surcharge */
					when @serviceClass > 1
					then @airFuelPct
					else @groundFuelPct 
				end
			)
		)
	else
		/* no rural surcharge */
		(
			@shippingCost * /* multiplied by 1.<fuel surcharge> */ (1+(
					/* when a service is class 2 or higher use air fuel surcharge */
					case when @serviceClass > 1	then
						@airFuelPct
					else 
						@groundFuelPct
					end 
				)
			)
		)
	end
	return @total;
end
GO
/****** Object:  Table [dbo].[contacts]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[contacts](
	[contactId] [uniqueidentifier] NOT NULL,
	[firstName] [varchar](100) NOT NULL,
	[lastName] [varchar](100) NOT NULL,
	[address1] [varchar](25) NOT NULL,
	[address2] [varchar](25) NOT NULL,
	[city] [varchar](100) NOT NULL,
	[state] [varchar](100) NOT NULL,
	[zip] [varchar](20) NOT NULL,
	[country] [varchar](100) NOT NULL,
	[homePhone] [varchar](100) NOT NULL,
	[workPhone] [varchar](100) NOT NULL,
	[email] [varchar](100) NOT NULL,
	[specialInstructions] [varchar](max) NOT NULL,
	[sendShipmentUpdates] [bit] NOT NULL,
	[comments] [varchar](max) NOT NULL,
	[emailAds] [bit] NOT NULL,
	[rate] [int] NOT NULL,
	[company] [varchar](50) NOT NULL,
	[dateCreated] [datetime] NOT NULL,
	[shippingQuote] [money] NOT NULL,
	[weight] [float] NOT NULL,
	[taxRate] [float] NOT NULL,
	[sessionId] [uniqueidentifier] NOT NULL,
	[userId] [int] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_Contacts] PRIMARY KEY CLUSTERED 
(
	[contactId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE NONCLUSTERED INDEX [idx_contactsUserId] ON [dbo].[contacts] 
(
	[userId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[getContactShipPrice]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[getContactShipPrice](
	@addressId uniqueidentifier,
	@sessionId uniqueidentifier
)
RETURNS money
AS
BEGIN
declare @shipprice money
SELECT @shipprice = dbo.getShippingSurcharge(rateId,zip,shippingCost,zoneServiceClass,airFuelSurchgPct,groundFuelSurchgPct,wholesaledealer,cmrAreaSurch,resAreaSurchg)
	+shipping_services.addCharge
from
(
	select
	dbo.getContactWeight(addressId,ci.sessionId) as weight,
	dbo.getDiscountedContactWeight(addressId,ci.sessionId) as disc_wgt,
	ci.sessionid,
	case when isNumeric(substring(zip,1,5)) = 1 then cast(substring(zip,1,5) as int) else 0 end as zip,
	wholesaledealer,
	rate as selectedRateId,
	addressId
	from (
		select
		addressId,contacts.zip, wholesaledealer, rate, cart.sessionId
		from cart
		inner join contacts on contacts.contactId = addressId
		left join users on contacts.userId = users.userId
		where cart.sessionId = @sessionID
		group by addressID,cart.sessionID,contacts.zip,wholesaledealer,rate
	) ci
) c
inner join shipping_services on shipping_services.weight = c.weight and c.zip between shipping_services.fromzip and shipping_services.tozip
where
c.sessionId = @sessionId and c.addressId = @addressID and c.selectedRateId = shipping_services.rateId
if (@shipprice is null)	begin
	set @shipprice = 0
end
RETURN(@shipprice)
END
GO
/****** Object:  Table [dbo].[itemProperties]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[itemProperties](
	[itemPropertyId] [uniqueidentifier] NOT NULL,
	[itemNumber] [varchar](50) NULL,
	[itemProperty] [char](50) NULL,
	[propertyValue] [char](50) NULL,
	[displayValue] [char](50) NULL,
	[valueOrder] [int] NULL,
	[BOMItem] [bit] NULL,
	[price] [money] NULL,
	[taxable] [bit] NULL,
	[showAsSeperateLineOnInvoice] [bit] NULL,
	[showInFilter] [bit] NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_itemProperties] PRIMARY KEY CLUSTERED 
(
	[itemPropertyId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE NONCLUSTERED INDEX [IX_itemProperties] ON [dbo].[itemProperties] 
(
	[itemNumber] ASC,
	[propertyValue] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[userPriceList]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[userPriceList](
	[userPriceListId] [uniqueidentifier] NOT NULL,
	[userId] [int] NOT NULL,
	[itemNumber] [char](50) NOT NULL,
	[comments] [char](200) NULL,
	[price] [money] NOT NULL,
	[fromDate] [datetime] NOT NULL,
	[toDate] [datetime] NOT NULL,
	[flagTypeId] [int] NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_userPriceList] PRIMARY KEY CLUSTERED 
(
	[userPriceListId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[visitors]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[visitors](
	[sessionId] [uniqueidentifier] NOT NULL,
	[HTTP_REFERER] [varchar](1000) NOT NULL,
	[HTTP_USER_AGENT] [varchar](1000) NOT NULL,
	[REMOTE_ADDR] [char](15) NOT NULL,
	[context] [char](200) NOT NULL,
	[userId] [int] NOT NULL,
	[recordsPerPage] [int] NOT NULL,
	[orderBy] [int] NOT NULL,
	[listMode] [int] NOT NULL,
	[zip] [varchar](20) NOT NULL,
	[rate] [int] NOT NULL,
	[addDate] [datetime] NOT NULL,
	[unique_site_id] [uniqueidentifier] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_Visitors] PRIMARY KEY CLUSTERED 
(
	[sessionId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE NONCLUSTERED INDEX [idx_visitorsSessionId] ON [dbo].[visitors] 
(
	[sessionId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_visitorsUserId] ON [dbo].[visitors] 
(
	[userId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[cartDetail]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[cartDetail](
	[CartDetailId] [uniqueidentifier] NOT NULL,
	[cartId] [uniqueidentifier] NOT NULL,
	[inputName] [varchar](100) NOT NULL,
	[value] [varchar](max) NOT NULL,
	[sessionId] [uniqueidentifier] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK__CartDetail] PRIMARY KEY CLUSTERED 
(
	[CartDetailId] DESC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE NONCLUSTERED INDEX [idx_cartDetail_cover] ON [dbo].[cartDetail] 
(
	[sessionId] ASC
)
INCLUDE ( [CartDetailId],
[cartId],
[inputName],
[value]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  StoredProcedure [dbo].[insertKit]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[insertKit](
@itemnumber varchar(50),
@cartId uniqueidentifier,
@qty int,
@wholesale int,
@sessionid uniqueidentifier,
@userid int,
@price money,
@isTaxable bit
) as
		/* insertKit version 1 */
		declare @emptyGUID uniqueidentifier = '{00000000-0000-0000-0000-000000000000}';
		declare @isInventoryItem bit = 1;
		/* 
			a kit can be constructed during 'place order' using the property list of an item 
			or by using the parentItem field on the item
			either way the a dynamic kit requires that the item have a customization form (cartDetail hash)
			When the form 
				
		*/
		/* insert unallocated kit into the @kitallocation table */
		declare @kitAllocation table(cartId uniqueidentifier, itemNumber varchar(50), qty int,vendorItemKitAssignmentId uniqueidentifier,
		itemConsumed bit,allowPreorders bit,showAsSeperateLineOnInvoice bit,valueCostTotal money,noTaxValueCostTotal money,inventoryItem bit,
		generalLedgerId uniqueidentifier, VerCol binary(50))
		/* if a kit exists enter it into the kit allocation table */
		insert into @kitAllocation
		select @cartId as cartId, sub.subItemNumber as itemNumber, sub.qty*@qty as qty, @emptyGUID as vendorItemKitAssignmentId, 
		0 as itemConsumed, 1 as allowPreorders, showAsSeperateLineOnInvoice as showAsSeperateLineOnInvoice,
		0 as valueCostTotal, 0 as noTaxValueCostTotal, inventoryItem,@emptyGUID as generalLedgerId, null as VerCol
		from (
			select d.itemNumber, subItemNumber, qty, itemComponetType,
			showAsSeperateLineOnInvoice, onlyWhenSelectedOnForm, cast(case when itemType = 0 then 1 else 0 end as bit) as inventoryItem
			from itemdetail d with (nolock)
			inner join items i on i.itemNumber = d.subItemNumber
			where d.itemNumber = @itemnumber
			union all
			select p.itemNumber, itemProperty as subItemNumber,1 as qty, 'prop' as itemComponetType,
			showAsSeperateLineOnInvoice, 1 as onlyWhenSelectedOnForm, cast(case when itemType = 0 then 1 else 0 end as bit) as inventoryItem
			from itemProperties p with (nolock)
			inner join items i on p.itemProperty = i.itemNumber
			where BOMItem = 1 and p.itemNumber = @itemnumber
			union all
			select p.itemNumber, propertyValue as subItemNumber,1 as qty, itemProperty as itemComponetType,
			showAsSeperateLineOnInvoice, 1 as onlyWhenSelectedOnForm, cast(case when itemType = 0 then 1 else 0 end as bit) as inventoryItem
			from itemProperties p with (nolock)
			inner join items i on p.propertyValue = i.itemNumber
			where BOMItem = 1 and p.itemNumber = @itemnumber
			union all
			select parentItemnumber, itemNumber as subItemNumber, 1 as qty, 'childItem' as itemComponetType,
			0 as showAsSeperateLineOnInvoice, 1 as onlyWhenSelectedOnForm, cast(case when itemType = 0 then 1 else 0 end as bit) as inventoryItem
			from items with (nolock) where parentItemNumber = @itemnumber
		) sub  
		left join cartDetail d on d.cartId = @cartID
		where 
		(sub.itemnumber = @itemnumber)
		and
		(
			(
				sub.onlyWhenSelectedOnForm = 1
				and (
					(d.inputName = sub.subItemNumber and d.value = 'True' and itemComponetType = 'prop')
					or (d.value = sub.subItemNumber and d.inputName = itemComponetType and not subItemNumber = 'True')
				)
			)
		or
			(sub.onlyWhenSelectedOnForm = 0)
		)
		group by cartId, sub.subItemNumber, qty, showAsSeperateLineOnInvoice, inventoryItem

		set @isInventoryItem = (select cast(case when itemType = 0 then 1 else 0 end as bit) as inventoryItem
		from items i with (nolock) where itemNumber = @itemnumber)

		/* even if the item has no kit then stick the parent item into the kit alocation table, and set it to ALWAYS show up on the invoice*/
		insert into @kitAllocation (cartId, itemNumber, qty, vendorItemKitAssignmentId, itemConsumed, allowPreorders,
		showAsSeperateLineOnInvoice,noTaxValueCostTotal,ValueCostTotal,inventoryItem,generalLedgerId,VerCol) 
		values (@cartID,@itemnumber,@qty,@emptyGUID,0,1,1,
		/* no tax price */case when @isTaxable = 1 then 0 else @price end,
		/* tax price */case when @isTaxable = 0 then 0 else @price end
		,@isInventoryItem, @emptyGUID, null)

		/* do the actual insert */
		insert into kitAllocation
		select cartId, itemNumber, qty, vendorItemKitAssignmentId, 
		itemConsumed,allowPreorders,showAsSeperateLineOnInvoice,
		valueCostTotal,noTaxValueCostTotal,inventoryItem,generalLedgerId,
		null as VerCol from @kitAllocation
GO
/****** Object:  Table [dbo].[tax]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tax](
	[Autonumber] [int] IDENTITY(1,1) NOT NULL,
	[ZIPFrom] [char](50) NULL,
	[ZIPTo] [char](50) NULL,
	[Tax] [float] NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK__Tax__1CF15040] PRIMARY KEY CLUSTERED 
(
	[Autonumber] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF

SET IDENTITY_INSERT [dbo].[tax] ON
INSERT [dbo].[tax] ([Autonumber], [ZIPFrom], [ZIPTo], [Tax]) VALUES (1, N'0                                                 ', N'89999                                             ', 0)
INSERT [dbo].[tax] ([Autonumber], [ZIPFrom], [ZIPTo], [Tax]) VALUES (2, N'90000                                             ', N'96199                                             ', 0.0825)
INSERT [dbo].[tax] ([Autonumber], [ZIPFrom], [ZIPTo], [Tax]) VALUES (3, N'96200                                             ', N'999999                                            ', 0)
SET IDENTITY_INSERT [dbo].[tax] OFF
/****** Object:  UserDefinedFunction [dbo].[getContactTaxTotal]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[getContactTaxTotal](
	@addressID uniqueidentifier,
	@sessionid uniqueidentifier
	)
	returns money
	as
	begin
		/* [getContactTaxTotal version 1.1 */
		declare @cartTaxTotal money

		if exists(
			select 0 
			from dbo.users 
			inner join dbo.visitors v on users.userId = v.userId and v.sessionid = @sessionid
			where notax = 1
		) begin
			set @cartTaxTotal = 0;
			return @cartTaxTotal;
		end
	
		set @cartTaxTotal = (
			select 
			sum((cart.price+valueCostTotal)*qty)*(case when dbo.tax.tax is null then 0 else dbo.tax.tax end) 
			from dbo.cart with (nolock)
			inner join dbo.items with (nolock) on items.itemnumber = cart.itemnumber
			inner join dbo.contacts with (nolock) on contactid = @addressId
			left join dbo.tax with (nolock) on 
				case when isNumeric(substring(dbo.contacts.zip,1,5)) = 1 then
					substring(dbo.contacts.zip,1,5)
				else
					0
				end
			 between zipFrom and zipTo 
			where dbo.cart.sessionid = @sessionid and items.notax = 0 and cart.addressid = @addressID
			group by dbo.tax.tax
		)
	if @cartTaxTotal is null
	begin
		set @cartTaxTotal = 0
	end 
	return ROUND(@cartTaxTotal, 2)
	end
GO
/****** Object:  Table [dbo].[paymentMethods]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[paymentMethods](
	[paymentMethodId] [uniqueidentifier] NOT NULL,
	[paymentType] [varchar](50) NULL,
	[cardName] [char](100) NULL,
	[cardType] [char](25) NULL,
	[cardNumber] [char](20) NULL,
	[expMonth] [char](10) NULL,
	[expYear] [char](10) NULL,
	[secNumber] [char](4) NULL,
	[userId] [int] NULL,
	[sessionId] [uniqueidentifier] NULL,
	[addressId] [uniqueidentifier] NULL,
	[routingNumber] [varchar](50) NULL,
	[checkNumber] [varchar](50) NULL,
	[bankAccountNumber] [varchar](50) NULL,
	[payPalEmailAddress] [varchar](200) NULL,
	[swift] [varchar](50) NULL,
	[bankName] [varchar](50) NULL,
	[routingTransitNumber] [varchar](50) NULL,
	[cash] [bit] NULL,
	[notes] [varchar](max) NULL,
	[amount] [money] NULL,
	[generalLedgerInsertId] [uniqueidentifier] NULL,
	[promiseToPay] [bit] NULL,
	[paymentRefId] [int] NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_creditcards] PRIMARY KEY CLUSTERED 
(
	[paymentMethodId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[paymentMethodsDetail]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[paymentMethodsDetail](
	[paymentMethodDetailId] [uniqueidentifier] NOT NULL,
	[paymentMethodId] [uniqueidentifier] NOT NULL,
	[orderId] [int] NULL,
	[amount] [money] NULL,
 CONSTRAINT [PK_paymentMethodsDetail] PRIMARY KEY CLUSTERED 
(
	[paymentMethodDetailId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[addresses]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[addresses](
	[addressId] [uniqueidentifier] NOT NULL,
	[firstName] [varchar](100) NOT NULL,
	[lastName] [varchar](100) NOT NULL,
	[address1] [varchar](25) NOT NULL,
	[address2] [varchar](25) NOT NULL,
	[city] [varchar](100) NOT NULL,
	[state] [varchar](100) NOT NULL,
	[zip] [varchar](20) NOT NULL,
	[country] [varchar](100) NOT NULL,
	[homePhone] [varchar](100) NOT NULL,
	[workPhone] [varchar](100) NOT NULL,
	[email] [varchar](100) NOT NULL,
	[specialInstructions] [varchar](max) NOT NULL,
	[sendShipmentUpdates] [bit] NOT NULL,
	[comments] [varchar](max) NOT NULL,
	[emailAds] [bit] NOT NULL,
	[rate] [int] NOT NULL,
	[company] [varchar](50) NOT NULL,
	[dateCreated] [datetime] NOT NULL,
	[shippingQuote] [money] NOT NULL,
	[weight] [float] NOT NULL,
	[taxRate] [float] NOT NULL,
	[orderId] [int] NOT NULL,
	[shipmentId] [int] NOT NULL,
	[sessionId] [uniqueidentifier] NOT NULL,
	[shipmentNumber] [char](20) NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_Addresses] PRIMARY KEY CLUSTERED 
(
	[addressId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  UserDefinedFunction [dbo].[f_convert_from_base10]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     FUNCTION [dbo].[f_convert_from_base10]
  (@num INT, @base TINYINT)
RETURNS VARCHAR(255) AS 
BEGIN 

  -- Declarations
  DECLARE @string VARCHAR(255)
  DECLARE @return VARCHAR(255)
  DECLARE @finished BIT
  DECLARE @div INT
  DECLARE @rem INT
  DECLARE @char CHAR(1)

  -- Initialise
  -- Base 36 removed, replaced with word safe base 31
  -- SELECT @string   = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  SELECT @string   = '0123456789BCDFGHJKLMNPQRSTVWXYZ'
  SELECT @return   = CASE WHEN @num <= 0 THEN '0' ELSE '' END
  SELECT @finished = CASE WHEN @num <= 0 THEN 1 ELSE 0 END
  SELECT @base     = CASE WHEN @base < 2 OR @base IS NULL THEN 2 WHEN @base > 36 THEN 36 ELSE @base END

  -- Loop
  WHILE @finished = 0
  BEGIN

    -- Do the maths
    SELECT @div = @num / @base
    SELECT @rem = @num - (@div * @base)
    SELECT @char = SUBSTRING(@string, @rem + 1, 1)
    SELECT @return = @char + @return
    SELECT @num = @div

    -- Nothing left?
    IF @num = 0 SELECT @finished = 1

  END

  -- Done
  RETURN @return

END
GO
/****** Object:  Table [dbo].[errors]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[errors](
	[ErrorId] [int] IDENTITY(1,1) NOT NULL,
	[script] [char](50) NULL,
	[description] [char](300) NULL,
	[number] [char](100) NULL,
	[source] [char](100) NULL,
	[sessionId] [uniqueidentifier] NULL,
	[reference] [varchar](max) NULL,
	[logTime] [datetime] NULL,
	[url] [varchar](max) NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_errors] PRIMARY KEY CLUSTERED 
(
	[ErrorId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO

/****** Object:  StoredProcedure [dbo].[placeOrder]    Script Date: 11/15/2011 16:30:00 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[placeOrder](
		@sessionid uniqueidentifier,
		@userid int,
		@paymentMethodId uniqueidentifier,
		@testmode bit,
		@unique_site_id uniqueidentifier,
		@cartSessionId uniqueidentifier,
		@purchaseOrderNumber varchar(50),
		@orderDate datetime,
		@termId int,
		@discountAmount money
	)
	AS
	begin
	/**********************************************************************************************
											Place Order v. 0.1.6
			All orders in this system are in here because they passed through this procedure.
	**********************************************************************************************/

	/**********************************************************************************************
											RETURNS
											
		Column errorOccured tells why the order could not be placed.  
		If errorOccured = 0 then the order was commited
		0 = No error
		1 = No Bill to address found
		2 = 1 or more ship to address missing
		3 = Calulation error - one or more monitary values is missing
		4 = one or more items was out of stock
		5 = this order was placed in test mode
	**********************************************************************************************/

	/**********************************************************************************************
	*		 WARNING   WARNING   WARNING   WARNING   WARNING   WARNING   WARNING   WARNING   
	*	WARNING   WARNING   WARNING   WARNING   WARNING   WARNING   WARNING   WARNING   WARNING   
	*
	*	Never change this SP - use event handlers in the binary application to modify orders
	*   before or after they are entered.  Always use a transaction while using this SP!
	*	
	*
	**********************************************************************************************/

		set NOCOUNT ON
		--set XACT_ABORT ON --transactions are now handled in the C# host application

		declare @orderId int
		declare @shipmentId int
		declare @serialId int
		declare @emptyGUID uniqueidentifier = '{00000000-0000-0000-0000-000000000000}'
		declare @checkoutFields table(
										fieldName varchar(512),
										fieldValue varchar(max)
									)
		declare @taxRates  table(
								taxRate float
								)
		declare @shipments table(
								addressId uniqueidentifier,
								weight float,
								shipPrice money,
								taxTotal money
								)
		declare @lines table(
							cartid uniqueidentifier,
							itemnumber varchar(50),
							qty int,
							price money,
							addressId uniqueidentifier,
							orderid int,
							ordernumber varchar(25),
							shipmentid int,
							shipmentnumber varchar(25),
							serialid int,
							serialnumber varchar(25),
							linenumber int,
							userId int,
							sessionId uniqueidentifier,
							termId int,
							epsmmcsoutput varchar(25),
							inventoryDepletesOnFlagId int,
							newItem bit,
							GLprice money,
							noTax bit,
							parentCartId uniqueidentifier,
							epsmmcsAIFilename varchar(50)
							)
		declare @epsmmcsAIFilename varchar(50)
		declare @addressId uniqueidentifier
		declare @cartId uniqueidentifier
		declare @addressShipPrice money
		declare @addressweight float
		declare @addressTax money
		declare @shiptotal money
		declare @taxTotal money
		declare @grandtotal money
		declare @subTotal money
		declare @discountPct float
		declare @printstate varchar(50)
		declare @parentCartId uniqueidentifier
		declare @serializationbase int
		declare @x int
		declare @inventoryDepletesOnFlagId int
		declare @newcontactId uniqueidentifier
		declare @newBillToAddressId uniqueidentifier
		declare @newsessionId uniqueidentifier
		declare @concatSerialNumbers varchar(max)
		declare @concatShipmentNumbers varchar(max)
		declare @discounted money
		declare @itemnumber varchar(50)
		declare @qty int
		declare @concatSerialIds varchar(max)
		declare @concatShipmentIds varchar(max)
		declare @errorOccured int
		declare @errorDesc varchar(255)
		declare @addrCount int
		declare @addrLineCount int
		declare @comment varchar(max)
		declare @allowPreorders bit
		declare @newFlagId int
		declare @wholesale bit
		declare @discountCode varchar(50) = '';
		declare @orderNumber varchar(50);
		declare @currentShipmentNumber varchar(50);
		declare @diff money = 0;
		declare @previous_billToAddressId uniqueidentifier;
		declare @previous_grandTotal money = 0;
		declare @previous_subTotal money = 0;
		declare @previous_taxTotal money = 0;
		declare @previous_shipTotal money = 0;
		declare @previous_discountTotal money = 0;
		declare @newItem bit = 0;
		declare @paymentAmount money;
		declare @GLprice money;
		declare @noTax bit;
		print 'set defaults'
		set @wholesale = (select wholesaledealer from Users   with (nolock) where userId = @userid)
		select @serializationbase = serializationbase from site_configuration  with (nolock) where unique_siteId = @unique_site_id
		set @printstate = ''
		set @newsessionId = newId()
		set @concatSerialNumbers = ''
		set @concatShipmentNumbers = ''
		set @taxTotal = 0
		set @shiptotal = 0
		set @grandtotal = 0
		set @x = 1
		set @discountPct = 0
		set @concatSerialIds = ''
		set @concatShipmentIds = ''
		set @errorOccured = 0
		set @errorDesc = ''
		set @comment = ''
		set @newFlagId = -10
	/* figure out if this order has already been placed and were updating it */
		declare @existingOrder bit = 0
		if exists(select 0 from orders  with (nolock) where sessionId = @sessionid) begin
			print 'Existing order (update order mode)'
			set @existingOrder = 1
			/* if this an existing order, copy the addresses into the contacts table
			where the rest of the procedure expects them to be, and remove them from the addresses table
			where they will return to
			- make sure to use the same Ids as they go into contacts and as they go back into addresses
			*/
			select 
			@orderid = orderId,
			@previous_billToAddressId = billToAddressId,
			@previous_discountTotal = discount,
			@previous_grandTotal = grandTotal,
			@previous_shipTotal = shippingTotal,
			@previous_subTotal = subTotal,
			@previous_taxTotal = taxTotal,
			@orderNumber = orderNumber
			from orders  with (nolock) where sessionId = @sessionid
			
			/* remove any contacts that may have been left from previous updates */
			delete from contacts where contactId in (select addressId from addresses with (nolock) where orderId = @orderid)
			/* move the addresses back into the contacts */
			insert into contacts
			select case when shipmentId = -1 then @previous_billToAddressId else addressId end as contactId,
			firstName, lastName, address1, address2, city, state, zip, country, homePhone, workPhone, 
			email, specialInstructions, sendShipmentUpdates, comments, emailAds, rate, company, dateCreated, 
			shippingQuote, weight, taxRate, @cartSessionId as sessionId, @userid as userId, null as VerCol
			from addresses with (nolock) where orderId = @orderid
					
			/* check if there are any items in the order's 'cart'*/
			if not @cartSessionId = @emptyGUID begin
				/* move the items into the real session */
				update cart set sessionId = @sessionid where sessionId = @cartSessionId
			end
		end
		if @existingOrder = 0 begin
			/* check if the cart has items in it */
			if not exists(select 0 from cart where sessionId = @sessionId) begin
				print 'Error 7: there are no items in the order.'
				set @errorOccured = 7
				set @errorDesc = 'There are no items in this order.'
			end
			if @errorOccured = 0 begin
				print 'New order'
				/* create a new orderId */
				insert into serial_order (sessionid,lastFlagId,lastFlagStatus) values (@sessionid,@emptyGUID,-1)
				set @orderId = SCOPE_IDENTITY()
				set @orderNumber = dbo.f_convert_from_base10(@orderId,@serializationbase);
				/* update the paymentMethodsDetail table new orderId */
				update paymentMethodsDetail set orderId = @orderId where paymentMethodId = @paymentMethodId
			end
			
		end
		if @errorOccured = 0 begin
			/* fill the table @shipments with all the addreses we'll be shipping to */
			print 'Fill shipments'
			insert into @shipments
			select
			a.contactid as addressId,
			c22 as weight,
			c23 as shipPrice,
			c24 as taxTotal
			from (select f.addressid,
					dbo.getContactWeight(f.addressid,@sessionid) as c22,
					dbo.getContactShipPrice(f.addressId,@sessionid) as c23,
					dbo.getContactTaxTotal(f.addressId,@sessionid) as c24
					from (select cart.addressid from cart with (nolock) where sessionid = @sessionid group by addressid) f 
				) d
			inner join contacts a with (nolock) on a.contactId = d.addressId
		/* fill the table @lines with all lines we'll be ordering */
			print 'Fill lines'
			insert into @lines
			select	cartid,
					cart.itemnumber,
					qty,
					cart.price+valueCostTotal+noTaxValueCostTotal,
					addressId,
					@orderid as orderid,
					@orderNumber as ordernumber,
					-1 as shipmentid,
					'' as shipmentnumber,
					-1 as serialid,
					'' as serialnumber,
					-1 as linenumber,
					@userid as userid,
					@newsessionId as sessionid,
					@termId as termId,
					case when epsmmcsoutput is null then '' else epsmmcsoutput end as epsmmcsoutput,
					inventoryDepletesOnFlagId as inventoryDepletesOnFlagId,
					0 as newItem,
					cart.price,
					items.noTax,
					cart.parentCartId,
					cart.epsmmcsAIFilename
					from cart with (nolock)
					inner join Items with (nolock) on Items.Itemnumber = cart.Itemnumber
					where sessionid = @sessionid
		/* Create a shipmentId and assign this to each shipment in the order */
			print 'Start shipment cursor'
			declare shipment_cursor cursor forward_only static for
			select addressid, weight, shipprice, taxtotal
			from @shipments
			open shipment_cursor;
			fetch next from shipment_cursor
			into @addressid, @addressweight, @addressShipPrice, @addressTax
			while @@FETCH_STATUS = 0
			begin
		/* Create a shipmentId */
				print 'Adding addressId '+convert(varchar(50),@addressid)
				if exists(select 0 from cart with (nolock) where addressId = @addressId and sessionId = @sessionId and shipmentId = -1) begin
					insert into serial_shipment (orderId,sessionid,lastFlagId,lastFlagStatus) values (@orderId,@newsessionId,@emptyGUID,-1)
					set @shipmentId = SCOPE_IDENTITY()
				end else begin
					select @shipmentId = shipmentId from cart with (nolock) where addressId = @addressId and sessionId = @sessionId
				end
				set @currentShipmentNumber = dbo.f_convert_from_base10(@shipmentId,@serializationbase);
				set @concatShipmentNumbers = @concatShipmentNumbers + @currentShipmentNumber + ','
				set @concatShipmentIds = @concatShipmentIds + cast(@shipmentId as varchar(50))+ ','
		/* Create a permanent copy of the contact into the ADDRESS table*/
				if @existingOrder = 0 begin
					set @newcontactId = newId()
				end else begin
					set @newcontactId = @addressId
				end
				if not exists(select 0 from addresses with (nolock) where addressId = @newcontactId) begin
					insert into addresses
					select @newcontactId, firstName, lastName, address1, address2, city, state, zip, country, homePhone, workPhone,
					email, specialInstructions, sendShipmentUpdates, comments, emailAds, rate, company, dateCreated,
					shippingQuote, weight, tax.Tax as taxRate, @orderId, @shipmentId, @sessionid, @currentShipmentNumber, null as VerCol
					from contacts with (nolock)
					left join tax with (nolock) on case when isNumeric(substring(contacts.ZIP,1,5)) = 1 then cast(substring(contacts.ZIP,1,5) as integer) else 0 end between ZIPFrom and ZIPTo
					where contactid = @addressid
				end
				
		/* update the table @lines with the new info */
				update @lines set
				addressId = @newcontactId,
				shipmentId = @shipmentId,
				shipmentNumber = @currentShipmentNumber
				where addressid = @addressid;
		/* update running totals */
				set @taxTotal = @taxTotal + round(@addressTax,2)
				set @shiptotal = @shiptotal + round(@addressShipPrice,2)
		/* move to the next record */
				fetch next from shipment_cursor
				into @addressid, @addressweight, @addressShipPrice, @addressTax
			end
			close shipment_cursor;
			deallocate shipment_cursor;
			set @concatShipmentNumbers = substring(@concatShipmentNumbers,1,len(@concatShipmentNumbers)-1)
			set @concatShipmentIds = substring(@concatShipmentIds,1,len(@concatShipmentIds)-1)
			print 'Start line cursor'
		/* Create a serialId and assign it to each line item */
			declare line_cursor cursor forward_only static for
			select cartid, itemnumber, qty, inventoryDepletesOnFlagId, GLprice, noTax, epsmmcsoutput, parentCartId, epsmmcsAIFilename
			from @lines
			OPEN line_cursor;
			fetch next from line_cursor
			into @cartId, @itemnumber, @qty, @inventoryDepletesOnFlagId, @GLprice, @noTax, @printstate, @parentCartId, @epsmmcsAIFilename
			while @@FETCH_STATUS = 0
			begin
				print 'Adding cartId '+convert(varchar(50),@cartId)
		/* Create a serialId */
				if exists(select 0 from cart with (nolock) where cartId = @cartId and serialId = -1) begin
					/* set the flag type to null, later we'll update this column and check the lastFlagStatus column to see if
					its status in the inventory system is ok, or if we should roll back the order */
					insert into serial_line (cartId,orderId,shipmentId,sessionId,lastFlagId,lastFlagStatus,lastErrorId) values (@cartId,@orderId,@shipmentId,@sessionid,@emptyGUID,@newFlagId,0);
					set @serialId = SCOPE_IDENTITY();
					set @newItem = 1;
				end else begin
					select @serialId = serialId from cart with (nolock) where cartId = @cartId;
					set @newItem = 0;
				end
				set @concatSerialNumbers = @concatSerialNumbers + dbo.f_convert_from_base10(@serialId,@serializationbase) + ','
				set @concatSerialIds = @concatSerialIds + cast(@serialId as varchar(50)) + ','
		/* update the table @lines with the new info */
				update @lines set 
				epsmmcsOutput = @printstate, 
				serialId = @serialId,
				serialNumber = dbo.f_convert_from_base10(@serialId,@serializationbase),
				linenumber = @x,
				newItem = @newItem
				where cartId = @cartId;
				if exists(select 0 from cart with (nolock) where cartId = @cartId and serialId = -1) begin
					/* only insert kits for items that haven't had kits inserted yet */
					exec dbo.insertKit @itemnumber,@cartId,@qty,@wholesale,@sessionid,@userid,@GLprice,@noTax
				end
				/* move item from one item to another. Deplete refering order's qty  if such a refering order exists */
				if @existingOrder = 0 and not @parentCartId = @emptyGUID  begin
					/* check if item still exists */
					if exists(select 0 from cart with (nolock) where cartId = @parentCartId and qty > 0) begin
						/* get reference numbers */
						declare @refSerialId int;
						declare @refSerialNumber varchar(50);
						select @refSerialNumber = serialNumber, @refSerialId = serialId
						from cart with (nolock) where cartId = @parentCartId;
						/* update source order */
						update cart set returnToStock = @qty where cartId = @parentCartId;
						exec dbo.backorderCancel @refSerialId, 1, 0
						/* update target order */
						update @lines set 
						parentCartId = @emptyGUID,
						epsmmcsAIFilename = @refSerialNumber,
						epsmmcsOutput = 'Printed'
						where cartid = @cartId;
					end
				end else if not @parentCartId = @emptyGUID begin
					print 'Error 9: Unique item is out of stock.'
					set @errorOccured = 9
					set @errorDesc = 'Unique item is out of stock.'
				end
		/* Increment line counter and move to the next record */
				set @x = @x + 1
				fetch next from line_cursor
				into @cartId, @itemnumber, @qty, @inventoryDepletesOnFlagId, @GLprice, @noTax, @printstate, @parentCartId, @epsmmcsAIFilename
			end
			close line_cursor;
			deallocate line_cursor;
			set @concatSerialNumbers = substring(@concatSerialNumbers,1,len(@concatSerialNumbers)-1)
			set @concatSerialIds = substring(@concatSerialIds,1,len(@concatSerialIds)-1)

			print 'calculate totals'
		/* set the grand total based on the sum of the cart items+tax+shipping */
			set @subTotal = (select sum(price*qty) from @lines)
			set @discounted = @discountAmount
			if(not ISNUMERIC(@discounted)=1) begin
				set @discounted = 0;
			end
			set @grandtotal = @taxTotal+@shiptotal+@subTotal-@discounted
			
		/* Create a permanent copy of the BILL TO ADDRESS into the ADDRESS table*/
			if @existingOrder=1 begin
				set @newBillToAddressId = @previous_billToAddressId;
			end else begin
				set @newBillToAddressId = newId();
			end
			print 'insert bill to address'
			if not exists(select 0 from addresses with (nolock) where addressId = @newBillToAddressId) begin
				insert into addresses
				select
				@newBillToAddressId as AddressId, firstName, lastName, address1, address2, city, state, zip, country,
				homePhone, workPhone, email, specialInstructions, sendShipmentUpdates, comments,
				emailAds, rate, company, dateCreated, 0 as shippingQuote, 0 as weight, 0 as taxRate, @orderId,
				-1 as shipmentId, sessionId, '' as shipmentNumber,null as VerCol
				from contacts with (nolock) where contactid = @sessionId
			end
			print 'begin error checking'
			/* don't worry about getting paid in test mode  */
			if @testmode = 0 begin 
				if @diff != 0 or @existingOrder = 0 begin
					if not exists(select 0 from paymentMethods where paymentMethodId = @paymentMethodId) begin
						print 'Error 8: there was no valid payment method on record.'
						set @errorOccured = 8
						set @errorDesc = 'There was no valid payment method on record.'
					end
				end 
			end
		/* when in test mode test -  We put this first so other errors show up before it */	
			if (@testmode = 1)
			begin
				print 'Error 5: test mode'
				set @errorOccured = 5
				set @errorDesc = 'This order was placed as a test order.  No errors occurred.'
			end
		/* 
		first update the column in serial_line to trigger the update trigger that updates the qty status of the orders
		if then the lastFlagStatus column is still null that means there was an error in inventory (the item is out of stock and does not allow preorders)
		Check if the kits in this order are allocated or if the order needs to be rolled back */
			update serial_line set lastFlagStatus = -1 where serialId in (select serialId from @lines where newItem = 1)
			/* now that the trigger has run check if the lastFlagStatus = @newFlagId ,
			 if it = @newFlagId there was a stock error caused during the tr_line_deplete_inventory_UPDATE trigger */
			if exists(select 0 from serial_line with (nolock)
				 inner join @lines l on l.serialid = serial_line.serialId
				 where lastFlagStatus = @newFlagId)
			begin
				print 'Error 4: out of stock'
				set @errorOccured = 4
				set @errorDesc = 'One or more items that do not allow preorders has run out of stock.  First example:'+
				(select top 1 itemNumber from serial_line with (nolock)
				inner join @lines l on l.serialid = serial_line.serialId
				where lastFlagStatus = @newFlagId)
			end

		/* Check if important variables have data */
			if((@subTotal is null) or (@grandtotal is null) or (@discounted is null) or (@taxTotal is null) or (@shiptotal is null))
			begin
				print 'Error 3: invalid total field'
				set @errorOccured = 3
				set @errorDesc = 'One of the following values was null. subtotal, grandtotal, discounted, taxtotal or shiptotal'
			end

		/* Check if addresses in the ship to list actualy exist now */
			set @addrCount = (select count(*) as c1 from addresses with (nolock) where addressid in (select addressid from @lines group by addressid))
			set @addrLineCount = (select count(c1) from (select count(*) as c1 from @lines group by addressid)f)
			if(not (@addrCount=@addrLineCount))
			begin
				/* Address is missing from addresses where addressId = @newBillToAddressId */
				print 'Error 2: missing ship to address'
				set @errorOccured = 2
				set @errorDesc = 'Ship to address is missing from list generated'
			end

		/* Check if bill to address actualy exist now */
			if (not exists(select 0 from addresses with (nolock) where addressId = @newBillToAddressId))
			begin
				/* Address is missing from addresses where addressId = @newBillToAddressId */
				print 'Error 1: missing bill to'
				set @errorOccured = 1
				set @errorDesc = 'Bill to address is missing from addresses'
			end
		/* check if this PO has already been placed in this account if the PO is not blank (if it is a new order)*/
			if exists (select 0 from orders with (nolock)
				where canceled = 0 and purchaseOrder = @purchaseOrderNumber and userId = @userid and len(RTRIM(@purchaseOrderNumber)) > 0)
				and @existingOrder = 0 begin
				print 'Error 6: purchase order already exists in this account.'
				set @errorOccured = 6
				set @errorDesc = 'Purchase order already exists in this account.  Duplicate purchase order numbers are not allowed.'
			end

		/* Check if there were errors  */
			if(@errorOccured > 0)
			begin
				/* There was some kind of error */
				insert into errors (script, description, number, source, sessionId, reference, logtime) values
				('dbo.placeOrder',@errorDesc,@errorOccured,'dbo.placeOrder',@sessionid,@errorDesc,GETDATE())
			end
			else
			begin
				print 'No handled errors, update the actual tables with the results'
				UPDATE CART
				set
				cart.itemnumber = l.itemnumber,
				cart.qty = l.qty,
				cart.price = l.price,
				cart.addressId = l.addressId,
				cart.orderid = l.orderid,
				cart.ordernumber = l.ordernumber,
				cart.shipmentid = l.shipmentid,
				cart.shipmentnumber = l.shipmentnumber,
				cart.serialid = l.serialid,
				cart.serialnumber = l.serialnumber,
				cart.linenumber = l.linenumber,
				cart.userId = l.userId,
				cart.sessionid = l.sessionid,
				cart.termId = l.termId,
				cart.epsmmcsoutput = l.epsmmcsoutput,
				cart.parentCartId = l.parentCartId,
				cart.epsmmcsAIFilename = l.epsmmcsAIFilename
				from @lines l
				where l.cartId = cart.cartId
				
				/* get the avg tax rate */
				print 'get avg tax rate'
				declare @avgTaxRate float
				set @avgTaxRate = (select AVG(taxRate) from addresses with (nolock) where orderId = @orderId and addressId in (select addressId from cart with (nolock) where orderId = @orderId))
				if @comment is null begin set @comment = '' end
				
				if @existingOrder = 0 begin
					print 'insert new order into orders table'
					/* insert the new order into the order table */
					insert into orders (orderId, orderDate, grandTotal, taxTotal, subTotal, shippingTotal, service1, service2, manifest, purchaseOrder, discount,
					comment, paid, billToAddressId, closed, canceled, termId, userId, orderNumber, creditMemo, sessionId, discountPct, discountCode,
					avgTaxRate, scanned_order_image, readyForExport, recalculatedOn, soldBy, approvedBy, requisitionedBy, deliverBy, vendor_accountNo,
					FOB,parentOrderId,unique_siteId,instantiationSession,exported,generalLedgerInsertId)
					values (@orderId, @orderDate, @grandtotal, @taxtotal, @subTotal, @shiptotal, 0, 0, '', '', @discounted, @comment, 0, @newBillToAddressId,
					0, 0, @termId, @userid, @orderNumber, 0, @newsessionId, @discountPct, @discountCode, @avgTaxRate, '', 0, @orderDate,-1,-1,-1,
					cast('1/1/1900 00:00:00.000' as datetime), '','',-1,@unique_site_id,@sessionid,0,@emptyGUID)
				end else begin
					print 'update existing order into orders table'
					update orders set
					grandTotal = @grandtotal,
					taxTotal = @taxtotal,
					subTotal = @subTotal,
					shippingTotal = @shiptotal,
					discount = @discounted,
					discountPct = @discountPct,
					discountCode = @discountCode,
					avgTaxRate = @avgTaxRate,
					sessionId = @newsessionId
					where orderId = @orderId
					print 'clean up contacts table by removing contacts created during update process'
					delete from contacts where sessionId = @cartSessionId
				end
				
			end
			
		end
		print 'begin output select'
		set NOCOUNT OFF
		select @newBillToAddressId as billToAddressId, 
		@paymentMethodId as paymentId, 
		@orderNumber as ordernumber,
		@subTotal as subtotal,
		@grandtotal as grandTotal,
		@taxtotal as taxtotal,
		@shiptotal as shiptotal,
		@discounted as discounted,
		@printstate as printstate,
		@concatSerialNumbers as serialNumbers,
		@concatShipmentNumbers as shipmentNumbers,
		@concatSerialIds as concatSerialIds,
		@concatShipmentIds as concatShipmentIds,
		@errorOccured as errorOccured,
		@errorDesc as errorDesc,
		@orderId as orderId,
		@discountPct as discountPct,
		@discountCode as discountCode,
		@termId as termId,
		@userid as userId,
		@newsessionId as sessionId,
		@previous_grandTotal as previous_grandTotal,
		@previous_subTotal as previous_subTotal,
		@previous_taxTotal as previous_taxTotal,
		@previous_shipTotal as previous_shipTotal,
		@previous_discountTotal as previous_discountTotal,
		@sessionId as previous_sessionId
		if @existingOrder = 1 begin
			select addressId,shipmentId from addresses with (nolock) where orderId = @orderId
		end
	end



GO
/****** Object:  Table [dbo].[serial_line]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[serial_line](
	[serialId] [int] IDENTITY(1,1) NOT NULL,
	[cartId] [uniqueidentifier] NOT NULL,
	[orderId] [int] NOT NULL,
	[shipmentId] [int] NOT NULL,
	[sessionId] [uniqueidentifier] NOT NULL,
	[lastFlagId] [uniqueidentifier] NOT NULL,
	[lastFlagStatus] [int] NOT NULL,
	[lastErrorId] [int] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_serial_line] PRIMARY KEY CLUSTERED 
(
	[serialId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  StoredProcedure [dbo].[backorderCancel]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[backorderCancel](
	@serialId int,
	@cancel bit,
	@backorder bit
)
as begin
		/*@lastFlagStatus = -11 (non existant flag) restocks for automated programs (eg backorder)*/
		/*@lastFlagStatus = -12 (non existant flag) cancel/restocks for automated programs (eg cancel)*/
		update serial_line
		set lastFlagStatus = case when @cancel = 1 then -12 when @backorder = 1 then -11 end
		where serialId = @serialId
end
GO
/****** Object:  Table [dbo].[zoneExclusions]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[zoneExclusions](
	[zoneExclusionId] [uniqueidentifier] NOT NULL,
	[rate] [int] NOT NULL,
	[shipZone] [int] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_zoneexclusions] PRIMARY KEY CLUSTERED 
(
	[zoneExclusionId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cover] ON [dbo].[zoneExclusions] 
(
	[rate] ASC,
	[shipZone] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[workRate]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[workRate](
	[rateID] [int] NOT NULL,
	[rate] [float] NOT NULL,
	[low] [int] NOT NULL,
	[high] [int] NOT NULL,
	[jobid] [int] NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_workRate] PRIMARY KEY CLUSTERED 
(
	[rateID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
INSERT [dbo].[workRate] ([rateID], [rate], [low], [high], [jobid]) VALUES (0, 0, -5000, 100, 0)
INSERT [dbo].[workRate] ([rateID], [rate], [low], [high], [jobid]) VALUES (1, 0.03, 101, 200, 0)
INSERT [dbo].[workRate] ([rateID], [rate], [low], [high], [jobid]) VALUES (2, 0.04, 201, 300, 0)
INSERT [dbo].[workRate] ([rateID], [rate], [low], [high], [jobid]) VALUES (3, 0.05, 301, 1000, 0)
/****** Object:  Table [dbo].[workLogMsgs]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[workLogMsgs](
	[workLogMsgID] [int] NOT NULL,
	[msgType] [int] NOT NULL,
	[addDate] [datetime] NOT NULL,
	[msg] [char](300) NULL,
	[userid] [int] NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_workLogMsgs] PRIMARY KEY CLUSTERED 
(
	[workLogMsgID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[workLog]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[workLog](
	[workLogID] [int] NOT NULL,
	[addedByUserID] [int] NOT NULL,
	[workerUserID] [int] NULL,
	[credit] [money] NOT NULL,
	[addDate] [datetime] NOT NULL,
	[makeupDate] [datetime] NULL,
	[qty] [int] NOT NULL,
	[workType] [int] NOT NULL,
	[serialid] [int] NULL,
	[orderid] [int] NULL,
	[shipmentid] [int] NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_workLog] PRIMARY KEY CLUSTERED 
(
	[workLogID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  StoredProcedure [dbo].[updateStatistics]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[updateStatistics] as
UPDATE STATISTICS [dbo].[accountTypes] 
WITH FULLSCAN
GO
/****** Object:  Table [dbo].[redirector]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[redirector](
	[redirectorId] [uniqueidentifier] NOT NULL,
	[urlMatchPattern] [varchar](1000) NOT NULL,
	[urlToRedirectToMatch] [varchar](1000) NOT NULL,
	[errorMatch] [varchar](1000) NOT NULL,
	[contentType] [varchar](50) NULL,
	[type] [varchar](50) NULL,
	[listOrder] [int] NULL,
	[enabled] [bit] NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_redirector] PRIMARY KEY CLUSTERED 
(
	[redirectorId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  StoredProcedure [dbo].[rebuildIndexes]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[rebuildIndexes] as
ALTER INDEX [PK_accountTypes] ON [dbo].[accountTypes] REBUILD PARTITION = ALL WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, ONLINE = OFF, SORT_IN_TEMPDB = OFF )
GO
/****** Object:  Table [dbo].[ui_columns]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ui_columns](
	[ui_columnId] [varchar](100) NOT NULL,
	[userId] [int] NOT NULL,
	[objectId] [int] NOT NULL,
	[colOrder] [int] NOT NULL,
	[size] [int] NOT NULL,
	[orderBy] [int] NULL,
	[direction] [char](5) NULL,
	[visibility] [bit] NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_ui_columns] PRIMARY KEY CLUSTERED 
(
	[ui_columnId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[sessionHash]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[sessionHash](
	[sessionHashId] [uniqueidentifier] NOT NULL,
	[userId] [int] NOT NULL,
	[sessionId] [uniqueidentifier] NOT NULL,
	[property] [varchar](50) NOT NULL,
	[value] [varchar](max) NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_sessionHash] PRIMARY KEY CLUSTERED 
(
	[sessionHashId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE NONCLUSTERED INDEX [idx_sessionHash] ON [dbo].[sessionHash] 
(
	[sessionId] ASC
)
INCLUDE ( [property],
[value]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[vtTransactions]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[vtTransactions](
	[vtTransactionID] [uniqueidentifier] NOT NULL,
	[transactionDate] [datetime] NULL,
	[amount] [money] NULL,
	[cardNumber] [varchar](25) NULL,
	[secNumber] [varchar](10) NULL,
	[authResponseCode] [varchar](255) NULL,
	[authResponse] [varchar](max) NULL,
	[addedby] [int] NULL,
	[provider] [varchar](50) NULL,
	[request] [varchar](max) NULL,
	[billToCompany] [varchar](100) NULL,
	[billToFirstName] [varchar](100) NULL,
	[billToLastName] [varchar](100) NULL,
	[billToAddress1] [varchar](100) NULL,
	[billToAddress2] [varchar](25) NULL,
	[billToCity] [varchar](50) NULL,
	[billToState] [varchar](25) NULL,
	[billToZIP] [varchar](20) NULL,
	[billToCountry] [varchar](50) NULL,
	[shipToCompany] [varchar](100) NULL,
	[shipToFirstName] [varchar](100) NULL,
	[shipToLastName] [varchar](100) NULL,
	[shipToAddress1] [varchar](100) NULL,
	[shipToAddress2] [varchar](25) NULL,
	[shipToCity] [varchar](50) NULL,
	[shipToState] [varchar](25) NULL,
	[shipToZIP] [varchar](20) NULL,
	[shipToCountry] [varchar](50) NULL,
	[expDate] [varchar](10) NULL,
	[sessionId] [uniqueidentifier] NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_vtTransactions] PRIMARY KEY CLUSTERED 
(
	[vtTransactionID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[visitorDetail]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[visitorDetail](
	[visitorDetailId] [uniqueidentifier] NOT NULL,
	[sessionId] [uniqueidentifier] NOT NULL,
	[URL] [varchar](255) NOT NULL,
	[time] [datetime] NOT NULL,
	[querystring] [nvarchar](max) NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_VisitorDetail] PRIMARY KEY CLUSTERED 
(
	[visitorDetailId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE NONCLUSTERED INDEX [idx_visitorDetail_querystring] ON [dbo].[visitorDetail] 
(
	[time] ASC
)
INCLUDE ( [querystring]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[version]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[version](
	[versionNumber] [decimal](18, 0) NULL
) ON [PRIMARY]
GO
INSERT [dbo].[version] ([versionNumber]) VALUES (CAST(6 AS Decimal(18, 0)))
/****** Object:  Table [dbo].[userLevels]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[userLevels](
	[userLevelID] [int] NOT NULL,
	[userLevelName] [char](50) NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_userLevels] PRIMARY KEY CLUSTERED 
(
	[userLevelID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
INSERT [dbo].[userLevels] ([userLevelID], [userLevelName]) VALUES (0, N'Anonymous Internet User                           ')
INSERT [dbo].[userLevels] ([userLevelID], [userLevelName]) VALUES (1, N'Internet User                                     ')
INSERT [dbo].[userLevels] ([userLevelID], [userLevelName]) VALUES (3, N'Internet Super User                               ')
INSERT [dbo].[userLevels] ([userLevelID], [userLevelName]) VALUES (4, N'Employee Level 1                                  ')
INSERT [dbo].[userLevels] ([userLevelID], [userLevelName]) VALUES (5, N'Employee Level 2                                  ')
INSERT [dbo].[userLevels] ([userLevelID], [userLevelName]) VALUES (6, N'Employee Level 3                                  ')
INSERT [dbo].[userLevels] ([userLevelID], [userLevelName]) VALUES (7, N'Employee Level 4                                  ')
INSERT [dbo].[userLevels] ([userLevelID], [userLevelName]) VALUES (8, N'Employee Level 5                                  ')
INSERT [dbo].[userLevels] ([userLevelID], [userLevelName]) VALUES (9, N'Administrator                                     ')
/****** Object:  UserDefinedFunction [dbo].[usDate]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[usDate](@inDate as datetime) returns char(8) as begin
return datepart(mm,@inDate)+'/'+datepart(dd,@inDate)+'/'+datepart(yyyy,@inDate)
end
GO
/****** Object:  UserDefinedFunction [dbo].[URLDecode]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[URLDecode](@str varchar(max))
RETURNS varchar(max)
AS
BEGIN

DECLARE
     @outstr varchar(max),
     @carint int
SET @outstr = ''

IF ISNULL(CHARINDEX('%', @str), 0) <> 0
     BEGIN
     WHILE CHARINDEX('%', @str) <> 0
          BEGIN
          IF CHARINDEX('%', @str) + 2 <= LEN(@str)
               BEGIN
               SET @carint =
                    (CASE SUBSTRING(@str, CHARINDEX('%', @str) + 1, 1)
                         WHEN 'a' then 10
                         WHEN 'A' THEN 10
                         WHEN 'b' then 11
                         WHEN 'B' THEN 11
                         WHEN 'c' then 12
                         WHEN 'C' THEN 12
                         WHEN 'd' then 13
                         WHEN 'D' THEN 13
                         WHEN 'e' then 14
                         WHEN 'E' THEN 14
                         WHEN 'f' then 15
                         WHEN 'F' THEN 15
                         ELSE CAST(SUBSTRING(@str, CHARINDEX('%', @str) + 1, 1) AS int)
                    END * 16) +
                    CASE SUBSTRING(@str, CHARINDEX('%', @str) + 2, 1)
                         WHEN 'a' then 10
                         WHEN 'A' THEN 10
                         WHEN 'b' then 11
                         WHEN 'B' THEN 11
                         WHEN 'c' then 12
                         WHEN 'C' THEN 12
                         WHEN 'd' then 13
                         WHEN 'D' THEN 13
                         WHEN 'e' then 14
                         WHEN 'E' THEN 14
                         WHEN 'f' then 15
                         WHEN 'F' THEN 15
                         ELSE CAST(SUBSTRING(@str, CHARINDEX('%', @str) + 2, 1) AS int)
                    END

               SET @outstr = @outstr + SUBSTRING(@str, 1, CHARINDEX('%', @str) - 1) + CHAR(@carint)
               SET @str = RIGHT(@str, LEN(@str)-CHARINDEX('%', @str)-2)
               END
          ELSE
               BEGIN
               SET @outstr = @outstr + @str
               SET @str = ''
               END
          END
     SET @outstr = @outstr + @str
     END
ELSE
     SET @outstr = @str

RETURN(replace(@outstr,'+',' '))

END
GO
/****** Object:  Table [dbo].[duplicateChecking]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[duplicateChecking](
	[duplicateCheckingId] [uniqueidentifier] NOT NULL,
	[refrenceId] [sql_variant] NOT NULL,
	[userId] [int] NOT NULL,
	[sessionId] [uniqueidentifier] NOT NULL,
	[addedOn] [datetime] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_duplicateChecking] PRIMARY KEY CLUSTERED 
(
	[duplicateCheckingId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[divisions]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[divisions](
	[divisionId] [uniqueidentifier] NOT NULL,
	[divisionName] [varchar](50) NOT NULL,
	[VerCol] [timestamp] NOT NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
INSERT [dbo].[divisions] ([divisionId], [divisionName]) VALUES (N'00000000-0000-0000-0000-000000000000', N'No Division')
/****** Object:  Table [dbo].[discount]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[discount](
	[discountCode] [char](50) NOT NULL,
	[discount] [real] NOT NULL,
	[comments] [varchar](max) NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK__Discount__164452B1] PRIMARY KEY CLUSTERED 
(
	[discountCode] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  StoredProcedure [dbo].[columnsInTable]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[columnsInTable](@tableName varchar(100)) as
select name from syscolumns
where id = OBJECT_ID(@tableName,'table')
order by name
GO
/****** Object:  StoredProcedure [dbo].[dataGridUpdate]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[dataGridUpdate](
	@objectName varchar(100),
	@primaryKeyName varchar(500),
	@primaryKeyValue varchar(max),
	@setStatement varchar(max),
	@timestamp int,
	@overwrite bit
) as
begin
	/* 
	updates a specific column in a specific record on a specific table
	compared to the @originalValue passed to the SP at runtime.
	returns status,description
	0 success
	-1 =! @timestamp
	-2 record deleted
	*/
	declare @statement nvarchar(max)
	set @statement = 'select 0 from ['+@objectName+']'+
	' where '+@primaryKeyName+' = '''+@primaryKeyValue+''' and cast(['+@objectName+'].[VerCol] as int) = '+cast(@timestamp as varchar(50));
	declare @tab table(val varchar(max))
	insert into @tab exec sp_executesql @statement
	if exists(select 1 from @tab) or @overwrite = 1 begin
		set @statement = 'update ['+@objectName+'] set '+@setStatement+
		' where '+@primaryKeyName+' = '''+@primaryKeyValue+'''';
		exec sp_executesql @statement;
		select 0 as status,'Record written successfully' as description;
	end else begin
		set @statement = 'select 0 from ['+@objectName+']'+
		' where '+@primaryKeyName+' = '''+@primaryKeyValue+'''';
		delete from @tab;
		insert into @tab exec sp_executesql @statement;
		if exists(select 0 from @tab) begin
			select -1 as status,'Record has changed since last refresh' as description;
		end else begin
			select -2 as status,'The record has been deleted' as description;
		end
	end
end
GO
/****** Object:  Table [dbo].[events]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[events](
	[eventId] [uniqueidentifier] NOT NULL,
	[eventName] [char](100) NULL,
	[eventBeginDate] [datetime] NULL,
	[eventDescriptionHTML] [varchar](max) NULL,
	[eventEndDate] [datetime] NULL,
	[userId] [char](100) NULL,
	[eventType] [char](100) NULL,
	[imageSrc] [char](100) NULL,
	[imageAlt] [char](100) NULL,
	[addDate] [datetime] NULL,
	[posted] [bit] NULL,
	[globalEvent] [bit] NULL,
	[emailEvent] [bit] NULL,
	[emailEveryone] [bit] NULL,
	[repeatsYearly] [bit] NULL,
	[eventUpdateLastSent] [datetime] NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_events] PRIMARY KEY CLUSTERED 
(
	[eventId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[eventHandlers]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[eventHandlers](
	[taskId] [uniqueidentifier] NOT NULL,
	[name] [varchar](50) NOT NULL,
	[description] [varchar](max) NOT NULL,
	[startTime] [datetime] NOT NULL,
	[lock] [bit] NOT NULL,
	[enabled] [bit] NOT NULL,
	[interval] [int] NOT NULL,
	[lastRun] [datetime] NOT NULL,
	[error] [varchar](20) NOT NULL,
	[errorDesc] [varchar](max) NOT NULL,
	[language] [varchar](50) NOT NULL,
	[sourceCode] [varchar](max) NOT NULL,
	[eventType] [varchar](50) NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_taskScheduler] PRIMARY KEY CLUSTERED 
(
	[taskId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO


/****** Object:  Table [dbo].[exportFiles]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[exportFiles](
	[exportFileId] [uniqueidentifier] NOT NULL,
	[exportName] [varchar](50) NULL,
	[exportFileName] [varchar](max) NOT NULL,
	[itemTranslationHeaderId] [int] NOT NULL,
	[URL] [varchar](max) NULL,
	[uploadMethod] [int] NULL,
	[uploadInterval] [int] NULL,
	[uploadUser] [varchar](50) NULL,
	[uploadPassword] [varchar](50) NULL,
	[logVerbosity] [int] NULL,
	[lastRun] [date] NULL,
	[processLock] [bit] NULL,
	[enabled] [bit] NULL,
	[exportTypeId] [int] NULL,
	[exportCode] [varchar](max) NULL,
	[occursAfterImportFileId] [int] NULL,
	[preventMultipleExports] [bit] NULL,
	[dateFrom] [date] NULL,
	[dateTo] [date] NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_exportFiles] PRIMARY KEY CLUSTERED 
(
	[exportFileId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[exportFileAudit]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[exportFileAudit](
	[exportFileAuditId] [uniqueidentifier] NOT NULL,
	[exportFileId] [uniqueidentifier] NULL,
	[exportFileName] [varchar](255) NULL,
	[controlId] [varchar](50) NULL,
	[exportDate] [datetime] NULL,
	[controlIdType] [varchar](50) NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_exportFileAudit] PRIMARY KEY CLUSTERED 
(
	[exportFileAuditId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  UserDefinedFunction [dbo].[f_convert_to_base10]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[f_convert_to_base10]
  (@string VARCHAR(255), @base TINYINT)
RETURNS INT AS 
BEGIN

  -- Declarations
  DECLARE @return INT
  DECLARE @len INT
  DECLARE @finished BIT
  DECLARE @pos INT
  DECLARE @thischar CHAR(1)
  DECLARE @thisasc INT
  DECLARE @val INT

  -- Initialise
  SELECT @base     = CASE WHEN @base < 2 OR @base IS NULL THEN 2 WHEN @base > 36 THEN 36 ELSE @base END
  SELECT @return   = 0
  SELECT @finished = 0
  SELECT @string   = UPPER(@string)
  SELECT @len      = DATALENGTH(@string)

  -- Failsafe
  IF @len = 0
     SELECT @finished = 1

  -- Loop over all characters: capitalise first character and those after spaces, replace underscores with spaces
  SELECT @pos = 0

  WHILE @finished = 0
  BEGIN

    SELECT @pos = @pos + 1

    IF @pos > @len

       -- If we've run out of characters, we're done
       SELECT @finished = 1

    ELSE
    BEGIN

       -- Get the character (from right to left)
       SELECT @thischar = SUBSTRING(@string, (@len - (@pos - 1)), 1)

       -- Get the character's ASCII value
       SELECT @thisasc  = ASCII(@thischar)

       -- Convert to a numerical value
       SELECT @val = CASE
                       WHEN @thisasc BETWEEN 48 AND 57 -- '0' AND '9'
                         THEN @thisasc - 48
                       WHEN @thisasc BETWEEN 65 AND 90 -- 'A' (= decimal 10) AND 'Z'
                         THEN @thisasc - 65 + 10
                       ELSE 0 END

       -- Add this portion on
       SELECT @return = @return + (POWER(@base, (@pos - 1)) * @val)

    END

  END

  -- Done
  RETURN @return

END
GO
/****** Object:  UserDefinedFunction [dbo].[extractSite]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [dbo].[extractSite](@url varchar(1000))
RETURNS varchar(1000)
AS
BEGIN
	return SUBSTRING(@URL,0,CHARINDEX('/',@url))

END
GO
/****** Object:  UserDefinedFunction [dbo].[extractPage]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [dbo].[extractPage](@url varchar(1000))
RETURNS varchar(1000)
AS
BEGIN
	return SUBSTRING(@url,charindex('/',@url)+1,charindex('?',@url)-charindex('/',@url)-1)

END
GO
/****** Object:  Table [dbo].[feedback]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[feedback](
	[feedbackId] [int] IDENTITY(1,1) NOT NULL,
	[firstName] [char](50) NULL,
	[lastName] [char](50) NULL,
	[phone] [char](50) NULL,
	[re] [char](100) NULL,
	[contactBy] [char](100) NULL,
	[email] [char](100) NULL,
	[check1] [char](3) NULL,
	[check2] [char](3) NULL,
	[check3] [char](3) NULL,
	[text1] [char](100) NULL,
	[text2] [char](100) NULL,
	[text3] [char](100) NULL,
	[comments] [char](2500) NULL,
	[pagename] [char](300) NULL,
	[IPAddress] [char](15) NULL,
	[submitTime] [datetime] NULL,
	[recieved] [bit] NULL,
	[followedUp] [bit] NULL,
	[address] [char](100) NULL,
	[city] [char](50) NULL,
	[state] [char](2) NULL,
	[zip] [char](10) NULL,
	[email_if_Logged_on] [char](100) NULL,
	[sessionId] [uniqueidentifier] NULL,
	[userId] [int] NULL,
	[browser] [char](200) NULL,
	[httpReferer] [char](200) NULL,
	[serverPort] [char](4) NULL,
	[userEmailAddress] [char](55) NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_feedback] PRIMARY KEY CLUSTERED 
(
	[feedbackId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  UserDefinedFunction [dbo].[f_nzero]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[f_nzero] (@val int)
returns int
as begin
	declare @returns int
	set @returns = @val
	if @returns is null
	begin
		set @returns = 0
	end
	return @returns
end
GO
/****** Object:  UserDefinedFunction [dbo].[f_jsonEncode]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--dbo.toJSON 'orders',1,0,1,100,''
CREATE function [dbo].[f_jsonEncode](@str varchar(max))
returns varchar(max)
begin
declare @rep varchar(max) = @str;
set @rep = replace(@rep,char(10),'\\n')
set @rep = replace(@rep,char(13),'\\l')
set @rep = replace(@rep,'"','\"')
return @rep
end
GO
/****** Object:  Table [dbo].[generalLedger]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[generalLedger](
	[generalLedgerId] [uniqueidentifier] NOT NULL,
	[refId] [varchar](255) NOT NULL,
	[refType] [int] NOT NULL,
	[creditRecord] [bit] NOT NULL,
	[debitRecord] [bit] NOT NULL,
	[amount] [money] NOT NULL,
	[userId] [int] NOT NULL,
	[addDate] [datetime] NOT NULL,
	[reference] [varchar](max) NOT NULL,
	[generalLedgerInsertId] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_payments] PRIMARY KEY CLUSTERED 
(
	[generalLedgerId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[importFiles]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[importFiles](
	[importfileId] [int] NOT NULL,
	[importFileName] [char](25) NULL,
	[autoGenerateHeaderID] [bit] NULL,
	[importFileType] [int] NULL,
	[itemTranslationAccount] [int] NULL,
	[reverseScan] [bit] NULL,
	[delimiter] [char](5) NULL,
	[URL] [char](500) NULL,
	[sampleFilePath] [char](100) NULL,
	[downloadMethod] [char](50) NULL,
	[downloadInterval] [int] NULL,
	[downloadCondition] [char](100) NULL,
	[downloadUser] [char](50) NULL,
	[downloadPassword] [char](50) NULL,
	[downloadDeleteCondition] [char](50) NULL,
	[logVerbosity] [int] NULL,
	[firstLetterCap] [bit] NULL,
	[downloadRemoteDirectory] [char](100) NULL,
	[sendNotificationEmail] [bit] NULL,
	[lastRun] [datetime] NULL,
	[processlock] [bit] NULL,
	[enabled] [bit] NULL,
	[importExportTypeID] [int] NULL,
	[importCode] [varchar](max) NULL,
	[occursAfter] [int] NULL,
	[occursAfterExportId] [uniqueidentifier] NULL,
	[userId] [int] NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_importFiles] PRIMARY KEY CLUSTERED 
(
	[importfileId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[importFileItemTranslation]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[importFileItemTranslation](
	[itemTranslationId] [int] IDENTITY(1,1) NOT NULL,
	[userId] [int] NULL,
	[convertType] [char](10) NULL,
	[localItemNumber] [char](50) NULL,
	[remoteItemNumber] [char](100) NULL,
	[dropShip] [bit] NULL,
	[additionalCost] [money] NULL,
	[remoteCustomField1] [char](100) NULL,
	[remoteCustomField2] [char](100) NULL,
	[remoteCustomField3] [char](100) NULL,
	[remoteCustomField4] [char](100) NULL,
	[remoteCustomField5] [char](100) NULL,
	[remoteCustomField6] [char](100) NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_importFileItemTranslation] PRIMARY KEY CLUSTERED 
(
	[itemTranslationId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[importFileAuditDetail]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[importFileAuditDetail](
	[importFileAuditDetailId] [uniqueidentifier] NOT NULL,
	[cartId] [uniqueidentifier] NOT NULL,
	[importSessionId] [uniqueidentifier] NOT NULL,
	[batchId] [uniqueidentifier] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_importFileAuditDetail] PRIMARY KEY CLUSTERED 
(
	[importFileAuditDetailId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[importFileAudit]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[importFileAudit](
	[importFileAuditId] [uniqueidentifier] NOT NULL,
	[importFileName] [varchar](255) NULL,
	[userId] [int] NULL,
	[importSessionID] [uniqueidentifier] NULL,
	[previewSession] [bit] NULL,
	[purchaseOrder] [varchar](255) NULL,
	[manifestNumber] [varchar](255) NULL,
	[processed] [bit] NULL,
	[ordernumber] [varchar](50) NULL,
	[batchId] [uniqueidentifier] NULL,
	[dateImported] [datetime] NULL,
	[importFileId] [int] NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_importFileAudit] PRIMARY KEY CLUSTERED 
(
	[importFileAuditId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[imagingTemplates]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[imagingTemplates](
	[imagingTemplateId] [uniqueidentifier] NOT NULL,
	[templateName] [varchar](255) NOT NULL,
	[comments] [varchar](max) NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_imagingTemplates] PRIMARY KEY CLUSTERED 
(
	[imagingTemplateId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[imagingTemplateDetail]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[imagingTemplateDetail](
	[imagingTemplateDetailId] [uniqueidentifier] NOT NULL,
	[imagingTemplateId] [uniqueidentifier] NOT NULL,
	[name] [varchar](50) NOT NULL,
	[description] [varchar](max) NOT NULL,
	[script] [varchar](max) NOT NULL,
	[language] [varchar](50) NOT NULL,
	[filterOrder] [int] NOT NULL,
	[enabled] [bit] NOT NULL,
	[template] [uniqueidentifier] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_imagingTemplatesDetail] PRIMARY KEY CLUSTERED 
(
	[imagingTemplateDetailId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO


INSERT [dbo].[imagingTemplates] ([imagingTemplateId], [templateName], [comments]) VALUES (N'865bb238-daaa-4436-a405-215edb9da797', N'165x165', N'<br>')
INSERT [dbo].[imagingTemplates] ([imagingTemplateId], [templateName], [comments]) VALUES (N'd5d0254d-fbbe-45d5-ae32-2920b16b186a', N'100x100', N'resize to 75x75 without regard to aspect ratio.')
INSERT [dbo].[imagingTemplates] ([imagingTemplateId], [templateName], [comments]) VALUES (N'af891e5a-29c5-40eb-9924-2fa90c062c38', N'Do nothing', N'This template just returns the image')
INSERT [dbo].[imagingTemplates] ([imagingTemplateId], [templateName], [comments]) VALUES (N'6024424c-141d-423d-8973-535248bfb968', N'375x375', N'Resize to 375x375 without regard to aspect ratio.')
INSERT [dbo].[imagingTemplates] ([imagingTemplateId], [templateName], [comments]) VALUES (N'cc9a830a-cb14-47e7-84de-59ec8f983ad6', N'600x600', N'<br>')
INSERT [dbo].[imagingTemplates] ([imagingTemplateId], [templateName], [comments]) VALUES (N'dd38d2b0-5e7f-4217-864e-b848e18ceac4', N'300x300', N'')
INSERT [dbo].[imagingTemplates] ([imagingTemplateId], [templateName], [comments]) VALUES (N'da8b80ab-fc27-43c3-83f6-c0f1d8fca626', N'800 width', N'Resize to 800px wide')
INSERT [dbo].[imagingTemplates] ([imagingTemplateId], [templateName], [comments]) VALUES (N'59ece4f8-0524-4496-a991-cacb6478fb1f', N'50x50', N'Resize 50x50 without regard to aspect ratio.')
INSERT [dbo].[imagingTemplateDetail] ([imagingTemplateDetailId], [imagingTemplateId], [name], [description], [script], [language], [filterOrder], [enabled], [template]) VALUES (N'955ae2b8-f4f6-4bdd-8af8-27f2f30a9459', N'cc9a830a-cb14-47e7-84de-59ec8f983ad6', N'Resize 600px width', N'', N'using System;
using System.Diagnostics;
using System.Drawing;
using Rendition;
public class script {
	public static Bitmap main(Bitmap image){
		Bitmap result = new Bitmap( 600, 600);
  		using( Graphics g = Graphics.FromImage( (Image) result ) ){
			g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
    			g.DrawImage( image, 0, 0, 600, 600);
		}
		return result;
	}
};', N'CSharp', 0, 1, N'00000000-0000-0000-0000-000000000000')
INSERT [dbo].[imagingTemplateDetail] ([imagingTemplateDetailId], [imagingTemplateId], [name], [description], [script], [language], [filterOrder], [enabled], [template]) VALUES (N'835e89e2-6c5b-449f-8e1f-442d6ef9bbdf', N'da8b80ab-fc27-43c3-83f6-c0f1d8fca626', N'800 width', N'', N'using System;
using System.Diagnostics;
using System.Drawing;
using Rendition;
public class script {
	public static Bitmap main(Bitmap image){
		return admin.resize(image,800,0);

	}
};', N'CSharp', 0, 1, N'00000000-0000-0000-0000-000000000000')
INSERT [dbo].[imagingTemplateDetail] ([imagingTemplateDetailId], [imagingTemplateId], [name], [description], [script], [language], [filterOrder], [enabled], [template]) VALUES (N'0a1fc074-3a7c-4b92-a7e1-48932c2a371d', N'865bb238-daaa-4436-a405-215edb9da797', N'Resize 165x165', N'Resize ignoring aspect ratio', N'using System;
using System.Diagnostics;
using System.Drawing;
using Rendition;
public class script {
	public static Bitmap main(Bitmap image){
		Bitmap result = new Bitmap( 165, 165);
  		using( Graphics g = Graphics.FromImage( (Image) result ) ){
			g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
    			g.DrawImage( image, 0, 0, 165, 165);
		}
		return result;
	}
};', N'CSharp', 0, 1, N'00000000-0000-0000-0000-000000000000')
INSERT [dbo].[imagingTemplateDetail] ([imagingTemplateDetailId], [imagingTemplateId], [name], [description], [script], [language], [filterOrder], [enabled], [template]) VALUES (N'31fe4064-6f23-42f7-81e2-602dd177fc14', N'af891e5a-29c5-40eb-9924-2fa90c062c38', N'Do nothing', N'This filter just returns the image', N'using System;
using System.Diagnostics;
using System.Drawing;
using Rendition;
public class script {
	public static Bitmap main(Bitmap image){
		
		/* Your code goes here */
		
		return image;
	}
};', N'CSharp', 0, 0, N'00000000-0000-0000-0000-000000000000')
INSERT [dbo].[imagingTemplateDetail] ([imagingTemplateDetailId], [imagingTemplateId], [name], [description], [script], [language], [filterOrder], [enabled], [template]) VALUES (N'1b93250d-6ab8-49bf-8cad-76e76e280a96', N'd5d0254d-fbbe-45d5-ae32-2920b16b186a', N'100x100', N'', N'using System;
using System.Diagnostics;
using System.Drawing;
using Rendition;
public class script {
	public static Bitmap main(Bitmap image){
		Bitmap result = new Bitmap( 100, 100);
  		using( Graphics g = Graphics.FromImage( (Image) result ) ){
			g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
    			g.DrawImage( image, 0, 0, 100, 100);
		}
		return result;
	}
};', N'CSharp', 0, 1, N'00000000-0000-0000-0000-000000000000')
INSERT [dbo].[imagingTemplateDetail] ([imagingTemplateDetailId], [imagingTemplateId], [name], [description], [script], [language], [filterOrder], [enabled], [template]) VALUES (N'f32bdb40-cadb-45bc-8f9f-7c369c53aa2a', N'6024424c-141d-423d-8973-535248bfb968', N'375x375', N'', N'using System;
using System.Diagnostics;
using System.Drawing;
using Rendition;
public class script {
	public static Bitmap main(Bitmap image){
		Bitmap result = new Bitmap( 375, 375);
  		using( Graphics g = Graphics.FromImage( (Image) result ) ){
			g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
    			g.DrawImage( image, 0, 0, 375, 375);
		}
		return result;
	}
};', N'CSharp', 0, 1, N'00000000-0000-0000-0000-000000000000')
INSERT [dbo].[imagingTemplateDetail] ([imagingTemplateDetailId], [imagingTemplateId], [name], [description], [script], [language], [filterOrder], [enabled], [template]) VALUES (N'04d69321-1530-49cc-9b61-899abaadbfdb', N'59ece4f8-0524-4496-a991-cacb6478fb1f', N'50x50', N'', N'using System;

using System.Diagnostics;
using System.Drawing;
using Rendition;
public class script {
	public static Bitmap main(Bitmap image){
    	Bitmap result = new Bitmap( 50, 50);
  		using( Graphics g = Graphics.FromImage( (Image) result ) ){
			g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
    			g.DrawImage( image, 0, 0, 50, 50);
		}
		return result;
	}
};', N'CSharp', 0, 1, N'00000000-0000-0000-0000-000000000000')
INSERT [dbo].[imagingTemplateDetail] ([imagingTemplateDetailId], [imagingTemplateId], [name], [description], [script], [language], [filterOrder], [enabled], [template]) VALUES (N'5a790aa5-b57a-4478-8d5e-e5e0f852b9f1', N'dd38d2b0-5e7f-4217-864e-b848e18ceac4', N'300x300', N'300x300', N'using System;
using System.Diagnostics;
using System.Drawing;
using Rendition;
public class script {
    public static Bitmap main(Bitmap image){
		Bitmap result = new Bitmap( 300, 300);
  		using( Graphics g = Graphics.FromImage( (Image) result ) ){
			g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
    			g.DrawImage( image, 0, 0, 300, 300);
		}
		return result;
	}
};', N'CSharp', 0, 1, N'00000000-0000-0000-0000-000000000000')




/****** Object:  Table [dbo].[imagingDetail]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[imagingDetail](
	[ImagingDetailId] [uniqueidentifier] NOT NULL,
	[ImagingId] [uniqueidentifier] NOT NULL,
	[unique_siteId] [uniqueidentifier] NOT NULL,
	[height] [int] NOT NULL,
	[width] [int] NOT NULL,
	[itemNumber] [varchar](50) NOT NULL,
	[fileName] [varchar](255) NOT NULL,
	[locationType] [char](1) NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_ImagingDetail] PRIMARY KEY CLUSTERED 
(
	[ImagingDetailId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[imaging]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[imaging](
	[imagingId] [uniqueidentifier] NOT NULL,
	[itemNumber] [char](50) NULL,
	[fileSize] [int] NULL,
	[fileName] [varchar](255) NULL,
	[thumbnail] [bit] NULL,
	[width] [int] NULL,
	[height] [int] NULL,
	[thumbOrder] [int] NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_Imaging] PRIMARY KEY CLUSTERED 
(
	[imagingId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[imageRotatorDetail]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[imageRotatorDetail](
	[imageRotatorDetailId] [uniqueidentifier] NOT NULL,
	[imageRotatorCategoryId] [uniqueidentifier] NOT NULL,
	[path] [varchar](max) NULL,
	[link] [varchar](255) NULL,
	[title] [varchar](255) NULL,
	[cropX] [int] NULL,
	[cropY] [int] NULL,
	[cropH] [int] NULL,
	[cropW] [int] NULL,
	[x] [int] NULL,
	[y] [int] NULL,
	[height] [int] NULL,
	[width] [int] NULL,
	[comments] [varchar](max) NULL,
	[description] [varchar](max) NULL,
	[enabled] [bit] NOT NULL,
	[rotator_order] [int] NULL,
	[thumb_order] [int] NULL,
	[rotatorHeight] [int] NULL,
	[rotatorWidth] [int] NULL,
	[thumbHeight] [int] NULL,
	[thumbWidth] [int] NULL,
	[userId] [int] NULL,
	[addDate] [datetime] NULL,
	[blogHeight] [int] NULL,
	[blogWidth] [int] NULL,
	[portfolioHeight] [int] NULL,
	[portfolioWidth] [int] NULL,
	[tags] [varchar](max) NULL,
	[tagsToSearchFor] [varchar](max) NULL,
	[exif] [varchar](max) NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_imageRotatorDetail] PRIMARY KEY CLUSTERED 
(
	[imageRotatorDetailId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[imageRotatorCategories]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[imageRotatorCategories](
	[imageRotatorCategoryId] [uniqueidentifier] NOT NULL,
	[categoryName] [varchar](75) NOT NULL,
	[height] [int] NOT NULL,
	[width] [int] NOT NULL,
	[resizeMethod] [int] NOT NULL,
	[rotatorTemplate] [uniqueidentifier] NOT NULL,
	[thumbTemplate] [uniqueidentifier] NOT NULL,
	[fullsizeTemplate] [uniqueidentifier] NOT NULL,
	[portfolioTemplate] [uniqueidentifier] NULL,
	[blogTemplate] [uniqueidentifier] NULL,
	[gallery] [bit] NULL,
	[gallery_description] [varchar](max) NULL,
	[gallery_order] [int] NULL,
	[tags] [varchar](max) NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_imageRotatorCategories] PRIMARY KEY CLUSTERED 
(
	[imageRotatorCategoryId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  UserDefinedTableType [dbo].[hashTable]    Script Date: 05/30/2011 18:09:40 ******/
CREATE TYPE [dbo].[hashTable] AS TABLE(
	[keyName] [varchar](100) NULL,
	[keyValue] [sql_variant] NULL,
	[primary_key] [bit] NULL,
	[dataType] [varchar](50) NULL,
	[dataLength] [int] NULL,
	[varCharMaxValue] [varchar](max)
)
GO
/****** Object:  UserDefinedFunction [dbo].[hashColToUpdateString]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[hashColToUpdateString](
	@value sql_variant,
	@dataType varchar(50),
	@dataLength int,
	@varCharMaxValue varchar(max)
) returns varchar(max)
as 
begin
	declare @return varchar(max);
	if @dataType in ('int','money','float','real','bigint','datetime','bit','uniqueidentifier','timestamp') begin
		set @return = 'convert('+@dataType+','''+convert(varchar(max),@value)+'''),';
	end else if @dataType in ('varchar') begin
		set @return = 'convert('+@dataType+case when @dataLength > 0 then '(' + cast(@dataLength as varchar(50)) + ')' else '(max)' end + ','''+replace(convert(varchar(max),@varCharMaxValue),'''','''''')+'''),';
	end else if @dataType in ('nvarchar','ntext','char','nchar') begin
		set @return = 'convert('+@dataType+'(' + cast(@dataLength as varchar(50)) + ')'+ ','''+replace(convert(varchar(max),@varCharMaxValue),'''','''''')+'''),';
	end;
	return(@return);
end
GO
/****** Object:  UserDefinedFunction [dbo].[Guid_Empty]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Guid_Empty]()
RETURNS UniqueIdentifier
AS
BEGIN
RETURN cast(cast(0 as binary) as uniqueidentifier)
END
GO
/****** Object:  Table [dbo].[countries]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[countries](
	[countryId] [uniqueidentifier] NOT NULL,
	[country] [char](50) NOT NULL,
	[carrierId] [int] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_Countries] PRIMARY KEY CLUSTERED 
(
	[countryId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'd8878ffc-c199-4b47-ba86-01c9a1300a85', N'Swaziland                                         ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'77005dd0-3a93-4874-8eac-03e5ef5f912c', N'Barbuda                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'd2d599e5-a216-4c95-9227-03ff08db9d18', N'Central African Republic                          ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'146d7c58-519b-4f31-9dd4-05ec500a1251', N'Peru                                              ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'0a250e75-dd86-4fcf-b1ae-05eda8d5941c', N'Suriname                                          ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'ae417bff-1c9b-44ed-9fc1-0691221e6fa3', N'Malaysia
                                        ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'632e2f37-7dd4-4d7d-9f0b-06a69ceaa2c5', N'Morocco                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'31230ebf-9044-4720-9e20-07dd51123901', N'Colombia                                          ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'337f9db6-57de-478e-b271-094f73cb3f16', N'Yugoslavia                                        ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'c933941c-364a-4d5d-ba62-096a592af911', N'Saudi Arabia                                      ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'1818019c-c616-4863-809e-09c177ab4686', N'Macau                                             ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'115eb016-4645-497c-bf23-0b1ea7f5380a', N'Romania                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'b3187d8d-af30-4de3-8388-0bc9539b6141', N'Marshall Islands                                  ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'4d896e6f-6658-44c3-9357-0bc9e4bf8c80', N'Brazil                                            ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'b1b2f82e-9ee2-496e-90cf-0c0f09cd8de8', N'St. Croix                                         ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'6d60efc2-3766-4de7-8a6a-0e0ebbdfd5c1', N'Somalia                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'e5cc472a-cd85-4886-a3da-10eb11f3c9c3', N'Vanuatu                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'e8f9cfef-7c76-46f0-b648-13049d62b4fd', N'Luxembourg                                        ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'028a9025-17d9-4aaa-a6ab-141369d159bb', N'MyanmarBurma                                      ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'c87c7f8f-6aab-4945-bc8c-1424a40a502a', N'Ivory Coast                                       ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'f10d35a3-0fbd-4101-bdd1-144bc42e88b9', N'Saipan
                                          ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'c9c0ce44-ec90-468f-a8ea-1564dc72fb3e', N'South Africa                                      ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'974ef6e2-81b9-4423-9c0c-188abd31ffa9', N'Namibia                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'e63cd491-8fef-4b30-a048-1938cb03d109', N'Singapore                                         ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'21b4b560-37f6-49d6-8677-197d9278d1d4', N'Grenada
                                         ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'3b55c09a-9d35-4e91-8d45-19e0e0d96a8f', N'Maldives                                          ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'8ca39002-db13-4bc0-9bf9-1a3bbdb1d028', N'Mongolia                                          ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'6d13c6b1-3143-4b2d-8535-1c3669a9e60d', N'Macedonia                                         ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'3f3b7ec0-5d1e-48b5-b9b4-1dc532afd7d7', N'Bolivia                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'7e90d43f-9b90-4564-b752-1fc82bd044ca', N'Uganda                                            ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'8620a5be-446c-44ee-9054-21ec3f46fa35', N'Anguilla                                          ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'e7a2cfe0-2c4e-4ad9-aa70-22cd2a52f318', N'St. Lucia                                         ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'26d6fade-385a-4341-aedb-22eaaa485732', N'Lebanon                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'dd86c5ee-030f-4ea5-bf81-2557ec888db2', N'Turks and Caicos Islands                          ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'3eaf0a84-bbb2-4139-b85c-2857dc00fb74', N'Madagascar                                        ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'b724bf63-cf5a-4f7c-a427-285f798dcdc6', N'Latvia                                            ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'1948e160-a53d-4280-aa2c-2ce21159d671', N'Haiti                                             ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'073d671e-759b-496b-a3a2-2d893fdf2734', N'Oman                                              ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'6f2a58a6-c142-4f2f-93f9-2dc4c2275c00', N'Curacao                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'81a98d07-a29b-4cbb-a258-2e3fc9a6e4df', N'Chad                                              ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'701b86f2-428f-48bf-b295-2fdb97138e78', N'Burundi                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'ba73f351-e2a2-4ca4-a505-320334d292ff', N'Israel                                            ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'4b0c847c-e5d5-43da-ad7c-3349525b3e11', N'Pakistan                                          ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'2f1ef517-1404-422c-86d2-379b3f954519', N'Gibraltar                                         ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'6c5d1518-4f32-47e8-b0d2-38461d480ad5', N'Kyrgyzstan                                        ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'2a8dcccc-0249-4225-8bde-388ff8fd0fb8', N'Malta                                             ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'b6d30ff9-36f2-411f-aeae-3b0199ba6155', N'Ghana                                             ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'b1bbb620-3699-42c8-ac59-3bd937bd75f0', N'Zimbabwe                                          ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'65523b1f-2043-446c-90ce-3d21573797cb', N'Austria                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'2280445a-5a73-4408-9e37-3e4a1db0b82f', N'Brunei                                            ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'2df8de57-ec96-4592-b161-3e50a502a360', N'Sierra Leone                                      ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'e6e43685-69ab-431b-933e-3eee7094c626', N'Dominica                                          ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'8c13d347-0b09-4763-aaf0-3f420061cf44', N'Senegal                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'06820179-fbd7-4bd3-8719-3ffb595916ee', N'Iran                                              ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'59004f92-6200-4e98-bb1a-417904fe45d8', N'Palau                                             ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'05a91b03-3ba4-430c-a7a5-42a0e2379084', N'Turkey                                            ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'9c0552b1-41df-49ab-b8ff-436b7ef6757d', N'Bahamas                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'f5dbc3da-ac6f-43f6-8c02-43a4130f76fb', N'Cook Islands                                      ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'f844fd8d-010c-4ccd-8b4e-43dfc9c8423d', N'Italy                                             ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'31d7c22b-d5de-41aa-97d1-441be309ede3', N'Zambiac                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'942f6cd4-d004-47b9-8033-441d98beb01f', N'Fiji                                              ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'536156f9-4a4c-428d-8b00-47814fb64ba0', N'Egypt                                             ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'a790948e-88e1-4a39-9695-48e8e4efff0c', N'Denmark                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'78591e5d-04af-47f3-8fc4-495d4f1eb682', N'Belgium                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'f1d0ec03-6d14-4d6c-98d0-49a4c423a422', N'Iraq                                              ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'e4280ef7-d73a-40b3-ba00-4c2210facd51', N'French Polynesia                                  ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'035e2950-e5c0-49f2-94cd-4fa540b71337', N'Barbados                                          ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'a122a900-78ca-40db-a289-5138d27342e2', N'Portugal                                          ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'19247b27-9c4f-49a3-8a51-527596f03442', N'St. Kitts and Nevis                               ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'6ecfa9e3-d03d-43b9-bdbc-53957eed7e1b', N'Greece                                            ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'e787b210-a462-4134-8f9c-5559863e41e0', N'Panama                                            ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'f6c23209-421b-4b7c-b1c6-5592f90c6368', N'Chile                                             ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'b37a9ef9-d57e-4ab2-aa1b-5847af0daf62', N'St. Maarten/St. Martin                            ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'baabdf3e-55dd-4d5a-8e5d-5a025ee14f84', N'Thailand                                          ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'75bfb278-5d33-4925-ac1a-5a479e622286', N'Wallis Futuna                                     ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'ea6674f9-3703-40a6-8529-5a7d7e30c844', N'Rwanda                                            ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'0332744e-f576-4bef-be1b-5ad31602af3a', N'Martinique                                        ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'2d2ab0b3-ff9b-449a-8df4-5be636144179', N'Nicaragua                                         ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'c0e4b155-b338-437e-a654-5c3075597e54', N'Norway                                            ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'8aa3688d-44e1-4e80-8872-5cd5ea3b6ee1', N'Indonesia                                         ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'ee13ef50-462a-44f4-9a1d-5d0e43cbf360', N'Bahrain                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'62cb4003-61d5-4a93-84cc-609255a21e26', N'Jamaica                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'7921a67a-ffc5-42d7-80ea-60d94bb1a40f', N'Ukraine                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'71bdb5ea-5722-4372-93ba-6171968b222e', N'Afghanistan                                       ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'e81521c7-e713-49db-9c73-627235178c2b', N'Azerbaijan                                        ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'49b2bb10-e0e4-46dd-9c05-6536802266bf', N'Netherlands Antilles                              ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'dd2047f2-651d-4cb8-a28c-653f20ea8bc5', N'Liberia                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'e9f0a8d0-d413-46e2-948f-658bbecceab3', N'Burkina Faso                                      ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'e8217476-3dcb-4369-ba4b-681f7ed27023', N'Cayman Islands                                    ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'17a6132f-3a7b-4ca2-9029-689e70e8f4ee', N'Seychelles                                        ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'81d98bdf-7b4d-496e-94b6-6b4e4a030114', N'Uruguay                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'f50e7222-0d19-4286-8f4a-6b8f0fa1f36b', N'Switzerland                                       ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'ff026295-aaad-449f-a0f9-6c51ea802212', N'Papua New Guinea                                  ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'e2a0ff7b-68f7-4899-b13e-6c61e0e21da8', N'Tunisia                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'31117bff-a432-4366-a703-6d3c48e20224', N'Belize                                            ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'fe88e845-7073-4e8d-ae7e-6dac2e45f47f', N'Laos                                              ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'770a1dd9-82ea-4cdb-90e8-6f4eac01882d', N'Finland                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'03753400-32c7-4ba3-8f9b-718225695b65', N'Monaco                                            ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'e091dc71-839f-4dd6-9417-72abf1e88ab2', N'Ecuador                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'8d124d7a-78d8-4d60-97cc-74a4a5963d7c', N'Mauritius                                         ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'b51e3e37-53f0-437e-b762-752660148c3c', N'Slovak Republic                                   ', 0)
GO
print 'Processed 100 total records'
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'1cebaa89-2845-44c7-ab2d-760bae9c5a6f', N'Slovenia                                          ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'02007e75-2924-44ee-bdbf-78972a3d97d0', N'Nepal                                             ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'4f725172-1473-4fef-b78c-7b84fec0748f', N'Armenia                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'9416fbee-de08-4353-b53a-7c06b44dd3f4', N'Kuwait                                            ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'3ac2f82a-3dd5-4819-9eee-7cc4187b5071', N'Kazakhstan                                        ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'938685c9-bacb-4479-84c8-7d10b33b0a84', N'Ireland                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'eefbea40-c191-4c72-a871-7eba00539197', N'Netherlands                                       ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'446e59fa-8882-4ae1-aec3-7ff1a03e48dd', N'San Marino                                        ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'e3a33981-3754-400d-9b44-7ffc2db3d695', N'Dominican Republic                                ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'd7202e9a-d653-439a-8957-80258944ea13', N'Lithuania                                         ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'23393ba9-5dcc-486c-9504-8082f9d9cfbb', N'St. Vincent                                       ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'7cd069bb-f7e1-4aed-a2e3-83998f4f6c69', N'Togo                                              ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'c4d679c0-646f-4587-a952-8454c959090b', N'Moldova                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'39865db4-cd7e-4afb-82ed-87c2a75f3faa', N'Estonia                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'74ff0ae8-5676-42ab-a571-8dfeffc3873c', N'Czech Republic
                                  ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'40ad6728-da98-4c8a-b7be-8e5b23654bfc', N'Mexico                                            ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'22bf965c-4da3-4c46-82a8-8ee47892b25a', N'Honduras                                          ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'eb85e54b-481b-4e5b-be05-90075d87cdbd', N'Canada - English                                  ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'648a3551-e109-41e6-8dcb-90234326fd08', N'Cyprus                                            ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'90028b8d-0072-4e27-bd92-907d8a3d8b18', N'Eritrea                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'66f46460-f900-4a3a-8ba5-90d27523667d', N'Benin                                             ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'76d0cf6d-1bc1-4eb7-80f1-9127f9eb6c00', N'Hungary                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'e8efae12-2674-43c8-b1bd-921fcdc33bfd', N'Congo, The Republic of                            ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'91f88a5f-b5ee-44f5-858b-9230c531cc15', N'Botswana                                          ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'a3130abd-1382-4aa8-826a-93c56a7dc20f', N'China                                             ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'be81ef64-b28d-4607-ad77-9767d537dc70', N'Bangladesh                                        ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'65efb6bd-59df-4f9d-ba80-983206844695', N'Faroe Islands                                     ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'02ae0040-bd30-4132-a192-997927e33554', N'Venezuela                                         ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'7af82073-6a76-4b0a-bba5-9a051e8904f3', N'United Kingdom                                    ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'2b0f669a-78b2-4fc2-b7a7-9c506b4cde0c', N'India                                             ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'df906fa6-4b4e-45a2-a178-9c7bff15342c', N'Congo - Brazzaville                               ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'8a576d51-bf6f-401d-845b-9d3f18675257', N'Sri Lanka                                         ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'aac81ac1-8a01-4a53-801e-a0f4961f62af', N'Vatican City                                      ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'545afe80-bcbd-40a8-8fa4-a0f9fd98d0a7', N'Hong Kong                                         ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'0289e99b-7776-4daf-a027-a1b0f126ae3b', N'Cameroon                                          ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'456ce817-5953-4e63-8111-a1cea5d58d25', N'Bermuda                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'03b2915e-b930-4c0d-b6c0-a2b118f7df06', N'Lesotho                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'ce3108bd-6b90-453a-8154-a2cfa38f023c', N'El Salvador                                       ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'83b2af60-7039-4d64-be25-a304c730cd8a', N'French Guiana                                     ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'2d90619e-e153-4603-836a-a38da8d1d0cf', N'Guinea Bissau                                     ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'10c2da02-3b8d-4770-a39c-a46503c615a6', N'Algeria                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'e15de282-e041-4846-8507-a4d69fc20a07', N'France                                            ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'61a4a06c-7a77-41ba-afd1-a4e6de139013', N'Niger                                             ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'4dc4ed2b-4f7f-45a9-b0ac-a5326c1a9672', N'Tanzania                                          ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'72d4152d-091e-4bd7-b399-a5f27af2a20b', N'Turkmenistan                                      ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'8e5ace5d-82a9-4016-948f-a70daf94db53', N'Micronesia                                        ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'7cc17329-daab-4add-b9a3-a98222172ab5', N'Australia                                         ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'3fd870a7-d840-4344-8efd-aa11d85ce307', N'U.S. Virgin Islands                               ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'87ca16c1-45f8-42dc-a9e4-aa47cbfbe024', N'Bulgaria                                          ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'ebd6f40e-3345-4cc2-903a-ab501d3b47bc', N'Guadeloupe                                        ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'46e9d015-5f12-4b13-ba14-ad4c582409fd', N'Uzbekistan                                        ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'eb8b9154-dd50-4858-8c84-ad7be70bba0a', N'Aruba
                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'24da4dbb-06b2-48d5-ad3a-afd28ccb6e75', N'Guam                                              ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'ae69980d-56df-4128-9852-b017fe156b1c', N'British Virgin Islands                            ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'3c8ebfda-9633-4c77-87a5-b05b46911739', N'Japan
                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'7b870b1a-3d9a-4546-bdb9-b1b052d7d7b0', N'U.S.A.                                            ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'd5f11bfe-c2bb-4808-8b1d-b26daaf02792', N'Nigeria                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'a116cfda-7238-43d0-8425-b27b87e52424', N'Gabon                                             ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'156aaba7-5199-4e16-a328-b2a6a2d08c4c', N'Guatemala                                         ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'c644062c-45d0-484c-b1e8-b3294767c4cb', N'Angola                                            ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'b2112b91-1c13-4d64-8eb6-b3ac42ebe63a', N'Yemen                                             ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'5725a965-1c2b-418f-b4c6-b41149feefbd', N'Gambia                                            ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'43d7b0d2-d530-48fd-acb9-b486d2d27ba5', N'Taiwan                                            ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'e8cfe9c0-1399-4558-a35e-b55a709483a5', N'Germany                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'33cc7f6a-23cd-445c-abfd-b5d636668ff9', N'Andorra                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'99922181-ba60-4b95-91f9-b83c50d33937', N'Montserrat                                        ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'd6bdecdc-7577-4880-abe3-b8677bdfc93c', N'Reunion                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'fbf2ff3e-b087-40c4-8703-b9d9c28bad9c', N'Antigua                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'76839092-1839-4304-871a-bd1196942114', N'Tortola                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'92fcb973-1765-4863-8b2a-bdf0b00bb8e9', N'Mali                                              ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'1d0109ca-6f9d-4be0-8615-be9e1b661ee8', N'American Samoa                                    ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'166ce0f2-ffc8-4e1a-a28b-c095cbe343c3', N'Ethiopia                                          ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'867bad33-e548-4164-928b-c0f365b1761c', N'Qatar                                             ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'1f4c33e9-6f03-4e36-b514-c224d6f6e962', N'St. Thomas                                        ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'03571869-861d-4dd8-8f24-c393b578d469', N'New Caledonia                                     ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'cdbab019-ec56-4426-905a-c51b85ee7ac1', N'St. Barthelemy                                    ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'1a14d05d-5479-4953-8484-c673a1e135df', N'Cambodia                                          ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'cc50ac02-c446-47ea-a956-c6ba4dfa2ca7', N'Iceland                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'e68524b3-4ec5-4501-86dc-c6e3e5f4832e', N'Bonaire                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'43d43f4e-8493-4c33-b5df-c70de7f9d208', N'Sudan                                             ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'737effdb-eaf2-4a8b-ba98-c7a0053e6a5c', N'Costa Rica                                        ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'8a94ed6b-8829-495a-94be-c7f2397caf23', N'Philippines                                       ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'c00f9d0b-fea3-46cd-81a4-ca10a3110843', N'Croatia                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'4cbeb1c5-9661-4e4a-98d7-caab63452087', N'Greenland                                         ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'bc1962cf-ed4d-4737-8c19-cb7a53f7a250', N'Trinidad and Tobago                               ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'6afc0835-766a-4c0b-9075-cc05a7bf862e', N'Russia                                            ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'2791282e-2918-48a7-80f4-d038c8d3af9e', N'Spain                                             ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'a47e3a3e-66d9-420c-a239-d10d3734ce52', N'Saba                                              ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'eea562c1-a3ed-44d3-923a-d398d8ae80f8', N'United Arab Emirates                              ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'76ee1df5-7850-4588-bed1-d455724382c9', N'Canada - Francais                                 ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'5496394d-959a-4ec9-a05d-d5c4680b7e6f', N'Kenya                                             ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'815961ef-54ef-4654-b73a-d61b5fe2c254', N'St. Eustatius                                     ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'02e19a94-d03a-4392-bf95-d6cf65662c54', N'Guinea                                            ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'ef4226cf-8a33-4af7-a6ab-d76c38aadc8b', N'Channel Islands                                   ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'272240b3-bc4e-4493-b624-d79e797c2a13', N'Mauritania                                        ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'd983e690-292b-41aa-8ac5-dec2a16d1f44', N'Sweden                                            ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'81d0acac-8d8b-4c09-8728-dfddea6d20d7', N'Liechtenstein                                     ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'8fc1fdb5-c26a-4b6b-8027-e0f9d4fa9b89', N'Mozambique                                        ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'db855d2e-d316-4091-b572-e20148e460dd', N'Vietnam                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'f8a53f55-c621-4b6e-9619-e47db76ac5f5', N'Puerto Rico                                       ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'6c8bb7e6-caf1-4052-b41d-e67c1ae00ebe', N'Poland                                            ', 0)
GO
print 'Processed 200 total records'
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'99aa4f9e-51a6-427b-bb16-e8351ea6cc90', N'Libya                                             ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'd3cd015d-4c8f-42b5-ac62-e862f54eca73', N'Argentina                                         ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'5ab2bf28-01d7-4d8e-9975-e8af73c103cc', N'Guyana                                            ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'1d1919f6-0185-4c75-8257-e9153a6764f0', N'Cape Verde                                        ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'f622f04f-5a66-49d7-a5a1-eb38af6aa7c4', N'Syria                                             ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'15e0e21e-5443-406f-a32b-ed1abebea3ac', N'Belarus                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'61e2a6ec-2140-44f5-8ff4-ed83e703abbd', N'Djibouti                                          ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'3d89df72-0e3a-474b-ab04-eee0534c59bf', N'Paraguay                                          ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'effdc53a-19de-40c9-b358-efc53c88bf47', N'Equatorial Guinea                                 ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'f5f72e41-bfba-475a-9066-efda7e06cffa', N'Georgia                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'933d4ce7-4ad1-4030-900c-f34a1b79f89b', N'Bhutan                                            ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'638da0ed-c044-44d5-9515-f55793f6811f', N'New Zealand                                       ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'b3598047-d56e-456d-8f64-f6cb27b933c7', N'Albania                                           ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'9a701e7d-f593-4213-baf3-fa5fdd7e2bac', N'Bosnia-Herzegovina                                ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'7dd4512b-883f-4916-977c-faf21943a7f9', N'Jordan                                            ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'aecbc072-b19c-4f3b-99f0-fb3e2dabd6a4', N'South Korea                                       ', 0)
INSERT [dbo].[countries] ([countryId], [country], [carrierId]) VALUES (N'af8c62e4-dca0-476f-96d2-fdaff2562a39', N'Malawi                                            ', 0)
/****** Object:  StoredProcedure [dbo].[contactForm]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE    PROCEDURE [dbo].[contactForm](
@contactID as uniqueidentifier
)
AS
begin
	set nocount on
	declare @defaultContact bit
	declare @FirstName varchar(50)
	declare @LastName varchar(50)
	declare @Address1 varchar(25)
	declare @Address2 varchar(25)
	declare @City varchar(25)
	declare @State varchar(3)
	declare @ZIP varchar(10)
	declare @Country varchar(50)
	declare @HomePhone varchar(25)
	declare @WorkPhone varchar(25)
	declare @Email varchar(50)
	declare @SpecialInstructions varchar(max)
	declare @Comments varchar(max)
	declare @sendshipmentupdates bit
	declare @emailads bit

	select @defaultContact = defaultContact, @FirstName = firstname, @LastName = LastName, @Address1 = Address1, @Address2 = Address2,
	@City = City, @State = State, @ZIP = ZIP, @Country = Country, @HomePhone = HomePhone, @WorkPhone = WorkPhone, @Email = Email,
	@SpecialInstructions = SpecialInstructions, @Comments = Comments, @sendshipmentupdates = sendshipmentupdates, @emailads = emailads
	from contactview where contactID = @contactID


	select 'contactid', rtrim(cast(@contactID as varchar(36))) union all
	select 'defaultcontact', rtrim(cast(@defaultContact as varchar)) union all
	select 'firstname', rtrim(cast(@FirstName as varchar(50))) union all
	select 'lastname', rtrim(cast(@LastName as varchar(50))) union all
	select 'address1', rtrim(cast(@Address1 as varchar(25))) union all
	select 'address2', rtrim(cast(@Address2 as varchar(25))) union all
	select 'city', rtrim(cast(@City as varchar(25))) union all
	select 'state', rtrim(cast(@State as varchar(3))) union all
	select 'zip', rtrim(cast(@ZIP as varchar(10))) union all
	select 'country', rtrim(cast(@Country as varchar(25))) union all
	select 'homephone', rtrim(cast(@HomePhone as varchar(10))) union all
	select 'workphone', rtrim(cast(@WorkPhone as varchar(10))) union all
	select 'email', rtrim(cast(@Email as varchar(50))) union all
	select 'specialinstructions', rtrim(cast(@SpecialInstructions as varchar(max))) union all
	select 'comments', rtrim(cast(@Comments as varchar(max))) union all
	select 'sendshipmentupdates', rtrim(cast(@sendshipmentupdates as varchar(5))) union all
	select 'emailads', rtrim(cast(@emailads as varchar(5)))

	set nocount off
end
GO
/****** Object:  Table [dbo].[blogCategories]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[blogCategories](
	[blogCategoryId] [uniqueidentifier] NOT NULL,
	[categoryName] [varchar](50) NOT NULL,
	[publicCategory] [bit] NOT NULL,
	[author] [int] NOT NULL,
	[showInTicker] [bit] NULL,
	[blogPage] [varchar](50) NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_blogCategories] PRIMARY KEY CLUSTERED 
(
	[blogCategoryId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  UserDefinedFunction [dbo].[bfdate]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[bfdate] (@date datetime)
RETURNS varchar(11)
as
begin

return rtrim(convert(char(2),datepart(mm,@date))) + '/' + rtrim(convert(char(2),datepart(dd,@date))) + '/' + convert(char(4),datepart(yyyy,@date))

end
GO
/****** Object:  UserDefinedFunction [dbo].[contInvoiceIDs]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[contInvoiceIDs](
@orderID int
)
returns varchar(1000)
as
begin
	Declare @String varchar(1000)
	Set @String = ''
	Select @String = @String + cast(b.invoiceID as char(100)) + char(13) +  char(10)
	from batchInvoiceDetail d
	inner join batchInvoices b on b.batchInvoiceID = d.batchInvoiceID
	where orderID = @orderID
	Return case when len(@String)>0 then substring(@String,0,len(@String)-1) else '' end
	return @string
end
GO
/****** Object:  UserDefinedFunction [dbo].[BankersRound]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[BankersRound](@Val DECIMAL(32,16), @Digits INT)
RETURNS DECIMAL(32,16)
AS
BEGIN
    RETURN CASE WHEN ABS(@Val - ROUND(@Val, @Digits, 1)) * POWER(10, @Digits+1) = 5 
                THEN ROUND(@Val, @Digits, CASE WHEN CONVERT(INT, ROUND(ABS(@Val) * POWER(10,@Digits), 0, 1)) % 2 = 1 THEN 0 ELSE 1 END)
                ELSE ROUND(@Val, @Digits)
                END
END
GO
/****** Object:  Table [dbo].[blogs]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[blogs](
	[blogId] [uniqueidentifier] NOT NULL,
	[subject] [varchar](max) NULL,
	[message] [varchar](max) NULL,
	[comments] [varchar](max) NULL,
	[tags] [varchar](max) NULL,
	[editor] [int] NULL,
	[author] [int] NULL,
	[addDate] [datetime] NULL,
	[dateChanged] [datetime] NULL,
	[lastEditor] [int] NULL,
	[annotations] [varchar](max) NULL,
	[enabled] [bit] NULL,
	[auditComments] [bit] NULL,
	[allowComments] [bit] NULL,
	[emailUpdates] [bit] NULL,
	[blogImage] [varchar](255) NULL,
	[blogCategoryId] [uniqueidentifier] NULL,
	[publicBlog] [bit] NULL,
	[listOrder] [int] NULL,
	[archive] [bit] NULL,
	[galleryId] [uniqueidentifier] NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_blogs] PRIMARY KEY CLUSTERED 
(
	[blogId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[chartOfAccounts]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[chartOfAccounts](
	[chartOfAccountsId] [uniqueidentifier] NOT NULL,
	[description] [varchar](255) NOT NULL,
	[low] [int] NOT NULL,
	[high] [int] NOT NULL,
	[listOrder] [int] NOT NULL,
 CONSTRAINT [PK_chartOfAccounts] PRIMARY KEY CLUSTERED 
(
	[chartOfAccountsId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  UserDefinedFunction [dbo].[cbit]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[cbit](
@strIn varchar
)
returns bit
begin
	declare @returnbit bit
	if(@strIn is null)
	begin
		set @returnbit = 0
	end
	else
	begin
		if(lower(rtrim(@strIn))='on')
		begin
			set @returnbit = 1
		end
		else
		begin
			set @returnbit = 0
		end
	end
	return @returnbit
end
GO
/****** Object:  Table [dbo].[categoryTemp]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[categoryTemp](
	[tempCatId] [uniqueidentifier] NOT NULL,
	[categoryId] [uniqueidentifier] NOT NULL,
	[selectId] [uniqueidentifier] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_categoryTemp] PRIMARY KEY CLUSTERED 
(
	[tempCatId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[categoryDetail]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[categoryDetail](
	[categoryDetailId] [uniqueidentifier] NOT NULL,
	[categoryId] [uniqueidentifier] NOT NULL,
	[itemNumber] [varchar](50) NULL,
	[listOrder] [int] NULL,
	[childCategoryId] [uniqueidentifier] NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_CategoryDetail] PRIMARY KEY CLUSTERED 
(
	[categoryDetailId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[categories]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[categories](
	[categoryId] [uniqueidentifier] NOT NULL,
	[category] [char](50) NOT NULL,
	[enabled] [bit] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_Categories] PRIMARY KEY CLUSTERED 
(
	[categoryId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
INSERT [dbo].[categories] ([categoryId], [category], [enabled]) VALUES (N'00000000-0000-0000-0000-000000000000', N'No Suggestion Category                            ',0)
/****** Object:  Table [dbo].[carriers]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[carriers](
	[carrierId] [int] NOT NULL,
	[carrierName] [varchar](50) NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_carriers] PRIMARY KEY CLUSTERED 
(
	[carrierId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[captcha]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[captcha](
	[captchaId] [uniqueidentifier] NOT NULL,
	[captchaText] [char](10) NOT NULL,
	[addDate] [datetime] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_captcha] PRIMARY KEY CLUSTERED 
(
	[captchaId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[adCategoryDetail]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[adCategoryDetail](
	[adCategoryDetailId] [uniqueidentifier] NOT NULL,
	[adCategoryId] [uniqueidentifier] NOT NULL,
	[adId] [uniqueidentifier] NOT NULL,
	[adOrder] [int] NOT NULL,
	[impressions] [int] NOT NULL,
	[clicks] [int] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_adCategoryDetail] PRIMARY KEY CLUSTERED 
(
	[adCategoryDetailId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[adCategory]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[adCategory](
	[adCategoryId] [uniqueidentifier] NOT NULL,
	[adCategory] [char](50) NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_adCategory] PRIMARY KEY CLUSTERED 
(
	[adCategoryId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[accountTypes]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[accountTypes](
	[accountTypeId] [int] NOT NULL,
	[accountType] [varchar](50) NOT NULL,
	[rangeLow] [int] NULL,
	[rangeHigh] [int] NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_accountTypes] PRIMARY KEY CLUSTERED 
(
	[accountTypeId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
INSERT [dbo].[accountTypes] ([accountTypeId], [accountType], [rangeLow], [rangeHigh]) VALUES (0, N'Customer - Receivable Series 10,000,000', 10000000, 19999999)
INSERT [dbo].[accountTypes] ([accountTypeId], [accountType], [rangeLow], [rangeHigh]) VALUES (1, N'Vendor - Payable Series 2,000,000', 2000000, 2999999)
INSERT [dbo].[accountTypes] ([accountTypeId], [accountType], [rangeLow], [rangeHigh]) VALUES (2, N'Employee/Operator Series 20,000,000', 20000000, 29999999)
INSERT [dbo].[accountTypes] ([accountTypeId], [accountType], [rangeLow], [rangeHigh]) VALUES (3, N'Asset accounts Series 1,000,000', 1000000, 1999999)
INSERT [dbo].[accountTypes] ([accountTypeId], [accountType], [rangeLow], [rangeHigh]) VALUES (4, N'Liability accounts Series 2,000,000', 2000000, 2999999)
INSERT [dbo].[accountTypes] ([accountTypeId], [accountType], [rangeLow], [rangeHigh]) VALUES (5, N'Equity accounts Series 3,000,000', 3000000, 3999999)
INSERT [dbo].[accountTypes] ([accountTypeId], [accountType], [rangeLow], [rangeHigh]) VALUES (6, N'Revenue accounts Series 4,000,000', 4000000, 4999999)
INSERT [dbo].[accountTypes] ([accountTypeId], [accountType], [rangeLow], [rangeHigh]) VALUES (7, N'Cost of goods sold Series 5,000,000', 5000000, 5999999)
INSERT [dbo].[accountTypes] ([accountTypeId], [accountType], [rangeLow], [rangeHigh]) VALUES (8, N'Expense accounts Series 6,000,000', 6000000, 6999999)
INSERT [dbo].[accountTypes] ([accountTypeId], [accountType], [rangeLow], [rangeHigh]) VALUES (9, N'Other revenue Series 7,000,000', 7000000, 7999999)
INSERT [dbo].[accountTypes] ([accountTypeId], [accountType], [rangeLow], [rangeHigh]) VALUES (10, N'Other expense Series 8,000,000', 8000000, 8999999)
INSERT [dbo].[accountTypes] ([accountTypeId], [accountType], [rangeLow], [rangeHigh]) VALUES (11, N'Gain/loss on sale of assets 9,000,000', 9000000, 9999999)
/****** Object:  Table [dbo].[addressUpdate]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[addressUpdate](
	[addressUpdateId] [uniqueidentifier] NOT NULL,
	[shipmentNumber] [char](20) NULL,
	[tracking] [char](50) NULL,
	[dateShipped] [char](25) NULL,
	[actualWeight] [char](25) NULL,
	[actualService] [char](25) NULL,
	[actualCost] [char](20) NULL,
	[actualBilledWeight] [char](10) NULL,
	[packageLength] [char](25) NULL,
	[packageWidth] [char](25) NULL,
	[packageHeight] [char](25) NULL,
	[thirdPartyAccount] [char](30) NULL,
	[voidStatus] [char](10) NULL,
	[emailSent] [datetime] NULL,
	[addDate] [datetime] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_AddressUpdate] PRIMARY KEY CLUSTERED 
(
	[addressUpdateId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[adTrack]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[adTrack](
	[adtrackId] [int] NOT NULL,
	[adCategoryDetailID] [int] NOT NULL,
	[logTime] [datetime] NOT NULL,
	[sessionId] [uniqueidentifier] NULL,
	[http_referer] [char](200) NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_adtrack] PRIMARY KEY CLUSTERED 
(
	[adtrackId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ads]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ads](
	[adId] [uniqueidentifier] NOT NULL,
	[adDescription] [char](50) NULL,
	[adHTML] [char](300) NULL,
	[impressions] [int] NULL,
	[clicks] [int] NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_ads] PRIMARY KEY CLUSTERED 
(
	[adId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[attachments]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[attachments](
	[attachmentId] [uniqueidentifier] NOT NULL,
	[referenceId] [varchar](50) NOT NULL,
	[path] [varchar](255) NOT NULL,
	[referenceType] [varchar](50) NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_attachments] PRIMARY KEY CLUSTERED 
(
	[attachmentId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  StoredProcedure [dbo].[numericList]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[numericList] @max int as
begin
	declare @list table(row int);
	declare @x int = 0;
	while(@x<@max) begin
		insert into @list (row) values (@x);
		set @x=@x+1;
	end
	select row as row1,row as row2,row as row3,row as row4,row as row5,row as row6,row as row7,
	row as row8,row as row9,row as row10,row as row11,row as row12 from @list;
end
GO
/****** Object:  Table [dbo].[menus]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[menus](
	[menuId] [uniqueidentifier] NOT NULL,
	[menuName] [varchar](255) NOT NULL,
	[spacer] [bit] NOT NULL,
	[menuDescription] [varchar](max) NOT NULL,
	[menuOnClick] [varchar](max) NOT NULL,
	[listOrder] [int] NOT NULL,
	[menutype] [int] NOT NULL,
	[parentId] [uniqueidentifier] NOT NULL,
	[href] [varchar](max) NOT NULL,
	[enabled] [bit] NOT NULL,
	[onmouseover] [varchar](max) NOT NULL,
	[onmouseout] [varchar](max) NOT NULL,
	[addDate] [datetime] NOT NULL,
	[userId] [int] NOT NULL,
	[childType] [int] NOT NULL,
	[childFilter] [varchar](100) NOT NULL,
	[maxChildren] [int] NOT NULL,
	[usePager] [bit] NOT NULL,
	[childOrder] [int] NOT NULL,
	[script] [varchar](50) NOT NULL,
	[unique_siteId] [uniqueidentifier] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_menus] PRIMARY KEY CLUSTERED 
(
	[menuId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[picklist]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[picklist](
	[itemnumber] [char](50) NULL,
	[lvl] [int] NULL,
	[qty] [int] NULL,
	[addID] [int] IDENTITY(1,1) NOT NULL,
	[serialID] [int] NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_picklist] PRIMARY KEY CLUSTERED 
(
	[addID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[pdfForms]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[pdfForms](
	[pdfFormID] [uniqueidentifier] NOT NULL,
	[pdfFormName] [char](50) NULL,
	[addDate] [datetime] NULL,
	[workingCopy] [uniqueidentifier] NULL,
	[pdfEncryption] [bit] NULL,
	[userPassword] [varchar](50) NULL,
	[ownerPassword] [varchar](50) NULL,
	[antiAliasScene] [bit] NULL,
	[antiAliasText] [bit] NULL,
	[overPrint] [bit] NULL,
	[antiAliasPolygons] [bit] NULL,
	[antiAliasImages] [bit] NULL,
	[autoPrint] [bit] NULL,
	[queryType] [varchar](50) NULL,
	[recordsPerPage] [int] NULL,
	[colorModel] [varchar](5) NULL,
	[allowEmbeddedFonts] [bit] NULL,
	[enabled] [bit] NULL,
	[checkoutDate] [datetime] NULL,
	[original] [bit] NULL,
	[currentState] [bit] NULL,
	[masterID] [uniqueidentifier] NULL,
	[pageOffsetx] [int] NULL,
	[pageOffsety] [int] NULL,
	[firstPageRecordsPerPage] [int] NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_pdfForms] PRIMARY KEY CLUSTERED 
(
	[pdfFormID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[pdfFormDetail]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[pdfFormDetail](
	[pdfFormDetailID] [uniqueidentifier] NOT NULL,
	[pdfFormID] [uniqueidentifier] NULL,
	[name] [varchar](50) NULL,
	[Type] [int] NULL,
	[colorSpace] [varchar](5) NULL,
	[Height] [float] NULL,
	[Width] [float] NULL,
	[X1] [float] NULL,
	[Y1] [float] NULL,
	[X2] [float] NULL,
	[Y2] [float] NULL,
	[content] [varchar](max) NULL,
	[polyString] [varchar](max) NULL,
	[firstPage] [bit] NULL,
	[lastPage] [bit] NULL,
	[middlePage] [bit] NULL,
	[color] [varchar](50) NULL,
	[backgroundColor] [varchar](50) NULL,
	[font] [varchar](50) NULL,
	[pieAngleStart] [float] NULL,
	[pieAngleEnd] [float] NULL,
	[fillRect] [bit] NULL,
	[radiusX] [float] NULL,
	[radiusY] [float] NULL,
	[fontSize] [float] NULL,
	[bold] [bit] NULL,
	[charSpacing] [float] NULL,
	[indent] [float] NULL,
	[italic] [bit] NULL,
	[justification] [float] NULL,
	[leftMargin] [float] NULL,
	[lineSpacing] [float] NULL,
	[outline] [float] NULL,
	[paraSpacing] [float] NULL,
	[strike] [bit] NULL,
	[strike2] [bit] NULL,
	[underline] [bit] NULL,
	[wordSpacing] [float] NULL,
	[renderOrder] [int] NULL,
	[firstRecordOnly] [bit] NULL,
	[queryLineItemSpacing] [float] NULL,
	[queryLineItemRange] [varchar](50) NULL,
	[queryOrdinal] [varchar](50) NULL,
	[queryOutputString] [varchar](max) NULL,
	[imagePath] [varchar](255) NULL,
	[hpos] [float] NULL,
	[transparency] [float] NULL,
	[vpos] [float] NULL,
	[objectRepeats] [bit] NULL,
	[pageoffsetx] [float] NULL,
	[pageoffsety] [float] NULL,
	[conditionScript] [varchar](255) NULL,
	[strokeWidth] [float] NULL,
	[locked] [bit] NULL,
	[groupId] [uniqueidentifier] NULL,
	[deleted] [bit] NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_pdfFormDetail] PRIMARY KEY CLUSTERED 
(
	[pdfFormDetailID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[pageTitles]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[pageTitles](
	[pageTitleId] [uniqueidentifier] NOT NULL,
	[page] [int] NULL,
	[category] [char](50) NULL,
	[title] [char](59) NULL,
	[metaDescription] [char](100) NULL,
	[metaKeywords] [char](300) NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_pageTitles] PRIMARY KEY CLUSTERED 
(
	[pageTitleId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[rights]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[rights](
	[rightsID] [int] NOT NULL,
	[rightsDescription] [varchar](50) NOT NULL,
	[VerCol] [timestamp] NOT NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
INSERT [dbo].[rights] ([rightsID], [rightsDescription]) VALUES (-1, N'Denied')
INSERT [dbo].[rights] ([rightsID], [rightsDescription]) VALUES (0, N'Read Only')
INSERT [dbo].[rights] ([rightsID], [rightsDescription]) VALUES (1, N'Read/Write')
INSERT [dbo].[rights] ([rightsID], [rightsDescription]) VALUES (2, N'Read/Write/Delete/Add')
/****** Object:  Table [dbo].[reviews]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[reviews](
	[reviewId] [uniqueidentifier] NOT NULL,
	[userId] [int] NULL,
	[rating] [float] NULL,
	[message] [varchar](max) NULL,
	[refId] [varchar](50) NULL,
	[archive] [bit] NULL,
	[addDate] [datetime] NULL,
	[refType] [varchar](50) NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_reviews] PRIMARY KEY CLUSTERED 
(
	[reviewId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[researchDetail]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[researchDetail](
	[researchDetailID] [uniqueidentifier] NOT NULL,
	[researchPageID] [uniqueidentifier] NOT NULL,
	[widigitType] [int] NOT NULL,
	[prams] [varchar](max) NULL,
	[style] [varchar](max) NULL,
	[listOrder] [int] NOT NULL,
	[condition] [varchar](max) NULL,
	[widigitTitle] [varchar](50) NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_researchDetail] PRIMARY KEY CLUSTERED 
(
	[researchDetailID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[research]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[research](
	[researchPageID] [uniqueidentifier] NOT NULL,
	[userID] [int] NOT NULL,
	[addedOn] [datetime] NULL,
	[title] [varchar](50) NULL,
	[page_group] [varchar](50) NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_research] PRIMARY KEY CLUSTERED 
(
	[researchPageID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[replies]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[replies](
	[replyId] [uniqueidentifier] NOT NULL,
	[email] [varchar](50) NOT NULL,
	[subject] [varchar](50) NOT NULL,
	[rating] [int] NOT NULL,
	[userId] [int] NOT NULL,
	[comment] [varchar](max) NOT NULL,
	[addedOn] [datetime] NOT NULL,
	[parentId] [uniqueidentifier] NOT NULL,
	[reference] [varchar](50) NOT NULL,
	[disabled] [bit] NOT NULL,
	[approves] [int] NOT NULL,
	[disapproves] [int] NOT NULL,
	[flaggedInappropriate] [int] NOT NULL,
	[flaggedOk] [bit] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_replys] PRIMARY KEY CLUSTERED 
(
	[replyId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  StoredProcedure [dbo].[reorganizeIndex]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[reorganizeIndex] as 
ALTER INDEX [PK_accountTypes] ON [dbo].[accountTypes] REORGANIZE WITH ( LOB_COMPACTION = ON )
GO
/****** Object:  Table [dbo].[security_items]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[security_items](
	[security_itemsId] [uniqueidentifier] NOT NULL,
	[userId] [int] NOT NULL,
	[categoryId] [uniqueidentifier] NOT NULL,
	[rightsId] [int] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_security_items] PRIMARY KEY CLUSTERED 
(
	[security_itemsId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
INSERT [dbo].[security_items] ([security_itemsId], [userId], [categoryId], [rightsId]) VALUES (N'7333575c-3a27-4369-bd4f-5eb7b7c8017f', 153, N'8a4c7400-0864-41de-a6bd-dbed1a70500b', 2)
/****** Object:  Table [dbo].[printForms]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[printForms](
	[printFormID] [uniqueidentifier] NOT NULL,
	[pdfFormID] [uniqueidentifier] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_printForms] PRIMARY KEY CLUSTERED 
(
	[printFormID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[order_line_forms]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[order_line_forms](
	[cartId] [uniqueidentifier] NOT NULL,
	[sourceCode] [varchar](max) NULL,
	[formName] [varchar](50) NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_order_line_forms] PRIMARY KEY CLUSTERED 
(
	[cartId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[timer]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[timer](
	[timerId] [uniqueidentifier] NOT NULL,
	[currentItemName] [varchar](255) NOT NULL,
	[totalItemCount] [bigint] NOT NULL,
	[currentItemCount] [bigint] NOT NULL,
	[totalItemSize] [bigint] NOT NULL,
	[currentItemSize] [bigint] NOT NULL,
	[currentSizeComplete] [bigint] NOT NULL,
	[complete] [bit] NOT NULL,
	[started] [datetime] NOT NULL,
	[updated] [datetime] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_timer] PRIMARY KEY CLUSTERED 
(
	[timerId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[timeCard]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[timeCard](
	[userId] [int] NULL,
	[timeIn] [datetime] NULL,
	[timeOut] [datetime] NULL,
	[comments] [varchar](255) NULL,
	[VerCol] [timestamp] NOT NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ticketDetail]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ticketDetail](
	[ticketDetailId] [uniqueidentifier] NOT NULL,
	[ticketId] [uniqueidentifier] NOT NULL,
	[message] [varchar](max) NOT NULL,
	[addDate] [datetime] NOT NULL,
	[addedBy] [int] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_ticketDetail] PRIMARY KEY CLUSTERED 
(
	[ticketDetailId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ticket]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ticket](
	[ticketId] [uniqueidentifier] NOT NULL,
	[subject] [varchar](max) NOT NULL,
	[createdBy] [int] NOT NULL,
	[createdFor] [int] NOT NULL,
	[addDate] [datetime] NOT NULL,
	[importance] [int] NOT NULL,
	[state] [int] NOT NULL,
	[unique_siteId] [uniqueidentifier] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_ticket] PRIMARY KEY CLUSTERED 
(
	[ticketId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[thirdPartyShipping]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[thirdPartyShipping](
	[thirdPartyShippingID] [uniqueidentifier] NOT NULL,
	[userId] [int] NOT NULL,
	[rateId] [int] NOT NULL,
	[thirdPartyAccountNumber] [varchar](50) NOT NULL,
	[thirdPartyAccountName] [varchar](50) NULL,
	[thirdPartyAccountState] [varchar](50) NULL,
	[thirdPartyAccountcountry] [varchar](50) NULL,
	[thirdPartyAccountZip] [varchar](50) NULL,
	[thirdPartyAccountStreet] [varchar](50) NULL,
	[thirdPartyAccountCity] [varchar](50) NULL,
	[UsethirdPartyAccount] [bit] NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_thirdPartyShipping] PRIMARY KEY CLUSTERED 
(
	[thirdPartyShippingID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[terms]    Script Date: 03/11/2011 19:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[terms](
	[termId] [int] NOT NULL,
	[termName] [char](50) NULL,
	[termDays] [int] NULL,
	[accrued] [bit] NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_Terms] PRIMARY KEY CLUSTERED 
(
	[termId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
INSERT [dbo].[terms] ([termId], [termName], [termDays], [accrued]) VALUES (0, N'Credit Card                                       ', 0, 0)
INSERT [dbo].[terms] ([termId], [termName], [termDays], [accrued]) VALUES (1, N'Net 10                                            ', 10, 1)
INSERT [dbo].[terms] ([termId], [termName], [termDays], [accrued]) VALUES (2, N'Net 15                                            ', 15, 1)
INSERT [dbo].[terms] ([termId], [termName], [termDays], [accrued]) VALUES (3, N'Net 30                                            ', 30, 1)
INSERT [dbo].[terms] ([termId], [termName], [termDays], [accrued]) VALUES (4, N'Net 45                                            ', 45, 1)
INSERT [dbo].[terms] ([termId], [termName], [termDays], [accrued]) VALUES (5, N'Net 60                                            ', 60, 1)
INSERT [dbo].[terms] ([termId], [termName], [termDays], [accrued]) VALUES (6, N'Net 90                                            ', 90, 1)
INSERT [dbo].[terms] ([termId], [termName], [termDays], [accrued]) VALUES (9, N'COD Check                                         ', 5, 1)
INSERT [dbo].[terms] ([termId], [termName], [termDays], [accrued]) VALUES (10, N'COD Cash only                                     ', 5, 1)
INSERT [dbo].[terms] ([termId], [termName], [termDays], [accrued]) VALUES (11, N'Net Due On Receipt                                ', 10, 1)
INSERT [dbo].[terms] ([termId], [termName], [termDays], [accrued]) VALUES (12, N'Credit Memo                                       ', 0, 1)
INSERT [dbo].[terms] ([termId], [termName], [termDays], [accrued]) VALUES (13, N'Cash                                              ', 0, 0)
INSERT [dbo].[terms] ([termId], [termName], [termDays], [accrued]) VALUES (14, N'Memo Billing                                      ', 0, 1)
INSERT [dbo].[terms] ([termId], [termName], [termDays], [accrued]) VALUES (15, N'Proforma                                          ', 0, 1)
INSERT [dbo].[terms] ([termId], [termName], [termDays], [accrued]) VALUES (16, N'Deposit Required                                  ', 21, 1)
INSERT [dbo].[terms] ([termId], [termName], [termDays], [accrued]) VALUES (19, N'Letter Of Credit                                  ', 10, 1)
INSERT [dbo].[terms] ([termId], [termName], [termDays], [accrued]) VALUES (20, N'Wire Transfer                                     ', 0, 0)
INSERT [dbo].[terms] ([termId], [termName], [termDays], [accrued]) VALUES (21, N'No Charge                                         ', 0, 0)
/****** Object:  Table [dbo].[tblnumericList]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblnumericList](
	[row1] [int] NOT NULL,
	[row2] [int] NOT NULL,
	[row3] [int] NOT NULL,
	[row4] [int] NOT NULL,
	[row5] [int] NOT NULL,
	[row6] [int] NOT NULL,
	[row7] [int] NOT NULL,
	[row8] [int] NOT NULL,
	[row9] [int] NOT NULL,
	[row10] [int] NOT NULL,
	[row11] [int] NOT NULL,
	[row12] [int] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_tblnumericList] PRIMARY KEY CLUSTERED 
(
	[row1] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tableMonitor]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tableMonitor](
	[tableMonitorID] [int] NOT NULL,
	[tableName] [char](25) NOT NULL,
	[tableDescription] [char](60) NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_tableMonitor] PRIMARY KEY CLUSTERED 
(
	[tableMonitorID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (1, N'addresses                ', N'Confirmed Order Addresses                                   ')
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (2, N'adtrack                  ', N'Ad Tracker                                                  ')
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (3, N'cart                     ', N'Orders and line items                                       ')
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (4, N'cartdetail               ', N'Orders''s Form Values                                        ')
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (5, N'contacts                 ', N'User Address Book                                           ')
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (6, N'creditcards              ', N'User Credit Cards                                           ')
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (8, N'errors                   ', N'Error Logging Utility                                       ')
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (9, N'feedback                 ', N'Submitted Feedback Form                                     ')
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (11, N'imaging                  ', N'Image Masters                                               ')
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (12, N'imagingDetail            ', N'Style Switcher Images                                       ')
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (13, N'importFileAudit          ', N'Import File Auditor                                         ')
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (14, N'itemdetail               ', N'Item Kits                                                   ')
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (15, N'itemProperties           ', N'Item Filters                                                ')
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (16, N'items                    ', N'Items                                                       ')
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (17, N'news                     ', N'Blog Entries                                                ')
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (18, N'objectFlags              ', N'Production Flags                                            ')
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (19, N'sessionItemHistory       ', N'Items viewed history                                        ')
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (20, N'userlog                  ', N'User audit log                                              ')
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (21, N'userPriceList            ', N'User price list                                             ')
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (22, N'users                    ', N'User accounts                                               ')
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (23, N'validation               ', N'Stored Form Validation Values                               ')
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (24, N'validationStrings        ', N'Stored Form Validation Pass Strings                         ')
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (25, N'Visitors                 ', N'Session Tracking                                            ')
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (26, N'VisitorDetail            ', N'Hit Tracking                                                ')
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (27, N'ImportFileAudit          ', N'Import Tracking Table                                       ')
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (28, N'ImportFileAuditDetail    ', N'Import Tracking Table (line items)                          ')
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (29, N'AddressUpdate            ', N'Shipping address update                                     ')
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (30, N'redirector               ', N'Error Redirector Tracker                                    ')
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (31, N'vtTransactions           ', N'Merchant account transactions                               ')
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (32, N'workLog                  ', N'Work tracking log                                           ')
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (33, N'workLogMsgs              ', N'Messages for the work log                                   ')
INSERT [dbo].[tableMonitor] ([tableMonitorID], [tableName], [tableDescription]) VALUES (34, N'shipZone                 ', N'Zone lookup table for shipping                              ')
/****** Object:  Table [dbo].[systemColors]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[systemColors](
	[color] [varchar](50) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[color] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
INSERT [dbo].[systemColors] ([color]) VALUES (N'AliceBlue')
INSERT [dbo].[systemColors] ([color]) VALUES (N'AntiqueWhite')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Aqua')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Aquamarine')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Azure')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Beige')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Bisque')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Black')
INSERT [dbo].[systemColors] ([color]) VALUES (N'BlanchedAlmond')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Blue')
INSERT [dbo].[systemColors] ([color]) VALUES (N'BlueViolet')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Brown')
INSERT [dbo].[systemColors] ([color]) VALUES (N'BurlyWood')
INSERT [dbo].[systemColors] ([color]) VALUES (N'CadetBlue')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Chartreuse')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Chocolate')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Coral')
INSERT [dbo].[systemColors] ([color]) VALUES (N'CornflowerBlue')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Cornsilk')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Crimson')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Cyan')
INSERT [dbo].[systemColors] ([color]) VALUES (N'DarkBlue')
INSERT [dbo].[systemColors] ([color]) VALUES (N'DarkCyan')
INSERT [dbo].[systemColors] ([color]) VALUES (N'DarkGoldenrod')
INSERT [dbo].[systemColors] ([color]) VALUES (N'DarkGray')
INSERT [dbo].[systemColors] ([color]) VALUES (N'DarkGreen')
INSERT [dbo].[systemColors] ([color]) VALUES (N'DarkKhaki')
INSERT [dbo].[systemColors] ([color]) VALUES (N'DarkMagena')
INSERT [dbo].[systemColors] ([color]) VALUES (N'DarkOliveGreen')
INSERT [dbo].[systemColors] ([color]) VALUES (N'DarkOrange')
INSERT [dbo].[systemColors] ([color]) VALUES (N'DarkOrchid')
INSERT [dbo].[systemColors] ([color]) VALUES (N'DarkRed')
INSERT [dbo].[systemColors] ([color]) VALUES (N'DarkSalmon')
INSERT [dbo].[systemColors] ([color]) VALUES (N'DarkSeaGreen')
INSERT [dbo].[systemColors] ([color]) VALUES (N'DarkSlateBlue')
INSERT [dbo].[systemColors] ([color]) VALUES (N'DarkSlateGray')
INSERT [dbo].[systemColors] ([color]) VALUES (N'DarkTurquoise')
INSERT [dbo].[systemColors] ([color]) VALUES (N'DarkViolet')
INSERT [dbo].[systemColors] ([color]) VALUES (N'DeepPink')
INSERT [dbo].[systemColors] ([color]) VALUES (N'DeepSkyBlue')
INSERT [dbo].[systemColors] ([color]) VALUES (N'DimGray')
INSERT [dbo].[systemColors] ([color]) VALUES (N'DodgerBlue')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Firebrick')
INSERT [dbo].[systemColors] ([color]) VALUES (N'FloralWhite')
INSERT [dbo].[systemColors] ([color]) VALUES (N'ForestGreen')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Fuschia')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Gainsboro')
INSERT [dbo].[systemColors] ([color]) VALUES (N'GhostWhite')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Gold')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Goldenrod')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Gray')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Green')
INSERT [dbo].[systemColors] ([color]) VALUES (N'GreenYellow')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Honeydew')
INSERT [dbo].[systemColors] ([color]) VALUES (N'HotPink')
INSERT [dbo].[systemColors] ([color]) VALUES (N'IndianRed')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Indigo')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Ivory')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Khaki')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Lavender')
INSERT [dbo].[systemColors] ([color]) VALUES (N'LavenderBlush')
INSERT [dbo].[systemColors] ([color]) VALUES (N'LawnGreen')
INSERT [dbo].[systemColors] ([color]) VALUES (N'LemonChiffon')
INSERT [dbo].[systemColors] ([color]) VALUES (N'LightBlue')
INSERT [dbo].[systemColors] ([color]) VALUES (N'LightCoral')
INSERT [dbo].[systemColors] ([color]) VALUES (N'LightCyan')
INSERT [dbo].[systemColors] ([color]) VALUES (N'LightGoldenrodYellow')
INSERT [dbo].[systemColors] ([color]) VALUES (N'LightGray')
INSERT [dbo].[systemColors] ([color]) VALUES (N'LightGreen')
INSERT [dbo].[systemColors] ([color]) VALUES (N'LightSalmon')
INSERT [dbo].[systemColors] ([color]) VALUES (N'LightSeaGreen')
INSERT [dbo].[systemColors] ([color]) VALUES (N'LightSkyBlue')
INSERT [dbo].[systemColors] ([color]) VALUES (N'LightSlateGray')
INSERT [dbo].[systemColors] ([color]) VALUES (N'LightSteelBlue')
INSERT [dbo].[systemColors] ([color]) VALUES (N'LightYellow')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Lime')
INSERT [dbo].[systemColors] ([color]) VALUES (N'LimeGreen')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Linen')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Magenta')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Maroon')
INSERT [dbo].[systemColors] ([color]) VALUES (N'MediumAquamarine')
INSERT [dbo].[systemColors] ([color]) VALUES (N'MediumBlue')
INSERT [dbo].[systemColors] ([color]) VALUES (N'MediumOrchid')
INSERT [dbo].[systemColors] ([color]) VALUES (N'MediumPurple')
INSERT [dbo].[systemColors] ([color]) VALUES (N'MediumSeaGreen')
INSERT [dbo].[systemColors] ([color]) VALUES (N'MediumSlateBlue')
INSERT [dbo].[systemColors] ([color]) VALUES (N'MediumSpringGreen')
INSERT [dbo].[systemColors] ([color]) VALUES (N'MediumTurquoise')
INSERT [dbo].[systemColors] ([color]) VALUES (N'MediumVioletRed')
INSERT [dbo].[systemColors] ([color]) VALUES (N'MidnightBlue')
INSERT [dbo].[systemColors] ([color]) VALUES (N'MintCream')
INSERT [dbo].[systemColors] ([color]) VALUES (N'MistyRose')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Moccasin')
INSERT [dbo].[systemColors] ([color]) VALUES (N'NavajoWhite')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Navy')
INSERT [dbo].[systemColors] ([color]) VALUES (N'OldLace')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Olive')
INSERT [dbo].[systemColors] ([color]) VALUES (N'OliveDrab')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Orange')
INSERT [dbo].[systemColors] ([color]) VALUES (N'OrangeRed')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Orchid')
GO
print 'Processed 100 total records'
INSERT [dbo].[systemColors] ([color]) VALUES (N'PaleGoldenrod')
INSERT [dbo].[systemColors] ([color]) VALUES (N'PaleGreen')
INSERT [dbo].[systemColors] ([color]) VALUES (N'PaleTurquoise')
INSERT [dbo].[systemColors] ([color]) VALUES (N'PaleVioletRed')
INSERT [dbo].[systemColors] ([color]) VALUES (N'PapayaWhip')
INSERT [dbo].[systemColors] ([color]) VALUES (N'PeachPuff')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Peru')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Pink')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Plum')
INSERT [dbo].[systemColors] ([color]) VALUES (N'PowderBlue')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Purple')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Red')
INSERT [dbo].[systemColors] ([color]) VALUES (N'RosyBrown')
INSERT [dbo].[systemColors] ([color]) VALUES (N'RoyalBlue')
INSERT [dbo].[systemColors] ([color]) VALUES (N'SaddleBrown')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Salmon')
INSERT [dbo].[systemColors] ([color]) VALUES (N'SandyBrown')
INSERT [dbo].[systemColors] ([color]) VALUES (N'SeaGreen')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Seashell')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Sienna')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Silver')
INSERT [dbo].[systemColors] ([color]) VALUES (N'SkyBlue')
INSERT [dbo].[systemColors] ([color]) VALUES (N'SlateBlue')
INSERT [dbo].[systemColors] ([color]) VALUES (N'SlateGray')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Snow')
INSERT [dbo].[systemColors] ([color]) VALUES (N'SpringGreen')
INSERT [dbo].[systemColors] ([color]) VALUES (N'SteelBlue')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Tan')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Teal')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Thistle')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Tomato')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Turquoise')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Violet')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Wheat')
INSERT [dbo].[systemColors] ([color]) VALUES (N'White')
INSERT [dbo].[systemColors] ([color]) VALUES (N'WhiteSmoke')
INSERT [dbo].[systemColors] ([color]) VALUES (N'Yellow')
INSERT [dbo].[systemColors] ([color]) VALUES (N'YellowGreen')
/****** Object:  Table [dbo].[swatches]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[swatches](
	[swatchId] [uniqueidentifier] NULL,
	[description] [varchar](50) NULL,
	[code] [varchar](20) NULL,
	[path] [varchar](255) NULL,
	[VerCol] [timestamp] NOT NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
INSERT [dbo].[swatches] ([swatchId], [description], [code], [path]) VALUES (N'00000000-0000-0000-0000-000000000000', N'No Swatch', N'No Swatch', N' ')
/****** Object:  Table [dbo].[stateConvert]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[stateConvert](
	[stateConvertID] [int] NOT NULL,
	[full_name] [varchar](50) NOT NULL,
	[abbr_name] [varchar](2) NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_stateConvert] PRIMARY KEY CLUSTERED 
(
	[stateConvertID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (0, N'ALABAMA                         ', N'AL')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (1, N'ALASKA                          ', N'AK')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (2, N'AMERICAN SAMOA                  ', N'AS')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (3, N'ARIZONA                         ', N'AZ')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (4, N'ARKANSAS                        ', N'AR')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (5, N'CALIFORNIA                      ', N'CA')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (6, N'COLORADO                        ', N'CO')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (7, N'CONNECTICUT                     ', N'CT')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (8, N'DELAWARE                        ', N'DE')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (9, N'DISTRICT OF COLUMBIA            ', N'DC')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (10, N'FEDERATED STATES OF MICRONESIA', N'FM')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (11, N'FLORIDA                         ', N'FL')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (12, N'GEORGIA                         ', N'GA')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (13, N'GUAM                            ', N'GU')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (14, N'HAWAII                          ', N'HI')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (15, N'IDAHO                           ', N'ID')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (16, N'ILLINOIS                        ', N'IL')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (17, N'INDIANA                         ', N'IN')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (18, N'IOWA                            ', N'IA')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (19, N'KANSAS                          ', N'KS')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (20, N'KENTUCKY                        ', N'KY')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (21, N'LOUISIANA                       ', N'LA')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (22, N'MAINE                           ', N'ME')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (23, N'MARSHALL ISLANDS               ', N'MH')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (24, N'MARYLAND                        ', N'MD')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (25, N'MASSACHUSETTS                   ', N'MA')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (26, N'MICHIGAN                        ', N'MI')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (27, N'MINNESOTA                       ', N'MN')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (28, N'MISSISSIPPI                     ', N'MS')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (29, N'MISSOURI                        ', N'MO')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (30, N'MONTANA                         ', N'MT')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (31, N'NEBRASKA                        ', N'NE')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (32, N'NEVADA                          ', N'NV')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (33, N'NEW HAMPSHIRE                   ', N'NH')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (34, N'NEW JERSEY ', N'NJ')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (35, N'NEW MEXICO                      ', N'NM')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (36, N'NEW YORK                       ', N'NY')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (37, N'NORTH CAROLINA                  ', N'NC')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (38, N'NORTH DAKOTA                    ', N'ND')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (39, N'NORTHERN MARIANA ISLANDS        ', N'MP')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (40, N'OHIO                            ', N'OH')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (41, N'OKLAHOMA                        ', N'OK')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (42, N'OREGON                          ', N'OR')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (43, N'PALAU                           ', N'PW')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (44, N'PENNSYLVANIA                    ', N'PA')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (45, N'PUERTO RICO                     ', N'PR')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (46, N'RHODE ISLAND                    ', N'RI')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (47, N'SOUTH CAROLINA                  ', N'SC')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (48, N'SOUTH DAKOTA                    ', N'SD')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (49, N'TENNESSEE                       ', N'TN')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (50, N'TEXAS                           ', N'TX')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (51, N'UTAH                            ', N'UT')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (52, N'VERMONT                         ', N'VT')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (53, N'VIRGIN ISLANDS     ', N'VI')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (54, N'VIRGINIA                        ', N'VA')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (55, N'WASHINGTON                      ', N'WA')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (56, N'WEST VIRGINIA                   ', N'WV')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (57, N'WISCONSIN                       ', N'WI')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (58, N'WYOMING                         ', N'WY')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (59, N'Armed Forces Africa', N'AE')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (60, N'Armed Forces Americas', N'AA')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (61, N'Armed Forces Canada', N'AE')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (62, N'Armed Forces Europe', N'AE')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (63, N'Armed Forces Middle East', N'AE')
INSERT [dbo].[stateConvert] ([stateConvertID], [full_name], [abbr_name]) VALUES (64, N'Armed Forces Pacific', N'AP')
/****** Object:  UserDefinedFunction [dbo].[SPLIT]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[SPLIT]
(
  @s nvarchar(max),
  @c nvarchar(10) = ',',
  @trimPieces bit = 0,
  @returnEmptyStrings bit = 1
)
returns @t table (val nvarchar(max))
as
begin

declare @i int, @j int
select @i = 0, @j = (len(@s) - len(replace(@s,@c,'')))

;with cte 
as
(
  select
    i = @i + 1,
    s = @s, 
    n = substring(@s, 0, charindex(@c, @s)),
    m = substring(@s, charindex(@c, @s)+1, len(@s) - charindex(@c, @s))

  union all

  select 
    i = cte.i + 1,
    s = cte.m, 
    n = substring(cte.m, 0, charindex(@c, cte.m)),
    m = substring(
      cte.m,
      charindex(@c, cte.m) + 1,
      len(cte.m)-charindex(@c, cte.m)
    )
  from cte
  where i <= @j
)
insert into @t (val)
select pieces
from 
(
  select 
  case 
    when @trimPieces = 1
    then ltrim(rtrim(case when i <= @j then n else m end))
    else case when i <= @j then n else m end
  end as pieces
  from cte
) t
where
  (@returnEmptyStrings = 0 and len(pieces) > 0)
  or (@returnEmptyStrings = 1)
option (maxrecursion 0)

return

end
GO
/****** Object:  Table [dbo].[sizes]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[sizes](
	[sizeId] [uniqueidentifier] NOT NULL,
	[size] [varchar](50) NOT NULL,
	[sizeDescription] [varchar](50) NOT NULL,
	[sizeInteger] [float] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_size] PRIMARY KEY CLUSTERED 
(
	[sizeId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
INSERT [dbo].[sizes] ([sizeId], [size], [sizeDescription], [sizeInteger]) VALUES (N'00000000-0000-0000-0000-000000000000', N'No Size', N'No Size', 0)
/****** Object:  Table [dbo].[siteSectionsDetail]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[siteSectionsDetail](
	[siteSectionDetailId] [uniqueidentifier] NOT NULL,
	[siteSectionId] [uniqueidentifier] NOT NULL,
	[data] [varchar](max) NOT NULL,
	[addDate] [datetime] NOT NULL,
	[active] [bit] NOT NULL,
	[description] [varchar](255) NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_siteSectionsDetail] PRIMARY KEY CLUSTERED 
(
	[siteSectionDetailId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[siteSections]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[siteSections](
	[siteSectionId] [uniqueidentifier] NOT NULL,
	[name] [varchar](255) NOT NULL,
	[description] [varchar](255) NOT NULL,
	[URL] [varchar](255) NOT NULL,
	[unique_siteId] [uniqueidentifier] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_siteSections] PRIMARY KEY CLUSTERED 
(
	[siteSectionId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[site_prices]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[site_prices](
	[site_priceID] [int] NOT NULL,
	[unique_siteID] [uniqueidentifier] NULL,
	[itemnumber] [varchar](50) NOT NULL,
	[price] [money] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_site_prices] PRIMARY KEY CLUSTERED 
(
	[site_priceID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  StoredProcedure [dbo].[ShowHierarchy]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [dbo].[ShowHierarchy]
(
	@Root uniqueidentifier
)
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @reply table(newsID uniqueidentifier,treeDepth int)
	DECLARE @newsID uniqueidentifier
	DECLARE @subject varchar(30)
	DECLARE @treeDepth int
	DECLARE @addDate datetime

	SET @subject = (SELECT subject FROM news WHERE newsID = @Root)
	SET @newsID = (SELECT top 10000 newsID FROM news WHERE parentid = @Root order by adddate)
	SET @treeDepth = (SELECT treeDepth FROM news WHERE newsID = @Root)
	SET @addDate = (SELECT AddDate FROM news WHERE newsID = @Root)
	PRINT REPLICATE('-', @@NESTLEVEL * 4) + @subject + '   ' + cast(@newsID as char(36)) + '   ' + cast(@treeDepth as char(3))

	WHILE @newsID IS NOT NULL
	BEGIN
		EXEC dbo.ShowHierarchy @newsID
		SET @newsID = (SELECT top 10000 newsID FROM news WHERE parentid = @Root order by adddate)
	END
END
GO
/****** Object:  UserDefinedFunction [dbo].[jguid]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[jguid](
@GUIDSTRING VARCHAR(100)
)
RETURNS VARCHAR(100)
AS
BEGIN
	DECLARE @JGUIDSTRING VARCHAR(100)
	SET @JGUIDSTRING = 'd' + lower(replace(replace(replace(@GUIDSTRING,'}',''),'{',''),'-','_'))
	RETURN(@JGUIDSTRING)
	/*
	function jguid(x)
		jguid = "d" & replace(replace(replace(x,"}",""),"{",""),"-","_")
	end function
	*/
END
GO
/****** Object:  Table [dbo].[itemVendorAssignment]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[itemVendorAssignment](
	[itemVendorAssignmentID] [uniqueidentifier] NOT NULL,
	[vendorId] [int] NOT NULL,
	[vendorItem] [char](50) NOT NULL,
	[description] [char](100) NOT NULL,
	[localItemNumber] [varchar](50) NOT NULL,
	[casePack] [int] NOT NULL,
	[innerPack] [int] NOT NULL,
	[minOrder] [int] NOT NULL,
	[price] [money] NOT NULL,
	[VerCol] [timestamp] NOT NULL,
 CONSTRAINT [PK_itemVendorAssignment] PRIMARY KEY CLUSTERED 
(
	[itemVendorAssignmentID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  UserDefinedFunction [dbo].[ConcatString]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[ConcatString] (

      @ID      uniqueidentifier
                  )  
RETURNS varchar(1000)
AS
BEGIN 
      
               Declare @String varchar(1000)

      Set @String = ''

      Select @String = @String  + rtrim(value) + char(13) +  char(10) From cartdetail Where cartId = @Id and rtrim(inputname) like '%monogram%' and not rtrim(inputname) like '%ovlenmonogram%' order by inputname
	  
      Return case when len(@String)>0 then substring(@String,0,len(@String)-1) else '' end

END
GO
/****** Object:  UserDefinedFunction [dbo].[ConcatBackorderNumbers]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[ConcatBackorderNumbers] (

      @ID      uniqueidentifier
                  )  
RETURNS varchar(1000)
AS
BEGIN 
      Declare @String varchar(1000)
      Set @String = ''
      Select @String = @String  + rtrim(orders.OrderNumber) + ',' From cart
	  inner join orders on orders.orderId = cart.orderId
	  Where cartId = @Id
      Return case when len(@String)>0 then substring(@String,0,len(@String)-1) else '' end
END
GO
/****** Object:  View [dbo].[orderOverview]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[orderOverview] as
	/* order overview version 1.1 */

	/**********************************************************************************************
	*		 WARNING   WARNING   WARNING   WARNING   WARNING   WARNING   WARNING   WARNING   
	*	WARNING   WARNING   WARNING   WARNING   WARNING   WARNING   WARNING   WARNING   WARNING   
	*
	*	Flat style presentation of order detail information
	*  NEVER CHANGE THE ORDER OF THE COLUMNS IN THIS VIEW
	*  NEVER CHANGE ANY OF THE VALUES OF THE FIRST 193 COLUMNS IN THIS VIEW (upto VerCol)
	*  Really, just don't change anything, make another view that refrences this one
	*  if you just gotta add or modify this view make sure you add your new columns AFTER vercol
	*  failure to do this will seriously mess up a lot of other parts of this application!
	*
	**********************************************************************************************/

	select ik.Itemnumber as itemNumber, l.lastFlagStatus as line_status, l.lastFlagId as line_flag,
	h.lastFlagStatus as shipment_status, h.lastFlagId as shipment_flag,
	r.lastFlagStatus as order_status, r.lastFlagId as order_flag, o.readyForExport as readyForExport, 
	ik.reorderpoint, ik.BOMOnly, ik.Price as listPrice, ik.SalePrice,
	case when c.backorderedQty is null then 0 else c.backorderedQty end as backordered,
	case when c.canceledQty is null then 0 else c.canceledQty end as canceled,
	case when c.backorderedQty > 0 then
		dbo.ConcatBackorderNumbers(c.cartId)
	else
		''
	end as backOrders,
	ik.WholeSalePrice, ik.IsOnSale, 
	case when i.Itemnumber = ik.Itemnumber then
		ik.Description
	else
		ik.Description + ' ' + c.serialnumber
	end as Description
	, ik.ShortCopy, ik.HomeCategory, ik.HomeAltCategory, ik.Weight as itemlistWeight, ik.quantifier, ik.shortDescription, 
	ik.freeShipping, ik.formName as listFormName, ik.M as imageIdM, ik.C as imageIdC, ik.F as imageIdF, ik.T as imageIdT, ik.A as imageIdA, ik.X as imageIdX, ik.Y as imageIdY, ik.Z as imageIdZ,
	 ik.keywords, ik.searchPriority, ik.workCreditValue, c.cartId, c.sessionId, 
	  c.qty,
	 case when i.Itemnumber = ik.Itemnumber then
		c.qty*(c.Price-c.valueCostTotal-c.noTaxValueCostTotal)
	 else
		c.qty*(k.valueCostTotal+k.noTaxValueCostTotal)
	 end
	 as lineTotal,
	  case when i.Itemnumber = ik.Itemnumber then
		(c.Price-c.valueCostTotal-c.noTaxValueCostTotal)
	  else
		(k.valueCostTotal+k.noTaxValueCostTotal)
	 end as price,
	  c.addTime, i.formName, c.orderId, c.serialId, c.orderNumber, c.serialNumber, 
	c.addressId, c.shipmentId, c.shipmentNumber, c.lineNumber, c.epsmmcsOutput, o.scanned_order_image, c.epsmmcsAIFilename,
	c.userId, u.userLevel, handle, u.email, wholeSaleDealer, lastVisit, u.comments as user_comments, password, administrator, 
	a.sendShipmentUpdates, createDate as dateAccountCreated, quotaWholesale, quotaComplete, quota, credit, loggedIn, purchaseAccount, 
	creditLimit, u.contact, u.address1, u.address2, u.zip, u.state, u.country, u.city, u.workPhone, 
	u.email as accountEmail, u.fax, u.www, u.termId, usesTerms, accountType,
	a.addressId as shipToAddressid, a.firstName as shipToFirstName, a.lastName as shipToLastName, a.address1 as shipToAddress1,
	a.address2 as shipToAddress2, a.city as shipToCity, a.state as shipToState, a.zip as shipToZip, a.country as shipToCountry,
	a.HomePhone as shipToHomePhone, a.WorkPhone as shipToWorkPhone, a.Email as shipToEmail, 
	a.specialInstructions as shipToSpecialInstructions, a.rate, a.shippingQuote, a.weight as estimatedShipmentWeight,
	b.addressId as billToAddressid, b.firstName as billToFirstName, b.LastName as billToLastName, b.address1 as billToAddress1,
	b.address2 as billToAddress2, b.city as billToCity, b.State as billToState, b.zip as billToZip, b.country as billToCountry,
	b.homePhone as billToHomePhone, b.workPhone as billToWorkPhone, b.Email as billToEmail, b.specialInstructions as billToSpecialInstructions,
	/* moved to getOrders SP for UI and export lookup */
	'' as addressUpdateId,
	'' as tracking,
	'' as dateShipped,
	'' actualWeight,
	'' as actualService,
	'' as actualCost,
	'' as actualBilledWeight, 
	'' as packageLength,
	'' as packageWidth,
	'' as packageHeight,
	'' as thirdPartyAccount,
	'' as voidStatus,
	'' as emailSent,
	'' as addDate,
	case when i.Itemnumber = ik.Itemnumber then
		dbo.ConcatString(c.cartId)
	else
		''
	end as concatline,
	o.orderDate as orderTime,cast(convert(varchar(100), orderdate,101)+' 00:00:00.00' as datetime) as orderDate,o.grandTotal,
	o.taxTotal,o.subTotal,o.shippingTotal,o.service1,o.service2,o.manifest,o.purchaseOrder,o.comment as orderComments,
	(select top 1 remoteItemNumber from importFileItemTranslation where importFileItemTranslation.localItemNumber = c.itemNumber) as customerItemNumber,
	flagTypeName, flagTypeDesc, customerReadable as customerReadableFlagStatus, volume, prebook, wip, ats, shippingName, menuOrder as ship_type_menuOrder, international,
	enabled as ship_type_enabled, ratetype, zoneCarrierId, zoneServiceClass, discountRate, trackingLink, cmrAreaSurch, resAreaSurchg, groundFuelSurchgPct, airFuelSurchgPct,
	e.termName, o.discount as discounted, 
	case when objectFlags.addTime is null then cast('1/1/1900 00:00:00.000' as datetime) else objectFlags.addTime end as order_lastFlagAddTime, 
	case when objectFlags.comments is null then '' else objectFlags.comments end as order_lastFlagComments, 
	u.purchaseAccount as export_to_account, i.revenueAccount, c.price as line_price,k.valueCostTotal, k.noTaxValueCostTotal, ik.itemNumber as kitItemNumber,
	c.valueCostTotal as cartValueCostTotal, customerLineNumber,
 
	RTRIM(b.firstName)+' '+RTRIM(b.lastName)+'
	'+RTRIM(b.address1)+case when LEN(b.address2) >0 then '
	'+RTRIM(b.address2) else '' end + '
	'+RTRIM(b.city)+' '+RTRIM(b.state)+' '+RTRIM(b.zip)+' '+RTRIM(b.country)+'
	Home:'+b.homePhone+' Work:'+b.workPhone+'
	'+b.email+case when LEN(b.specialInstructions) > 0 then '
	Special Instructions:
	'+RTRIM(b.specialInstructions) else '' end as billToBlock,

	RTRIM(a.firstName)+' '+RTRIM(a.lastName)+'
	'+RTRIM(a.address1)+case when LEN(a.address2) >0 then '
	'+RTRIM(a.address2) else '' end + '
	'+RTRIM(a.city)+', '+RTRIM(a.state)+' '+RTRIM(a.zip)+' '+RTRIM(a.country)+'
	Home:'+a.homePhone+' Work:'+a.workPhone+'
	'+case when LEN(a.specialInstructions) > 0 then '
	Special Instructions:
	'+RTRIM(a.specialInstructions) else '' end as shipToBlock,
	 'not implemented' as serialBarcodeImage,
	 'not implemented' as orderBarcodeImage,
	 'not implemented' as shipmentBarcodeImage,
	 'not implemented' as userBarcodeImage,
	 n.scanned_image_path as baseScannedImagePath,
	 RTRIM(n.company_name)+'
	 '+case when LEN(n.company_co) >0 then '
	 '+RTRIM(n.company_co)+'
	 ' else '' end + RTRIM(n.company_address1)+case when LEN(n.company_address2) >0 then '
	 '+RTRIM(n.company_address2) else '' end + '
	 '+RTRIM(n.company_city)+' '+RTRIM(n.company_state)+' '+RTRIM(n.company_zip)+' '+RTRIM(n.company_country)+'
	 Phone:'+n.company_phone+' Fax:'+n.company_fax+'
	 Email:'+n.company_email as companyBlock,
	 n.company_HTML_subHeader as companySubHeader,
	 n.company_name as companyName,
	 n.friendlySiteName as friendlySiteName,
	 n.siteaddress as siteAddress,
	 convert(varchar(50),orderdate,101) as orderDate101,
	 convert(varchar(50),orderdate,10) as orderDate10,
	 convert(varchar(50),orderdate,100) as orderDate100,
	 o.paid as paid,
	 o.closed as closed,
	 '' as paymentMethodId,
	 o.creditMemo as creditMemo,
	 o.recalculatedOn as recalculatedOn,
	 o.soldBy as soldBy,
	 o.requisitionedBy as requisitionedBy,
	 o.approvedBy as approvedBy,
	 o.deliverBy as deliverBy,
	 o.vendor_accountNo as vendor_accountNo,
	 o.FOB as FOB,
	 parentOrderId as parentOrderId,
	 parentCartId as parentCartId,
	 i.parentItemNumber as parentItemNumber,
	 c.fulfillmentDate as fulfillmentDate,
	 c.estimatedFulfillmentDate as estimatedFulfillmentDate,
	 k.kitAllocationId,k.showAsSeperateLineOnInvoice,k.vendorItemKitAssignmentId,
	 k.qty as kitQty, k.cartId as kitAllocationCartId, k.itemConsumed, k.inventoryItem
	 -1 as VerCol
	from cart c 
	inner join items i on c.itemnumber = i.itemnumber 
	inner join orders o on o.orderid = c.orderid
	inner join addresses a on a.addressid = c.addressid 
	inner join addresses b on b.addressid = o.billtoaddressid
	inner join users u on u.userid = c.userid
	inner join serial_line l on l.cartId = c.cartId
	inner join serial_shipment h on h.shipmentid = c.shipmentId
	inner join serial_order r on r.orderId = o.orderId
	left join flagTypes f on f.flagTypeId = l.lastFlagStatus
	left join Shippingtype s on s.Rate = a.rate
	left join dbo.itemOnHandTemp t on t.itemnumber = c.Itemnumber
	inner join Terms e on e.termId = c.termId
	left join objectFlags on objectFlags.flagId = r.lastFlagId
	left join kitAllocation k on k.cartId = c.cartId and k.showAsSeperateLineOnInvoice = 1
	left join items ik on ik.itemnumber = k.itemNumber
	left join site_configuration n on o.unique_siteId = n.unique_siteId
GO
/****** Object:  StoredProcedure [dbo].[getOrders]    Script Date: 05/30/2011 18:14:48 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[getOrders] (
	@orderIds hashTable READONLY
) as 
begin
	/* getOrders version 0.1.0 */
	select 
	itemNumber, line_status, line_flag, shipment_status, shipment_flag, order_status, order_flag, readyForExport,
	reorderpoint, BOMOnly, listPrice, SalePrice, backordered, canceled, backOrders, WholeSalePrice, IsOnSale,
	Description, ShortCopy, HomeCategory, HomeAltCategory, itemlistWeight, quantifier, shortDescription,
	freeShipping, listFormName, imageIdM, imageIdC, imageIDF, imageIdT, imageIdA, imageIdX, imageIdY, imageIdZ,
	keywords, searchPriority, workCreditValue, cartId, sessionId, qty, lineTotal, price, addTime, formName, orderId,
	serialId, orderNumber, serialNumber, addressId, shipmentId, shipmentNumber, lineNumber, epsmmcsOutput,
	scanned_order_image, epsmmcsAIFilename, userId, userLevel, handle, email, wholeSaleDealer, lastVisit,
	user_comments, password, administrator, sendShipmentUpdates, dateAccountCreated, quotaWholesale, quotaComplete,
	quota, credit, loggedIn, purchaseAccount, creditLimit, contact, address1, address2, zip, state, country, city,
	workPhone, accountEmail, fax, www, termId, usesTerms, accountType, shipToAddressid, shipToFirstName,
	shipToLastName, shipToAddress1, shipToAddress2, shipToCity, shipToState, shipToZip, shipToCountry, shipToHomePhone,
	shipToWorkPhone, shipToEmail, shipToSpecialInstructions, rate, shippingQuote, estimatedShipmentWeight,
	billToAddressid, billToFirstName, billToLastName, billToAddress1, billToAddress2, billToCity, billToState,
	billToZip, billToCountry, billToHomePhone, billToWorkPhone, billToEmail, billToSpecialInstructions, '',
	'', '', '', '', '', '', '', '',	'', '', '', '', '', concatline, orderTime, orderDate, grandTotal,
	taxTotal, subTotal, shippingTotal, service1, service2, manifest, purchaseOrder, orderComments, customerItemNumber,
	flagTypeName, flagTypeDesc, customerReadableFlagStatus, volume, prebook, wip, ats, shippingName, ship_type_menuOrder,
	international, ship_type_enabled, ratetype, zoneCarrierId, zoneServiceClass, discountRate, trackingLink, cmrAreaSurch,
	resAreaSurchg, groundFuelSurchgPct, airFuelSurchgPct, termName, discounted, order_lastFlagAddTime, order_lastFlagComments,
	export_to_account, revenueAccount, line_price, valueCostTotal, noTaxValueCostTotal, kitItemNumber, cartValueCostTotal,
	customerLineNumber, billToBlock, shipToBlock, serialBarcodeImage, orderBarcodeImage, shipmentBarcodeImage, userBarcodeImage,
	baseScannedImagePath, companyBlock, companySubHeader, companyName, friendlySiteName, siteAddress, orderDate101, orderDate10,
	orderDate100, paid, closed, paymentMethodId, creditMemo, recalculatedOn, soldBy, requisitionedBy, approvedBy,
	deliverBy, vendor_accountNo, FOB, parentOrderId, parentCartId, fulfillmentDate, estimatedFulfillmentDate,
	o.kitAllocationId, o.kitQty, o.showAsSeperateLineOnInvoice, o.vendorItemKitAssignmentId, o.kitAllocationCartId,VerCol
	from orderOverview o with (nolock)
	inner join @orderIds r on convert(int,r.keyValue) = o.orderId
	order by orderId,orderDate,userId,o.flagTypeName,o.lineNumber
	/* next batch... shipments, this table is updated by an external source so some values may be null - MUST COMPENSATE! */
	select
	cart.orderId,
	addressUpdateId,
	cart.shipmentNumber,
	case when tracking is null then '' else tracking end,
	case when dateShipped is null then '' else dateShipped end,
	case when actualWeight is null then '' else actualWeight end,
	case when actualService is null then '' else actualService end,
	case when actualCost is null then '' else actualCost end,
	case when actualBilledWeight is null then '' else actualBilledWeight end,
	case when packageLength is null then '' else packageLength end,
	case when packageWidth is null then '' else packageWidth end,
	case when packageHeight is null then '' else packageHeight end,
	case when thirdPartyAccount is null then '' else thirdPartyAccount end,
	case when voidStatus is null then '' else voidStatus end,
	case when emailSent is null then convert(datetime,'1/1/1900 00:00:00.000') else emailSent end,
	case when addDate is null then convert(datetime,'1/1/1900 00:00:00.000') else addDate end
	from addressUpdate with (nolock)
	inner join cart with (nolock) on addressUpdate.shipmentNumber = cart.shipmentNumber
	inner join orders with (nolock) on orders.orderId = cart.orderId
	group by
	cart.orderId,
	addressUpdateId,
	cart.shipmentNumber,
	tracking,
	dateShipped,
	actualWeight,
	actualService,
	actualCost,
	actualBilledWeight,
	packageLength,
	packageWidth,
	packageHeight,
	thirdPartyAccount,
	voidStatus,
	emailSent,
	addDate
	
end
GO
/****** Object:  View [dbo].[xmlLine]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[xmlLine] as
select qty,c.itemNumber,c.price,serialNumber,shipmentNumber,lineNumber,customerLineNumber,
[description],f.flagTypeName,f.flagTypeId,c.canceledQty,c.backorderedQty,l.orderId,l.cartId,
n.formName,n.sourceCode
from serial_line l
inner join cart c on c.cartId = l.cartId
inner join items i on c.itemNumber = i.itemNumber
inner join flagTypes f on f.flagTypeId = l.lastFlagStatus
inner join order_line_forms n on n.cartId = c.cartId
GO
/****** Object:  UserDefinedFunction [dbo].[isOnInvoice]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[isOnInvoice](
@orderID int
)
returns bit
as
begin
	declare @occurs bit
	SET @occurs = 0
		IF EXISTS(SELECT * from batchInvoiceDetail d
		inner join batchInvoices b on b.batchInvoiceID = d.batchInvoiceID
		where orderID = @orderID and not invoiceID = -1
		)
		BEGIN
			SET @occurs = 1
		END
	return @occurs
end
GO
/****** Object:  StoredProcedure [dbo].[getGalleries]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[getGalleries] as
begin
	select
	imageRotatorDetailID,
	path,
	link,
	title,
	cropX,
	cropY,
	cropH,
	cropW,
	d.height,
	d.width,
	comments,
	description,
	enabled,
	rotator_order,
	thumb_order,
	rotatorHeight,
	rotatorWidth,
	thumbHeight,
	thumbWidth,
	userid,
	addDate,
	blogHeight,
	blogWidth,
	portfolioHeight,
	portfolioWidth,
	d.tags,
	tagsToSearchFor,
	exif,
	c.imageRotatorCategoryID,
	categoryName,
	c.height,
	c.width,
	resizeMethod,
	rotatorTemplate,
	thumbTemplate, 
	fullsizeTemplate,
	portfolioTemplate,
	blogTemplate,
	gallery,
	gallery_description,
	gallery_order,
	c.tags,
	d.x,
	d.y
	from imageRotatorCategories c
	inner join imageRotatorDetail d on c.imageRotatorCategoryID = d.imageRotatorCategoryID
	order by c.imageRotatorCategoryID, rotator_order
end
GO
/****** Object:  StoredProcedure [dbo].[getForm]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[getForm] (@cartId uniqueidentifier) as
begin
	select f.sourceCode,f.formName,itemNumber
	from dbo.order_line_forms f
	inner join cart on f.cartId = cart.cartId
	where f.cartId = @cartId
end
GO
/****** Object:  StoredProcedure [dbo].[getFlagTypes]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[getFlagTypes] as 
	/* getFlagTypes version 1.0 */
	select flagTypeId, flagTypeName, flagTypeDesc, userLevel, shipmentFlag, userFlag, orderFlag,
	lineFlag, lineDetailFlag, customerReadable, agingDaysStatus1, agingDaysStatus2, agingDaysStatus3,
	agingDaysStatus4, agingDaysStatus5, showInProductionAgingReport, productionAgingReportOrder,
	cannotOccurBeforeFlagId, cannotOccurAfterFlagId, purchaseOrderFlag, purchaseShipmentFlag,
	purchaseLineFlag, createsNewPurchaseOrder, finishedPurchaseOrderFlag, color
	from flagTypes order by productionAgingReportOrder
GO
/****** Object:  StoredProcedure [dbo].[getDiscounts]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[getDiscounts] as begin
		/* getDiscounts version 1.1 */
		select DiscountCode, Discount, comments from discount
	end
GO
/****** Object:  StoredProcedure [dbo].[getRotatorCategory]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[getRotatorCategory] (@imageRotatorCategoryId uniqueidentifier) as begin
	select c.imageRotatorCategoryId, categoryName, c.height as rotatorHeight, c.width as rotatorWidth, resizeMethod, rotatorTemplate, thumbTemplate, 
	fullsizeTemplate, portfolioTemplate, blogTemplate, gallery, gallery_description, gallery_order, c.tags as rotatorTags,
	imageRotatorDetailId, path, link, title, cropX, cropY, cropH, cropW, x, y, d.height as height, d.width as width, 
	comments, description, enabled, rotator_order, thumb_order, rotatorHeight, rotatorWidth, thumbHeight, thumbWidth, 
	userid, addDate, blogHeight, blogWidth, portfolioHeight, portfolioWidth, d.tags as tags, tagsToSearchFor, exif
	from imageRotatorCategories c
	inner join dbo.imageRotatorDetail d on d.imageRotatorCategoryId = c.imageRotatorCategoryId
	where c.imageRotatorCategoryId = @imageRotatorCategoryId or imageRotatorDetailId = @imageRotatorCategoryId
end
GO
/****** Object:  StoredProcedure [dbo].[getReviews]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[getReviews] as
begin
	select 
	reviewId, 
	userId, 
	rating, 
	message, 
	archive, 
	addDate, 
	refId, 
	refType from reviews order by addDate desc
end
GO
/****** Object:  StoredProcedure [dbo].[getRemaningPaymentMethodIdsTotal]    Script Date: 05/30/2011 18:15:19 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[getRemaningPaymentMethodIdsTotal](@paymentMethodIds hashtable readonly) as
begin
/* getRemaningPaymentMethodIdsTotal version 0.1.0 */
	
	select SUM(remainingAmount) from (
		select p.amount-SUM(case when pd.amount is null then 0 else pd.amount end) as remainingAmount
		from @paymentMethodIds pids
		inner join paymentMethods p on CONVERT(uniqueidentifier,pids.keyValue) = p.paymentMethodId
		left join paymentMethodsDetail pd on p.paymentMethodId = pd.paymentMethodId
		group by p.paymentMethodId,p.amount
	) fs

end
GO


/****** Object:  StoredProcedure [dbo].[getRedirectors]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[getRedirectors] as begin
	select redirectorId, urlMatchPattern, urlToRedirectToMatch, errorMatch,
	case when [contentType] is null then '' else [contentType] end,
	case when [type] is null then '' else [type] end,
	case when [listOrder] is null then 0 else [listOrder] end,
	case when [enabled] is null then cast(0 as bit) else [enabled] end
	from redirector
end
GO
/****** Object:  StoredProcedure [dbo].[getRates]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[getRates] as
begin
select ShippingName, Rate, MenuOrder, International, Enabled, ratetype, ZoneCarrierID, ZoneServiceClass, discountRate, TrackingLink, cmrAreaSurch, resAreaSurchg, groundFuelSurchgPct, airFuelSurchgPct, showsUpInRetailCart, showsUpInWholesaleCart, showsUpInOrderEntry
from dbo.ShippingType
end
GO
/****** Object:  StoredProcedure [dbo].[getProperties]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[getProperties] as
begin
	select 
	itemPropertyID, 
	rtrim(itemNumber) as itemNumber, 
	rtrim(itemProperty) as itemProperty, 
	rtrim(propertyValue) as propertyValue, 
	rtrim(displayValue) as displayValue, 
	valueOrder,
	bomItem, 
	price, 
	taxable, 
	showAsSeperateLineOnInvoice,
	showInFilter
	from itemProperties
	order by itemProperty,displayValue,propertyValue
end
GO
/****** Object:  StoredProcedure [dbo].[getPageTitles]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[getPageTitles] as begin
	select pageTitleId, page, category, title, metaDescription, metaKeywords
	from pageTitles with (nolock)
end
GO
/****** Object:  StoredProcedure [dbo].[getOrderForm]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[getOrderForm] @cartId uniqueidentifier as
begin
select sourceCode, formName, itemNumber
from order_line_forms f
inner join cart on f.cartId = cart.cartId
where f.cartId = @cartId
end
GO
/****** Object:  StoredProcedure [dbo].[getNewAccountNumber]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[getNewAccountNumber](
	@accountType int
) as begin
	/* getNewAccountNumber version 0.1.0 */
	declare @newUserId int = -1;
	set @newUserId = (
		select case when MAX(userId) is null then MAX(at.rangeLow)+1 else MAX(userId)+1 end
		from users with (nolock)
		inner join accountTypes at with (nolock) on at.accountTypeId = @accountType
		and userId between at.rangeLow and at.rangeHigh
	)
	select @newUserId as newUserId
end
GO
/****** Object:  StoredProcedure [dbo].[getMenus]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[getMenus] as
begin
	select
	menuId,
	parentId,
	menuName as Name,
	href,
	enabled,
	listOrder,
	childType,
	childOrder,
	menutype,
	childFilter as child_filter,
	0 as max_children,
	script as expand_on_pageName
	from menus order by listOrder
end
GO
/****** Object:  UserDefinedFunction [dbo].[getShipPrice]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[getShipPrice](
	@rateID int,
	@weight float,
	@zip varchar(15),
	@disc_wgt float,
	@wholesale bit
)
RETURNS money
AS
BEGIN
declare @shipprice money

if (isnumeric(substring(@zip,1,5))=1)
	begin
		set @shipprice =	(SELECT 
								case 
									when exists(select count(*) from areaSurcharge where carrier = @rateID and deliveryArea = SUBSTRING(@zip,1,5))
								then (shipzone.cost+(case 
														when @wholesale = 1 
														then shippingtype.cmrAreaSurch 
														else shippingtype.resAreaSurchg 
													end))*(1+(case 
															when zoneServiceClass > 1
															then airFuelSurchgPct
															else groundFuelSurchgPct 
														end))
								else
								shipzone.cost*(1+(case 
												when zoneServiceClass > 1
												then airFuelSurchgPct
												else groundFuelSurchgPct
											end ))
								end
								as cost
							FROM shipzone 
								inner join shippingtype on shipzone.rate = shippingtype.rate
							WHERE 
								shippingtype.zoneserviceclass in (SELECT [service] from ziptozone WHERE SUBSTRING(@zip,1,5) between fromzip and tozip)
								and shipzone.shipzone in (select shipzone from ziptozone where SUBSTRING(@zip,1,5) between fromzip and tozip)
								and shipzone.weight = (@weight - @disc_wgt) and shipzone.weight > 0
								and	shippingtype.enabled = 1 
								and shippingtype.rate not in (select rate from zoneexclusions where shipzone.shipzone = zoneexclusions.shipzone)
								and shippingtype.rate = @rateID
						)
		end 

if (@shipprice is null)
	begin
		set @shipprice = 0
	end

RETURN(@shipprice)
END
GO
/****** Object:  StoredProcedure [dbo].[insertItemIntoCategories]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[insertItemIntoCategories](@categories varchar(max),@itemNumber varchar(50))
as
begin
	declare @items table(columnIndex int identity,value varchar(50));
	insert into @items select * from dbo.SPLIT(@categories,',',1,1);
	insert into categoryDetail
	select NEWID() as categoryDetailId,value as categoryId,@itemNumber as itemNumber,
	columnIndex as listorder,'00000000-0000-0000-0000-000000000000' as childCategoryId, null as VerCol
	from @items
end
GO
/****** Object:  StoredProcedure [dbo].[insertItemImageDetail]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[insertItemImageDetail](
	@imagingDetailId uniqueidentifier, 
	@imagingId uniqueidentifier, 
	@unique_siteId uniqueidentifier, 
	@itemNumber varchar(50), 
	@height int, 
	@width int, 
	@fileName varchar(255), 
	@locationType varchar(1)
) as begin
	print 'begin [insertItemImageDetail]'
	if exists(select 0 from ImagingDetail where unique_siteID = @unique_siteId and imagingId = @imagingId and locationType = @locationType) begin
		update ImagingDetail
		set
		ImagingDetailID = @imagingDetailId,
		ImagingID = @imagingId,
		unique_siteID = @unique_siteId,
		height = @height,
		width = @width,
		@itemNumber = itemnumber,
		filename = @fileName,
		locationType = @locationType
		where unique_siteID = @unique_siteId and imagingId = @imagingId and locationType = @locationType
	end else begin 
		insert into ImagingDetail
		(ImagingDetailID, ImagingID, unique_siteID, height, width, itemnumber, filename, locationType)
		values
		(
			@imagingDetailId, 
			@imagingId, 
			@unique_siteId, 
			@height, 
			@width, 
			@itemNumber, 
			@fileName, 
			@locationType
		)
	end
end
GO
/****** Object:  StoredProcedure [dbo].[insertItem]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[insertItem]  (
	@itemNumber sql_variant,
	@displayPrice sql_variant,
	@reorderPoint sql_variant,
	@BOMOnly sql_variant,
	@itemHTML sql_variant,
	@price sql_variant,
	@salePrice sql_variant,
	@wholeSalePrice sql_variant, 
	@isOnSale sql_variant,
	@description sql_variant,
	@shortCopy sql_variant,
	@productCopy sql_variant,
	@weight sql_variant,
	@quantifier sql_variant, 
	@shortDescription sql_variant, 
	@freeShipping sql_variant, 
	@formName sql_variant,
	@keywords sql_variant, 
	@searchPriority sql_variant, 
	@workCreditValue sql_variant, 
	@noTax sql_variant, 
	@deleted sql_variant, 
	@removeAfterPurchase sql_variant,
	@parentItemNumber sql_variant,
	@allowPreorders sql_variant, 
	@inventoryOperator sql_variant,
	@inventoryRestockOnFlagId sql_variant,
	@itemIsConsumedOnFlagId sql_variant,
	@inventoryDepletesOnFlagId sql_variant,
	@revenueAccount sql_variant,
	@ratio sql_variant,
	@highThreshold sql_variant,
	@expenseAccount sql_variant,
	@inventoryAccount sql_variant,
	@COGSAccount sql_variant,
	@SKU sql_variant,
	@itemType sql_variant,
	@averageCost sql_variant,	
	@dupeMode int/*0=ignore imported dupe, 1=update existing record*/
) as begin
	/* insertItem version 0.1.0 */
	declare @emptyGUID uniqueidentifier = '00000000-0000-0000-0000-000000000000';
	if exists(select 0 from items where itemNumber = @itemNumber) begin
		if (@dupeMode=1) begin
			print 'update'
			declare @updateQuery nvarchar(max) = '';
			if not @displayPrice is null begin set @updateQuery = @updateQuery+' displayPrice = '''+convert(varchar(max),@displayPrice)+''','; end
			if not @reorderPoint is null begin set @updateQuery = @updateQuery+' reorderPoint = '''+convert(varchar(max),@reorderPoint)+''','; end
			if not @BOMOnly is null begin set @updateQuery = @updateQuery+' BOMOnly = '''+cast(@BOMOnly as varchar(50))+''','; end
			if not @itemHTML is null begin set @updateQuery = @updateQuery+' itemHTML = '''+convert(varchar(max),@itemHTML)+''','; end
			if not @price is null begin set @updateQuery = @updateQuery+' price = '''+convert(varchar(max),@price)+''','; end
			if not @salePrice is null begin set @updateQuery = @updateQuery+' salePrice = '''+convert(varchar(max),@salePrice)+''','; end
			if not @wholeSalePrice is null begin set @updateQuery = @updateQuery+' wholeSalePrice = '''+convert(varchar(max),@wholeSalePrice)+''','; end 
			if not @isOnSale is null begin set @updateQuery = @updateQuery+' isOnSale = '''+cast(@isOnSale as varchar(50))+''','; end
			if not @description is null begin set @updateQuery = @updateQuery+' description = '''+convert(varchar(max),@description)+''','; end
			if not @shortCopy is null begin set @updateQuery = @updateQuery+' shortCopy = '''+convert(varchar(max),@shortCopy)+''','; end
			if not @productCopy is null begin set @updateQuery = @updateQuery+' productCopy = '''+convert(varchar(max),@productCopy)+''','; end
			if not @weight is null begin set @updateQuery = @updateQuery+' weight = '''+convert(varchar(max),@weight)+''','; end
			if not @quantifier is null begin set @updateQuery = @updateQuery+' quantifier = '''+convert(varchar(max),@quantifier)+''','; end 
			if not @shortDescription is null begin set @updateQuery = @updateQuery+' shortDescription = '''+convert(varchar(max),@shortDescription)+''','; end 
			if not @freeShipping is null begin set @updateQuery = @updateQuery+' freeShipping = '''+cast(@freeShipping as varchar(50))+''','; end 
			if not @formName is null begin set @updateQuery = @updateQuery+' formName = '''+convert(varchar(max),@formName)+''','; end
			if not @keywords is null begin set @updateQuery = @updateQuery+' keywords = '''+convert(varchar(max),@keywords)+''','; end 
			if not @searchPriority is null begin set @updateQuery = @updateQuery+' searchPriority = '''+convert(varchar(max),@searchPriority)+''','; end 
			if not @workCreditValue is null begin set @updateQuery = @updateQuery+' workCreditValue = '''+convert(varchar(max),@workCreditValue)+''','; end 
			if not @noTax is null begin set @updateQuery = @updateQuery+' noTax = '''+cast(@noTax as varchar(50))+''','; end 
			if not @deleted is null begin set @updateQuery = @updateQuery+' deleted = '''+cast(@deleted as varchar(50))+''','; end
			if not @removeAfterPurchase is null begin set @updateQuery = @updateQuery+' removeAfterPurchase = '''+cast(@removeAfterPurchase as varchar(50))+''','; end
			if not @parentItemNumber is null begin set @updateQuery = @updateQuery+' parentItemNumber = '''+convert(varchar(max),@parentItemNumber)+''','; end
			if not @allowPreorders is null begin set @updateQuery = @updateQuery+' allowPreorders = '''+cast(@allowPreorders as varchar(50))+''','; end 
			if not @inventoryOperator is null begin set @updateQuery = @updateQuery+' inventoryOperator = '''+convert(varchar(max),@inventoryOperator)+''','; end
			if not @inventoryRestockOnFlagId is null begin set @updateQuery = @updateQuery+' inventoryRestockOnFlagId = '''+convert(varchar(max),@inventoryRestockOnFlagId)+''','; end
			if not @itemIsConsumedOnFlagId is null begin set @updateQuery = @updateQuery+' itemIsConsumedOnFlagId = '''+convert(varchar(max),@itemIsConsumedOnFlagId)+''','; end
			if not @inventoryDepletesOnFlagId is null begin set @updateQuery = @updateQuery+' inventoryDepletesOnFlagId = '''+convert(varchar(max),@inventoryDepletesOnFlagId)+''','; end
			if not @revenueAccount is null begin set @updateQuery = @updateQuery+' revenueAccount = '''+convert(varchar(max),@revenueAccount)+''','; end
			if not @ratio is null begin set @updateQuery = @updateQuery+' ratio = '''+convert(varchar(max),@ratio)+''','; end
			if not @highThreshold is null begin set @updateQuery = @updateQuery+' highThreshold = '''+convert(varchar(max),@highThreshold)+''','; end
			if not @expenseAccount is null begin set @updateQuery = @updateQuery+' expenseAccount = '''+convert(varchar(max),@expenseAccount)+''','; end
			if not @inventoryAccount is null begin set @updateQuery = @updateQuery+' inventoryAccount = '''+convert(varchar(max),@inventoryAccount)+''','; end
			if not @COGSAccount is null begin set @updateQuery = @updateQuery+' COGSAccount = '''+convert(varchar(max),@COGSAccount)+''','; end
			if not @SKU is null begin set @updateQuery = @updateQuery+' SKU = '''+convert(varchar(max),@SKU)+''','; end
			if not @itemType is null begin set @updateQuery = @updateQuery+' itemType = '''+convert(varchar(max),@itemType)+''','; end
			if not @averageCost is null begin set @updateQuery = @updateQuery+' highThreshold = '''+convert(varchar(max),@averageCost)+''','; end
			set @updateQuery = 'update items set '+substring(@updateQuery,1,len(@updateQuery)-1)+' where itemNumber = '''+convert(varchar(50),@itemNumber)+'''';
			print @updateQuery;
			declare @prep nchar(1000) = 'EXEC sp_executesql @Rsql'
			exec sp_executesql @prep,N'@Rsql ntext',@Rsql = @updateQuery;
		end
	end else begin
		print 'insert'
		insert into items
		select
		convert(varchar(50),@itemNumber) as itemNumber, convert(varchar(50),@displayPrice) as displayPrice,
		convert(int,@reorderPoint) as reorderPoint, convert(bit,@BOMOnly) as BOMOnly,
		convert(varchar(max),@itemHTML) as itemHTML, convert(money,@price) as price,
		convert(money,@salePrice) as salePrice, convert(money,@wholeSalePrice) as wholeSalePrice, 
		convert(bit,@isOnSale) as isOnSale, convert(varchar(255),@description) as description,
		convert(varchar(max),@shortCopy) as shortCopy, convert(varchar(max),@productCopy) as productCopy,
		@emptyGUID as homeCategory, @emptyGUID as homeAltCategory, convert(float,@weight) as weight, 
		convert(varchar(50),@quantifier) as quantifier, convert(varchar(50),@shortDescription) as shortDescription,
		convert(bit,@freeShipping) as freeShipping,convert(varchar(50),@formName) as formName,
		@emptyGUID as m, @emptyGUID as c, @emptyGUID as f, @emptyGUID as t, @emptyGUID as a, @emptyGUID as x, @emptyGUID as y,
		@emptyGUID as z, @emptyGUID as b, @emptyGUID as d,
		convert(varchar(max),@keywords) as keywords, convert(int,@searchPriority) as searchPriority,
		convert(money,@workCreditValue) as workCreditValue,convert(bit,@noTax) as noTax,convert(bit,@deleted) as deleted,
		convert(bit,@removeAfterPurchase) as removeAfterPurchase, convert(varchar(50),@parentItemNumber) as parentItemNumber,
		@emptyGUID swatchId,convert(bit,@allowPreorders) as allowPreorders,convert(int,@inventoryOperator) as inventoryOperator,
		convert(int,@inventoryDepletesOnFlagId) as inventoryDepletesOnFlagId, 
		convert(int,@inventoryRestockOnFlagId) as inventoryRestockOnFlagId,convert(int,@itemIsConsumedOnFlagId) as itemIsConsumedOnFlagId,
		convert(varchar(50),@revenueAccount) as revenueAccount, @emptyGUID as sizeId,convert(int,@ratio) as ratio, @emptyGUID as divisionId,
		convert(int,@highThreshold) as highThreshold, 
		convert(int,@expenseAccount) as expenseAccount, convert(int,@inventoryAccount) as inventoryAccount, convert(int,@COGSAccount) as COGSAccount, 
		convert(varchar(50),@SKU) as SKU, convert(int,@itemType) as itemType, convert(int,@averageCost) as averageCost, 
		null as VerCol
	end
	/* show the results to the user */
	select 
	itemNumber,
	displayPrice,
	reorderPoint,
	BOMOnly,
	itemHTML,
	price,
	salePrice,
	wholeSalePrice, 
	isOnSale,
	description,
	shortCopy,
	productCopy,
	weight,
	quantifier, 
	shortDescription, 
	freeShipping, 
	formName,
	keywords, 
	searchPriority, 
	workCreditValue, 
	noTax, 
	deleted, 
	removeAfterPurchase,
	parentItemNumber,
	allowPreorders, 
	inventoryOperator,
	inventoryRestockOnFlagId,
	itemIsConsumedOnFlagId,
	inventoryDepletesOnFlagId,
	revenueAccount,
	ratio,
	highThreshold,
	expenseAccount,
	inventoryAccount,
	COGSAccount,
	SKU,
	itemType,
	averageCost
	from items where itemNumber = convert(varchar(50),@itemNumber)
end
GO
/****** Object:  View [dbo].[inventorySnapshot]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[inventorySnapshot] as 
/* inventorySnapshot version 0.1.0 */
select t.itemNumber, i.shortDescription,
	case when ats+wip < i.reorderPoint then
		case when prebook > 0 then
			case when wip = 0 and ats = 0 then
				'URGENT REORDER'
			else
				'OVERSOLD'
			end
		else
			case when ats+wip = 0 then
				'OUT OF STOCK'
			else
				'REORDER'
			end
		end
	when ats+wip = 0 then
		'OUT OF STOCK'
	when prebook > wip+ats then
		'OVERSOLD'
	when ats < prebook then
		'INCOMING'
	when prebook > 0 then
		'UNALLOCATED'
	when ats-prebook > i.highThreshold then
		'OVERSTOCK'
	else
		'OK'
	end
as stockStatus,
i.reorderPoint,i.highThreshold, volume, prebook, wip, ats, consumed, -1 as VerCol
from itemonhandtemp t with (nolock)
inner join items i on t.itemNumber = i.itemNumber
GO
/****** Object:  StoredProcedure [dbo].[insertVTTransaction]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[insertVTTransaction] 
@amount money,
@cardNumber varchar(50),
@secNumber varchar(10),
@authResponseCode varchar(255),
@authResponse varchar(max),
@addedby int,
@provider varchar(50),
@request varchar(max),
@billToCompany varchar(100),
@billToFirstName varchar(100),
@billToLastName varchar(100),
@billToAddress1 varchar(100),
@billToAddress2 varchar(25),
@billToCity varchar(100),
@billToState varchar(100),
@billToZIP varchar(20),
@billToCountry varchar(100),
@shipToCompany varchar(100),
@shipToFirstName varchar(100),
@shipToLastName varchar(100),
@shipToAddress1 varchar(100),
@shipToAddress2 varchar(25),
@shipToCity varchar(100),
@shipToState varchar(100),
@shipToZIP varchar(20),
@shipToCountry varchar(50),
@expDate varchar(10),
@sessionId uniqueidentifier as
begin
	declare @newId uniqueidentifier = NEWID();
	insert into vtTransactions
	(vtTransactionID, transactionDate, amount, cardNumber, secNumber, authResponseCode, authResponse, addedby, provider, request, billToCompany, billToFirstName, billToLastName, billToAddress1, billToAddress2, billToCity, billToState, billToZIP, billToCountry, shipToCompany, shipToFirstName, shipToLastName, shipToAddress1, shipToAddress2, shipToCity, shipToState, shipToZIP, shipToCountry, expDate, sessionId)
	values
	(
	@newId,
	GETDATE(),
	@amount,
	@cardNumber,
	@secNumber,
	@authResponseCode,
	@authResponse,
	@addedby,
	@provider,
	@request,
	@billToCompany,
	@billToFirstName,
	@billToLastName,
	@billToAddress1,
	@billToAddress2,
	@billToCity,
	@billToState,
	@billToZIP,
	@billToCountry,
	@shipToCompany,
	@shipToFirstName,
	@shipToLastName,
	@shipToAddress1,
	@shipToAddress2,
	@shipToCity,
	@shipToState,
	@shipToZIP,
	@shipToCountry,
	@expDate,
	@sessionId)
	select @newId as newTransactionId
end
GO
/****** Object:  StoredProcedure [dbo].[insertUpdateSessionHash]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[insertUpdateSessionHash]
	/* insertUpdateSessionHash version 1.1 */
	(@userId int, @sessionId uniqueidentifier,@keyName varchar(max), @keyValue varchar(max)) as 
	begin
		if exists(select 0 from sessionHash where (userId = @userId or sessionId = @sessionId) and property = @keyValue) begin
			update sessionHash set value = @keyValue where 
			property = @keyName and (userId = @userId or sessionId = @sessionId)
		end else begin
			insert into sessionHash (sessionHashId, userId, sessionId, property, value, VerCol) values
			(NEWID(), @userId, @sessionId, @keyName, @keyValue, null);
		end
	end
GO
/****** Object:  StoredProcedure [dbo].[insertupdatecontact]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[insertupdatecontact](
	@CID varchar(255),
	@defaultContact varchar(255),
	@FirstName varchar(255),
	@LastName varchar(255),
	@Address1 varchar(255),
	@Address2 varchar(255),
	@City varchar(255),
	@State varchar(255),
	@ZIP varchar(255),
	@Country varchar(255),
	@HomePhone varchar(255),
	@WorkPhone varchar(255),
	@Email varchar(255),
	@SpecialInstructions varchar(255),
	@Comments varchar(255),
	@sendshipmentupdates varchar(255),
	@emailads varchar(255),
	@rate varchar(255),
	@Company varchar(255),
	@userid varchar(255),
	@sessionid varchar(255),
	@unique_siteID uniqueidentifier
)
as
begin
	declare @strExec varchar(4000)
	declare @strInCols varchar(4000)
	declare @existingCID uniqueidentifier
	set @strExec = ''
	set @strInCols = ''
	if exists(select contactid from contacts with(nolock) where contactid = @CID)
	begin
		if(not @defaultContact is null)
		begin
			SET @strExec = @strExec + 'defaultContact = '''+cast(dbo.cbit(@defaultContact) as varchar)+''','
		end
		if(not @FirstName is null)
		begin
			SET @strExec = @strExec + 'FirstName = '''+@FirstName+''','
		end
		if(not @LastName is null)
		begin
			SET @strExec = @strExec + 'LastName = '''+@LastName+''','
		end
		if(not @Address1 is null)
		begin
			SET @strExec = @strExec + 'Address1 = '''+@Address1+''','
		end
		if(not @Address2 is null)
		begin
			SET @strExec = @strExec + 'Address2 = '''+@Address2+''','
		end
		if(not @City is null)
		begin
			SET @strExec = @strExec + 'City = '''+@City+''','
		end
		if(not @State is null)
		begin
			SET @strExec = @strExec + 'State = '''+@State+''','
		end
		if(not @ZIP is null)
		begin
			SET @strExec = @strExec + 'ZIP = '''+@ZIP+''','
		end
		if(not @Country is null)
		begin
			SET @strExec = @strExec + 'Country = '''+@Country+''','
		end
		if(not @HomePhone is null)
		begin
			SET @strExec = @strExec + 'HomePhone = '''+@HomePhone+''','
		end
		if(not @WorkPhone is null)
		begin
			SET @strExec = @strExec + 'WorkPhone = '''+@WorkPhone+''','
		end
		if(not @Email is null)
		begin
			SET @strExec = @strExec + 'Email = '''+@Email+''','
		end
		if(not @SpecialInstructions is null)
		begin
			SET @strExec = @strExec + 'SpecialInstructions = '''+@SpecialInstructions+''','
		end
		if(not @Comments is null)
		begin
			SET @strExec = @strExec + 'Comments = '''+@Comments+''','
		end
		if(not @sendshipmentupdates is null)
		begin
			SET @strExec = @strExec + 'sendshipmentupdates = '''+cast(dbo.cbit(@sendshipmentupdates) as varchar)+''','
		end
		if(not @emailads is null)
		begin
			SET @strExec = @strExec + 'emailads = '''+cast(dbo.cbit(@emailads) as varchar)+''','
		end
		if(not @rate is null)
		begin
			SET @strExec = @strExec + 'rate = '''+@rate+''','
		end
		if(not @Company is null)
		begin
			SET @strExec = @strExec + 'Company = '''+@Company+''','
		end
		if(not @strExec is null)
		begin
			set @strExec = 'update contacts set userid = '+@userid+',sessionid = '''+@sessionid+''','+substring(@strExec,1,len(@strExec)-1)+' where contactid = '''+@CID+''''
			exec(@strExec)
		end
	end
	else
	begin
		if(not @defaultContact is null)
		begin
			SET @strInCols = @strInCols + 'defaultContact,'
			SET @strExec = @strExec + ''''+cast(dbo.cbit(@defaultContact) as varchar)+''','
		end
		if(not @FirstName is null)
		begin
			SET @strInCols = @strInCols + 'FirstName,'
			SET @strExec = @strExec + ''''+@FirstName+''','
		end
		if(not @LastName is null)
		begin
			SET @strInCols = @strInCols + 'LastName,'
			SET @strExec = @strExec + ''''+@LastName+''','
		end
		if(not @Address1 is null)
		begin
			SET @strInCols = @strInCols + 'Address1,'
			SET @strExec = @strExec + ''''+@Address1+''','
		end
		if(not @Address2 is null)
		begin
			SET @strInCols = @strInCols + 'Address2,'
			SET @strExec = @strExec + ''''+@Address2+''','
		end
		if(not @City is null)
		begin
			SET @strInCols = @strInCols + 'City,'
			SET @strExec = @strExec + ''''+@City+''','
		end
		if(not @State is null)
		begin
			SET @strInCols = @strInCols + 'State,'
			SET @strExec = @strExec + ''''+@State+''','
		end
		if(not @ZIP is null)
		begin
			SET @strInCols = @strInCols + 'ZIP,'
			SET @strExec = @strExec + ''''+@ZIP+''','
		end
		if(not @Country is null)
		begin
			SET @strInCols = @strInCols + 'Country,'
			SET @strExec = @strExec + ''''+@Country+''','
		end
		if(not @HomePhone is null)
		begin
			SET @strInCols = @strInCols + 'HomePhone,'
			SET @strExec = @strExec + ''''+@HomePhone+''','
		end
		if(not @WorkPhone is null)
		begin
			SET @strInCols = @strInCols + 'WorkPhone,'
			SET @strExec = @strExec + ''''+@WorkPhone+''','
		end
		if(not @Email is null)
		begin
			SET @strInCols = @strInCols + 'Email,'
			SET @strExec = @strExec + ''''+@Email+''','
		end
		if(not @SpecialInstructions is null)
		begin
			SET @strInCols = @strInCols + 'SpecialInstructions,'
			SET @strExec = @strExec + ''''+@SpecialInstructions+''','
		end
		if(not @Comments is null)
		begin
			SET @strInCols = @strInCols + 'Comments,'
			SET @strExec = @strExec + ''''+@Comments+''','
		end
		if(not @sendshipmentupdates is null)
		begin
			SET @strInCols = @strInCols + 'sendshipmentupdates,'
			SET @strExec = @strExec + ''''+cast(dbo.cbit(@sendshipmentupdates) as varchar)+''','
		end
		if(not @emailads is null)
		begin
			SET @strInCols = @strInCols + 'emailads,'
			SET @strExec = @strExec + ''''+cast(dbo.cbit(@emailads) as varchar)+''','
		end
		if(not @rate is null)
		begin
			SET @strInCols = @strInCols + 'rate,'
			SET @strExec = @strExec + ''''+@rate+''','
		end
		else
		begin
			SET @strInCols = @strInCols + 'rate,'
			SET @strExec = @strExec + ''''+(select top 1 cast(default_rateID as varchar(255)) from site_configuration)+''','
		end
		if(not @Company is null)
		begin
			SET @strInCols = @strInCols + 'Company,'
			SET @strExec = @strExec + ''''+@Company+''','
		end
		if(not @strExec is null)
		begin
			set @strExec = 'insert into contacts (datecreated,contactid,userid,sessionid,'+substring(@strInCols,1,len(@strInCols)-1)+') values '+
			' (getDate(),'''+@CID+''','+@userid+','''+@sessionid+''','+substring(@strExec,1,len(@strExec)-1)+')'
			exec(@strExec)
		end
	end
end
GO
/****** Object:  StoredProcedure [dbo].[insertReview]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[insertReview](@reviewId uniqueidentifier,@userId int,@rating int,@message varchar(max),@refId varchar(50),
	@archive bit,@addDate datetime,@refType varchar(50))
as begin
	insert into reviews (reviewId,userId,rating,message,refId,archive,addDate,refType) values
				(@reviewId,@userId,@rating,@message,@refId,@archive,@addDate,@refType)
end
GO
/****** Object:  StoredProcedure [dbo].[insertReply]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[insertReply] (
@replyId uniqueidentifier, @email varchar(50), @subject varchar(50), @rating int,
@userId int, @comment varchar(max), @addedOn datetime, @parentId uniqueidentifier,
@refrence varchar(50), @disabled bit, @approves int, @disapproves int,
@flaggedInappropriate bit
) as begin
	insert into replies
	select @replyId, @email, @subject, @rating, @userId, @comment, @addedOn, @parentId, 
	@refrence, @disabled, @approves, @disapproves, @flaggedInappropriate, 1 as flaggedOk, null as VerCol
end
GO
/****** Object:  StoredProcedure [dbo].[insertPaymentMethod]    Script Date: 05/30/2011 18:11:59 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[insertPaymentMethod] 
@paymentMethodId uniqueidentifier,
@paymentType varchar(50),
@cardName varchar(50),
@cardType varchar(50),
@cardNumber varchar(50),
@expMonth varchar(50),
@expYear varchar(50),
@secNumber varchar(50),
@userId int,
@sessionId uniqueidentifier,
@addressId uniqueidentifier,
@routingNumber varchar(50),
@checkNumber varchar(50),
@bankAccountNumber varchar(50),
@payPalEmailAddress varchar(255),
@swift varchar(50),
@bankName varchar(50),
@routingTransitNumber varchar(50),
@cash bit,
@notes varchar(max),
@termId int,
@reference varchar(max),
@amount money,
@promiseToPay bit,
@orderIds hashtable readonly
as
/* insertPaymentMethod version 0.1.3 */
declare @emptyGUID uniqueidentifier = '00000000-0000-0000-0000-000000000000';
insert into paymentMethods 
(paymentMethodId, paymentType, cardName, cardType, cardNumber, expMonth, expYear, secNumber, userId, sessionId, 
addressId, routingNumber, checkNumber, bankAccountNumber, payPalEmailAddress, swift, bankName, 
routingTransitNumber, cash, notes, amount, generalLedgerInsertId, promiseToPay, paymentRefId, VerCol)
values
(@paymentMethodId, @paymentType, @cardName, @cardType, @cardNumber, @expMonth, @expYear, @secNumber, @userId, @sessionId, 
@addressId, @routingNumber, @checkNumber, @bankAccountNumber, @payPalEmailAddress, @swift, @bankName,
@routingTransitNumber, @cash, @notes, @amount, @emptyGUID, @promiseToPay, -1, null)

/*
	only enter this record if the record does not exist.
	this record will not exist during the inital entry phase.
	when accrued orders are paid off this record will be entred 
	by the commerce.makePayment.updateOrders function
	called internally by the many public payment methods.
*/
if not exists(select 0 from paymentMethodsDetail pd with (nolock) inner join @orderIds oids on cast(oids.keyValue as int) = pd.orderId ) begin
	insert into paymentMethodsDetail
	select NEWID(),@paymentMethodId,cast(oids.keyValue as int) as orderId,@amount
	from @orderIds oids
end
GO
/****** Object:  StoredProcedure [dbo].[insertOrderLineForm]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[insertOrderLineForm] @cartId uniqueidentifier, @sourceCode varchar(max), @formName varchar(50) as
if exists(select cartID from order_line_forms where cartID = @cartid) begin delete from order_line_forms where cartID = @cartid end
insert into order_line_forms 
(cartID,sourceCode,formName)
values 
(@cartid, @sourceCode, @formName)
GO
/****** Object:  View [dbo].[orderPrintForms]    Script Date: 08/17/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[orderPrintForms] as
select o.userId, o.orderId, o.orderNumber, c.shipmentId, c.shipmentNumber, o.sessionId, packingSlip, quote, invoice
from orders o with (nolock)
inner join cart c with (nolock) on c.orderId = o.orderId
inner join users u with (nolock) on o.userId = u.userId
GO
/****** Object:  View [dbo].[orderPayments]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[orderPayments] as 
/* orderPayments version 0.1.0 */
select 
p.paymentMethodId, pd.amount, paymentType, p.amount as paymentTotal, cardName, cardType, cardNumber, expMonth, expYear,
secNumber, o.userId, o.sessionId, addressId, routingNumber, checkNumber, 
bankAccountNumber, payPalEmailAddress, swift, bankName, routingTransitNumber, cash, notes, o.orderId, o.termId,
DATEDIFF(d,DATEADD(d,t.termDays*-1,GETDATE()),GETDATE()) as dueInDays,
p.VerCol
from paymentMethods p with (nolock)
inner join paymentMethodsDetail pd on p.paymentMethodId = pd.paymentMethodId and p.promiseToPay = 0
inner join orders o with (nolock) on o.orderId = pd.orderId
inner join terms t on o.termId = t.termId
GO
/****** Object:  StoredProcedure [dbo].[itemStock]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[itemStock] (@itemnumber char(50),@qty int = 1) as
 SET NOCOUNT ON
 DECLARE @lvl int
 DECLARE @line char(50)
 DECLARE @itemQty int
 CREATE TABLE #stack (itemnumber char(50), lvl int,qty int)	--Create stack.
 CREATE TABLE #out (itemnumber char(50), lvl int,qty int,itemQty int,kitStock int)
 INSERT INTO #stack VALUES (@itemnumber, 1,@qty)	--insert this node.
 SELECT @lvl = 1				
 WHILE @lvl > 0					--DESC
	BEGIN
	    IF EXISTS (SELECT * FROM #stack WHERE lvl = @lvl)
	        BEGIN
	            SELECT @itemnumber = itemnumber,@qty = qty	--Get this node.
	            FROM #stack
	            WHERE lvl = @lvl
	            SET @line = @itemnumber --@lvl.
				SET @itemQty = (select sum(qtyOnHand) from dbo.vendorItems with (nolock) where itemnumber = @itemnumber and qtyOnHand >= 1)
				IF(@itemQty is null)
				BEGIN
					SET @itemQty = 0
				END
				insert #out (itemnumber,lvl,qty,itemQty,kitStock) values (@line,@lvl,@qty,@itemQty,@itemQty/@qty) -- Insert into #out.
	            DELETE FROM #stack
	            WHERE lvl = @lvl
	                AND itemnumber = @itemnumber	--Remove this node from #stack.
	            INSERT #stack		--Insert the children of this node into #stack.
	                SELECT subitemnumber, @lvl + 1,qty*@qty
	                FROM itemdetail with (nolock)
	                WHERE itemnumber = @itemnumber
	            IF @@ROWCOUNT > 0		--If the previous statement added one or more nodes, go down for its first child.
                        SELECT @lvl = @lvl + 1	--If no nodes are added, check its sibling nodes.
		END
    	    ELSE
	      	SELECT @lvl = @lvl - 1		--Back to the level immediately above.
       END 
-- select populated stack
if exists(select * from #out where lvl > 1)
BEGIN
	select min(kitStock) as qty, itemnumber from (
		select * from #out where lvl > 1
	) f group by itemnumber order by min(kitStock) asc
END
ELSE
BEGIN
	select min(kitStock) as qty, itemnumber from (
		select * from #out
	) f group by itemnumber order by min(kitStock) asc
END
GO
/****** Object:  View [dbo].[item_list]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE view [dbo].[item_list]
as
select
i.itemNumber, 
i.displayPrice, 
i.price, 
i.salePrice, 
i.wholeSalePrice, 
i.isOnSale, 
i.description, 
i.shortCopy,
case when a.filename is null then '' else rtrim(a.filename) end as packingSlipImage,
case when b.filename is null then '' else rtrim(b.filename) end as auxillaryImage,
case when c.filename is null then '' else rtrim(c.filename) end as cartImage,
case when d.filename is null then '' else rtrim(d.filename) end as detailImage,
case when f.filename is null then '' else rtrim(f.filename) end as fullSizeImage,
case when m.filename is null then '' else rtrim(m.filename) end as listingImage,
case when y.filename is null then '' else rtrim(y.filename) end as listing2Image,
case when z.filename is null then '' else rtrim(z.filename) end as listing3Image,
case when m.unique_siteId is null then '00000000-0000-0000-0000-000000000000' else m.unique_siteId end as unique_siteId,
productCopy, 
formName,
itemHTML as HTML,
i.reorderPoint, 
BOMOnly,
homeCategory, 
homeAltCategory, 
weight,
quantifier,
shortDescription,
freeShipping,
keywords, 
searchPriority, 
workCreditValue, 
noTax, 
deleted, 
removeAfterPurchase, 
parentItemNumber, 
swatchId, 
allowPreorders, 
inventoryOperator,
inventoryDepletesOnFlagId,
inventoryRestockOnFlagId,
itemIsConsumedOnFlagId,
revenueAccount,
sizeId,
ratio,
divisionId
from items i
left join ImagingDetail m with (nolock) on m.itemnumber = i.itemnumber and i.m = m.ImagingID and m.locationType = 'm'
left join ImagingDetail y with (nolock) on y.itemnumber = i.itemnumber and i.y = y.ImagingID and y.locationType = 'y' and m.unique_siteID = y.unique_siteID
left join ImagingDetail z with (nolock) on z.itemnumber = i.itemnumber and i.z = z.ImagingID and z.locationType = 'z' and m.unique_siteID = z.unique_siteID
left join ImagingDetail b with (nolock) on b.itemnumber = i.itemnumber and i.b = b.ImagingID and b.locationType = 'b' and m.unique_siteID = b.unique_siteID
left join ImagingDetail c with (nolock) on c.itemnumber = i.itemnumber and i.c = c.ImagingID and c.locationType = 'c' and m.unique_siteID = c.unique_siteID
left join ImagingDetail d with (nolock) on d.itemnumber = i.itemnumber and i.d = d.ImagingID and d.locationType = 'd' and m.unique_siteID = d.unique_siteID
left join ImagingDetail f with (nolock) on f.itemnumber = i.itemnumber and i.f = f.ImagingID and f.locationType = 'f' and m.unique_siteID = f.unique_siteID
left join ImagingDetail a with (nolock) on a.itemnumber = i.itemnumber and i.a = a.ImagingID and a.locationType = 'a' and m.unique_siteID = a.unique_siteID
GO
/****** Object:  StoredProcedure [dbo].[item_detail]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[item_detail](
@userid int,
@wholesale int,
@itemnumber varchar(50),
@siteid uniqueidentifier
)
as
SET NOCOUNT ON

DECLARE @stock table(qty int, itemnumber varchar(50))
DECLARE @qty int
DECLARE @nextin datetime
DECLARE @execStr nvarchar(100)
SET @execStr = 'dbo.itemStock '''+replace(@itemnumber,'''','''''')+''' '
insert into @stock EXEC sp_executesql @execStr
SET @qty = (select top 1 qty from @stock)
SET @nextin = (select top 1 estimatedRecieveDate from vendorItems where itemnumber = @itemnumber and qtyOrdered > 0 order by estimatedRecieveDate asc)
select
i.Itemnumber,
i.displayprice, 
i.itemHTML,
@qty Quantity,
case when not p.price is null then p.price 
	when @wholesale = 1 then i.wholesalePrice
	when i.isonsale = 1 then i.salePrice
	else i.price
	end as user_price,
i.Price,
i.SalePrice,
i.WholeSalePrice,
i.IsOnSale,
i.Description,
i.ShortCopy,
i.ProductCopy,
i.HomeCategory,
i.Weight,
i.quantifier,
i.shortDescription,
i.freeShipping,
i.formName,
rtrim(m.filename) as m_filePath,
rtrim(c.filename) as c_filePath,
rtrim(f.filename) as f_filePath,
rtrim(t.filename) as t_filePath,
rtrim(a.filename) as a_filePath,
rtrim(x.filename) as x_filePath,
rtrim(y.filename) as y_filePath,
rtrim(z.filename) as z_filePath,
rtrim(b.filename) as b_filePath,
rtrim(d.filename) as d_filePath,
@nextin as nextin,
s.price as siteprice,
i.swatchid,
i.allowPreorders,
h.volume,
h.prebook,
h.wip,
h.ats,
i.HomeAltCategory
from items i with (nolock)
left join ImagingDetail m with (nolock) on m.itemnumber = i.itemnumber and i.m = m.ImagingID and m.locationType = 'm' and m.unique_siteID = @siteid
left join ImagingDetail c with (nolock) on c.itemnumber = i.itemnumber and i.c = c.ImagingID and c.locationType = 'c' and c.unique_siteID = @siteid
left join ImagingDetail f with (nolock) on f.itemnumber = i.itemnumber and i.m = f.ImagingID and f.locationType = 'f' and f.unique_siteID = @siteid
left join ImagingDetail t with (nolock) on t.itemnumber = i.itemnumber and i.m = t.ImagingID and t.locationType = 't' and t.unique_siteID = @siteid
left join ImagingDetail a with (nolock) on a.itemnumber = i.itemnumber and i.m = a.ImagingID and a.locationType = 'a' and a.unique_siteID = @siteid
left join ImagingDetail x with (nolock) on x.itemnumber = i.itemnumber and i.m = x.ImagingID and x.locationType = 'x' and x.unique_siteID = @siteid
left join ImagingDetail y with (nolock) on y.itemnumber = i.itemnumber and i.m = y.ImagingID and y.locationType = 'y' and y.unique_siteID = @siteid
left join ImagingDetail z with (nolock) on z.itemnumber = i.itemnumber and i.m = z.ImagingID and z.locationType = 'z' and z.unique_siteID = @siteid
left join ImagingDetail b with (nolock) on b.itemnumber = i.itemnumber and i.m = b.ImagingID and b.locationType = 'b' and b.unique_siteID = @siteid
left join ImagingDetail d with (nolock) on d.itemnumber = i.itemnumber and i.m = d.ImagingID and d.locationType = 'd' and d.unique_siteID = @siteid
left join userPriceList p with (nolock) on p.itemnumber = i.itemnumber and userID = @userid and getDate() between fromDate and toDate
left join site_prices s with (nolock) on s.itemnumber = i.itemnumber and s.unique_siteID = @siteid
left join itemOnHandTemp h with (nolock) on h.itemnumber = i.itemnumber
where i.itemnumber = @itemnumber
SET NOCOUNT OFF
GO
/****** Object:  StoredProcedure [dbo].[insertCategory]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[insertCategory](
@categoryName varchar(50),
@itemNumber varchar(50)
) as
begin
	declare @categoryId uniqueidentifier = newId();
	declare @categoryDetailId uniqueidentifier = newId();
	if( not exists(select 0 from categories where category = @categoryName) ) begin
		insert into categories (categoryId, category, VerCol) values (@categoryId, @categoryName, null)
		print 'create category ' +@categoryName
	end else begin
		set @categoryId = (select categoryId from categories where category = @categoryName)
		print 'existing category ' +@categoryName
	end
	if(exists(select 0 from items where itemNumber = @itemNumber))begin/* Add an item to a category */
		if(not exists(select 0 from categoryDetail where itemNumber = @itemNumber and categoryId = @categoryId)) begin
			insert into categoryDetail (categoryDetailId, categoryId, itemNumber, listOrder, childCategoryId, VerCol)
			values (@categoryDetailId,@categoryId,@itemNumber,0,'00000000-0000-0000-0000-000000000000',null)
			print 'add '+@categoryName+' to category ' +cast(@categoryId as varchar(50))
		end
	end	else if(exists(select 0 from categories where category = @itemNumber)) begin /* Add a category to a category */
		declare @childCategoryId uniqueidentifier = (select categoryId from categories where category = @itemNumber);
		if(not exists(select 0 from categoryDetail where childCategoryId = @childCategoryId and categoryId = @categoryId)) begin
			insert into categoryDetail (categoryDetailId, categoryId, itemNumber, listOrder, childCategoryId, VerCol)
			values (@categoryDetailId,@categoryId,'',0,@childCategoryId,null)
			print 'add '+cast(@childCategoryId as varchar(50))+' to category ' +cast(@categoryId as varchar(50))
		end
	end
	print 'show categoryDetailId '+cast(@categoryDetailId as varchar(50))
	select category, itemNumber, listOrder, childCategoryId, categories.categoryId, categoryDetailId from
	categoryDetail
	inner join categories on categories.categoryId = categoryDetail.categoryId
	where categoryDetail.categoryId = @categoryId and (itemNumber = @itemNumber or childCategoryId = @childCategoryId)
end
GO
/****** Object:  StoredProcedure [dbo].[logoff]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[logoff](@sessionId uniqueidentifier) as 
begin
	update visitors set userid = -1 where sessionid = @sessionId;
	delete from cart where sessionid = @sessionId;
end
GO
/****** Object:  View [dbo].[shortUserList]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[shortUserList] as
/* shortUserList version 0.1.0 */
select userId, handle, email, accountTypes.accountType, -1 as VerCol
from users with (nolock)
inner join accountTypes with (nolock) on accountTypes.accountTypeId = users.accountType
GO
/****** Object:  View [dbo].[shortShippingRates]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[shortShippingRates] as
select s.rate as rateId, s.shippingName as name, -1 as VerCol from shippingType s
GO
/****** Object:  View [dbo].[orderList]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[orderList] as 
select orderId, userId, handle, termName, status, 
case when not owed = 0 then
	case when dueInDays > 0 then
		'DUE IN '+CAST(dueInDays as varchar(50))
	when dueInDays < 0 then
		'OVERDUE BY '+CAST(dueInDays as varchar(50))
	end
else
	'PAID'
end as paymentStatus, orderNumber, amount, paid, owed, orderDate, deliverBy, lastEventDate as statusChangedOn, dueInDays, -1 as VerCol
from (
	select o.orderId, u.userId, u.handle, orderNumber, grandTotal as amount, o.paid, grandTotal-o.paid as owed, o.orderDate, o.deliverBy, 
	case when ob.addTime is null then o.orderDate else ob.addTime end as lastEventDate,
	f.flagTypeName as status,datediff(d,dateadd(d,t.termDays,o.orderDate),GETDATE())*-1 as dueInDays, t.termName
	from orders o
	inner join users u on u.userId = o.userId
	inner join serial_order so on so.orderId = o.orderId
	inner join terms t on t.termId = o.termId
	inner join flagTypes f on f.flagTypeId = so.lastFlagStatus
	left join objectFlags ob on ob.flagId = so.lastFlagId
) f
GO
/****** Object:  View [dbo].[orderHeader]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[orderHeader] as
select o.orderId, orderDate, grandTotal, taxTotal, subTotal, shippingTotal, manifest, 
purchaseOrder, discount, comment, closed, canceled, t.termName as terms, r.userId as accountNumber, handle as accountName,
orderNumber, readyForExport, recalculatedOn, soldBy, requisitionedBy, approvedBy, deliverBy, vendor_accountNo,
r.FOB, discountPct, discountCode, r.exported as exported,
avgTaxRate, g.friendlySiteName as siteName, g.siteaddress as siteAddress, f.flagTypeName as status,f.flagTypeId as statusId,
b.firstName as billToFirstName, b.lastName as billToLastName, 
b.address1 as billToAddress1, b.address2 as billToAddress2, b.city as billToCity, b.state as billToState, b.zip as billToZip, b.country as billToCountry, 
b.homePhone as billToHomePhone, b.workPhone as billToWorkPhone, b.email as billToEmail, b.specialInstructions as billToSpecialInstructions,
b.sendShipmentUpdates as billToSendShipmentUpdates, b.comments as billToComments, 
b.emailAds as billToEmailAds, b.company as billToCompany, b.dateCreated as billToDateCreated, b.taxRate as billToTaxRate,
s.firstName as shipToFirstName, s.lastName as shipToLastName, 
s.address1 as shipToAddress1, s.address2 as shipToAddress2, s.city as shipToCity, s.state as shipToState, s.zip as shipToZip, s.country as shipToCountry, 
s.homePhone as shipToHomePhone, s.workPhone as shipToWorkPhone, s.email as shipToEmail, s.specialInstructions as shipToSpecialInstructions,
s.sendShipmentUpdates as shipToSendShipmentUpdates, s.comments as shipToComments, 
s.emailAds as shipToEmailAds, s.company as shipToCompany, s.dateCreated as shipToDateCreated, 
s.shippingQuote as shipToShippingQuote, s.weight as shipToWeight, s.taxRate as shipToTaxRate, p.shippingName
from serial_order o
inner join orders r on r.orderId = o.orderId
inner join addresses b on r.billToAddressId = b.addressId
inner join addresses s on o.orderId = s.orderId and not (r.billToAddressId = s.addressId)
inner join flagTypes f on f.flagTypeId = o.lastFlagStatus
inner join terms t on t.termId = r.termId
inner join users u on u.userId = r.userId
inner join site_configuration g on g.unique_siteId = r.unique_siteId
inner join shippingType p on p.rate = s.rate;
GO
/****** Object:  View [dbo].[prebook]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[prebook] as
/* prebook version 0.1.0 */
select k.itemNumber,i.shortDescription,t.prebook,t.ats,t.wip,t.volume,k.qty,o.orderNumber,
shipmentNumber,serialNumber,lineNumber,orderDate,manifest,purchaseOrder,
closed,canceled,u.userId,u.handle,o.deliverBy,parentItemNumber,
d.divisionName as division, s.size as size, w.code as swatch, o.orderId, c.cartId, -1 as VerCol
from kitAllocation k with (nolock)
inner join cart c with (nolock) on c.cartId = k.cartId 
inner join orders o with (nolock) on o.orderId = c.orderId
inner join users u with (nolock) on u.userId = o.userId and u.accountType = 0
inner join items i with (nolock) on k.itemNumber = i.itemNumber
inner join itemOnHandTemp t with (nolock) on t.itemNumber = i.itemNumber
inner join sizes s with (nolock) on s.sizeId = i.sizeId
inner join swatches w with (nolock) on w.swatchId = i.swatchId
inner join divisions d with (nolock) on d.divisionId = i.divisionId
where k.vendorItemKitAssignmentId = '{00000000-0000-0000-0000-000000000000}'
GO
/****** Object:  StoredProcedure [dbo].[postPaymentsToGeneralLedger]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[postPaymentsToGeneralLedger](
	@paymentMethodIds hashTable READONLY,
	@unique_site_id uniqueidentifier,
	@postingDate datetime,
	@referenceNotes varchar(max)
) as
begin

	/* postPaymentsToGeneralLedger version 0.1.0
	
		return multiple batches:
		1: errorId,desc
		2: general ledger view
		3: raw GL
		
		this procedure looks at the list of paymentMethodIds passed as a hashTable
		makes a select statement that should be equal to the amount of the payment.
		
		If there is a difference there is somthing wrong with the payment and it needs
		to be re-entered? - these payments won't be added to the GL, but rather
		an error will be returned saying they need to be re-entered.
		
		payments in balance will be added to the GL.
		
		the payments will be summed by their GL sub ledger account number
		and posted to said account (insert into generalLedger).  The payments
		will be referenced using the table generalLedgerDetail, which contains
		id for the generalLedger table and a id for each paymentMethodId.  This will create
		a list of payments for this GL entry.
				

		
	*/

	declare @emptyGUID uniqueidentifier = '{00000000-0000-0000-0000-000000000000}'
	declare @shippingGLAccount int;
	declare @taxGLAccount int;
	declare @discountGLAccount int;
	declare @accountsReceivableGLAccount int;
	declare @accountsPayableGLAccount int;
	declare @checkingGLAccount int;
	declare @GLInsertId uniqueidentifier = NEWID();
	
		/* sample general ledger */
	declare @generalLedger table(generalLedgerId uniqueidentifier, refId varchar(255), refType int, creditRecord bit, 
	debitRecord bit, amount money, userId int, addDate datetime, reference varchar(max), generalLedgerInsertId uniqueidentifier)
	
	/* get special accounts from site_configuration */
	select @checkingGLAccount = checkingGLAccount, @shippingGLAccount = shippingGLAccount,@taxGLAccount = taxGLAccount,
	@discountGLAccount = discountGLAccount, @accountsReceivableGLAccount = accountsReceivableGLAccount,
	@accountsPayableGLAccount = accountsPayableGLAccount
	from dbo.site_configuration with (nolock) where unique_siteID = @unique_site_id;
	
	/* ---------------------------------------- GENERAL LEDGER INSERT ROWS LEFT SIDE (Cr.) ---------------------------------------- */
	
	insert into @generalLedger
	select NEWID() as generalLedgerId,
	p.paymentMethodId as refId,
	9 as refType,
	case when u.accountType = 0 then 1 else 0 end as creditRecord,
	case when u.accountType = 0 then 0 else 1 end as debitRecord,
	amount as amount,
	@checkingGLAccount as userId,
	@postingDate, @referenceNotes as reference,
	@GLInsertId as generalLedgerInsertId
	from @paymentMethodIds pids
	inner join paymentMethods p with (nolock) on p.paymentMethodId = cast(pids.keyValue as uniqueidentifier)
	inner join users u with (nolock) on u.userId = p.userid
	where p.generalLedgerInsertId = @emptyGUID and amount > 0
	
	

	/* ---------------------------------------- GENERAL LEDGER INSERT ROWS RIGHT SIDE (Dr.)---------------------------------------- */
	
	insert into @generalLedger
	select NEWID() as generalLedgerId,
	p.paymentMethodId as refId,
	8 as refType,
	case when u.accountType = 0 then 0 else 1 end as creditRecord,
	case when u.accountType = 0 then 1 else 0 end as debitRecord,
	amount as amount,
	p.userId, @postingDate, @referenceNotes as reference, @GLInsertId as generalLedgerInsertId
	from @paymentMethodIds pids
	inner join paymentMethods p with (nolock) on p.paymentMethodId = cast(pids.keyValue as uniqueidentifier)
	inner join users u with (nolock) on u.userId = p.userid
	where p.generalLedgerInsertId = @emptyGUID and amount > 0
	
	
	/* ---------------------------------------- WRITE VALIDATION (prevent duplicate inserts) ---------------------------------------- */
	
	/* update all related payment methods with the generalLedgerId that was inserted
	this way we can tell what was inserted and what was not inserted. */
	update paymentMethods set generalLedgerInsertId = @GLInsertId
	where paymentMethodId in (select cast(keyValue as uniqueidentifier) from @paymentMethodIds)
	
	/* does the sum of the Cr.s match the sum of the Dr.s? */
	/* sum Cr.s */
	declare @crTotal money = (select SUM(amount) from @generalLedger g where g.creditRecord = 1 and g.debitRecord = 0);
	declare @drTotal money = (select SUM(amount) from @generalLedger g where g.creditRecord = 0 and g.debitRecord = 1);
	
	if @crTotal = @drTotal begin
		print 'GL Entries are in balance.  Do the insert.';
		/* do actual inserts */
		insert into generalLedger
		select generalLedgerId, refId, refType, creditRecord, debitRecord, amount, userId, addDate, reference, generalLedgerInsertId
		from @generalLedger
		
		/* BATCH 1: show error code */
		select 0 as errorId, '' as errorDescription,@drTotal as drTotal, @crTotal as crTotal
		
		/* BATCH 2:  show human readable result based on table vars */
		select userId, handle, addDate, sum(drAmount) as debit, sum(crAmount) as credit, reference as notes, -1 as VerCol
		from (
			select generalLedgerId,u.userId,addDate,
			case when creditRecord = 0 and debitRecord = 1 then
				0
			else
				amount
			end as drAmount, 
			case when debitRecord = 0 and creditRecord = 1 then
				0 
			else
				amount
			end
			as crAmount, handle, reference
			from @generalLedger g
			inner join users u with (nolock) on u.userId = g.userId
		) f
		group by userId, handle, addDate, reference
		order by sum(drAmount) asc

	end else begin
		if @crTotal is null begin
			set @crTotal = 0
		end
		if @drTotal is null begin
			set @drTotal = 0
		end
		print 'GL Entries are not in balance.  Do not insert.';
		/* BATCH 1: show error code */
		select -1 as errorId, 'GL Entries are not in balance.  Recalculate selected orders and try again.' as errorDescription,
		@drTotal as drTotal, @crTotal as crTotal
		
		/* BATCH 2: show a bs preview entry to prevent read errors */
		select -1 as userId, '' as handle, cast('1/1/1900' as datetime) as addDate,
		cast(0 as money) as debit, cast(0 as money) as credit, '' as notes, -1 as VerCol
		
		/* BATCH 3: show raw GL entries */
		select generalLedgerId, creditRecord, debitRecord, amount, userId, addDate, reference,
		 generalLedgerInsertId from @generalLedger
		
	end
end
GO
/****** Object:  StoredProcedure [dbo].[postOrdersToGeneralLedger]    Script Date: 05/30/2011 18:12:55 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[postOrdersToGeneralLedger](
	@orderIds hashTable READONLY,
	@unique_site_id uniqueidentifier,
	@postingDate datetime,
	@referenceNotes varchar(max)
) as
begin
	/* postOrdersToGeneralLedger version 0.1.0
	
		return multiple batches:
		1: errorId,desc
		2: general ledger view
		3: raw GL
		
		this procedure looks at the list of orderIds passed as a hashTable
		makes a select statement that should be equal to the grand total of the order.
		
		If there is a difference there is somthing wrong with the order and it needs
		to be recalculated - these orders won't be added to the GL, but rather
		an error will be returned saying they need to be recacluated.
		
		orders in balance will be added to the GL.
		
		the orders will be summed by their GL revenue account number
		and posted to said account (insert into generalLedger).  The orders
		will be referenced using the table generalLedgerDetail, which contains
		id for the generalLedger table and a id for each order.  This will create
		a list of the order for this GL entry.
				
		
	*/
	/* get acct numbers */
	
	/* has this order has CR postings already? */
	
	
	/* get all the kit lines for all related orders and group them into
	their respective GL accounts */
	declare @emptyGUID uniqueidentifier = '{00000000-0000-0000-0000-000000000000}'
	declare @shippingGLAccount int;
	declare @taxGLAccount int;
	declare @discountGLAccount int;
	declare @accountsReceivableGLAccount int;
	declare @accountsPayableGLAccount int;
	declare @checkingGLAccount int;
	declare @newGeneralLedgerInsertId uniqueidentifier = NEWID();

	
	/* sample general ledger */
	declare @generalLedger table(generalLedgerId uniqueidentifier, refId varchar(255), refType int, creditRecord bit, 
	debitRecord bit, amount money, userId int, addDate datetime, reference varchar(max), generalLedgerInsertId uniqueidentifier)
	
	/* get special accounts from site_configuration */
	select @checkingGLAccount = checkingGLAccount, @shippingGLAccount = shippingGLAccount,@taxGLAccount = taxGLAccount,
	@discountGLAccount = discountGLAccount, @accountsReceivableGLAccount = accountsReceivableGLAccount,
	@accountsPayableGLAccount = accountsPayableGLAccount
	from dbo.site_configuration with (nolock) where unique_siteID = @unique_site_id;
	
	/* ---------------------------------------- GENERAL LEDGER INSERT ROWS LEFT SIDE (Cr.) ---------------------------------------- */
	
	/* order are either prepaid 'sales reciepts' or they are 'promises to pay'
	and entered into the 'pendingPayment' GL account. */
	
	
	/* AP accounts don't get prepaid so there is no chance that an AP account will show up here */
	
	/* 'sales reciept' header payment group goes directly into cash/bank account */
	insert into @generalLedger
	select NEWID() as generalLedgerId,p.paymentMethodId as refId, 5 as refType, 1 as creditRecord , 0 as debitRecord, p.amount,
	j.userId,/*<--- Account to add the DR to */
	@postingDate, @referenceNotes as reference, @newGeneralLedgerInsertId as generalLedgerInsertId
	from dbo.paymentMethods p with (nolock)
	inner join dbo.paymentMethodsDetail pd with (nolock) on p.paymentMethodId = pd.paymentMethodId
	inner join (
		select o.orderId, o.userId
		from orders o with (nolock)
		inner join @orderIds oid on o.orderId = oid.keyValue and o.termId in (select termId from terms with (nolock) where accrued = 0)
		where o.generalLedgerInsertId = @emptyGUID
	) j on j.orderId = pd.orderId
	
	/* 'recieveable' header payment group goes into Accounts Receivable GL account */
	insert into @generalLedger
	select NEWID() as generalLedgerId,p.paymentMethodId as refId, 6 as refType, 1 as creditRecord, 0 as debitRecord, p.amount as amount, 
	j.userId,/*<--- Account to add the DR to */
	@postingDate, @referenceNotes as reference, @newGeneralLedgerInsertId as generalLedgerInsertId
	from dbo.paymentMethods p with (nolock)
	inner join dbo.paymentMethodsDetail pd with (nolock) on p.paymentMethodId = pd.paymentMethodId and p.promiseToPay = 1
	inner join (
		select o.orderId, o.userId, grandTotal, u.accountType
		from orders o with (nolock)
		inner join users u with (nolock) on u.userId = o.userId
		inner join @orderIds oid on o.orderId = oid.keyValue and o.termId in (select termId from terms with (nolock) where accrued = 1)
		where o.generalLedgerInsertId = @emptyGUID
	) j on j.orderId = pd.orderId
	
	/* check if __inventory__ is allocated, if it is insert Dr. into item's cost of good sold account, but not for purchase orders */
	insert into @generalLedger
	select NEWID() as generalLedgerId, kitAllocationId as refId, 7 as refType, 1 as creditRecord, 0 as debitRecord, amount,
	inventoryAccount as userId,
	@postingDate as postingDate, @referenceNotes as reference, @newGeneralLedgerInsertId as generalLedgerInsertId
	from (
		select ik.kitAllocationId,ik.qty*(k.valueCostTotal+k.noTaxValueCostTotal) as amount, i.COGSAccount as inventoryAccount
		from @orderIds a
		inner join cart ic with (nolock) on ic.orderId = a.keyValue
		inner join kitAllocation ik with (nolock)
			on ic.cartId = ik.cartId and ik.generalLedgerId = @emptyGUID
			and ik.inventoryItem = 1
		inner join items i with (nolock) on ik.itemNumber = i.itemNumber
		inner join orders o with (nolock) on o.orderId = ic.orderId and o.generalLedgerInsertId = @emptyGUID
		inner join users u with (nolock) on u.userId = o.userId and u.accountType = 0
		inner join vendorItemKitAssignment ka with (nolock) on ka.vendorItemKitAssignmentId = ik.vendorItemKitAssignmentId
		inner join vendorItems va with (nolock) on va.vendorItemId = ka.vendorItemId
		inner join cart c with (nolock) on c.cartId = va.cartId
		inner join kitAllocation k with (nolock) on k.cartId = c.cartId
	) s
	

	/* ---------------------------------------- GENERAL LEDGER INSERT ROWS RIGHT SIDE (Dr.) ---------------------------------------- */
	
	/* header group line items */
	insert into @generalLedger
	select NEWID() as generalLedgerId, kitAllocationId as refId, 0 as refType, 0 as creditRecord, 1 as debitRecord,amount,
	/* notice here when the account type = 1 then expenseAccount else revenueAccount - AP customers use the correct account */
	case when accountType = 1 then inventoryAccount else revenueAccount end as userId,
	@postingDate, @referenceNotes as reference, @newGeneralLedgerInsertId as generalLedgerInsertId
	from (
		select k.kitAllocationId,k.qty*(k.valueCostTotal+k.noTaxValueCostTotal) as amount, i.revenueAccount, i.inventoryAccount, u.accountType
		from @orderIds a
		inner join cart c with (nolock) on c.orderId = a.keyValue
		inner join kitAllocation k with (nolock) on c.cartId = k.cartId
		inner join items i with (nolock) on k.itemNumber = i.itemNumber
		inner join orders o with (nolock) on o.orderId = c.orderId and o.generalLedgerInsertId = @emptyGUID
		inner join users u with (nolock) on u.userId = o.userId
	) s
	
	
	/* header group tax */
	insert into @generalLedger
	select NEWID() as generalLedgerId, o.orderId as refId, 1 as refType, 0 as creditRecord, 1 as debitRecord, taxTotal as amount,
	@taxGLAccount as userId, @postingDate, @referenceNotes as reference, @newGeneralLedgerInsertId as generalLedgerInsertId
	from orders o with (nolock)
	inner join @orderIds oid on oid.keyValue = o.orderId
	inner join users u with (nolock) on u.userId = o.userId
	where o.generalLedgerInsertId = @emptyGUID

	/* header group shipping */
	insert into @generalLedger
	select NEWID() as generalLedgerId, o.orderId as refId, 2 as refType, 0 as creditRecord, 1 as debitRecord, shippingTotal as amount,
	@shippingGLAccount as userId,@postingDate, @referenceNotes as reference, @newGeneralLedgerInsertId as generalLedgerInsertId
	from orders o with (nolock)
	inner join @orderIds oid on oid.keyValue = o.orderId
	inner join users u with (nolock) on u.userId = o.userId
	where o.generalLedgerInsertId = @emptyGUID

	/* header group discount */
	insert into @generalLedger
	select NEWID() as generalLedgerId, o.orderId as refId, 3 as refType, 0 as creditRecord, 1 as debitRecord, discount as amount,
	@discountGLAccount as userId, @postingDate, @referenceNotes as reference, @newGeneralLedgerInsertId as generalLedgerInsertId
	from orders o with (nolock)
	inner join @orderIds oid on oid.keyValue = o.orderId
	inner join users u with (nolock) on u.userId = o.userId
	where o.generalLedgerInsertId = @emptyGUID
	
	/* check if __inventory__ is allocated, if it is insert Cr. into item's inventory account */
	insert into @generalLedger
	select NEWID() as generalLedgerId,kitAllocationId as refId, 4 as refType, 0 as creditRecord, 1 as debitRecord, amount,
	inventoryAccount as userId, @postingDate as postingDate, @referenceNotes as reference, @newGeneralLedgerInsertId as generalLedgerInsertId
	from (
		select ik.kitAllocationId,ik.qty*(k.valueCostTotal+k.noTaxValueCostTotal) as amount, i.inventoryAccount as inventoryAccount
		from @orderIds a
		inner join cart ic with (nolock) on ic.orderId = a.keyValue
		inner join kitAllocation ik with (nolock)
			on ic.cartId = ik.cartId and ik.generalLedgerId = @emptyGUID
			and ik.inventoryItem = 1
		inner join items i with (nolock) on ik.itemNumber = i.itemNumber
		inner join orders o with (nolock) on o.orderId = ic.orderId and o.generalLedgerInsertId = @emptyGUID
		inner join users u with (nolock) on u.userId = o.userId and u.accountType = 0
		inner join vendorItemKitAssignment ka with (nolock) on ka.vendorItemKitAssignmentId = ik.vendorItemKitAssignmentId
		inner join vendorItems va with (nolock) on va.vendorItemId = ka.vendorItemId
		inner join cart c with (nolock) on c.cartId = va.cartId
		inner join kitAllocation k with (nolock) on k.cartId = c.cartId
	) s
	
	
	/* ---------------------------------------- WRITE VALIDATION (prevent duplicate inserts) ---------------------------------------- */
	
	/* update all related orders and payment methods with the generalLedgerId that was inserted
	this way we can tell what was inserted and what was not inserted. */
	update orders set generalLedgerInsertId = @newGeneralLedgerInsertId where orderId in (select keyValue from @orderIds)
	
	/* update paymentMethods table to show these payments are posted to the GL - earlier temp Ids were made @salesReceiptGLInsertId, @recieveableGLInsertId.
	I'm going to try and replace these temp ids with the actual ids after the linking table (paymentMethods) is updated with the new Ids. */
	update paymentMethods set generalLedgerInsertId = @newGeneralLedgerInsertId
	where paymentMethodId
	in (select paymentMethodId from paymentMethodsDetail with (nolock) where orderId in (
			select keyValue
			from orders o with (nolock)
			inner join users u with (nolock) on u.userId = o.userId
			inner join @orderIds oid on o.orderId = oid.keyValue and /* sales reciept orders */o.termId in (select termId from terms where accrued = 0)
		)
	)
	update paymentMethods set generalLedgerInsertId = @newGeneralLedgerInsertId
	where paymentMethodId
	in (select paymentMethodId from paymentMethodsDetail with (nolock) where orderId in (
			select keyValue
			from orders o with (nolock)
			inner join users u with (nolock) on u.userId = o.userId
			inner join @orderIds oid on o.orderId = oid.keyValue and /* 'terms' orders*/o.termId in (select termId from terms where accrued = 1)
		)
	)
	
	
	/* does the sum of the Cr.s match the sum of the Dr.s? */
	/* sum Cr.s */
	declare @crTotal money = (select SUM(amount) from @generalLedger g where g.creditRecord = 1 and g.debitRecord = 0);
	declare @drTotal money = (select SUM(amount) from @generalLedger g where g.creditRecord = 0 and g.debitRecord = 1);
	
	if @crTotal = @drTotal begin
		print 'GL Entries are in balance.  Do the insert.';
		/* do actual insert */
		insert into generalLedger
		select generalLedgerId, refId, refType, creditRecord, debitRecord, amount, userId, addDate, reference, generalLedgerInsertId
		from @generalLedger
		
		/* BATCH 1: show error code */
		select 0 as errorId, '' as errorDescription,@drTotal as drTotal, @crTotal as crTotal
		
		/* BATCH 2:  show human readable result based on table vars */
		select userId, handle, addDate, sum(drAmount) as debit, sum(crAmount) as credit, reference as notes, -1 as VerCol
		from (
			select generalLedgerId,u.userId,addDate,
			case when creditRecord = 0 and debitRecord = 1 then
				0
			else
				amount
			end as drAmount, 
			case when debitRecord = 0 and creditRecord = 1 then
				0 
			else
				amount
			end
			as crAmount, handle, reference
			from @generalLedger g
			inner join users u with (nolock) on u.userId = g.userId
		) f
		group by userId, handle, addDate, reference
		having sum(drAmount)>0 or sum(crAmount)>0
		order by sum(drAmount) asc
		
		
		/* BATCH 3: show raw GL entries */
		select generalLedgerId, refId, refType, creditRecord, debitRecord, amount, userId, addDate, reference,
		generalLedgerInsertId from @generalLedger


	end else begin
		if @crTotal is null begin
			set @crTotal = 0
		end
		if @drTotal is null begin
			set @drTotal = 0
		end
		print 'GL Entries are not in balance.  Do not insert.';
		/* BATCH 1: show error code */
		select -1 as errorId, 'GL Entries are not in balance.  Recalculate selected orders and try again.' as errorDescription,@drTotal as drTotal, @crTotal as crTotal
		
		/* BATCH 2: show a bs preview entry to prevent read errors */
		select -1 as userId, '' as handle, cast('1/1/1900' as datetime) as addDate,
		cast(0 as money) as debit, cast(0 as money) as credit, '' as notes, -1 as VerCol
		
		/* BATCH 3: show raw GL entries */
		select generalLedgerId, refId, refType, creditRecord, debitRecord, amount, userId, addDate, reference,
		generalLedgerInsertId from @generalLedger
		
	end
end
GO

/****** Object:  View [dbo].[salesJournalByDate]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[salesJournalByDate] as
select 
CONVERT(datetime,(CONVERT(varchar(50),orderdate,101))) as orderDate,
sum(grandTotal) as grandTotal,
sum(taxTotal) as taxTotal,
sum(subTotal) as subTotal,
sum(shippingTotal) as shippingTotal,
sum(discount) as discount,
-1 as VerCol
from orders
inner join users on orders.userId = users.userId and users.accountType = 0
group by CONVERT(varchar(50),orderdate,101)
GO
/****** Object:  View [dbo].[salesJournalByAccountAndDate]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[salesJournalByAccountAndDate] as
select 
CONVERT(datetime,(CONVERT(varchar(50),orderdate,101))) as orderDate,
users.userId,
users.handle,
sum(grandTotal) as grandTotal,
sum(taxTotal) as taxTotal,
sum(subTotal) as subTotal,
sum(shippingTotal) as shippingTotal,
sum(discount) as discount,
-1 as VerCol
from orders
inner join users on orders.userId = users.userId and users.accountType = 0
group by CONVERT(varchar(50),orderdate,101), users.userId, users.handle
GO
/****** Object:  View [dbo].[allocatedStock]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[allocatedStock] as
/* allocatedStock version 0.1.0 */
select k.itemNumber,i.shortDescription,t.prebook,t.ats,t.wip,t.volume,k.qty,o.orderNumber,
shipmentNumber,serialNumber,lineNumber,orderDate,manifest,purchaseOrder,
closed,canceled,u.userId,u.handle,o.deliverBy,parentItemNumber,
d.divisionName as division, s.size as size, w.code as swatch, o.orderId, c.cartId, -1 as VerCol
from kitAllocation k with (nolock)
inner join cart c with (nolock) on c.cartId = k.cartId 
inner join orders o with (nolock) on o.orderId = c.orderId
inner join users u with (nolock) on u.userId = o.userId and u.accountType = 0
inner join items i with (nolock) on k.itemNumber = i.itemNumber
inner join itemOnHandTemp t with (nolock) on t.itemNumber = i.itemNumber
inner join sizes s with (nolock) on s.sizeId = i.sizeId
inner join swatches w with (nolock) on w.swatchId = i.swatchId
inner join divisions d with (nolock) on d.divisionId = i.divisionId
where not k.vendorItemKitAssignmentId = '{00000000-0000-0000-0000-000000000000}' and k.itemConsumed = 0
GO
/****** Object:  View [dbo].[agingTable]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[agingTable] as
	/* agingTable version 1.0 */
	select userId, sum(amount) as amount,
	case when dayOff <= 0 then
		0
	when (dayOff > 0 and dayOff < 6) then
		5
	when (dayOff > 5 and dayOff < 16) then
		15
	when (dayOff > 15 and dayOff < 31) then
		30
	when (dayOff > 30 and dayOff < 46) then
		45
	when (dayOff > 45 and dayOff < 61) then
		60
	when dayOff > 120 then
		120
	else
		-1
	end as dayGroup
	from
	( 
		select u.userId, u.handle,
		grandTotal-paid
		as amount,
		DATEDIFF(d,g.recalculatedOn,getdate())-(
			case when t.termDays is null then 0 else t.termDays end
		) as dayOff
		from orders g
		left join terms t on t.termId = g.termId
		inner join users u on u.userId = g.userId and u.accountType = 0
	) s
	group by userId,s.dayOff
GO
/****** Object:  View [dbo].[aging]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[aging] as
	/* aging version 1.0 */
	select userid,
	case when [0] is null then 0 else [0] end as [0],
	case when [5] is null then 0 else [5] end as [5],
	case when [15] is null then 0 else [15] end as [15],
	case when [30] is null then 0 else [30] end as [30],
	case when [45] is null then 0 else [45] end as [45],
	case when [60] is null then 0 else [60] end as [60],
	case when [120] is null then 0 else [120] end as [120],
	VerCol from (
		select userId,handle,
		sum([0]) as [0],sum([5]) as [5],sum([15]) as [15],sum([30]) as [30],sum([45]) as [45],sum([60]) as [60],sum([120]) as [120],-1 as VerCol 
		from 
		(
			select userId, handle, amount,
			case when dayOff <= 0 then
				0
			when (dayOff > 0 and dayOff < 6) then
				5
			when (dayOff > 5 and dayOff < 16) then
				15
			when (dayOff > 15 and dayOff < 31) then
				30
			when (dayOff > 30 and dayOff < 46) then
				45
			when (dayOff > 45 and dayOff < 61) then
				60
			when dayOff > 120 then
				120
			end as dayGroup
			from
			( 
				select u.userId, handle,
				grandTotal-paid
				as amount, DATEDIFF(d,g.recalculatedOn,getdate())-(
					case when t.termDays is null then 0 else t.termDays end
				) as dayOff
				from orders g
				inner join users u on u.userId = g.userId and u.accountType = 0
				inner join terms t on t.termId = g.termId
			) s
		) f
		pivot (sum(amount) for dayGroup in ([0], [5], [15], [30], [45], [60], [120])) p 
		group by userId, handle
	) g
GO
/****** Object:  StoredProcedure [dbo].[attachPaymentMethods]    Script Date: 05/30/2011 18:13:39 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[attachPaymentMethods] (@amountTryingToBePaid money,@paymentMethodIds dbo.hashTable readonly, @orderIds dbo.hashTable readonly) as
begin
	/* attachPaymentMethods version 0.1.0 */
	declare @errorId int = 0;/* no errors yet! */
	declare @desc varchar(100) = '';
	declare @runningAmountToBeSubtractedFrom money = 0;
	declare @amountUnpaid money = 0;
	declare @amountStillUnpaid money = 0;
	declare @amountBeingPaid money = 0;
	declare @currentPaymentMethodId uniqueidentifier;
	declare @currentOrderId int = -1;
	/* sample paymentMethodsDetail */
	declare @paymentMethodsDetail table(paymentMethodDetailId uniqueidentifier,paymentMethodId uniqueidentifier,refId int,amount money);
	declare @newOrderAmounts table(orderId int, paid money);
	/* check and see if there is enough money left on the selected paymentMethods to allow for this transaction */
	declare @totalAmountRemaning money = (
		select SUM(amountRemaning) from (
			select p.paymentMethodId, p.amount-SUM(case when pd.amount is null then 0 else pd.amount end) as amountRemaning
			from paymentMethods p with (nolock)
			left join paymentMethodsDetail pd with (nolock) on p.paymentMethodId = pd.paymentMethodId
			inner join @paymentMethodIds pids on convert(uniqueidentifier, pids.keyValue) = p.paymentMethodId
			group by p.paymentMethodId, p.amount
		) pf
	)

	if @totalAmountRemaning < @amountTryingToBePaid begin
		set @errorId = -1;
		set @desc = 'The amount you''re trying to pay is more than the selected payment methods.';
	end
	if @errorId = 0 begin
		/* loop through the orders subtracting money from the selected payment methods until the orders are done */
		declare order_cursor cursor forward_only static for
		select o.orderId, grandTotal-paid as amountUnpaid
		from orders o with (nolock)
		inner join @orderIds oids on o.orderId = oids.keyValue
		open order_cursor;
		fetch next from order_cursor
		into @currentOrderId, @amountUnpaid
		while @@FETCH_STATUS = 0 begin
			print 'Starting Loop 1 -> @currentOrderId:'+cast(@currentOrderId as varchar(50))+'
			,@amountUnpaid:'+cast(@amountUnpaid as varchar(50))
			set @amountStillUnpaid = @amountUnpaid;
			while @amountStillUnpaid > 0 begin
				if (@runningAmountToBeSubtractedFrom = convert(money,0)) begin
					/*there was no money left on this purchase order, grab another one */
					select top 1 
					@runningAmountToBeSubtractedFrom = p.amount-SUM(case when pd.amount is null then 0 else pd.amount end),
					@currentPaymentMethodId = p.paymentMethodId
					from paymentMethods p with (nolock)
					left join (
						select amount,paymentMethodId from
						paymentMethodsDetail with (nolock)
						union all
						select amount,paymentMethodId from
						@paymentMethodsDetail
					) pd on p.paymentMethodId = pd.paymentMethodId
					inner join @paymentMethodIds pids on convert(uniqueidentifier, pids.keyValue) = p.paymentMethodId
					group by p.paymentMethodId, p.amount
					having p.amount-SUM(case when pd.amount is null then 0 else pd.amount end) > 0
					order by p.amount-SUM(case when pd.amount is null then 0 else pd.amount end)
					print 'selecting new method -> '+cast(@currentPaymentMethodId as varchar(50))
				end
					
				if (@runningAmountToBeSubtractedFrom>=@amountStillUnpaid) begin
					/* the payment method was greater than the amount to be paid on this order */
					set @amountBeingPaid = @amountStillUnpaid;
					set @runningAmountToBeSubtractedFrom = @runningAmountToBeSubtractedFrom - @amountBeingPaid;
					set @amountStillUnpaid = 0;
				end else begin
					/* the payment method was not enough to fully pay this order */
					set @amountBeingPaid = @runningAmountToBeSubtractedFrom;
					set @runningAmountToBeSubtractedFrom = 0;
					set @amountStillUnpaid = @amountStillUnpaid - @amountBeingPaid;
				end
				
				print 'Starting Loop 2 -> @runningAmountToBeSubtractedFrom:'+cast(@runningAmountToBeSubtractedFrom as varchar(50))+'
				'+',@currentPaymentMethodId:'+cast(@currentPaymentMethodId as varchar(50))+'
				'+',@amountStillUnpaid:'+cast(@amountStillUnpaid as varchar(50))+'
				'+',@amountBeingPaid:'+cast(@amountBeingPaid as varchar(50))+'
				'+',@runningAmountToBeSubtractedFrom:'+cast(@runningAmountToBeSubtractedFrom as varchar(50))
				
				/* insert into paymentMethodsDetail */
				insert into @paymentMethodsDetail
				select NEWID() as paymentMethodDetailId,
				@currentPaymentMethodId as paymentMethodId,
				@currentOrderId as refId,
				@amountBeingPaid as amount
				/* update orders */
				if exists(select 0 from @newOrderAmounts where orderId = @currentOrderId) begin
					update @newOrderAmounts set paid = @amountStillUnpaid where orderId = @currentOrderId
				end else begin
					insert into @newOrderAmounts select @currentOrderId, @amountStillUnpaid
				end
			end
			fetch next from order_cursor
			into @currentOrderId, @amountUnpaid
		end
		close order_cursor;
		deallocate order_cursor;
		if @errorId = 0 begin
			/* do the actual insert */
			insert into paymentMethodsDetail
			select paymentMethodDetailId,paymentMethodId,refId,amount
			from @paymentMethodsDetail
			/* do the actual updates */
			update orders set paid = grandTotal-oa.paid
			from @newOrderAmounts oa
			where orders.orderId = oa.orderId
		end
	end
	
	/* show the result */
	/* batch 1 is the summary */
	select @errorId,@desc;
	/* batch 2 is the actual paymentDetailInserts */
	select paymentMethodDetailId,paymentMethodId,refId,amount from @paymentMethodsDetail
	/* batch 3 is the actual orders updated, their Ids and the new 'paid' amount */
	select orderId, paid from @newOrderAmounts
end
GO

/****** Object:  View [dbo].[accountBalance]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[accountBalance] as
/* accountBalance version 0.1.0 */
select balance,u.userId,handle,at.accountType from
(
	select userId,SUM(amount) as balance from (
		select userId,amount*-1 as amount
		from generalLedger g with (nolock) 
		where debitRecord = 1
		union all
		select userId,amount as amount
		from generalLedger g with (nolock) 
		where creditRecord = 1
	) g group by userId
) gr
inner join users u with (nolock) on u.userId = gr.userId
inner join accountTypes at with (nolock) on at.accountTypeId = u.accountType
GO
/****** Object:  UserDefinedFunction [dbo].[abbrState]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[abbrState](
	@full_or_abbr_state_name varchar(255) = ''
)
returns char(2)
as
begin
	declare @abbr_state as char(2)

	IF LEN(@full_or_abbr_state_name) = 2
		BEGIN
			set @abbr_state = rtrim(@full_or_abbr_state_name)
		END
	ELSE
		BEGIN
			set @abbr_state = (select abbr_name from stateConvert where full_name like '%'+@full_or_abbr_state_name+'%')
			IF @abbr_state is null
			BEGIN
				set @abbr_state = @full_or_abbr_state_name
			END
		END
	return upper(@abbr_state)
end
GO
/****** Object:  View [dbo].[addToCategorySelector]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[addToCategorySelector] as 
	/* addToCategorySelector version 1 */
	select cast(categoryId as varchar(50)) as id, 'Category - '+Category as Value, '' as [Description], 0 as VerCol from categories
	union all
	select itemNumber as id, 'Item - '+itemnumber as Value, [Description] as [Description],0 as VerCol from items
	where items.BOMOnly = 0
GO
/****** Object:  StoredProcedure [dbo].[addItemImage]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[addItemImage] (
	@imagingId uniqueidentifier,
	@itemNumber varchar(50),
	@fileSize int,
	@fileName varchar(255),
	@thumbnail bit,
	@width int,
	@height int,
	@thumborder int) as
begin
/* check if any item images are assigned yet, if none exist then assign this image to all locations */
if not exists(select 0 from items where m in (select imagingId from imaging where itemnumber = @itemNumber)) begin
	update items set m = @imagingId where itemnumber = @itemNumber
end
if not exists(select 0 from items where c in (select imagingId from imaging where itemnumber = @itemNumber)) begin
	update items set c = @imagingId where itemnumber = @itemNumber
end
if not exists(select 0 from items where f in (select imagingId from imaging where itemnumber = @itemNumber)) begin
	update items set f = @imagingId where itemnumber = @itemNumber
end
if not exists(select 0 from items where t in (select imagingId from imaging where itemnumber = @itemNumber)) begin
	update items set t = @imagingId where itemnumber = @itemNumber
end
if not exists(select 0 from items where a in (select imagingId from imaging where itemnumber = @itemNumber)) begin
	update items set a = @imagingId where itemnumber = @itemNumber
end
if not exists(select 0 from items where x in (select imagingId from imaging where itemnumber = @itemNumber)) begin
	update items set x = @imagingId where itemnumber = @itemNumber
end
if not exists(select 0 from items where y in (select imagingId from imaging where itemnumber = @itemNumber)) begin
	update items set y = @imagingId where itemnumber = @itemNumber
end
if not exists(select 0 from items where z in (select imagingId from imaging where itemnumber = @itemNumber)) begin
	update items set z = @imagingId where itemnumber = @itemNumber
end
if not exists(select 0 from items where b in (select imagingId from imaging where itemnumber = @itemNumber)) begin
	update items set b = @imagingId where itemnumber = @itemNumber
end
if not exists(select 0 from items where d in (select imagingId from imaging where itemnumber = @itemNumber)) begin
	update items set d = @imagingId where itemnumber = @itemNumber
end
/* insert or update */
if exists(select 0 from imaging where imagingId = @imagingId) begin
	update imaging set 
	imagingId = @imagingId,
	itemNumber = @itemNumber,
	fileSize = @fileSize,
	fileName = @fileName,
	thumbnail = @thumbnail,
	width = @width,
	height = @height,
	thumborder = @thumborder
	where imagingId = @imagingId
end else begin
	insert into imaging (
	imagingID, itemnumber, filesize, filename, thumbnail, width, height, thumborder
	) values
	(
		@imagingId,
		@itemNumber,
		@fileSize,
		@fileName,
		@thumbnail,
		@width,
		@height,
		@thumborder
	)
	end
end
GO
/****** Object:  View [dbo].[cart_lines]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[cart_lines] as
select
cart.cartID as [cartid],
cart.Itemnumber as [Item Number],
cart.qty as [Qty]
from cart with (nolock)
GO
/****** Object:  StoredProcedure [dbo].[categoryItemList]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[categoryItemList] (@categoryId uniqueidentifier) as	--This is a non-recursive preorder traversal.
 if not @categoryId is null
 begin
	 DECLARE @lvl int
	 DECLARE @line uniqueidentifier
	 CREATE TABLE #stack (categoryId uniqueidentifier, lvl int)	--Create a tempory stack.
	 CREATE TABLE #out (categoryId uniqueidentifier, lvl int)
	 INSERT INTO #stack VALUES (@categoryId, 1)	--Insert current node to the stack.
	 SELECT @lvl = 1				
	 WHILE @lvl > 0					--From the top level going down.
		BEGIN
			IF EXISTS (SELECT * FROM #stack WHERE lvl = @lvl)
				BEGIN
					SELECT @categoryId = categoryId	--Find the first node that matches current node's name.
					FROM #stack
					WHERE lvl = @lvl
					SELECT @line = @categoryId --@lvl - 1 s spaces before the node name.
					insert #out (categoryId,lvl) values (@line,@lvl) -- Insert it into the output table.
					DELETE FROM #stack
					WHERE lvl = @lvl AND categoryId = @categoryId	--Remove the current node from the stack.
					INSERT #stack		--Insert the childnodes of the current node into the stack.
						SELECT childCategoryId, @lvl + 1
						FROM CategoryDetail with (nolock)
						WHERE categoryId = @categoryId and not childCategoryId = '00000000-0000-0000-0000-000000000000'
					IF @@ROWCOUNT > 0		--If the previous statement added one or more nodes, go down for its first child.
					BEGIN
						SELECT @lvl = @lvl + 1	--If no nodes are added, check its brother nodes.
					END
				END
			ELSE
				SELECT @lvl = @lvl - 1		--Back to the level immediately above.
		END 
	-- select populated stack
	select
	*
	from #out
end
GO
/****** Object:  StoredProcedure [dbo].[blogMonthCategories]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[blogMonthCategories] (@blogCategoryId uniqueidentifier,@year int) as begin
	select 
	DATENAME(MONTH,addDate) as [month],
	COUNT(0) as [count],
	@blogCategoryId as blogCategoryId,
	@year as [year],
	-1 as VerCol
	from blogs
	where blogCategoryId = @blogCategoryId and DATEPART(year,addDate) = @year
	group by DATENAME(MONTH,addDate)
end
GO
/****** Object:  View [dbo].[consumedStock]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[consumedStock] as
/* consumedStock version 0.1.0 */
select k.itemNumber,i.shortDescription,t.prebook,t.ats,t.wip,t.volume,k.qty,o.orderNumber,
shipmentNumber,serialNumber,lineNumber,orderDate,manifest,purchaseOrder,
closed,canceled,u.userId,u.handle,o.deliverBy,parentItemNumber,
d.divisionName as division, s.size as size, w.code as swatch, o.orderId, c.cartId, -1 as VerCol
from kitAllocation k with (nolock)
inner join cart c with (nolock) on c.cartId = k.cartId 
inner join orders o with (nolock) on o.orderId = c.orderId
inner join users u with (nolock) on u.userId = o.userId and u.accountType = 0
inner join items i with (nolock) on k.itemNumber = i.itemNumber
inner join itemOnHandTemp t with (nolock) on t.itemNumber = i.itemNumber
inner join sizes s with (nolock) on s.sizeId = i.sizeId
inner join swatches w with (nolock) on w.swatchId = i.swatchId
inner join divisions d with (nolock) on d.divisionId = i.divisionId
where not k.vendorItemKitAssignmentId = '{00000000-0000-0000-0000-000000000000}' and k.itemConsumed = 1
GO
/****** Object:  UserDefinedFunction [dbo].[ConcatSwatches]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[ConcatSwatches] (

      @itemnumber      varchar(50)
                  )  
RETURNS varchar(1000)
AS
BEGIN 
      
      Declare @String varchar(1000)

      Set @String = ''

      Select @String = @String  + rtrim(swatchId) + ',' From items with (nolock) where parentItemnumber = @itemnumber group by swatchId
	  
      Return case when len(@String)>0 then substring(@String,0,len(@String)) else '' end

END
GO
/****** Object:  StoredProcedure [dbo].[getZones]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[getZones] as
begin
select zoneID, rate, weight, shipzone, cost
from dbo.shipzone
end
GO
/****** Object:  StoredProcedure [dbo].[getZipToZones]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[getZipToZones] as
begin
select ziptozoneID, carrier, sourceZip, service, fromzip, tozip, shipzone
from ziptozone
end
GO
/****** Object:  StoredProcedure [dbo].[getUsers]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[getUsers] (@userId int) as
begin
	select 
	email,
	password,
	userId,
	userLevel,
	handle,
	wholesaledealer,
	lastVisit,
	comments,
	administrator,
	wouldLikeEmail,
	createdate,
	SessionID,
	quotaWholesale,
	quotaComplete,
	quota,
	credit,
	loggedIn,
	purchaseaccount,
	creditlimit,
	contact,
	address1,
	address2,
	zip,
	state,
	country,
	city,
	homePhone,
	email,
	fax,
	www,
	firstName,
	lastName,
	termID,
	usesTerms,
	accounttype,
	packingSlip,
	notax,
	allowPreorders,
	quote,
	invoice,
	FOB,
	logon_redirect,
	admin_script,
	rateId,
	workPhone,
	autoFillOrderForm,
	sendShipmentUpdates,
	estLeadTime,
	estTransitTime,
	UI_JSON,
	assetAccount,
	defaultPrinterPath	
	from
	users with (nolock)
	where 
	userId = @userId or @userId = -1
	order by userid
end
GO
/****** Object:  StoredProcedure [dbo].[getTimer]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[getTimer](@timerId uniqueidentifier) as begin
	select timerId, currentItemName, totalItemCount, currentItemCount, totalItemSize, currentItemSize, currentSizeComplete, complete, started, updated, cast(VerCol as bigint)
	from timer where timerId = @timerId
end
GO
/****** Object:  StoredProcedure [dbo].[getTerms]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[getTerms] as begin
	select termId, termName, termDays, accrued from terms order by termId
end
GO
/****** Object:  StoredProcedure [dbo].[getTemplateUsage]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[getTemplateUsage](@templateId uniqueidentifier) as begin
select unique_siteId,'m' as location from site_configuration where m_imagingTemplate = @templateId
	union all
select unique_siteId,'c' as location from site_configuration where c_imagingTemplate = @templateId
	union all
select unique_siteId,'f' as location from site_configuration where f_imagingTemplate = @templateId
	union all
select unique_siteId,'t' as location from site_configuration where t_imagingTemplate = @templateId
	union all
select unique_siteId,'a' as location from site_configuration where a_imagingTemplate = @templateId
	union all
select unique_siteId,'x' as location from site_configuration where x_imagingTemplate = @templateId
	union all
select unique_siteId,'y' as location from site_configuration where y_imagingTemplate = @templateId
	union all
select unique_siteId,'z' as location from site_configuration where z_imagingTemplate = @templateId
	union all	
select unique_siteId,'b' as location from site_configuration where b_imagingTemplate = @templateId
	union all	
select unique_siteId,'d' as location from site_configuration where d_imagingTemplate = @templateId
end
GO
/****** Object:  StoredProcedure [dbo].[getSiteConfiguration]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[getSiteConfiguration](@unique_siteID uniqueidentifier)
as begin
	/* getSiteConfiguration version 0.1.0 */
	select top 1
	siteaddress,
	friendlySiteName,
	days_until_session_expires,
	days_meta_expires,
	default_meta_keywords,
	default_meta_description,
	default_page_title,
	default_search_text,
	local_country,
	per_retail_shipment_handling,
	free_ship_threshold,
	default_Access_Denied_page,
	elevated_security_userId,
	elevated_security_password,
	elevated_security_domain,
	enable_file_version_tracking,
	default_empty_cart_page,
	default_records_per_page,
	default_rateID,
	default_zip,
	default_intresting_page,
	default_listmode,
	default_orderby,
	cookie_name,
	default_style_path,
	default_form_detail_directory,
	default_form_invoice_directory,
	add_to_cart_redirect,
	serializationbase,
	validation_fails_querystring,
	empty_cart_redirect,
	update_cart_redirect,
	max_retail_cart_quantity,
	default_ship_country,
	use_ssl,
	checkout_page_redirect,
	default_form_misc_directory,
	place_order_redirect,
	checkout_remember_credit_card,
	checkout_card_billtoaddressid,
	merchant_auth_type,
	merchant_auth_name,
	merchant_auth_password,
	smtp_server,
	smtp_username,
	smtp_password,
	smtp_port,
	smtp_authenticate,
	site_operator_email,
	site_send_order_email,
	site_send_shipment_update_email,
	site_send_import_export_log_email,
	site_log_email,
	site_order_email_from,
	site_order_email_bcc,
	logon_redirect,
	m_imagingTemplate,
	c_imagingTemplate,
	f_imagingTemplate,
	t_imagingTemplate,
	a_imagingTemplate,
	x_imagingTemplate,
	y_imagingTemplate,
	z_imagingTemplate,
	b_imagingTemplate,
	d_imagingTemplate,
	administrator_user_level,
	new_user_level,
	disabled_user_level,
	banned_user_level,
	test_mode,
	orders_export_on_flagId,
	orders_closed_on_flagId,
	site_specific_item_images,
	defaultPackingSlip,
	defaultQuote,
	defaultInvoice,
	admin_site_user_level,
	item_admin_user_level,
	user_admin_user_level,
	default_new_user_allow_preorder,
	site_allow_preorder,
	company_name,
	company_co,
	company_address1,
	company_address2,
	company_city,
	company_state,
	company_zip,
	company_country,
	company_phone,
	company_fax,
	company_email,
	site_order_email_url,
	site_order_email_subject,
	never_keep_creditcard_info,
	scanned_image_path,
	export_to_account_catch_all,
	shipment_email_url,
	shipment_email_subject,
	shipment_email_bcc,
	shipment_email_from,
	main_site,
	timezone,
	company_HTML_subHeader,
	site_server_500_page,
	site_server_404_page,
	merchant_auth_url,
	merchant_sucsess_match,
	merchant_message_match,
	merchant_message_match_index,
	default_inventoryDepletesOnFlagId,
	default_inventoryRestockOnFlagId,
	default_itemIsConsumedOnFlagId,
	default_revenueAccount,
	default_inventoryOperator,
	new_item_allowPreorders,
	unique_siteID,
	lost_password_email_URL,
	inappropriateHideThreshold,
	shippingGLAccount,
	taxGLAccount,
	discountGLAccount,
	accountsReceivableGLAccount,
	checkingGLAccount,
	accountsPayableGLAccount,
	default_expenseAccount,
	default_inventoryAccount,
	default_inventoryCOGSAccount,
	emailQueueRefreshInterval
	from site_configuration with (nolock) 
	where unique_siteID = @unique_siteID or @unique_siteID = '00000000-0000-0000-0000-000000000000'
	order by unique_siteID desc /* 0000 comes first so make the 'other' site the default (if any, right?) */
end
GO
/****** Object:  StoredProcedure [dbo].[getCountries]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[getCountries] as
select Country from Countries order by Country
GO
/****** Object:  StoredProcedure [dbo].[getContacts]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[getContacts]
AS
BEGIN
	select ContactID, 0 as defaultContact, userID, 
	rtrim(FirstName),rtrim(LastName), rtrim(Address1), 
	rtrim(Address2), rtrim(City), rtrim(State), rtrim(ZIP),
	rtrim(Country), rtrim(HomePhone), rtrim(WorkPhone),
	rtrim(Email), rtrim(SpecialInstructions), 
	rtrim(Comments), sessionID, sendshipmentupdates,
	emailads, rate, dateCreated, rtrim(Company) FROM contacts with (nolock)
END
GO
/****** Object:  UserDefinedFunction [dbo].[getCartSubTotal]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[getCartSubTotal](
@sessionid uniqueidentifier
)
returns money
as
begin

declare @cartSubTotal money
	set @cartSubTotal = (select 
						sum((price+valueCostTotal+noTaxValueCostTotal)*qty)
						from dbo.cart with (nolock)
						where sessionid = @sessionid)

if (@cartSubTotal is null)
begin
	set @cartSubTotal = 0
end 
return @cartSubTotal
end
GO
/****** Object:  StoredProcedure [dbo].[getCarriers]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[getCarriers] as
begin
select carrierId, carrierName
from carriers
end
GO
/****** Object:  StoredProcedure [dbo].[getBlogCategories]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[getBlogCategories] as
begin
	select
	blogId,
	subject,
	message,
	comments,
	tags,
	editor,
	d.author,
	addDate,
	dateChanged,
	lastEditor,
	annotations,
	enabled,
	auditComments,
	allowComments,
	emailUpdates,
	blogImage,
	publicBlog,
	listOrder,
	archive,
	c.blogCategoryId,
	categoryName,
	publicCategory,
	c.author,
	showInTicker,
	blogPage,
	d.galleryId
	from blogCategories c
	inner join blogs d on d.blogCategoryId = c.blogCategoryId
	order by blogCategoryId
end
GO
/****** Object:  StoredProcedure [dbo].[getBillOfMaterials]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[getBillOfMaterials] as
begin
	/* DO NOT CHANGE THE ORDER OF ANTYHING IN HERE! - the item list loading relies on this order */
	select itemDetailID, rtrim(itemNumber) as itemNumber,
	rtrim(subItemNumber) as itemNumber, qty, depth, itemQty, kitStock, 
	showAsSeperateLineOnInvoice, onlyWhenSelectedOnForm, itemComponetType, VerCol
	from itemDetail
end
GO
/****** Object:  UserDefinedFunction [dbo].[getAddressTaxTotal]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[getAddressTaxTotal](
@addressID uniqueidentifier,
@sessionid uniqueidentifier
)
returns money
as
begin
DECLARE @noTax bit
declare @cartTaxTotal money
	set @cartTaxTotal = (select 
						sum((cart.price+valueCostTotal)*qty)*(
														select tax from tax with (nolock) where (
																					select substring(zip,1,5) from addresses with (nolock) where addressId = @addressID
																					) 
														between zipFrom and zipTo) 
						from cart with (nolock)
						inner join items with (nolock) on items.itemnumber = cart.itemnumber
						where sessionid = @sessionid and items.notax = 0 and cart.addressid = @addressID)

if exists(select * from users where userId = (select userid from visitors where sessionid = @sessionid) and notax = 1)
begin
	set @cartTaxTotal = 0
end
if @cartTaxTotal is null
begin
	set @cartTaxTotal = 0
end 
return @cartTaxTotal
end
GO
/****** Object:  StoredProcedure [dbo].[getAddress]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[getAddress](
	@addressId uniqueidentifier
)
as begin 
select 
addressId,
firstName,
lastName,
address1,
address2,
city,
state,
zip,
country,
homePhone,
workPhone,
email,
specialInstructions,
comments,
sendshipmentupdates,
emailads,
rate,
dateCreated,
company
from addresses 
where addressId = @addressId
end
GO
/****** Object:  View [dbo].[generalLedgerView]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[generalLedgerView] as
/* generalLedgerView version 0.1.0 */
select generalLedgerId, generalLedgerInsertId, userId, handle, addDate, drAmount as debit, crAmount as credit, reference as notes, refType, refId, -1 as VerCol
from (
	select generalLedgerId,generalLedgerInsertId,refType,refId,u.userId,addDate,
	case when creditRecord = 0 and debitRecord = 1 then
		0
	else
		amount
	end as drAmount, 
	case when debitRecord = 0 and creditRecord = 1 then
		0 
	else
		amount
	end
	as crAmount, handle, reference
	from generalLedger g with (nolock)
	inner join users u with (nolock) on u.userId = g.userId
) f
GO
/****** Object:  View [dbo].[generalLedgerDetailViewRef2]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[generalLedgerDetailViewRef2] as
/* generalLedgerDetailViewRef2 version 0.1.0 */
select 
orderId,
orderNumber,
u.userId,
u.handle,
subTotal,
taxTotal,
shippingTotal,
discount,
grandTotal,
o.orderDate,
o.paid,
o.purchaseOrder,
o.manifest,
-1 as VerCol
from orders o with (nolock)
inner join users u with (nolock) on o.userId = u.userId
GO
/****** Object:  View [dbo].[generalLedgerDetailViewRef1]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[generalLedgerDetailViewRef1] as
/* generalLedgerDetailViewRef1 version 0.1.0 */
select 
paymentMethodId,
paymentType,
amount,
u.userId,
u.handle,
notes,
-1 as VerCol
from paymentMethods p with (nolock)
inner join users u with (nolock) on p.userId = u.userId
GO
/****** Object:  View [dbo].[generalLedgerDetailViewRef0]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[generalLedgerDetailViewRef0] as
/* generalLedgerDetailViewRef0 version 0.1.0 */
select
k.kitAllocationId,
c.serialId,
c.orderId,
c.orderNumber,
c.serialNumber,
k.itemNumber,
k.qty,
c.price,
vc.price as COGS,
vc.orderNumber as inventoryOrderNumber,
vc.orderId as inventoryOrderId,
vc.serialId as inventorySerialId,
vc.serialNumber as inventorySerialNumber,
-1 as VerCol
from
kitAllocation k with (nolock)
inner join cart c with (nolock) on k.cartId = c.cartId
inner join items i with (nolock) on k.itemNumber = i.itemNumber
left join vendorItemKitAssignment vka with (nolock) on vka.vendorItemKitAssignmentId = k.vendorItemKitAssignmentId
left join vendorItems vi with (nolock) on vi.vendorItemId = vka.vendorItemId
left join cart vc with (nolock) on vc.cartId = vi.cartId
GO
/****** Object:  UserDefinedFunction [dbo].[flagStatusType]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  function [dbo].[flagStatusType](@serialId int, @shipmentid int, @orderid int)
returns int as
begin
declare @return int
select @return = (select top 1 flagType from objectflags a with (nolock) where
(@orderid = a.orderID or @shipmentid = a.shipmentID or @serialId = a.serialId)
and not flagtype = 0
order by a.addtime desc)
return @return
end
GO
/****** Object:  UserDefinedFunction [dbo].[flagStatus]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  function [dbo].[flagStatus](@serialId int, @shipmentid int, @orderid int)
returns uniqueidentifier as
begin
declare @return uniqueidentifier
select @return = (select top 1 flagID from objectflags a with (nolock) where
(@orderid = a.orderID or @shipmentid = a.shipmentID or @serialId = a.serialId)
and not flagtype = 0
order by a.addtime desc)
return @return
end
GO
/****** Object:  View [dbo].[flagHistory]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[flagHistory] as 
select
flagId,
case when serialId is null and shipmentId is null and not orderId is null then 'Order'
when not serialId is null then 'Line'
when not shipmentId is null then 'Shipment' end as flagLevel,
serialId,
shipmentId,
orderId,
f.flagType,
o.flagTypeName,
u.handle,
u.userId,
f.comments,
addTime,
f.VerCol
from objectFlags f
inner join flagTypes o on f.flagType = o.flagTypeId
inner join (
		select userId,handle from users
		union all
		select -1,'Unknown'
	) u on u.userId = f.userId
GO
/****** Object:  UserDefinedFunction [dbo].[f_inventoryStatus]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[f_inventoryStatus] (@cartId uniqueidentifier)  
RETURNS varchar(50)
AS
BEGIN 
      declare @assignedCount int = 0;
      declare @totalCount int = 0;
      declare @consumedCount int = 0;
      declare @msg varchar(50) = '';
      declare @emptyGUID uniqueidentifier = '00000000-0000-0000-0000-000000000000';
      set @assignedCount = (select count(0) from kitAllocation k where cartId = @cartId and not k.vendorItemKitAssignmentId = @emptyGUID and k.inventoryItem = 1);
      set @totalCount = (select count(0) from kitAllocation k where cartId = @cartId and k.inventoryItem = 1);
      set @consumedCount = (select count(0) from kitAllocation k where cartId = @cartId and k.itemConsumed = 1 and k.inventoryItem = 1);
      if @consumedCount > 0 begin
		set @msg = 'CONSUMED';
      end else if @assignedCount = @totalCount begin
		set @msg = 'ALLOCATED';
      end else if not @assignedCount = @totalCount and @assignedCount > 0 begin
        set @msg = 'PARTIAL';
      end else begin
		set @msg = 'NOT ALLOCATED';
      end
      Return @msg;
END
GO
/****** Object:  View [dbo].[order_cart]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[order_cart] as 
select c.cartId, c.sessionId, qty, itemNumber, price, 
case when c.orderId = -1 then 'Unsaved' else f.flagTypeName end as productionStatus, dbo.f_inventoryStatus(c.cartId) as inventoryStatus,
addTime, c.orderId, c.serialId, orderNumber, 
serialNumber, userId, addressId, c.shipmentId, shipmentNumber, lineNumber, epsmmcsOutput, 
epsmmcsAIFilename, termId, valueCostTotal, noTaxValueCostTotal, fulfillmentDate, estimatedFulfillmentDate, 
parentCartId, backorderedQty, canceledQty, returnToStock, customerLineNumber, c.VerCol
from cart c
left join serial_line s on s.cartId = c.cartId
left join flagTypes f on f.flagTypeId = s.lastFlagStatus
GO
/****** Object:  UserDefinedFunction [dbo].[extractCategory]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[extractCategory](@url varchar(1000))
RETURNS varchar(1000)
AS
BEGIN
	return 
	case 
	when CHARINDEX('category=',@url) = 0 then
		''
	when CHARINDEX('&',@url) > 0 then
		dbo.urldecode(SUBSTRING(SUBSTRING(@url,charindex('category=',@url)+9,999),0,charindex('&',SUBSTRING(@url,charindex('category=',@url)+9,999))))
	when CHARINDEX('/',@url,charindex('category=',@url)) > 0 then
		dbo.urldecode(SUBSTRING(SUBSTRING(@url,charindex('category=',@url)+9,999),0,charindex('/',SUBSTRING(@url,charindex('category=',@url)+9,999))))
	else
		dbo.urldecode(SUBSTRING(@url,charindex('category=',@url)+9,999))
	end
END
GO
/****** Object:  View [dbo].[exportOrdersAudit]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[exportOrdersAudit]
as

select orderid,ordernumber,orderdate,purchaseorder,manifest,exportFileAuditId, exportFileId, exportFileName, controlId, exportDate, controlIdType
from exportFileAudit with (nolock)
inner join orders on controlId = orders.orderid
GO
/****** Object:  StoredProcedure [dbo].[expandNews]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[expandNews] (@current uniqueidentifier) as	--This is a non-recursive preorder traversal.
 SET NOCOUNT ON
 DECLARE @lvl int
 DECLARE @line uniqueidentifier

 CREATE TABLE #stack (item uniqueidentifier, lvl int)	--Create a tempory stack.
 CREATE TABLE #out (newsID uniqueidentifier, lvl int)
 INSERT INTO #stack VALUES (@current, 1)	--Insert current node to the stack.
 SELECT @lvl = 1				
 WHILE @lvl > 0					--From the top level going down.
	BEGIN
	    IF EXISTS (SELECT * FROM #stack WHERE lvl = @lvl)
	        BEGIN
	            SELECT @current = item	--Find the first node that matches current node's name.
	            FROM #stack
	            WHERE lvl = @lvl

	            SELECT @line = @current --@lvl - 1 s spaces before the node name.
		    insert #out (newsID,lvl) values (@line,@lvl)
 
	            DELETE FROM #stack
	            WHERE lvl = @lvl
	                AND item = @current	--Remove the current node from the stack.

	            INSERT #stack		--Insert the childnodes of the current node into the stack.
	                SELECT newsID, @lvl + 1
	                FROM news
	                WHERE parentID = @current and posted = 1 order by adddate desc

	            IF @@ROWCOUNT > 0		--If the previous statement added one or more nodes, go down for its first child.
                        SELECT @lvl = @lvl + 1	--If no nodes are added, check its brother nodes.
		END
    	    ELSE
	      	SELECT @lvl = @lvl - 1		--Back to the level immediately above.
       	
       END 
-- select populated stack
select
(select rtrim(newsHTML) from news where news.newsID = #out.newsID) as newsHTML,
(select adddate from news where newsID = #out.newsID) as adddate,
(select rtrim(handle) from users where users.userID = (select userID from news where newsID = #out.newsID)) as handle,
(select rtrim([image]) from news where newsID = #out.newsID) as [image],
(select rtrim(alt) from news where newsID = #out.newsID) as alt,
(select rtrim(email) from users where users.userID = (select userID from news where newsID = #out.newsID)) as email,
(select rtrim(subject) from news where newsID = #out.newsID) as subject,
#out.newsID,
(select rtrim(posted) from news where newsID = #out.newsID) as posted,
(select rtrim(category) from news where newsID = #out.newsID) as category,
(select userid from news where newsID = #out.newsID) as userid,
(select name from newscategory where newscategoryID = (select category from news where newsID = #out.newsID)) as categoryname,
#out.lvl,
(select category from news where newsID = #out.newsID) as category
from #out
GO
/****** Object:  StoredProcedure [dbo].[expandBOM]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[expandBOM] (@current char(50),@cqty int,@serialID int) as	--This is a non-recursive preorder traversal.
 DECLARE @lvl int
 DECLARE @line char(50)
 CREATE TABLE #stack (itemnumber char(50), lvl int,qty int)	--Create a tempory stack.
 CREATE TABLE #out (itemnumber char(50), lvl int,qty int,serialID int)
 INSERT INTO #stack VALUES (@current, 1,@cqty)	--Insert current node to the stack.
 SELECT @lvl = 1				
 WHILE @lvl > 0					--From the top level going down.
	BEGIN
	    IF EXISTS (SELECT * FROM #stack WHERE lvl = @lvl)
	        BEGIN
	            SELECT @current = itemnumber,@cqty = qty	--Find the first node that matches current node's name.
	            FROM #stack
	            WHERE lvl = @lvl
	            SELECT @line = @current --@lvl - 1 s spaces before the node name.
				insert #out (itemnumber,lvl,qty,serialID) values (@line,@lvl,@cqty,@serialID) -- Insert it into the output table.
	            DELETE FROM #stack
	            WHERE lvl = @lvl
	                AND itemnumber = @current	--Remove the current node from the stack.
	            INSERT #stack		--Insert the childnodes of the current node into the stack.
	                SELECT subitemnumber, @lvl + 1,qty*@cqty
	                FROM itemdetail
	                WHERE itemnumber = @current
	            IF @@ROWCOUNT > 0		--If the previous statement added one or more nodes, go down for its first child.
                        SELECT @lvl = @lvl + 1	--If no nodes are added, check its brother nodes.
		END
    	    ELSE
	      	SELECT @lvl = @lvl - 1		--Back to the level immediately above.
       END 
-- select populated stack
select
*
from #out
GO
/****** Object:  View [dbo].[eventEmails]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[eventEmails]
as
select
	eventID,
	rtrim(eventName) as eventname,
	EventBeginDate,
	EventEndDate,
	rtrim(eventDescriptionHTML) as eventDescriptionHTML,
	repeatsYearly,
	(select handle from users where events.userID = users.userID) as handle,
	eventtype,
	dbo.bfdate(EventBeginDate) as bfEventBeginDate,
	dbo.bfdate(EventEndDate) as bfEventEndDate,
	imagesrc,
	imagealt,
	addDate,
	userid,
	dbo.bfdate(eventupdatelastsent) as bfEventUpdateLastSent,
	globalEvent,
	emailEvent,
	emailEveryone,
	(select email from users b where b.userid = events.userid) as email,
	datediff(d,getDate(),EventBeginDate) as daysOut
from events
where 
	posted = 1 
	and 
	(
		emailevent = 1 or emaileveryone = 1
	)
	and
	(
		datediff(d,getDate(),EventBeginDate) = 45
		or
		datediff(d,getDate(),EventBeginDate) = 30
		or
		datediff(d,getDate(),EventBeginDate) = 15
		or
		datediff(d,getDate(),EventBeginDate) = 1
	)
	and
	(
		not dbo.bfdate(eventupdatelastsent) = dbo.bfdate(getdate())
		or eventupdatelastsent is null
	)
GO
/****** Object:  StoredProcedure [dbo].[dataGridSchemaUpdate]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[dataGridSchemaUpdate](
@userId int,
@objectId int,
@visibilityCSV varchar(max),
@orderCSV varchar(max),
@sizeCSV varchar(max),
@orderBy int,
@orderDirection int
) as begin
	declare @colOrder table(columnIndex int identity,value varchar(50));
	declare @colSize table(columnIndex int identity,value varchar(50));
	declare @colVisibility table(columnIndex int identity,value varchar(50));
	declare @dir varchar(5)
	insert into @colOrder select * from dbo.SPLIT(@orderCSV,',',1,1);
	insert into @colSize select * from dbo.SPLIT(@sizeCSV,',',1,1);
	insert into @colVisibility select * from dbo.SPLIT(@visibilityCSV,',',1,1);
	if exists(select 0 from 
			ui_columns	where ui_columnID like cast(@objectId as varchar(50))+'_%') begin
		update ui_columns set
		userId = @userId,
		objectId = @objectId,
		colOrder = _colOrder,
		size = _size,
		orderby = @orderBy,
		direction = @orderDirection,
		visibility = _visibility
		from (
			select o.value as _colOrder, s.value as _size, v.value as _visibility, o.columnIndex as _columnIndex from
			@colOrder o
			inner join @colSize s on o.columnIndex = s.columnIndex
			inner join @colVisibility v on o.columnIndex = v.columnIndex
		) t
		where ui_columnID = cast(cast(@objectId as varchar(50))+'_'+cast(_columnIndex as varchar(50)) as varchar(100))
	end else begin
		insert into ui_columns select cast(cast(@objectId as varchar(50))+'_'+cast(o.columnIndex as varchar(50)) as varchar(100)) as ui_columnID,
		@userId as userId,
		@objectId,
		o.value as colOrder,
		s.value as colSize,
		@orderBy as orderby,
		@orderDirection as direction,
		v.value as visibility,
		null as VerCol
		from @colOrder o
		inner join @colSize s on o.columnIndex = s.columnIndex
		inner join @colVisibility v on o.columnIndex = v.columnIndex
	end
end
GO

/****** Object:  StoredProcedure [dbo].[crud]    Script Date: 05/30/2011 18:14:09 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[crud](
	@objectName varchar(100),
	@row hashTable READONLY,
	@overwrite bit,
	@commandType int
) as
begin
	/* 
	Updates a table -
	uses row versioning to detect dirty data
	
	0 success
	-1 =! @timestamp
	-2 record deleted
	other is generated by SQL
	*/
	set nocount on
	declare @statement nvarchar(max);
	if @commandType = 0 begin /* 0 update */
		declare @setStatement varchar(max);
		declare @primaryKeyName varchar(100);
		declare @primaryKeyValue sql_variant;
		declare @timestamp sql_variant;
		SELECT @setStatement=coalesce(@setStatement,'')+'['+keyname+'] = '+dbo.hashColToUpdateString(keyvalue,dataType,dataLength,varCharMaxValue)
		from @row where not keyName = 'VerCol' and primary_key = 0;
		select @primaryKeyName = keyname,@primaryKeyValue = keyvalue from @row where primary_key = 1;
		select @timestamp = keyvalue from @row where keyName = 'VerCol';
		SET @setStatement = substring(@setStatement,1,LEN(@setStatement)-1);
		set @statement = 'select 0 from ['+@objectName+']'+
		' where '+@primaryKeyName+' = '''+convert(varchar(max),@primaryKeyValue)+''' and cast(['+@objectName+'].[VerCol] as int) = '+cast(@timestamp as varchar(50));
		declare @tab table(val varchar(max));
		insert into @tab exec sp_executesql @statement;
		if exists(select 1 from @tab) or @overwrite = 1 begin
			set @statement = 'update ['+@objectName+'] set '+@setStatement+
			' where '+@primaryKeyName+' = '''+convert(varchar(max),@primaryKeyValue)+'''';
			BEGIN TRY
				exec sp_executesql @statement;
				declare @timeStampStatement nchar(255) = 'select verCol from ['+@objectName+'] where ['+@primaryKeyName+'] = '''+replace(cast(@primaryKeyValue as varchar(50)),'''','''''')+'''';
				declare @newTimeStampTable table (vercol int);
				print @timeStampStatement
				insert into @newTimeStampTable exec sp_executesql @timeStampStatement;
				declare @newTimestamp int = (select cast(vercol as int) from @newTimeStampTable);
				select 0 as status,'Record updated successfully' as description, @primaryKeyValue as primaryKey,@newTimestamp as VerCol;
			END TRY
			BEGIN CATCH
				select ERROR_NUMBER() as status,ERROR_MESSAGE() as description, null as primaryKey;
			END CATCH;
		end else begin
			set @statement = 'select 0 from ['+@objectName+']'+
			' where '+@primaryKeyName+' = '''+convert(varchar(max),@primaryKeyValue)+'''';
			delete from @tab;
			insert into @tab exec sp_executesql @statement;
			if exists(select 0 from @tab) begin
				select -1 as status,'Record has changed since last refresh' as description, @primaryKeyValue as primaryKey,-1 as VerCol;
			end else begin
				select -2 as status,'The record has been deleted' as description, @primaryKeyValue as primaryKey,-1 as VerCol;
			end
		end
	end else if @commandType = 1 begin /* 1 insert */
		declare @namePart varchar(max);
		declare @valuePart varchar(max);
		select @primaryKeyName = keyname,@primaryKeyValue = keyvalue from @row where primary_key = 1;
		SELECT @namePart=coalesce(@namePart,'')+'['+keyname+'],',
		@valuePart=coalesce(@valuePart,'')+dbo.hashColToUpdateString(keyvalue,dataType,dataLength,varCharMaxValue)
		from @row where not keyName = 'VerCol';
		SET @namePart = substring(@namePart,1,LEN(@namePart)-1);
		SET @valuePart = substring(@valuePart,1,LEN(@valuePart)-1);
		set @statement = 'insert into ['+@objectName+'] ('+@namePart+') values ('+@valuePart+')';
		if @overwrite = 1 begin
			/* delete any existing PKs with the same name when in overwrite mode to prevent PK conflicts */
			declare @delstatement nvarchar(max);
			set @delstatement = 'delete from ['+@objectName+']'+
			' where '+@primaryKeyName+' = '''+convert(varchar(max),@primaryKeyValue)+'''';
			exec sp_executesql @delstatement;
		end
		BEGIN TRY
			print @statement
			exec sp_executesql @statement;
			select 0 as status,'Record inserted successfully' as description, @primaryKeyValue as primaryKey,-1 as VerCol;
		END TRY
		BEGIN CATCH
			select ERROR_NUMBER() as status,ERROR_MESSAGE() as description, null as primaryKey,-1 as VerCol;
		END CATCH;
		
	end else if @commandType = 2 begin /* 2 delete */
		declare @dataType varchar(50);
		declare @dataLength int;
		declare @value sql_variant;
		declare @varCharMaxValue varchar(max);
		select @primaryKeyName = keyname,@primaryKeyValue = keyvalue, @dataType = dataType, @dataLength = dataLength,
		@value = keyValue, @varCharMaxValue = varCharMaxValue from @row where primary_key = 1;
		set @statement = 'delete from ['+@objectName+'] where ['+@primaryKeyName+']= '+dbo.hashColToUpdateString(@value,@dataType,@dataLength,@varCharMaxValue)
		SET @statement = substring(@statement,1,LEN(@statement)-1);
		BEGIN TRY
			exec sp_executesql @statement;
			--print @statement
			select 0 as status,'Record deleted successfully' as description, @primaryKeyValue as primaryKey,-1 as VerCol;
		END TRY
		BEGIN CATCH
			select ERROR_NUMBER() as status,ERROR_MESSAGE() as description, null as primaryKey,-1 as VerCol;
		END CATCH;
	end
	set nocount off
end
GO

/****** Object:  StoredProcedure [dbo].[createSession]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[createSession](
@default_order_by as int,
@default_list_mode as int,
@default_records_per_page as int,
@referer as varchar(500),
@userAgent as varchar(500),
@ipAddr varchar(15),
@unique_site_id uniqueidentifier
) as
begin
SET NOCOUNT ON 

DECLARE @GUID as uniqueidentifier set @GUID = newID() 
insert into visitors (sessionID,userID,RecordsPerPage,orderby,listmode,addDate,HTTP_REFERER,HTTP_USER_AGENT,REMOTE_ADDR,zip,rate,context,unique_site_id) 
values (@GUID,-1,@default_records_per_page,@default_order_by,@default_list_mode,GETDATE(),@referer,@userAgent,@ipAddr,'','','',@unique_site_id) 
SELECT @GUID as sessionID
end
GO
/****** Object:  StoredProcedure [dbo].[createContact]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[createContact](
	@contactId uniqueidentifier,
	@sessionId uniqueidentifier,
	@userId int,
	@rate int,
	@country varchar(100)
) as begin
insert into contacts
(contactId, firstName, lastName, address1, address2, city, 
state, zip, country, homePhone, workPhone,
email, specialInstructions, sendShipmentUpdates, comments, 
emailAds, rate, company, dateCreated, shippingQuote, weight,
 taxRate, sessionId, userId, VerCol)
 values
 (
 @contactId,
 '','','','','','','',@country,'','','','','','',0/*emailAds*/,
 @rate,'',getDate()/*dateCreated*/,0,0,0,@sessionId,@userId,null
 )
 end
GO
/****** Object:  StoredProcedure [dbo].[createAccount]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[createAccount] (
	@email varchar(255),
	@password varchar(255),
	@sessionId uniqueidentifier,
	@default_new_user_allow_preorder bit,
	@defaultRateId int,
	@customUserId sql_variant,
	@unique_site_id uniqueidentifier
) as
begin
/* createAccount version 0.1.0 */
declare @accountType int = 0;/* customer recieivable */
declare @newUserId int = -1;
declare @newUserIdTable table(newUserId int);
begin try
if ISNUMERIC(convert(int,@customUserId)) = 1 begin
	set @newUserId = convert(int,@customUserId)
end
end try
begin catch
	set @newUserId = -1
end catch
if @newUserId = -1 begin
	while( exists(select 0 from users with (nolock) where userId = @newUserId) or @newUserId = -1) begin
		/* virtual copy of getNewAccountNumber version 0.1.0 */
		set @newUserId = (
			select case when MAX(userId) is null then MAX(at.rangeLow)+1 else MAX(userId)+1 end
			from users with (nolock)
			inner join accountTypes at with (nolock) on at.accountTypeId = @accountType
			and userId between at.rangeLow and at.rangeHigh
		)
	end
end

insert into users 
select @newUserId, userLevel, @email, @email, wholeSaleDealer, lastVisit, comments, @password,
administrator, wouldLikeEmail, createDate, @sessionId, quotaWholesale, quotaComplete,
quota, credit, loggedIn, purchaseAccount, creditLimit, contact, address1,
address2, zip, state, country, city, homePhone, companyEmail, fax, www, firstName,
lastName, termId, usesTerms, accountType, noTax, allowPreorders, FOB, packingSlip,
quote, invoice, logon_redirect, admin_script, rateId, workPhone, sendShipmentUpdates,
autoFillOrderForm, estTransitTime, estLeadTime, UI_JSON, assetAccount, defaultPrinterPath, null
from users with (nolock) where userId = 10000000

select @newUserId
end
GO
/****** Object:  UserDefinedFunction [dbo].[ConcatSizes]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[ConcatSizes] (

      @itemnumber      varchar(50)
                  )  
RETURNS varchar(1000)
AS
BEGIN 
      
      Declare @String varchar(1000)

      Set @String = ''

      Select @String = @String  + rtrim(sizeId) + ',' From items with (nolock) where parentItemnumber = @itemnumber group by sizeId
	  
      Return case when len(@String)>0 then substring(@String,0,len(@String)) else '' end

END
GO
/****** Object:  UserDefinedFunction [dbo].[ConcatCategoryName]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[ConcatCategoryName] (

      @ID      varchar(50)
                  )  
RETURNS varchar(1000)
AS  

BEGIN 
      
      Declare @String varchar(1000)

      Set @String = ''

      Select @String = @String + rtrim((select category from dbo.Categories c where c.CategoryID = d.CategoryID)) + ',' + char(13) +  char(10)  From dbo.CategoryDetail d Where itemnumber = @Id
	  
      Return case when len(@String)>0 then substring(@String,0,len(@String)-1) else '' end

END
GO
/****** Object:  StoredProcedure [dbo].[checkitemimages]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[checkitemimages](
	@newimageid uniqueidentifier,
	@itemnumber varchar(50)
)
as
begin
	if not exists(select * from imaging where imagingid = (select m from items where itemnumber = @itemnumber))
	begin
		update items set m = @newimageid where itemnumber = @itemnumber
	end
	if not exists(select * from imaging where imagingid = (select c from items where itemnumber = @itemnumber))
	begin
		update items set c = @newimageid where itemnumber = @itemnumber
	end
	if not exists(select * from imaging where imagingid = (select f from items where itemnumber = @itemnumber))
	begin
		update items set f = @newimageid where itemnumber = @itemnumber
	end
	if not exists(select * from imaging where imagingid = (select t from items where itemnumber = @itemnumber))
	begin
		update items set t = @newimageid where itemnumber = @itemnumber
	end
	if not exists(select * from imaging where imagingid = (select a from items where itemnumber = @itemnumber))
	begin
		update items set a = @newimageid where itemnumber = @itemnumber
	end
	if not exists(select * from imaging where imagingid = (select x from items where itemnumber = @itemnumber))
	begin
		update items set x = @newimageid where itemnumber = @itemnumber
	end
	if not exists(select * from imaging where imagingid = (select y from items where itemnumber = @itemnumber))
	begin
		update items set y = @newimageid where itemnumber = @itemnumber
	end
	if not exists(select * from imaging where imagingid = (select z from items where itemnumber = @itemnumber))
	begin
		update items set z = @newimageid where itemnumber = @itemnumber
	end
	if not exists(select * from imaging where imagingid = (select b from items where itemnumber = @itemnumber))
	begin
		update items set b = @newimageid where itemnumber = @itemnumber
	end
	if not exists(select * from imaging where imagingid = (select d from items where itemnumber = @itemnumber))
	begin
		update items set d = @newimageid where itemnumber = @itemnumber
	end
end
GO
/****** Object:  StoredProcedure [dbo].[blogYearCategories]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[blogYearCategories] (@blogCategoryId uniqueidentifier) as begin
select 
DATENAME(year,addDate) as [year],
COUNT(0) as [count],
@blogCategoryId,
-1 as VerCol
from blogs
where blogCategoryId = @blogCategoryId
group by DATENAME(year,addDate)

end
GO
/****** Object:  View [dbo].[blogUsers]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[blogUsers] as 
select 
author
from blogCategories
group by author
GO
/****** Object:  StoredProcedure [dbo].[depleteInventory]    Script Date: 03/11/2011 19:45:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[depleteInventory](
	@itemnumber varchar(50),
	@qty int,
	@cartID uniqueidentifier,
	@depleteInventoryFlag int
)
as
begin
	DECLARE @stockstate bit
	DECLARE @subitem char(100)
	DECLARE @subqty int
	DECLARE @vendorItemID uniqueidentifier
	DECLARE @vendorID int
	DECLARE @cost money
	DECLARE @allowPreorders bit
	DECLARE @consumedQty int
	DECLARE @qtyOnHand int
	DECLARE @totalQtyConsumed int
	DECLARE @outOfStock bit
	DECLARE @depleteOnFlag int
	DECLARE kitAlloc CURSOR FOR
	SELECT subitemnumber,qty 
	FROM itemdetail with (nolock)
	WHERE itemnumber = @itemnumber;
--Select the item from the vendors table
	
	/* this should be a while loop that continues to deplete the top 1 until the inventory is filled or the query is null */
	
	/* Start removing items from the whole inventory item vendor thingy 
	set a pont to roll back to in case inventory runs dry way in here
	
	The other way I thought of doing this was to check the items inventory level then start the loop,
	but I don't see the pros of doing it that way, and it will require an extra query against the inventory table
	so until this approach fails in some way ...	
	*/
	SET NOCOUNT ON
/* Begin actual procedure - set point to rollback transaction */
	select top 1 @allowPreorders = allowPreorders, @depleteOnFlag = inventoryDepletesOnFlagId 
	from Items with (nolock) where Itemnumber = @itemnumber
	if @depleteOnFlag = @depleteInventoryFlag
	begin
		SAVE TRANSACTION depleteqty
		SET @totalQtyConsumed = 0
		SET @outOfStock = 0
		while @totalQtyConsumed < @qty and @outOfStock = 0
		begin
			SET @consumedQty = 0
			SET @vendorItemID = null
			--Select any items that are avaliable at the time
			select top 1 @vendorItemID = vendorItemID, @vendorID = vendorID, @cost = price, @qtyOnHand = qtyOnHand 
			from vendorItems
			where qtyOnHand > 0 and itemnumber = @itemnumber
			order by depletionOrder desc, recievedOn asc
			--If there were any items at all  - if not set out of stock which will exit the loop
			if @vendorItemID is null
			begin
				SET @outOfStock = 1
			end
			else
			begin
				--there was no PO that could fill what QTY was left, any transactions thus far will be rolled back.
				--If there were more or equal items on hand (on this PO) than there were on this line
				if  @qtyOnHand >= (@qty-@totalQtyConsumed)
				begin
					SET @consumedQty = @qty - @totalQtyConsumed
				end
				--If there were fewer items on hand (on this PO) than there were on this line
				if @qtyOnHand < (@qty-@totalQtyConsumed)
				begin
					SET @consumedQty = @qtyOnHand
				end
				SET @totalQtyConsumed = @totalQtyConsumed + @consumedQty
				--Remove the item from the vendors table
				update vendorItems set qtyOnHand = qtyOnHand - @consumedQty where vendorItemID = @vendorItemID			
			end
		end
		if @outOfStock = 1
		begin
			/* The line item was fully filled by inventory, commit the transaction */
			ROLLBACK TRANSACTION depleteqty
		end
	end

--Add this item to the kitAllocation table
	
	insert into kitAllocation (cartID,itemNumber,qty,vendorItemKitAssignmentId,itemConsumed,allowPreorders) values (@cartID,@itemnumber,@qty,@vendorItemID,0,@allowPreorders)
	OPEN kitAlloc;
	FETCH NEXT FROM kitAlloc
	INTO @subitem, @subqty
	WHILE @@FETCH_STATUS = 0
	BEGIN
--Add addtional weight from BOM items
		--exec dbo.depleteInventory @subitem, @qty, @cartid
		FETCH NEXT FROM kitAlloc
		INTO @subitem, @qty
	END;
	CLOSE kitAlloc;
	DEALLOCATE kitAlloc;
end
GO
/****** Object:  StoredProcedure [dbo].[emptyCart]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[emptyCart](@sessionId uniqueidentifier)
as
begin
	delete from cart where sessionid = @sessionId;
end
GO
/****** Object:  StoredProcedure [dbo].[updateTimer]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[updateTimer]
@timerId uniqueidentifier,
@currentItemName varchar(max),
@totalItemCount bigint,
@currentItemCount bigint,
@totalItemSize bigint,
@currentItemSize bigint,
@currentSizeComplete bigint,
@complete bit,
@started varchar(50),
@updated varchar(50)
as begin
	if not exists(select 0 from timer where timerId = @timerId) begin
		insert into timer (timerId, currentItemName, totalItemCount, currentItemCount, totalItemSize, currentItemSize, currentSizeComplete, complete, started, updated)
		values (@timerId, @currentItemName, @totalItemCount, @currentItemCount, @totalItemSize, @currentItemSize, @currentSizeComplete, @complete, convert(varchar(50),@started, 21), convert(varchar(50),@updated, 21))
	end else begin
		update timer
		set 
		currentItemName = @currentItemName, 
		totalItemCount = @totalItemCount, 
		currentItemCount = @currentItemCount, 
		totalItemSize = @totalItemSize, 
		currentItemSize = @currentItemSize,
		currentSizeComplete = @currentSizeComplete,
		complete = @complete,
		started = convert(varchar(50),@started, 21), 
		updated = convert(varchar(50),@updated, 21)
		where timerId = @timerId
	end
end
GO
/****** Object:  StoredProcedure [dbo].[updateTaskStatus]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[updateTaskStatus] (
	@taskId uniqueIdentifier, @startTime datetime,@lock bit,
	@lastRun datetime,@error varchar(20),@errorDesc varchar(max)
) as begin
	update eventHandlers set
	startTime = @startTime,
	lock = @lock,
	lastRun = @lastRun,
	error = @error,
	errorDesc = @errorDesc
	where taskId = @taskId;
end
GO
/****** Object:  StoredProcedure [dbo].[setReplyState]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[setReplyState](
	@replyId uniqueidentifier,
	@inappropriate bit,
	@approve bit,
	@disapprove bit,
	@userId int,
	@sessionId uniqueidentifier
) as begin
	if not exists(select 0 from duplicateChecking where refrenceId = @replyId and userId = @userId and sessionId = @sessionId) begin
		update replies
		set
		flaggedInappropriate = case when @inappropriate = 1 then flaggedInappropriate+1 else flaggedInappropriate end,
		approves = case when @approve = 1 then approves+1 else approves end,
		disapproves = case when @disapprove = 1 then disapproves+1 else disapproves end
		where replyId = @replyId
		insert into duplicateChecking select NEWID(), @replyId, @userId, @sessionId, GETDATE(), null
	end
	select approves, disapproves, flaggedInappropriate from replies where replyId = @replyId
end
GO
/****** Object:  StoredProcedure [dbo].[update_alt_category]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_alt_category]
AS UPDATE    dbo.Items
SET              HomeAltCategory =
                          (SELECT     TOP 1 Category
                            FROM          dbo.AltCategories
                            WHERE      Category LIKE '%' + items.itemnumber + '%')
GO
/****** Object:  View [dbo].[unpostedWorkOrders]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view
[dbo].[unpostedWorkOrders] as
/* unpostedOrders version 0.1.0 */
select
orderId,u.userId,handle,orderNumber,grandTotal,paid,purchaseOrder,manifest,orderDate
,o.subTotal,o.taxTotal,o.shippingTotal,o.discount, -1 as VerCol
from orders o with (nolock)
inner join users u with (nolock) on o.userId = u.userId
where o.generalLedgerInsertId = '00000000-0000-0000-0000-000000000000'
and accountType = 0 and closed = 1 and canceled = 0
GO
/****** Object:  View [dbo].[unpostedPurchaseOrders]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view
[dbo].[unpostedPurchaseOrders] as
/* unpostedOrders version 0.1.0 */
select
orderId,u.userId,handle,orderNumber,grandTotal,paid,purchaseOrder,manifest,orderDate
,o.subTotal,o.taxTotal,o.shippingTotal,o.discount, -1 as VerCol
from orders o with (nolock)
inner join users u with (nolock) on o.userId = u.userId
where o.generalLedgerInsertId = '00000000-0000-0000-0000-000000000000'
and accountType = 1 and canceled = 0 and closed = 1
GO
/****** Object:  View [dbo].[unpostedPayments]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view
[dbo].[unpostedPayments] as
/* unpostedPayments version 0.1.0 */
select
paymentMethodId,u.userId,u.handle,
paymentType, cardName, cardType, cardNumber, expMonth, expYear, secNumber,
p.sessionId, addressId, routingNumber, checkNumber, bankAccountNumber,
payPalEmailAddress, swift, bankName, routingTransitNumber, cash, notes, amount,
generalLedgerInsertId, promiseToPay, -1 as VerCol
from paymentMethods p with (nolock)
inner join users u with (nolock) on p.userId = u.userId
where p.generalLedgerInsertId = '00000000-0000-0000-0000-000000000000' and promiseToPay = 0
GO
/****** Object:  View [dbo].[unpaidOrders]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view
[dbo].[unpaidOrders] as
/* unpaidOrders version 0.1.0 */
select
o.orderId,u.userId,handle,orderNumber,grandTotal,o.paid,purchaseOrder,manifest,orderDate
,o.subTotal,o.taxTotal,o.shippingTotal,o.discount,-1 as VerCol
from orders o with (nolock)
inner join users u with (nolock) on o.userId = u.userId
inner join paymentMethodsDetail pd with (nolock) on pd.orderId = o.orderId
inner join paymentMethods p with (nolock) on pd.paymentMethodId = p.paymentMethodId and promiseToPay = 1
where grandTotal > o.paid and canceled = 0
GO
/****** Object:  View [dbo].[unconsumedPayments]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[unconsumedPayments] as
/* unconsumedPayments version 0.1.0 */
select 
p.paymentMethodId,
p.amount-SUM(case when pd.amount is null then 0 else pd.amount end) as remainingAmount,
p.amount totalAmount,
paymentType, SUM(case when pd.amount is null then 0 else pd.amount end) as usedAmount,

u.userId,u.handle,

cardName, cardType, cardNumber, expMonth, expYear, secNumber,
p.sessionId, addressId, routingNumber, checkNumber, bankAccountNumber,
payPalEmailAddress, swift, bankName, routingTransitNumber, cash, notes,
generalLedgerInsertId, promiseToPay, -1 as VerCol
from paymentMethods p with (nolock)
left join paymentMethodsDetail pd with (nolock) on pd.paymentMethodId = p.paymentMethodId
inner join users u with (nolock) on p.userId = u.userId
group by p.paymentMethodId,u.userId,u.handle,
paymentType, p.amount, cardName, cardType, cardNumber, expMonth, expYear, secNumber,
p.sessionId, addressId, routingNumber, checkNumber, bankAccountNumber,
payPalEmailAddress, swift, bankName, routingTransitNumber, cash, notes,
generalLedgerInsertId, promiseToPay
having p.amount-SUM(case when pd.amount is null then 0 else pd.amount end) > 0
GO
/****** Object:  Trigger [tr_sumKitItems]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[tr_sumKitItems]
   ON [dbo].[itemDetail]
   AFTER insert
AS 
BEGIN
	SET NOCOUNT ON;
	/* don't happen on multi line inserts */
	if ((select count(0) from inserted) = 1) begin
		declare @insertedQty int;
		declare @insertedId uniqueidentifier;
		declare @itemNumber varchar(50);
		declare @subItemNumber varchar(50);
		select top 1 @insertedId=inserted.itemDetailId,@insertedQty=qty,@itemNumber = @itemNumber, @subItemNumber = subItemNumber from inserted
		if exists(select 0 from itemDetail where itemnumber = @itemNumber and subItemnumber = @subItemNumber) begin
			delete from itemDetail where itemDetailId = @insertedId
			update itemDetail set qty=qty+@insertedQty where itemnumber = @itemNumber and subItemnumber = @subItemNumber 
		end
	end
END
GO
/****** Object:  View [dbo].[purchaseorders]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[purchaseorders] as 
select
cast(vendorID as varchar(50))+''+poNumber as PK,
vendorId,
ponumber,
COUNT(ponumber) as line_count,
sum(price) as cost_total,
sum(qtyOnHand) as qtyOnHand_total,
sum(qtyReceived) as qty_received,
sum(qtyOrdered) as qty_ordered,
addedOn,
estimatedRecieveDate,
description,
recievedOn,
addedBy from vendoritems with (nolock)
group by vendorID,poNumber,addedOn,estimatedRecieveDate,description,recievedOn,addedBy
GO
/****** Object:  View [dbo].[public_user]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[public_user]
as
select 
	v.sessionid, v.userid, 
	case when v.zip is null then '' else v.zip end as zip, 
	case when v.rate is null then -1 else v.rate end as rate, 
	case when v.Context is null then '' else v.Context end as Context, 
	v.RecordsPerPage, v.orderby, v.listmode, 
	case when u.administrator is null then 0 else u.administrator end as administrator, 
	case when u.wholesaledealer is null then 0 else u.wholesaledealer end as wholesaler,
	case when u.userlevel is null then 0 else u.userlevel end as userlevel,
	case when u.email is null then '' else u.email end as user_email,
	case when u.allowPreorders is null then 0 else u.allowPreorders end as allowPreorders,
	case when u.admin_script is null then '' else u.admin_script end as admin_script,
	case when u.logon_redirect is null then '' else u.logon_redirect end as logon_redirect,
	case when u.UI_JSON is null then '' else u.UI_JSON end as UI_JSON
from visitors v
left join users u on u.userid = v.userid
GO
/****** Object:  View [dbo].[shortOrderList]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[shortOrderList] as
select orders.orderId, orderNumber, users.handle, orderDate, purchaseOrder, manifest, paid, flagTypes.flagTypeName, 
case when paid = grandTotal then
	1000000
else
	datediff(d,dateadd(d,terms.termDays,orderDate),getDate())*-1
end	as dueIn, deliverBy, termName, -1 as VerCol
from orders
inner join users with (nolock) on orders.userId = users.userid
inner join terms with (nolock) on orders.termId = terms.termId
inner join serial_order with (nolock) on serial_order.orderId = orders.orderId
inner join flagTypes with (nolock) on serial_order.lastFlagStatus = flagTypes.flagTypeId
GO
/****** Object:  View [dbo].[shortItemList]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[shortItemList] as
select itemNumber, shortDescription, -1 as VerCol from items
GO
/****** Object:  StoredProcedure [dbo].[toJSON]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[toJSON] 
			@objName varchar(50), 
			@record_from int, 
			@record_to int, 
			@suffix varchar(max), 
			@userId int, 
			@searchSuffix varchar(max), 
			@aggregateColumns varchar(max),
			@selectedRowsCSV varchar(max),
			@includeSchema bit,
			@checksum bigint,
			@delete bit,
			@orderBy_override varchar(50),
			@orderDirection_override varchar(4)
		as
			/* toJSON version 1.0 */
			set XACT_ABORT ON
			set nocount on
			if(LEN(@objName)=0)begin return end
			declare @name varchar(50)
			declare @type varchar(50)
			declare @newChecksum bigint
			declare @max_length int
			declare @objectId int
			declare @colorder int
			declare @colSize int
			declare @orderBy int
			declare @direction bit
			declare @visibility bit
			declare @column_count int = 0
			declare @order_by_name varchar(1000) = '1'
			declare @order_by_direction_name varchar(4) = 'asc'
			declare @header varchar(max) = '';
			declare @schema varchar(max) = '';
			declare @current_pk_length int;
			declare @current_pk_dataType varchar(50);
			declare @sql varchar(max) = '';
			declare @searchCols varchar(max) = '';
			declare @defaultValue varchar(max) = '';
			declare @pramDef int;
			declare @description varchar(max) = ''
			declare @is_nullable bit = 0;
			declare @primary_key bit = 0;
			declare @current_pk_column varchar(max);
			declare @displayName varchar(50);
			declare @hidden bit = 0;
			declare @tableDisplayName sql_variant;
			/* check column sizes */
			declare column_cursor cursor forward_only static for
				select syscolumns.name,
				s.DATA_TYPE,
				length,
				case when objectId is null then cast(syscolumns.id as varchar(50)) else objectId end as objectId,
				syscolumns.colOrder,
				case when size is null then 200 else size end as size,
				case when orderby is null then 0 else orderby end as orderby,
				case when direction is null then 0 else direction end as direction,
				case when visibility is null then 1 else visibility end as visibility,
				case when p.value is null then '' else convert(varchar(max),p.value) end as description,
				case when s.is_nullable is null then 0 else case when s.is_nullable = 'YES' then 1 else 0 end end as is_nullable,
				case when c.CONSTRAINT_NAME is null then 0 else 1 end as primary_key,
				case when m.text is null then '' else m.text end as defaultValue,
				case when dn.value is null then syscolumns.name else convert(varchar(max),dn.value) end as display_name,
				case when hd.value is null then 0 else convert(varchar(max),hd.value) end as hidden,
				case when tdn.value is null then @objName else tdn.value end as displayName
				from syscolumns with (NOLOCK)
				left join ui_columns on ui_columnID = cast(cast(syscolumns.id as varchar(50))+'_'+cast(colid as varchar(50)) as varchar(100)) and userid = @userId and objectId = syscolumns.id
				left join information_schema.columns s on s.TABLE_NAME = @objName and s.column_name = syscolumns.name
				left join sys.extended_properties p on p.name = 'MS_Description' and p.major_id = syscolumns.id and p.minor_id = colid and @includeSchema = 1
				left join sys.extended_properties dn on dn.name = 'displayName' and dn.major_id = syscolumns.id and dn.minor_id = colid and @includeSchema = 1
				left join sys.extended_properties tdn on tdn.name = 'displayName' and tdn.major_id = objectId and tdn.minor_id = 0 and @includeSchema = 1
				left join sys.extended_properties hd on hd.name = 'hidden' and hd.major_id = syscolumns.id and hd.minor_id = colid and @includeSchema = 1
				left join information_schema.constraint_column_usage u on u.TABLE_NAME = @objName and u.column_name = syscolumns.name and @includeSchema = 1 and substring(u.constraint_name,1,3) = 'PK_'
				left join information_schema.table_constraints c on CONSTRAINT_TYPE = 'PRIMARY KEY' and c.TABLE_NAME = u.TABLE_NAME and @includeSchema = 1
				left join syscomments m on m.id = syscolumns.cdefault and @includeSchema = 1
				where syscolumns.id = object_id(@objName) order by syscolumns.colid
			OPEN column_cursor;
			FETCH NEXT FROM column_cursor
			INTO @name, @type, @max_length, @objectId, @colorder, @colSize, @orderBy, @direction, @visibility, @description, @is_nullable, @primary_key, @defaultValue, @displayName, @hidden, @tableDisplayName
			WHILE @@FETCH_STATUS = 0
			BEGIN
				if (@primary_key=1) begin
					set @current_pk_column = @name;
					set @current_pk_dataType = @type;
					set @current_pk_length = @max_length;
				end
				if @type in ('text','varchar','nchar','char','ntext','nvarchar','sql_variant')  begin
					set @sql+='''"''+cast(case when ['+@name+'] is null then '''' else replace(replace(['+@name+'],''\'',''\\''),''"'',''\"'') end as varchar(max))+''",''+';
				end else if @type = 'timestamp' begin 
					set @sql+='''"''+cast(cast(['+@name+'] as int) as varchar(max))+''",''+';
				end else if @type = 'uniqueidentifier'  begin
					set @sql+='''"''+cast(case when ['+@name+'] is null then ''00000000-0000-0000-0000-000000000000'' else replace(replace(['+@name+'],''\'',''\\''),''"'',''\"'') end as varchar(36))+''",''+';
				end else if @type = 'datetime'  begin
					set @sql+='''"''+case when ['+@name+'] is null then '''' else convert(varchar,['+@name+'],100) end+''",''+';
				end else begin
					set @sql+='''"''+cast(case when ['+@name+'] is null then '''' else replace(replace(['+@name+'],''\'',''\\''),''"'',''\"'') end as varchar(max))+''",''+';
				end
				set @searchCols+='['+@name+'],'
				set @header+='{"name":"'+replace(@name,'"','\"')+'","dataType":"'+@type+'",
				"dataLength":'+cast(@max_length as varchar(50))+',
				"columnOrder":'+cast(@column_count as varchar(50))+',
				"columnSize":'+cast(@colSize as varchar(50))+',
				"visibility":'+cast(@visibility as varchar(50))+',
				"description":"'+replace(replace(@description,'"','\"'),'''','''''')+'",
				"isNullable":'+cast(@is_nullable as varchar(50))+',
				"primaryKey":'+cast(@primary_key as varchar(50))+',
				"defaultValue":"'+replace(cast(@defaultValue as varchar(50)),'"','\"')+'",
				"displayName":"'+replace(replace(cast(@displayName as varchar(50)),'"','\"'),'''','''''')+'",
				"hidden":'+cast(@hidden as varchar(50))+'
				},';
				if @orderBy = @column_count begin
					set @order_by_name = @name
				end
				if @direction=1 begin
					set @order_by_direction_name = 'desc';
				end
				if len(@orderBy_override) > 0 begin
					set @order_by_name = @orderBy_override
				end
				if len(@orderDirection_override) > 0 begin
					set @order_by_direction_name = @orderDirection_override
				end
				set @column_count=@column_count+1;
				FETCH NEXT FROM column_cursor
				INTO @name, @type, @max_length, @objectId, @colorder, @colSize, @orderBy, @direction, @visibility, @description, @is_nullable, @primary_key,@defaultValue, @displayName, @hidden, @tableDisplayName
			END
			CLOSE column_cursor;
			DEALLOCATE column_cursor;
			declare @count table(row_count int);
			declare @tableChecksum table(tableChecksum bigint);
			if(@includeSchema=1) begin
				insert into @count exec ('select cast(count(1) as varchar(50)) from ['+@objName+'] '+@suffix);
			end else begin
				insert into @count select -1
			end
			insert into @tableChecksum exec ('select sum(cast(BINARY_CHECKSUM(VerCol) as bigint)) from ['+@objName+']'); /* checksum looks w/o suffix */
			set @newChecksum = (select tableChecksum from @tableChecksum)
			set @sql = SUBSTRING(@sql,0,len(@sql)-2)
			declare @newTableChecksum bigint = (select CAST(tableChecksum as varchar(100)) from @tableChecksum)
			set @schema = '{
			"error":0,
			"errorDesc":"",
			"objectId":'+cast(@objectId as varchar(50))+',
			"columns":'+CAST(@column_count as varchar(50))+',
			"records":'+(select cast(row_count as varchar(50)) from @count)+',
			"orderBy":'+cast(@orderBy as varchar(50))+',
			"orderByDirection":'+cast(@direction as varchar(50))+',
			"checksum":'+cast(case when @newTableChecksum is null then -1 else @newTableChecksum end as varchar(100))+',
			"name":"'+@objName+'",
			"displayName":"'+cast(@tableDisplayName as varchar(100))+'"}';
			set @header = SUBSTRING(@header,1,len(@header)-1)
			set @searchCols = SUBSTRING(@searchCols,1,len(@searchCols)-1)
			if (@searchSuffix = '' and @aggregateColumns = '') begin
				set @sql = '
				select '''+@schema+''' as JSON,-2 as ROW_NUMBER,NULL as PK,NULL as PK_DATATYPE,0 as PK_DATALENGTH
				union all
				select ''['+case when @includeSchema = 1 then @header else '' end+']'' as JSON,-1 as ROW_NUMBER,NULL as PK,NULL as PK_DATATYPE,0 as PK_DATALENGTH
				union all 
				select JSON,ROW_NUMBER,PK,NULL as PK_DATATYPE,0 as PK_DATALENGTH
				from (
					select ''[''+' + @sql + ']'' as JSON,
					row_number() over(order by ['+@order_by_name+'] '+@order_by_direction_name+') as ROW_NUMBER,'+
					case when len(@current_pk_column) > 0 then
						' ['+@current_pk_column+'] as PK,
						'''+@current_pk_dataType+''' as PK_DATATYPE, '''+cast(@current_pk_length as varchar(50))+''' as PK_DATALENGTH'
					else
						' NULL as PK,NULL as PK_DATATYPE,0 as PK_DATALENGTH '
					end+
				' from ['+@objName+'] with (NOLOCK) '+@suffix+') J where ' +
				case when @delete = 1 and len(@selectedRowsCSV) > 0 then
					'ROW_NUMBER in ('+@selectedRowsCSV+')'
				else
					'ROW_NUMBER between @Rfrom  and @Rto '
				end +' group by JSON,ROW_NUMBER,PK,PK_DATATYPE,PK_DATALENGTH order by ROW_NUMBER'
				
				if (@newChecksum = @checksum and @delete = 1 and len(@selectedRowsCSV) > 0) begin 
					print 'DELETE!'
					declare @jsonTable table(json varchar(max),row_number int, pk sql_variant,pk_datType varchar(50), pk_dataLength int)
					declare @prep nchar(1000) = 'EXEC sp_executesql @Rsql'
					insert into @jsonTable exec sp_executesql @prep,N'@Rsql ntext',@Rsql = @sql
					declare @csvPKList varchar(max) = '';
					select * from @jsonTable
					SELECT @csvPKList=COALESCE(@csvPKList,'')+''''+CONVERT(varchar(max),pk)+''',' from @jsonTable where ROW_NUMBER > 0
					set @csvPKList = SUBSTRING(@csvPKList,1,len(@csvPKList)-1)
					print @csvPKList;
					declare @deleteStatement varchar(max) = 'delete from ['+@objName+'] where ['+@current_pk_column+'] in ('+@csvPKList+')';
					set @schema = replace(@schema,'"errorDesc":""','"errorDesc":"One or more records deleted - JSON = deleted recordset"')
				end else begin 
					set @schema = replace(@schema,'"error":0','"error":-1')
					set @schema = replace(@schema,'"errorDesc":""','"errorDesc":"Table version checksum error / table has changed since last update - delete aborted."')
				end
			end else if (@aggregateColumns = '') begin/* search for a row number, don't output any data */
				set @sql = '
				select ROW_NUMBER
				from (
					select '+@searchCols+',
					row_number() over(order by ['+@order_by_name+'] '+@order_by_direction_name+') as ROW_NUMBER
					from '+@objName+' with (NOLOCK) '+@suffix+'
				) J '+@searchSuffix+' group by '+@searchCols+',ROW_NUMBER order by ROW_NUMBER
				'
			end else begin/* produce a list of aggregates (within @selectedRowsCSV if @selectedRowsCSV has data)*/
				declare @aggResults table(columnName varchar(50), result varchar(50));
				declare @splitDest table(val nvarchar(max));
				declare @aggDest table(col nvarchar(100),agg varchar(100));
				declare @colAgg table(col nvarchar(100),agg nvarchar(50));
				declare @select varchar(max);
				declare @group varchar(max);
				declare @aggWhere varchar(max) = '';
				set @SQL = '';
				insert into @splitDest select * from dbo.SPLIT(@aggregateColumns,',',0,0);
				insert into @colAgg select substring(val,0,CHARINDEX('|',val,0)) as col, substring(val,CHARINDEX('|',val,0)+1,999) as agg from @splitDest
				if(len(@selectedRowsCSV)>0) begin
					set @aggWhere = 'where ROW_NUMBER in ('+@selectedRowsCSV+')';
				end
				SELECT @SQL=COALESCE(@SQL,'')+CAST(' select ''{"name":"'+col+'","aggregateFunction":"'+agg+'","aggregateResult":''+cast('+agg+'(['+col+']) as varchar(100))+''}'' as JSON from (
					select ['+col+'] from 
					(select ['+col+'] from
						(select
							['+col+'],
							row_number() over(order by ['+@order_by_name+'] '+@order_by_direction_name+') as ROW_NUMBER
							from '+@objName+' with (NOLOCK) '+@suffix+'
						) J '+@aggWhere+' group by ['+col+'],ROW_NUMBER
					) F ) g union all ' AS VARCHAR(MAX))
				from @colAgg;
				if(len(@sql)>0) begin
					set @SQL = substring(@sql,0,len(@sql)-9)/*remove the last union all<space> command*/
				end
			end
			print @sql
			BEGIN TRY
				/* sp_executesql wrapper used to pass (and cache) very large query to sp_executesql */
				declare @prep2 nchar(1000) = 'EXEC sp_executesql @Rsql,N''@Rfrom int,@Rto int'',@Rfrom='+cast(@record_from as varchar(50))+',@Rto='+cast(@record_to as varchar(50))+''
				exec sp_executesql @prep2,N'@Rsql ntext',@Rsql = @sql
			END TRY
			BEGIN CATCH
				if(ERROR_NUMBER()=1204 or ERROR_NUMBER()=1205)begin
					/* if there was a deadlock then try again after the timeout */
					execute dbo.toJson
					@objName, 
					@record_from, 
					@record_to, 
					@suffix, 
					@userId, 
					@searchSuffix, 
					@aggregateColumns,
					@selectedRowsCSV,
					@includeSchema,
					@checksum,
					@delete,
					@orderBy_override,
					@orderDirection_override
				end
			END CATCH;
			if (@delete = 1 and len(@deleteStatement) > 0) begin
				/* execute delete statement after the select statment */
				print @deleteStatement;
				exec sp_executesql @prep,N'@Rsql ntext',@Rsql = @deleteStatement;
			end
			set nocount off
GO
/****** Object:  StoredProcedure [dbo].[updateShippingMethod]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[updateShippingMethod] @addressId uniqueidentifier, @rateId int
as
update contacts set rate = @rateId where contactId = @addressId
GO
/****** Object:  StoredProcedure [dbo].[updateRecordsPerPage]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[updateRecordsPerPage](@sessionId uniqueidentifier,@recordsPerPage int)
as
begin
	update visitors set recordsPerPage = @recordsPerPage where sessionid = @sessionId;
end
GO
/****** Object:  StoredProcedure [dbo].[updateOrderExtInfo]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[updateOrderExtInfo]
@orderId int,
@purchaseOrder varchar(100) = '',
@soldBy int = -1,
@manifestNumber varchar(100) = '',
@requisitionedBy int =-1,
@deliverBy dateTime = '1/1/1900 00:00:00.000',
@vendorAccountNumber varchar(100) = '',
@fob varchar(100) = '',
@parentOrderId int = 0,
@scannedImage varchar(50) = '',
@comments varchar(max),
@orderDate datetime,
@orderNumber varchar(50) as

update orders set
purchaseOrder = @purchaseOrder,
soldBy = @soldBy,
manifest = @manifestNumber,
requisitionedBy = @requisitionedBy,
deliverBy = @deliverBy,
vendor_accountNo = @vendorAccountNumber,
FOB = @fob,
parentOrderId = @parentOrderId,
scanned_order_image  = @scannedImage,
comment = @comments,
orderNumber = case when len(@orderNumber)=0 then orderNumber else @orderNumber end,
orderDate = @orderDate
where orderid = @orderid

update cart set estimatedFulfillmentDate = @deliverBy where orderId = @orderId
GO
/****** Object:  StoredProcedure [dbo].[updateOrderBy]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[updateOrderBy](@sessionId uniqueidentifier,@orderby int)
as
begin
	update visitors set orderby = @orderby where sessionid = @sessionId;
end
GO
/****** Object:  StoredProcedure [dbo].[updateListMode]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[updateListMode](@sessionId uniqueidentifier,@listmode int)
as
begin
	update visitors set listmode = @listmode where sessionid = @sessionId;
end
GO
/****** Object:  StoredProcedure [dbo].[updateKeywords]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[updateKeywords]
AS UPDATE    dbo.Items
SET              Keywords = Itemnumber + ' ' + Description + ' ' + ProductCopy
GO
/****** Object:  StoredProcedure [dbo].[updateExtOrderInfo]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[updateExtOrderInfo] 
	@orderId int,
	@purchaseOrder varchar(100),
	@soldBy int,
	@manifestNumber varchar(100),
	@requisitionedBy int,
	@deliverBy datetime,
	@vendorAccountNumber varchar(100),
	@fob varchar(50),
	@parentOrderId int,
	@scannedImage varchar(100),
	@comments varchar(max),
	@approvedBy int,
	@oldSessionId uniqueidentifier,
	@uniqueSiteId uniqueidentifier,
	@customOrderNumber varchar(50),
	@discountCode varchar(50)
	as begin
		/* updateExtOrderInfo version 1.1 */
		update orders set
		purchaseOrder = @purchaseOrder,
		soldBy = @soldBy,
		manifest = @manifestNumber,
		requisitionedBy = @requisitionedBy,
		deliverBy = @deliverBy,
		vendor_accountNo = @vendorAccountNumber,
		FOB = @fob,
		parentOrderId = @parentOrderId,
		scanned_order_image = @scannedImage,
		comment = @comments,
		approvedBy = @approvedBy,
		unique_siteId = @uniqueSiteId,
		recalculatedOn = GETDATE(),
		readyForExport = 0,
		discountCode = @discountCode
		where orderId = @orderId
		update attachments set referenceId = (
			select sessionId from orders where orderId = @orderId
		) where referenceId = @oldSessionId and referenceType = 'sessionId'
		if len(@customOrderNumber) > 0 begin
			update cart set orderNumber = @customOrderNumber where orderId = @orderId
			update orders set orderNumber = @customOrderNumber where orderId = @orderId
		end
	end
GO
/****** Object:  StoredProcedure [dbo].[updateContact]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[updateContact] 
	@contactId uniqueidentifier,
	@userId int = -1,
	@FirstName varchar(100) = null,
	@LastName varchar(100) = null,
	@Address1 varchar(100) = null,
	@Address2 varchar(100) = null,
	@City varchar(100) = null,
	@State varchar(100) = null,
	@Zip varchar(100) = null,
	@Country varchar(100) = null,
	@homePhone varchar(100) = null,
	@workPhone varchar(100) = null,
	@email varchar(100) = null,
	@SpecialInstructions varchar(5000) = null,
	@Comments varchar(5000) = null,
	@sessionId uniqueidentifier = null,
	@sendshipmentupdates bit = null,
	@emailads bit = null,
	@rate int = null,
	@Company varchar(100) = null
as
declare @sql nvarchar(4000)
if not exists(select 0 from contacts with (nolock) where ContactID = @contactId) begin
	insert into Contacts (ContactID, userID, FirstName, LastName, Address1, Address2, City, 
	State, ZIP, Country, HomePhone, WorkPhone, Email, SpecialInstructions, Comments, sessionID, 
	sendshipmentupdates, emailads, rate, dateCreated, Company, shippingQuote, taxRate,weight) values (
		@ContactID, @userId,
		case when @FirstName is null then '' else @FirstName end,
		case when @LastName is null then '' else @LastName end ,
		case when @Address1 is null then '' else @Address1 end ,
		case when @Address2 is null then '' else @Address2 end ,
		case when @City is null then '' else @City end ,
		case when @State is null then '' else @State end ,
		case when @ZIP is null then '' else @ZIP end ,
		case when @Country is null then '' else @Country end ,
		case when @HomePhone is null then '' else @HomePhone end ,
		case when @WorkPhone is null then '' else @WorkPhone end ,
		case when @Email is null then '' else @Email end ,
		case when @SpecialInstructions is null then '' else @SpecialInstructions end ,
		case when @Comments is null then '' else @Comments end ,
		case when @sessionID is null then '' else @sessionID end ,
		case when @sendshipmentupdates is null then 0 else @sendshipmentupdates end ,
		case when @emailads is null then 0 else @emailads end ,
		case when @rate is null then -1 else @rate end ,
		GETDATE(),
		case when @Company is null then '' else @Company end, 0/*shippingQuote*/,0,1
	)
end
else begin

	set @sql = 'update Contacts set';
	if(not @userID is null) begin
		set @sql =  @sql + ' userId = ' + cast(@userID as varchar(50)) + ',';
	end
	if(not @FirstName is null) begin
		set @sql =  @sql + ' firstName = ''' + replace(@FirstName,'''','''''') + ''',';
	end
	if(not @LastName is null) begin
		set @sql =  @sql + ' lastName = ''' + replace(@LastName,'''','''''') + ''',';
	end
	if(not @Address1 is null) begin
		set @sql =  @sql + ' Address1 = ''' + replace(@Address1,'''','''''') + ''',';
	end
	if(not @Address2 is null) begin
		set @sql =  @sql + ' Address2 = ''' + replace(@Address2,'''','''''') + ''',';
	end
	if(not @City is null) begin
		set @sql =  @sql + ' City = ''' + replace(@City,'''','''''') + ''',';
	end
	if(not @State is null) begin
		set @sql =  @sql + ' State = ''' + replace(@State,'''','''''') + ''',';
	end
	if(not @ZIP is null) begin
		set @sql =  @sql + ' ZIP = ''' + replace(@ZIP,'''','''''') + ''',';
	end
	if(not @Country is null) begin
		set @sql =  @sql + ' Country = ''' + replace(@Country,'''','''''') + ''',';
	end
	if(not @HomePhone is null) begin
		set @sql =  @sql + ' HomePhone = ''' + replace(@HomePhone,'''','''''') + ''',';
	end
	if(not @WorkPhone is null) begin
		set @sql =  @sql + ' WorkPhone = ''' + replace(@WorkPhone,'''','''''') + ''',';
	end
	if(not @Email is null) begin
		set @sql =  @sql + ' Email = ''' + replace(@Email,'''','''''') + ''',';
	end
	if(not @SpecialInstructions is null) begin
		set @sql =  @sql + ' SpecialInstructions = ''' + replace(@SpecialInstructions,'''','''''') + ''',';
	end
	if(not @sessionID is null) begin
		set @sql =  @sql + ' sessionID = ''' + replace(@sessionID,'''','''''') + ''',';
	end
	if(not @sendshipmentupdates is null) begin
		set @sql =  @sql + ' sendshipmentupdates = ' + cast(@sendshipmentupdates as varchar(20)) + ',';
	end
	if(not @emailads is null) begin
		set @sql =  @sql + ' emailads = ' + cast(@emailads as varchar(20)) + ',';
	end
	if(not @rate is null) begin
		set @sql =  @sql + ' rate = ''' + cast(@rate as varchar(20)) + ''',';
	end
	if(not @Company is null) begin
		set @sql =  @sql + ' Company = ''' + replace(@Company,'''','''''') + ''',';
	end
	set @sql =  substring(@sql,0,LEN(@sql))/*trim off last comma*/
	set @sql =  @sql + ' where ContactID = '''+ CAST(@contactID as varchar(50)) + '''';
	exec sp_executesql @sql	
end
GO
/****** Object:  View [dbo].[workInProgress]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[workInProgress] as
select c.itemNumber,i.shortDescription,t.prebook,t.ats,t.wip,t.volume,c.qty,o.orderNumber,
shipmentNumber,serialNumber,lineNumber,orderDate,manifest,purchaseOrder,
closed,canceled,u.userId,u.handle,o.deliverBy,parentItemNumber,
d.divisionName as division, s.size as size, w.code as swatch, o.orderId, c.cartId, -1 as VerCol
from cart c
inner join orders o on o.orderId = c.orderId
inner join users u on u.userId = o.userId and u.accountType = 1
inner join items i on c.itemNumber = i.itemNumber
inner join itemOnHandTemp t on t.itemNumber = i.itemNumber
inner join sizes s on s.sizeId = i.sizeId
inner join swatches w on w.swatchId = i.swatchId
inner join divisions d on d.divisionId = i.divisionId
where c.fulfillmentDate = '1/1/1900 00:00:00.000'
GO
/****** Object:  Trigger [tr_cart_subItemCalc_update]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE trigger [dbo].[tr_cart_subItemCalc_update]
on [dbo].[cartDetail]
after update, insert
as
/* tr_cart_subItemCalc_update version 1 */
SET XACT_ABORT ON 
declare @cartId uniqueidentifier = (select cartId from inserted)
declare @valueCostTotal money = (
	select case when sum(s.subPrices) is null then 0 else sum(s.subPrices) end from
	(
		SELECT d.cartId,case when not p.price is null then
			p.price
		else
			case when u.wholeSaleDealer = 1 then 
				m.wholeSalePrice
			else
				case when m.isOnSale = 1 then
					m.salePrice
				else
					m.price
				end
			end
		end as subPrices
		from cartDetail d with (nolock) 
		inner join cart c with (nolock) on c.cartId = d.cartId
		inner join items i with (nolock)  on c.itemNumber = i.itemNumber
		inner join (
			select itemNumber, subItemNumber, itemComponetType
			from itemDetail with (nolock) where onlyWhenSelectedOnForm = 1
			union all
			select itemNumber, itemProperty as subItemNumber, 'prop' as itemComponetType
			from itemProperties with (nolock) where BOMItem = 1
			union all
			select itemNumber, propertyValue as subItemNumber, itemProperty as itemComponetType
			from itemProperties with (nolock) where BOMItem = 1
		) b on b.itemNumber = i.itemNumber
		and (d.inputName = itemComponetType or itemComponetType = 'prop')
		and (
			(d.inputName = b.subItemNumber and (lower(d.value) = 'true' or lower(d.value) = 'on'))
			or (d.value = b.subItemNumber and d.inputName = itemComponetType)
		)
		inner join items m with (nolock)  on b.subItemNumber = m.itemNumber and m.noTax = 0
		inner join visitors v with (nolock)  on c.sessionId = v.sessionId
		inner join itemProperties pr with (nolock) on pr.BOMItem = 1 and d.value = pr.propertyValue
		left join users u with (nolock)  on u.userId = v.userId
		left join userPriceList p with (nolock)  on p.userId = u.userId and getdate() between fromdate and todate
		where d.cartId = @cartId
		group by d.cartId,p.price,m.price,m.salePrice,m.wholeSalePrice,u.wholeSaleDealer,m.isOnSale
	) s
)
declare @noTaxValueCostTotal money = (
	select case when sum(s.subPrices) is null then 0 else sum(s.subPrices) end from
	(
		SELECT d.cartId,case when not p.price is null then
			p.price
		else
			case when u.wholeSaleDealer = 1 then 
				m.wholeSalePrice
			else
				case when m.isOnSale = 1 then
					m.salePrice
				else
					m.price
				end
			end
		end as subPrices
		from cartDetail d with (nolock) 
		inner join cart c with (nolock) on c.cartId = d.cartId
		inner join items i with (nolock)  on c.itemNumber = i.itemNumber
		inner join (
			select itemNumber, subItemNumber, itemComponetType
			from itemDetail with (nolock) where onlyWhenSelectedOnForm = 1
			union all
			select itemNumber, itemProperty as subItemNumber, 'prop' as itemComponetType
			from itemProperties with (nolock) where BOMItem = 1
			union all
			select itemNumber, propertyValue as subItemNumber, itemProperty as itemComponetType
			from itemProperties with (nolock) where BOMItem = 1
		) b on b.itemNumber = i.itemNumber
		and (d.inputName = itemComponetType or itemComponetType = 'prop')
		and (
			(d.inputName = b.subItemNumber and (lower(d.value) = 'true' or lower(d.value) = 'on'))
			or (d.value = b.subItemNumber and d.inputName = itemComponetType)
		)
		inner join items m with (nolock)  on b.subItemNumber = m.itemNumber and m.noTax = 1
		inner join visitors v with (nolock)  on c.sessionId = v.sessionId
		left join users u with (nolock)  on u.userId = v.userId
		left join userPriceList p with (nolock)  on p.userId = u.userId and getdate() between fromdate and todate
		where d.cartId = @cartId
		group by d.cartId,p.price,m.price,m.salePrice,m.wholeSalePrice,u.wholeSaleDealer,m.isOnSale
	) s
)
update cart set noTaxValueCostTotal = @noTaxValueCostTotal, valueCostTotal = @valueCostTotal where cartId = @cartId
GO
/****** Object:  View [dbo].[xmlLineDetail]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[xmlLineDetail] as 
select inputName as name,
value as value,
cartId from
cartDetail
GO
/****** Object:  StoredProcedure [dbo].[orderXML]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[orderXML] (@orderNumber varchar(50)) as begin
	DECLARE @var XML
	set @var = (
	select 
	orderDate, grandTotal, taxTotal, subTotal, shippingTotal, manifest, purchaseOrder, discount, 
	comment, closed, canceled, terms, accountNumber, accountName, orderNumber, readyForExport, 
	recalculatedOn, soldBy, requisitionedBy, approvedBy, deliverBy, vendor_accountNo, FOB, 
	discountPct, discountCode, avgTaxRate, siteName, siteAddress, status, statusId, billToFirstName,
	 billToLastName, billToAddress1, billToAddress2, billToCity, billToState, billToZip, billToCountry, 
	 billToHomePhone, billToWorkPhone, billToEmail, billToSpecialInstructions, billToSendShipmentUpdates, 
	 billToComments, billToEmailAds, billToCompany, billToDateCreated, billToTaxRate, shipToFirstName, 
	 shipToLastName, shipToAddress1, shipToAddress2, shipToCity, shipToState, shipToZip, shipToCountry, 
	 shipToHomePhone, shipToWorkPhone, shipToEmail, shipToSpecialInstructions, shipToSendShipmentUpdates, 
	 shipToComments, shipToEmailAds, shipToCompany, shipToDateCreated, shipToShippingQuote, shipToWeight, 
	 shipToTaxRate, shippingName,
	qty, itemNumber, price, serialNumber, shipmentNumber, lineNumber, customerLineNumber, 
	description, flagTypeName, flagTypeId, canceledQty, backorderedQty, formName,
	input.name, value
	from orderHeader [order]
	inner join xmlLine [items] on [order].orderId = [items].orderId
	inner join xmlLineDetail input on input.cartId = [items].cartId
	where  [order].orderNumber = @orderNumber
	FOR XML AUTO,TYPE)
	select convert(varchar(max),@var)

end
GO
/****** Object:  StoredProcedure [dbo].[ordersXML]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[ordersXML] (@fromDate sql_variant, @toDate sql_variant, @userId sql_variant, @exported sql_variant) as begin
	DECLARE @var XML
	if @fromDate is null or @toDate is null begin
		set @fromDate = '1900-01-01 00:00:00.000'
		set @toDate = '2200-01-01 00:00:00.000'
	end
	if @userId is null begin
		set @userId = -1;
	end
	if @exported is null begin
		set @exported = -1;
	end
	set @var = (
	select 
	orderDate, grandTotal, taxTotal, subTotal, shippingTotal, manifest, purchaseOrder, discount, 
	comment, closed, canceled, terms, accountNumber, accountName, orderNumber, readyForExport, 
	recalculatedOn, soldBy, requisitionedBy, approvedBy, deliverBy, vendor_accountNo, FOB, 
	discountPct, discountCode, avgTaxRate, siteName, siteAddress, status, statusId, billToFirstName,
	 billToLastName, billToAddress1, billToAddress2, billToCity, billToState, billToZip, billToCountry, 
	 billToHomePhone, billToWorkPhone, billToEmail, billToSpecialInstructions, billToSendShipmentUpdates, 
	 billToComments, billToEmailAds, billToCompany, billToDateCreated, billToTaxRate, shipToFirstName, 
	 shipToLastName, shipToAddress1, shipToAddress2, shipToCity, shipToState, shipToZip, shipToCountry, 
	 shipToHomePhone, shipToWorkPhone, shipToEmail, shipToSpecialInstructions, shipToSendShipmentUpdates, 
	 shipToComments, shipToEmailAds, shipToCompany, shipToDateCreated, shipToShippingQuote, shipToWeight, 
	 shipToTaxRate, shippingName,exported,
	qty, itemNumber, price, serialNumber, shipmentNumber, lineNumber, customerLineNumber, 
	description, flagTypeName, flagTypeId, canceledQty, backorderedQty, formName,
	input.name, value
	from orderHeader [order]
	inner join xmlLine [items] on [order].orderId = [items].orderId
	inner join xmlLineDetail input on input.cartId = [items].cartId
	where
	orderDate between convert(datetime,@fromDate) and convert(datetime,@toDate)  
	and (accountNumber = convert(int,@userId) or convert(int,@userId) = -1) and (convert(bit,@exported) = exported or @exported = -1)
	FOR XML AUTO,TYPE, ROOT ('orders')
	)
	select convert(varchar(max),@var)

end
GO
/****** Object:  View [dbo].[wsimportview]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[wsimportview]
AS
SELECT     RTRIM(c.shipmentnumber) AS Transaction_ID, RTRIM(a.FirstName) + ' ' + RTRIM(a.LastName) AS ShipToName, rtrim(a.Address1) AS ShipToAddress1, 
                      rtrim(a.Address2) AS ShipToAddress2, rtrim(a.City) AS ShipToCity, dbo.abbrState(rtrim(a.State)) AS ShipToState, rtrim(a.ZIP) AS ShipToPostCode, RTRIM(a.FirstName) 
                      + ' ' + RTRIM(a.LastName) AS Payor_name, a.Address1 AS Payoraddr1, a.Address2 AS Payoraddr2, a.City AS Payorcity, dbo.abbrState(rtrim(a.State)) AS Payorstate, 
                      a.ZIP AS Payorpostcode, 'Clay Design, Inc.' AS shipfromname, '519 West 15th Street' AS shipfromline1, '' AS shipfromline2, 
                      'Long Beach' AS shipfromcity, 'CA' AS shipfromstate, '90813' AS shipfrompostcode, 'U.S.A.' AS shipfromcountry, a.weight, a.rate AS service_code, 
                      '' AS payment_code, a.SpecialInstructions AS reference_notes, '' AS dry_ice_weight, 'N' AS signature_release, a.HomePhone AS shipfromphone, 
                      '' AS ponum, t.thirdPartyAccountNumber AS payor_acc_no, a.AddressID,(select purchaseorder from orders where orderid = (select top 1 orderid from cart where shipmentnumber = c.shipmentnumber)) AS c063,
					 (select purchaseorder from orders where orderid = (select top 1 orderid from cart where shipmentnumber = c.shipmentnumber)) AS c067, '' AS c011, '' AS c022, '' AS c021, '0' AS sendmail, a.Email,
					  thirdPartyAccountName AS tpname, thirdPartyAccountState AS tpstate, thirdPartyAccountCountry AS tbcountry, thirdPartyAccountZip AS tpzip, 
					  thirdPartyAccountStreet AS tpstreet, thirdPartyAccountCity AS tpcity, 'www.claydesign.com' AS reName, '519 West 15th Street' AS ReStreet, 
                      'U.S.A.' AS reCountry, '90813-1505' AS reZip, 'CA' AS reState, 'Long Beach' AS recity, case when usethirdPartyAccount = 1 then 'Y' else 'S' end AS useTPAccount, a.HomePhone
FROM         (SELECT     shipmentnumber, addressid, userid
                       FROM          cart
                       GROUP BY shipmentnumber, addressid, userid) c INNER JOIN
                      dbo.Addresses a ON a.AddressID = c.addressid
						left Join
						dbo.thirdPartyShipping t on (t.rateID = a.rate and c.userid = t.userid)
GO
/****** Object:  StoredProcedure [dbo].[updateCartValues]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[updateCartValues](
	@sessionid uniqueidentifier,
	@wholesale bit,
	@userid int
)
as
begin 
	set nocount on	
	/* only check inventory for AR accounts */
	IF EXISTS(select 0 from users where userid = @userid and accounttype = 0)
	BEGIN
		/* check the inventory */	
		DECLARE @cartId uniqueidentifier
		DECLARE @itemnumber varchar(50)
		DECLARE @qty int
		declare @stock table(qty int, itemnumber varchar(50))
		DECLARE @itemcount int
		DECLARE @execStr nvarchar(250)
		DECLARE @stock_qty int
		DECLARE @outofstock_item varchar(50)
		DECLARE @lowStockQty int
		DECLARE @lowStockCount int
		DECLARE @max_per_item int
		DECLARE @inventoryErrors varchar(max)
		DECLARE @allowPreorders bit
		DECLARE @site_allowPreorders bit
		set @site_allowPreorders = (select top 1 site_allow_preorder from site_configuration)
		DECLARE cart_cursor CURSOR FOR
		SELECT itemnumber, sum(qty), count(*)
		FROM cart with (nolock) where sessionid = @sessionid group by itemnumber
		OPEN cart_cursor;
		FETCH NEXT FROM cart_cursor
		INTO @itemnumber, @qty, @itemcount
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @allowPreorders = 0
			
			insert into @stock 
			select ats as qty, @itemnumber as itemNumber from itemOnHandTemp where itemnumber = @itemnumber
			
			EXEC sp_executesql @execStr
			select @stock_qty = qty, @allowPreorders = items.allowPreorders from @stock s
			inner join Items on s.itemnumber = Items.itemnumber
			if ((@qty > @stock_qty) and @allowPreorders = 0 and @site_allowPreorders = 0)
			begin
				while exists(SELECT 0 FROM cart with (nolock) where sessionid = @sessionid and itemnumber = @itemnumber having SUM(qty) >@stock_qty)
				begin
					if @stock_qty = 0
					begin
						--If there is no stock then delete the item from the cart
						delete from CartDetail where cartID in (select cartid from Cart where Itemnumber = @itemnumber and SessionID = @sessionid)
						delete from Cart where Itemnumber = @itemnumber and SessionID = @sessionid
						SET @inventoryErrors = @inventoryErrors + '{"desc":"Item '+@itemnumber+' was completely out of stock and removed from your cart","error":1},'
					end
					else
					begin
						--check how many items are left compared to how many lines the user has in their cart
						SET @max_per_item = @stock_qty - @itemcount;
						if @max_per_item > 0
						begin
							--If there are enough to evenly devide amongst the bunch than do so using straight integer divide math
							update Cart set qty = (@stock_qty / @itemcount) where Itemnumber = @itemnumber and SessionID = @sessionid
							SET @inventoryErrors = @inventoryErrors + '{"desc":"You have selected more '+@itemnumber+' than there is in stock.'+
							' The remaining '+cast(@stock_qty as varchar(50))+' '+@itemnumber+'s have been distributed into your cart","error":2},'
						end
						else
						begin
							--If there isn't enough for 1 each, then delete the overage items and update the rest with 1
							delete from Cart where cartID in (select top (@max_per_item*-1) cartID from cart where Itemnumber = @itemnumber and SessionID = @sessionid)
							update Cart set qty = 1 where Itemnumber = @itemnumber and SessionID = @sessionid
							SET @inventoryErrors = @inventoryErrors + '{"desc":"You have selected more '+@itemnumber+' than there is in stock.'+
							' The remaining '+cast(@stock_qty as varchar(50))+' '+@itemnumber+'s have been distributed into your cart, however you have more line items than there are items in stock'+
							' so some of the items in your cart have been removed","error":3},'
						end
					end
				end
			end
			delete from @stock
			FETCH NEXT FROM cart_cursor
			INTO @itemnumber, @qty, @itemcount
		END;
		CLOSE cart_cursor;
		DEALLOCATE cart_cursor;
		
	END 
	/* update the values based on the form values and new qtys */
	update cart
	set valueCostTotal = c.valueCostTotal,noTaxValueCostTotal = c.noTaxValueCostTotal
	from cart
		inner join (select cart.cartid,sum(
				case 
				when not il.price is null then il.price  
				when @wholesale = 1 and not i.wholesalePrice is null then i.wholesalePrice
				when i.isonsale = 1 and not i.salePrice is null then i.salePrice
				when not i.price is null then i.price
				when not i.price is null and i.price > 0 then i.price
				else 0
				end
				) as valueCostTotal,
				sum(
				case 
				when not tl.price is null then tl.price 
				when @wholesale = 1 and not t.wholesalePrice is null then t.wholesalePrice
				when t.isonsale = 1 and not t.salePrice is null then t.salePrice
				when not t.price is null then t.price
				when not t.price is null and t.price > 0 then i.price
				else 0
				end
				) as noTaxValueCostTotal
			from cart
				inner join cartdetail d with (nolock) on cart.cartid = d.cartid
				inner join items p with (nolock) on p.parentItemNumber = cart.itemNumber and d.inputName = 'childItem' and d.value = p.itemNumber
				left join items i with (nolock) on i.itemnumber = p.itemNumber and i.notax = 0
				left join items t with (nolock) on t.itemnumber = p.itemNumber and t.notax = 1
				left join userPriceList l with (nolock) on l.itemnumber = p.itemnumber and l.userID = @userid and getDate() between l.fromDate and l.toDate
				left join userPriceList tl with (nolock) on tl.itemnumber = p.itemnumber and tl.userID = @userid and getDate() between tl.fromDate and tl.toDate
				left join userPriceList il with (nolock) on il.itemnumber = p.itemnumber and il.userID = @userid and getDate() between il.fromDate and il.toDate
			where cart.sessionid = @sessionid
			group by cart.cartid
		) c on c.cartid = cart.cartid
	where cart.sessionid = @sessionid
	
	if LEN(@inventoryErrors) > 0
	begin
		set @inventoryErrors = '['+substring(@inventoryErrors,1,len(@inventoryErrors)-1)+']'; /* remove trailing comma and add square braces */
		insert into errors (script, description, number, source, sessionID, reference, logtime) values
		('dbo.updateCartValues','Stock or other inventory error',1,'dbo.updatecartvalues',@sessionid,@inventoryErrors,GETDATE())
	end
	
	SELECT @inventoryErrors


end
GO
/****** Object:  StoredProcedure [dbo].[updateCartDetailWhenPresent]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[updateCartDetailWhenPresent](
	@inputname varchar(255),
	@value varchar(max),
	@sessionid uniqueidentifier
)
as
begin
	declare @cartdetailid uniqueidentifier
	SET @cartdetailid = (select cartdetailid from cartdetail with (nolock) where cartid = @sessionid and inputname = @inputname)
	if (@cartdetailid is null)
	BEGIN
		Set @cartdetailid = newid()
		insert into cartdetail (cartdetailid,cartid,inputname,value,sessionid) values (@cartdetailid,@sessionid,@inputname,@value,@sessionid)
	END
	ELSE
	BEGIN
		update cartdetail set value = @value where cartid = @sessionid and inputname = @inputname
	END
	select @cartdetailid
end
GO
/****** Object:  StoredProcedure [dbo].[updateCartDetail]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[updateCartDetail](@cartDetailId uniqueidentifier,@value varchar(8000))
as begin
	update cartdetail set value = @value where cartDetailID = @cartDetailId;
end
GO
/****** Object:  StoredProcedure [dbo].[updateCart]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[updateCart](@cartId uniqueidentifier,@qty int,@price money, @setPrice bit)
as begin
	if exists(select 0 from cart where cartId = @cartId) begin
		declare @sessionId uniqueidentifier;
		declare @wholesale bit;
		declare @userId int;
		select @sessionId = sessionId, @userId = userId from cart where cartId = @cartId
		set @wholesale = (select wholeSaleDealer from users where userId = @userId)
		if @qty = 0 begin
			delete from cartDetail where cartId = @cartId;
			delete from cart where cartId = @cartId;
		end else begin
			update Cart set qty = @qty, price = case when @setPrice = 1 then @price else price end where cartID = @cartId;
		end
	end
end
GO
/****** Object:  StoredProcedure [dbo].[duplicateCartDetail]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[duplicateCartDetail](@sourceCartId uniqueidentifier, @targetCartId uniqueidentifier) as
begin
	/* get the sessionId from the targetCartId */
	declare @sessionId uniqueidentifier = (select sessionId from cart where cartId = @targetCartId)
	/* remove existing detail from target */
	delete from cartDetail where cartId = @targetCartId
	/* insert from source to target */
	insert into cartDetail
	select newId() as CartDetailId, @targetCartId as cartId, inputName, value, @sessionId, null as VerCol from cartDetail
	where cartId = @sourceCartId
end
GO
/****** Object:  StoredProcedure [dbo].[deleteCartItem]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[deleteCartItem](
@cartId uniqueidentifier
) as 
begin
	delete from cartDetail where cartId = @cartId
	delete from cart where cartId = @cartId
end
GO
/****** Object:  StoredProcedure [dbo].[fullCategoryList]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[fullCategoryList] as
begin
	declare @ilist table(categoryId uniqueidentifier,lvl int);
	declare @catList table(itemnumber varchar(50), categoryId uniqueidentifier, subCategoryId uniqueidentifier, listOrder int);
	declare @categoryId uniqueidentifier;
	DECLARE cur CURSOR FORWARD_ONLY STATIC FOR
	SELECT categoryId
	From categories
	OPEN cur;
	FETCH NEXT FROM cur
	INTO @categoryId
	WHILE @@FETCH_STATUS = 0
	BEGIN
		insert into @ilist exec dbo.categoryItemList @categoryId;
		insert into @catList select items.itemnumber, @categoryId as categoryId, 
			CategoryDetail.categoryId as subCategoryId, case when listOrder is null then 0 else listOrder end
		from items
		inner join CategoryDetail on CategoryDetail.Itemnumber = Items.Itemnumber
		inner join @ilist innerList on innerList.categoryId = CategoryDetail.CategoryID
		delete from @ilist
	FETCH NEXT FROM cur
	INTO @categoryId
	END
	CLOSE cur;
	DEALLOCATE cur;
	select itemnumber,c.Category as categoryName,s.Category as subCategoryName, c.categoryId,subCategoryId,listOrder, c.[enabled] from @catList a
	inner join Categories c on a.categoryId = c.CategoryID
	inner join Categories s on s.CategoryID = a.subCategoryId
end
GO
/****** Object:  UserDefinedFunction [dbo].[ConcatStringNoNulls]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[ConcatStringNoNulls] (

      @ID      uniqueidentifier
                  )  
RETURNS varchar(1000)
AS  

BEGIN 
      
               Declare @String varchar(1000)

      Set @String = ''

      Select @String = @String  + rtrim(value) + char(13) +  char(10) From cartdetail Where cartId = @Id and rtrim(inputname) like '%monogram' and not rtrim(inputname) like '%ovlenmonogram%' order by inputname
	  
      Return case when len(@String)>0 then substring(@String,0,len(@String)-1) else '-' end

END
GO
/****** Object:  UserDefinedFunction [dbo].[ConcatStringEPSMMCS]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[ConcatStringEPSMMCS] (

      @ID      uniqueidentifier
                  )  
RETURNS varchar(1000)
AS
BEGIN 
      
               Declare @String varchar(1000)

      Set @String = ''

      Select @String = '' + @String  + '' + rtrim(value) + '' + char(13) +  char(10) From cartdetail Where cartId = @Id and (rtrim(inputname) like 'monogram%') and not rtrim(inputname) like '%ovlenmonogram%' order by inputname
	  
      Return case when len(@String)>0 then substring(@String,0,len(@String)-1) else '' end

END
GO
/****** Object:  View [dbo].[shortOrderOverview]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[shortOrderOverview] as
	/* shortOrderOverview version 1 */
	select 
	ik.Itemnumber as itemNumber,
	l.lastFlagStatus as line_status,
	h.lastFlagStatus as shipment_status,
	r.lastFlagStatus as order_status,
	flagTypeName,
	case when c.backorderedQty is null then 0 else c.backorderedQty end as backordered,
	case when c.canceledQty is null then 0 else c.canceledQty end as canceled,
	case when c.backorderedQty > 0 then
		dbo.ConcatBackorderNumbers(c.cartId)
	else
		''
	end as backOrders,
	case when i.Itemnumber = ik.Itemnumber then
		ik.Description
	else
		ik.Description + ' ' + c.serialnumber
	end as Description,
	c.qty,
	case when i.Itemnumber = ik.Itemnumber then
		c.qty*(c.Price-c.valueCostTotal-c.noTaxValueCostTotal)
	else
		c.qty*(k.valueCostTotal+k.noTaxValueCostTotal)
	end
	as lineTotal,
	case when i.Itemnumber = ik.Itemnumber then
		(c.Price-c.valueCostTotal-c.noTaxValueCostTotal)
	else
		(k.valueCostTotal+k.noTaxValueCostTotal)
	end as price,
	c.addTime, c.orderId, c.serialId, c.orderNumber, c.serialNumber, 
	c.shipmentId, c.shipmentNumber, c.lineNumber, c.epsmmcsOutput, o.scanned_order_image, c.epsmmcsAIFilename,
	c.userId, handle, u.email, wholeSaleDealer, u.termId, accountType,
	a.addressId as shipToAddressid, a.firstName as shipToFirstName, a.lastName as shipToLastName, a.address1 as shipToAddress1,
	a.address2 as shipToAddress2, a.city as shipToCity, a.state as shipToState, a.zip as shipToZip, a.country as shipToCountry,
	a.HomePhone as shipToHomePhone, a.WorkPhone as shipToWorkPhone, a.Email as shipToEmail, a.rate, a.shippingQuote,
	a.weight as estimatedShipmentWeight,
	b.addressId as billToAddressid, b.firstName as billToFirstName, b.LastName as billToLastName, b.address1 as billToAddress1,
	b.address2 as billToAddress2, b.city as billToCity, b.State as billToState, b.zip as billToZip, b.country as billToCountry,
	b.homePhone as billToHomePhone, b.workPhone as billToWorkPhone, b.Email as billToEmail,
	case when i.Itemnumber = ik.Itemnumber then
		dbo.ConcatString(c.cartId)
	else
		''
	end as concatline,
	o.orderDate,
	o.grandTotal,
	o.taxTotal,
	o.subTotal,
	o.shippingTotal,
	o.manifest,
	o.purchaseOrder,
	shippingName,
	o.discount as discounted, 
	case when objectFlags.addTime is null then cast('1/1/1900 00:00:00.000' as datetime) else objectFlags.addTime end as order_lastFlagAddTime, 
	u.purchaseAccount as export_to_account,
	i.revenueAccount,
	c.price as line_price,
	k.valueCostTotal,
	k.noTaxValueCostTotal,
	ik.itemNumber as kitItemNumber,
	o.paid as paid,
	o.closed as closed,
	o.soldBy as soldBy,
	o.requisitionedBy as requisitionedBy,
	o.approvedBy as approvedBy,
	o.deliverBy as deliverBy,
	o.vendor_accountNo as vendor_accountNo,
	parentOrderId as parentOrderId,
	parentCartId as parentCartId,
	i.parentItemNumber as parentItemNumber,
	c.fulfillmentDate as fulfillmentDate,
	c.estimatedFulfillmentDate as estimatedFulfillmentDate,
	-1 as VerCol
	from cart c 
	inner join items i on c.itemnumber = i.itemnumber 
	inner join orders o on o.orderid = c.orderid
	inner join addresses a on a.addressid = c.addressid 
	inner join addresses b on b.addressid = o.billtoaddressid
	inner join users u on u.userid = c.userid
	inner join serial_line l on l.cartId = c.cartId
	inner join serial_shipment h on h.shipmentid = c.shipmentId
	inner join serial_order r on r.orderId = o.orderId
	left join flagTypes f on f.flagTypeId = l.lastFlagStatus
	left join Shippingtype s on s.Rate = a.rate
	left join dbo.itemOnHandTemp t on t.itemnumber = c.Itemnumber
	inner join Terms e on e.termId = c.termId
	left join objectFlags on objectFlags.flagId = r.lastFlagId
	left join kitAllocation k on k.cartId = c.cartId and k.showAsSeperateLineOnInvoice = 1
	left join items ik on ik.itemnumber = k.itemNumber
	left join site_configuration n on o.unique_siteId = n.unique_siteId
GO
/****** Object:  StoredProcedure [dbo].[byAccountProductionTotals]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[byAccountProductionTotals]
AS
BEGIN
select sum(listCount) as listCount,userid,case when flagType is null then 'Unprocessed' else flagType end as flagType from (
select count(*) as listCount,
	(
	select flagTypeName
	from flagtypes where flagTypeID = 
		(
		select objectFlags.flagType
		from objectflags 
		where flagID = dbo.flagStatus(cart.serialId,cart.shipmentid,cart.orderid)
		)
	) as flagtype, userid
from cart with (nolock)
group by dbo.flagStatus(cart.serialId,cart.shipmentid,cart.orderid), userid
) a group by flagType,userid
END
GO
/****** Object:  View [dbo].[accountProductionTotals]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[accountProductionTotals]
as
select sum(listCount) as listCount,userid,case when flagType is null then 'Unprocessed' else flagType end as flagType from (
select count(*) as listCount,
	(
	select flagTypeName
	from flagtypes where flagTypeID = 
		(
		select flagType
		from objectflags 
		where flagID = dbo.flagStatus(cart.serialId,cart.shipmentid,cart.orderid)
		)
	) as flagtype, userid
from cart where not userid is null
group by dbo.flagStatus(cart.serialId,cart.shipmentid,cart.orderid), userid
) a group by flagType,userid
GO
/****** Object:  Trigger [tr_line_deplete_inventory_UPDATE]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE trigger [dbo].[tr_line_deplete_inventory_UPDATE]
	on [dbo].[serial_line]
	after update
	as
	/**********************************************************************************************
						tr_line_deplete_inventory_UPDATE version 0.1.3
						All status changes pass through this function
	**********************************************************************************************/

	/**********************************************************************************************
							Updates serial_line.lastErrorId with
										
		0 = No error
		1 = item is out of stock
		2 = Never used (it was very bad, and I had to kill it)
		3 = cannotOccurBeforeFlagId (as set in the flagTypes table)
		4 = cannotOccurAfterFlagId (as set in the flagTypes table)
		5 = cannot set to a status that it is already in (unless that state is 'comment')
		6 = orders are not allowed to change once they are canceled
		7 = orders are not allowed to change once they are closed
		8 = error during recalculation when canceling an order
	
	**********************************************************************************************/

	/**********************************************************************************************
	*							Manual Trigger ids
	*	-11/-12 = backordered/cancled line item qty
	*		This uses the column 'returnToStock' to determine now many qty to reduce from the order
	*		and updates the inventory tables.  You don't need to modify 'qty', this function will do that for you.
	*	-3 = allocate inventory
	*	-5 = unallocate inventory
	*	-2 = consume inventory
	*	-4 = unconsume inventory
	**********************************************************************************************/

	/**********************************************************************************************
	*		 WARNING   WARNING   WARNING   WARNING   WARNING   WARNING   WARNING   WARNING   
	*	WARNING   WARNING   WARNING   WARNING   WARNING   WARNING   WARNING   WARNING   WARNING   
	*
	*	Never change this trigger
	*   Use event handlers in the binary application to handle status changes
	*   This trigger uses internal transaction handling
	*	
	*
	**********************************************************************************************/

	/**********************************************************************************************	
	*	This trigger is responsible for the following:
	*	All inventory transactions. (Allocation/deallocation, po stocking, consume/unconsume-ing)
	*	All flag status changes.
	*	Line item cancelation and backorders. (manual via 'returnToStock' column)
	*	Order cancelation (auto line cancelation and recalculation)
	*	Emails for stock levels are sent from here (via email table queue)
	*
	*	This also trigger manages the inventory and triggers itemOnHandTemp updates.
	*	any changes to the serial_line.lastFlagStatus will cause the inventory system to work.
	*	
	*	The lastFlagStatus is an int that is enumerated from table dbo.flagTypes
	*	A matching entry on the item's flag settings must occur for the trigger to fire.
	*	For instance, the item has the flag column "inventoryDepletesOnFlagId" set to 3
	*	when this serial_line is set to 3, it will try and consume inventory and refresh the changes.
	*	
	*	Updates are run after no errors are found to occur and after the table has been
	*	updated using SP dbo.refreshItemOnHandTemp for the selected item only (costly)
	*	
	*	An order can be closed in one of two ways
	*   when the flag a closesOrder flag
	*   when the flag a cancelesOrder flag
	*		
	*	There are 4 ways to trigger inventory updates through this trigger without chaning the status
	*	of the line. Once set, they will execute and change back to the lastFlagStatus they were before the update.
	*	Manual trigger ids are listed above.
	*	
	*	There is an @errorId var in this trigger that will be changed _from_ 0 if an error occurs
	*	@errorId will be written to serial_line.lastErrorId.
	*	In the event of an error, handled or unhandled, all internal transactions are rolled back internally.
	*	Always check serial_line.lastErrorId after updates to see if and what error occured.
	*	
	**********************************************************************************************/
	SET XACT_ABORT ON 
	if not update(lastFlagStatus)
	begin
		return
	end
	/* don't let this trigger fire inside itself or another trigger 
	if TRIGGER_NESTLEVEL() > 1 
	begin
		return
	end
	*/
	/* if the flag that was switched to depletes this item's inventory */
	SAVE TRANSACTION deplete_inventory
	DECLARE @r_termId int;
	DECLARE @qty int;
	DECLARE @subQty int;
	DECLARE @totalQtyConsumed int;
	DECLARE @errorId int;
	DECLARE @lastFlagStatus int;
	DECLARE @subItemNumber varchar(50);
	DECLARE @itemNumber varchar(50);
	DECLARE @consumedQty int;
	DECLARE @vendorItemId uniqueidentifier;
	DECLARE @vendorId int;
	DECLARE @cost money;
	DECLARE @qtyOnHand int;
	DECLARE @serialId int;
	DECLARE @cartId uniqueidentifier;
	DECLARE @operator varchar(255);
	DECLARE @vendorItemKitAssignmentId uniqueidentifier;
	DECLARE @stock table(qty int, itemnumber varchar(50));
	DECLARE @execStr nvarchar(255);
	DECLARE @reorderpoint int;
	DECLARE @qtyLeft int;
	DECLARE @returnToStock int;
	DECLARE @serialNumber varchar(50);
	DECLARE @orderNumber varchar(50);
	DECLARE @shipmentNumber varchar(50);
	DECLARE @ponumber varchar(50);
	DECLARE @sender varchar(50);
	DECLARE @bcc varchar(50);
	DECLARE @itemconsumed bit;
	DECLARE @orders_closed_on_flagId int;
	DECLARE @backorderedQty int;
	DECLARE @canceledQty int;
	DECLARE @kitAllocationId int;
	DECLARE @cartQty int;
	DECLARE @cannotOccurBeforeFlagId int;
	DECLARE @cannotOccurAfterFlagId int;
	DECLARE @orderId int;
	DECLARE @userId int;
	DECLARE @cartPrice money;
	DECLARE @desc varchar(50);
	DECLARE @orderDate datetime;
	DECLARE @deliverBy datetime;
	DECLARE @approvedBy int;
	DECLARE @now datetime = getdate();
	DECLARE @emptyGUID uniqueidentifier = '{00000000-0000-0000-0000-000000000000}';
	declare @r_orderId int;
	declare @r_sessionId uniqueidentifier;
	declare @r_userId int;
	declare @r_unique_siteId uniqueidentifier;
	declare @r_purchaseOrderNumber varchar(50);
	declare @r_orderDate datetime;
	declare @emailSubject varchar(500);
	SET @orders_closed_on_flagId = (select top 1 orders_closed_on_flagId from site_configuration  with (nolock));
	SET @itemnumber = null;
	SET @errorId = 0;

	/* loop thru the inserted/updated flags */
	DECLARE updated CURSOR FOR
		SELECT serialId, lastFlagStatus, cartId
		FROM inserted
	OPEN updated;
	FETCH NEXT FROM updated
	INTO @serialId, @lastFlagStatus, @cartId
	WHILE @@FETCH_STATUS = 0
	BEGIN
		/* __CLOSE THE ORDER__ */
		/* if order just got closed update the order line to show that, and when it was closed */
		if @lastFlagStatus in (select flagTypeId from flagTypes with (nolock) where closesOrder = 1) begin
			set @r_orderId = (select top 1 orderid from cart with (nolock) where cartId = @cartId);
			/* no point in doing this many times */
			if exists(select 0 from orders with (nolock) where closed = 0 and orderId = @r_orderId) begin
				update orders set closed = 1,readyForExport = getDate() where orderId = @r_orderId
			end
		end
		/* __INVENTORY CHECKS__ */
		/* only run inventory checks on AP accounts */
		if exists(
			select 0 from cart with (nolock)
			inner join users with (nolock) on users.userid = cart.userid where users.accounttype = 0 and cartId = @cartId
		)
		BEGIN
			/* if order just got canceled update the order line to show that, and when it was canceled */
			if @lastFlagStatus in (select flagTypeId from flagTypes with (nolock) where cancelsOrder = 1) begin
				/*what's the orderId?*/
				set @r_orderId = (select top 1 orderid from cart with (nolock) where cartId = @cartId);
				/* if this has already been done don't do it again! */
				if exists(select 0 from orders with (nolock) where closed = 0 and orderId = @r_orderId) begin
					/* update the order to show everyone this has been done already */
					update orders set canceled = 1 where orderId = @r_orderId
					/* set qtys of line items to canceled and recalculate order -  This will unallocate the stock and recalculate the order at $0
						the user should then be prompted to add a 'restocking fee' or whatever in the UI
					*/
					update cart set returnToStock = qty where orderId = @r_orderId and qty > 0;
					/* get the data from the existing order */
					select @r_sessionId = sessionId, @r_userId = userId, @r_unique_siteId = unique_siteId, @r_purchaseOrderNumber = purchaseOrder, @r_orderDate = orderDate, @r_termId = termId
					from orders with (nolock) where orderId = @r_orderId
				
				end
			end
		
		
			/* begin inventory checks */
			/* check if this line item is supposed to be unallocated 
				of course if the item has been consumed (k.itemconsumed = 1) it will not show up here
				but of course the user should have recieved a message stating that preventing such a thing
				from even getting this far - RIGHT?
			
			*/
			DECLARE unallocate CURSOR FOR
				select vendorItemKitAssignment.vendorItemId,vendorItemKitAssignment.vendorItemKitAssignmentId, vendorItemKitAssignment.qty,
				cart.itemnumber, cart.serialnumber, cart.shipmentnumber, cart.ordernumber, vendorItems.ponumber,
				case when items.inventoryRestockOnFlagId = @lastFlagStatus then
						cart.qty/* just restock the rest in the case of an inventory restock, don't use "return to qty" field */
					else
						case when cart.returnToStock is null then
							0
						else
							cart.returnToStock
						end
				end, kitAllocation.itemconsumed,
				case when cart.canceledQty is null then
					0
				else
					cart.canceledQty
				end,
				case when cart.backorderedQty is null then
					0
				else
					cart.backorderedQty
				end,
				kitAllocationId, cart.qty, cart.price, items.shortDescription, cart.orderId
				from cart with (nolock)
				left join vendorItemKitAssignment with (nolock) on cart.cartID = vendorItemKitAssignment.cartId
				left join vendorItems with (nolock) on vendorItems.vendorItemId = vendorItemKitAssignment.vendorItemId
				inner join kitAllocation with (nolock) on kitAllocation.cartID = cart.cartId and kitAllocation.inventoryItem = 1
				inner join items  with (nolock) on items.itemnumber = cart.itemnumber 
				where cart.cartId = @cartId and 
				(
				(items.inventoryRestockOnFlagId = @lastFlagStatus/*natural*/) 
				or (@lastFlagStatus = -11/*Procedural backordered execution*/)
				or (@lastFlagStatus = -12/*Procedural cancel execution*/)
				or (@lastFlagStatus = -5/*Manual unallocate inventory*/)
				or (@lastFlagStatus in (select flagTypeId from flagTypes with (nolock) where cancelsOrder = 1)/*Canceled*/)
				)
			OPEN unallocate;
			FETCH NEXT FROM unallocate
			INTO @vendorItemId, @vendorItemKitAssignmentId, @qty, @itemNumber, @serialNumber, 
			@shipmentNumber, @orderNumber, @ponumber, @returnToStock, @itemconsumed, @canceledQty, @backorderedQty, @kitAllocationId, @cartQty, @cartPrice, @desc, @orderId
			WHILE @@FETCH_STATUS = 0
			BEGIN
				if (@itemconsumed = 0 and not @vendorItemId = @emptyGUID)
				begin
					/* remove the allocated inventory from the order's allocation thingy */
					delete from vendorItemKitAssignment where vendorItemKitAssignmentId = @vendorItemKitAssignmentId;
					/* reconcile quantites */
					update vendorItems set qtyOnHand = qtyReceived - (
						select sum(qty)
						from vendorItemKitAssignment with (nolock)
						where vendorItemId = @vendorItemId
					)
					where vendorItemId = @vendorItemId
					/* update the cart to show that no po has been delivered */
					update cart set fulfillmentDate = '1/1/1900 00:00:00.000' where cartId = @cartId;
					/* update the kitAllocation table to show no Id is attached */
					update kitAllocation set vendorItemKitAssignmentId = @emptyGUID where vendorItemKitAssignmentId = @vendorItemKitAssignmentId
					/* send an email reflecting the inventory change to the operator for this item */
					/* make sure we don't spam the same message over and over */
					select @operator = users.email from Items with (nolock)
					inner join users with (nolock) on items.inventoryOperator = users.userid where Itemnumber = @itemNumber
					set @emailSubject = 'Item '+@itemNumber+' restocked';
					if not exists(select top 1 0 from emails with (nolock) where subject = @emailSubject and messageSentOn is null and mailto = @operator)
					begin
						select top 1 @sender = site_operator_email, @bcc = site_log_email from site_configuration with (nolock)
						if @operator is null begin
							set @operator = @sender
						end
						insert into emails (emailId,textBody,htmlBody,mailTo,mailFrom,sender,subject,bcc,messageSentOn,addedOn,errorDesc,errorId)
						values
						(NEWID(),'','Item '+@itemNumber+' has been returned to stock.'+char(13)+
						'Items return to Purchase Order:'+@ponumber+char(13)+'Order No.:'+@orderNumber+char(13)+
						'Shipment No.:'+@shipmentNumber+char(13)+
						'Serial No.:'+@serialNumber+char(13)+
						'Quantity Returned:'+cast(@qty as varchar(20))+char(13)+
						'If it has not been done already, these items should be returned to the Purchase Order staging area where they came from,'+
						' or the general staging area for Item '+@itemNumber+'. '+
						'Always follow standard operating procedures. If you are not sure what to do ask your supervisor.',
						@operator,@sender,@sender,@emailSubject,@bcc,'1/1/1900 00:00:00.000',getDate(),'',0)
					end
				end
				/* if this is a cancelation or a backorder change the related fields */
				if (@lastFlagStatus = -11 or @lastFlagStatus in (select flagTypeId from flagTypes with (nolock) where cancelsOrder = 1) or @lastFlagStatus = -12) begin 
					update cart set qty = qty - @returnToStock,
					backorderedQty = case when @lastFlagStatus = -11 then @backorderedQty + @returnToStock else backorderedQty end,
					canceledQty = case when (@lastFlagStatus in (select flagTypeId from flagTypes with (nolock) where cancelsOrder = 1) or @lastFlagStatus = -12) then @canceledQty + @returnToStock else canceledQty end,
					returnToStock = 0
					where cartid = @cartId and returnToStock > 0
					/* update the kit allocation table to reflect the changes */
					if @cartQty > 0
					begin
						update kitAllocation set qty = (qty*((@cartQty-@returnToStock)/@cartQty)) where kitAllocationId = @kitAllocationId
					end
					else
					begin
						update kitAllocation set qty = 0 where kitAllocationId = @kitAllocationId
					end
				end
				FETCH NEXT FROM unallocate
				INTO @vendorItemId, @vendorItemKitAssignmentId, @qty, @itemNumber, @serialNumber, 
				@shipmentNumber, @orderNumber, @ponumber, @returnToStock, @itemconsumed, @canceledQty, @backorderedQty, @kitAllocationId, @cartQty, @cartPrice, @desc, @orderId
			END
			CLOSE unallocate;
			DEALLOCATE unallocate;
			/* end of checks for unallocating inventory */	

			/* recalulate AFTER unallocating, if it's done the other way, the recalculation will pickup the canceled items */
			if @lastFlagStatus in (select flagTypeId from flagTypes with (nolock) where cancelsOrder = 1) begin
				/* only recalculate once all the items are depleted */
				if exists(select 0 from cart where orderId = @r_orderId group by orderId having sum(qty) = 0) begin 
					/* recalculate the order with the newly canceled items */
					exec dbo.placeOrder @r_sessionId, @r_userId, @emptyGUID, 0/*test*/,@r_unique_siteId, @r_sessionId, @r_purchaseOrderNumber, @r_orderDate, @r_termId, 0
				end
			end


			/* begin checks for allocating inventory */
			DECLARE allocating CURSOR FOR
			select kitAllocation.itemNumber, kitAllocation.qty, items.reorderPoint
			from cart with (nolock) 
			inner join kitAllocation on kitAllocation.cartId = cart.cartId and kitAllocation.inventoryItem = 1 and kitAllocation.vendorItemKitAssignmentId = @emptyGUID
			inner join items with (nolock) on items.itemNumber = kitAllocation.itemNumber
				and (
					inventoryDepletesOnFlagId = @lastFlagStatus
					or @lastFlagStatus = -3 or 
					@lastFlagStatus in (select flagTypeId from flagTypes with (nolock) where closesOrder = 1)
				)
			where cart.cartId = @cartId
			OPEN allocating;
			FETCH NEXT FROM allocating
			INTO @subItemNumber, @qty, @reorderpoint
			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @totalQtyConsumed = 0;
				while @totalQtyConsumed < @qty and @errorId = 0
				begin
					SET @consumedQty = 0;
					SET @vendorItemId = @emptyGUID;
					/* select pos containing this item, order by depletionOrder then recievedOn */
					select top 1 @vendorItemId = vendorItemId, @vendorId = vendorId, @cost = price, @qtyOnHand = qtyOnHand 
					from vendorItems with (nolock)
					where qtyOnHand > 0 and vendorItems.itemnumber = @subItemNumber
					order by depletionOrder desc, recievedOn asc
					/* If there were any items at all  - if not set out of stock which will exit the loop */
					if @vendorItemId = @emptyGUID /* there was no PO that could fill what QTY was left, any transactions thus far will be rolled back. */
					begin
						SET @errorId = 1
						set @emailSubject = 'Item '+@subItemNumber+' is out of stock';
						SET @operator = (select users.email from Items with (nolock) inner join users with (nolock) on items.inventoryOperator = users.userid where Itemnumber = @subItemNumber)
						if not exists(select top 1 0 from emails with (nolock) where subject = @emailSubject and messageSentOn is null and mailto = @operator)
						begin
							select top 1 @sender = site_operator_email, @bcc = site_log_email from site_configuration with (nolock)
							if @operator is null begin
								set @operator = @sender
							end
							insert into emails (emailID,textBody,htmlBody,mailTo,mailFrom,sender,subject,bcc,messageSentOn,addedOn,errorDesc,errorId)
							values
							(NEWID(),'','Item '+@subItemNumber+' is out of stock, you are advised to check your stock levels soon',
							@operator,@sender,@sender,@emailSubject,@bcc,'1/1/1900 00:00:00.000',getDate(),'',0)
						end
					end
					else
					begin
						/* If there were more or equal items on hand (on this PO) than there were on this line */
						if  @qtyOnHand >= (@qty-@totalQtyConsumed) begin
							SET @consumedQty = @qty - @totalQtyConsumed
						end
						/* If there were fewer items on hand (on this PO) than there were on this line */
						if @qtyOnHand < (@qty-@totalQtyConsumed) begin
							SET @consumedQty = @qtyOnHand
						end
						SET @totalQtyConsumed = @totalQtyConsumed + @consumedQty
					
						/* for each po items are drawn from a line is inserted into vendorItemKitAssignment
						to track where each piece of the PO was sent off to */
						set @vendorItemKitAssignmentId = newId();
						insert into vendorItemKitAssignment (vendorItemKitAssignmentId, cartId, serialId, vendorItemId, qty) 
						values
						(@vendorItemKitAssignmentId,@cartId,@serialId,@vendorItemId,@consumedQty)
						/* reconcile quantites */
						update vendorItems set qtyOnHand = qtyReceived - (
							select sum(qty)
							from vendorItemKitAssignment with (nolock)
							where vendorItemId = @vendorItemId
						)
						where vendorItemId = @vendorItemId
						/* update kit allocation table */
						update kitallocation set vendorItemKitAssignmentId = @vendorItemKitAssignmentId where cartId = @cartId and itemnumber = @subItemNumber
						/* update history state */
						update cart set fulfillmentDate = @now where cartid = @cartId
						/* check if this item has dropped below its minimum threshold, and if so send an email */
						SET @execStr = 'dbo.itemStock '''+replace(@subItemNumber,'''','''''')+''' '
						insert into @stock EXEC sp_executesql @execStr
						SET @qtyLeft = (select top 1 qty from @stock)
						delete from @stock
						if (@reorderpoint <= @qtyLeft) and (@reorderpoint > 0) begin
							/* send an email to whoever wants one */
							SET @operator = (select users.email from Items with (nolock) inner join users with (nolock) on items.inventoryOperator = users.userid where Itemnumber = @subItemNumber)
							/* don't spam duplicate messages - only send new messages once the previous one has been sent - that should keep this from blowing up someone's email box  */
							set @emailSubject = 'Item '+@subItemNumber+' is low';
							if not exists(select top 1 0 from emails with (nolock) where subject = @emailSubject and messageSentOn is null and mailto = @operator)
							begin
								select top 1 @sender = site_operator_email, @bcc = site_log_email from site_configuration with (nolock)
								insert into emails (emailId,textBody,htmlBody,mailTo,mailFrom,sender,subject,bcc,messageSentOn,addedOn,errorDesc,errorId)
								values
								(NEWID(),'','Item '+@subItemNumber+' has reached its reorder threshold inventory level, you are advised to check your stock levels soon'+char(13)+
								'Reorder Threshold:'+cast(@reorderpoint as varchar(20))+char(13)+
								'Quantity Remaining:'+cast(@qtyLeft as varchar(20))+char(13)
								,@operator,@sender,@sender,@emailSubject,@bcc,'1/1/1900 00:00:00.000',getDate(),'',0)
							end
						end
					end
				end
				FETCH NEXT FROM allocating
				INTO @subItemNumber, @qty, @reorderpoint
			END;
			CLOSE allocating;
			DEALLOCATE allocating;
			/* end of checks for allocating inventory */	

			/*reset vars */
			SET @itemNumber = null
		
			/* check if it's time to consume (or unconsume) inventory by seeing if itemIsConsumedOnFlagId = @lastFlagStatus */
			Select @cartId = cart.cartId from
			cart with (nolock) 
			inner join items on items.itemnumber = cart.itemnumber 
			where cartId = @cartId
			DECLARE consume CURSOR FOR
				select kitAllocation.itemNumber, kitAllocation.qty, items.reorderPoint
				from cart with (nolock) 
				inner join kitAllocation on kitAllocation.cartId = cart.cartId and inventoryItem = 1
				inner join items with (nolock) on items.itemNumber = kitAllocation.itemNumber
				and (
				itemIsConsumedOnFlagId = @lastFlagStatus or @lastFlagStatus = -2 or @lastFlagStatus = -4
				or @lastFlagStatus in (select flagTypeId from flagTypes with (nolock) where closesOrder = 1)
				)
				where cart.cartId = @cartId
			OPEN consume;
			FETCH NEXT FROM consume
			INTO @subItemNumber, @subQty, @reorderPoint
			WHILE @@FETCH_STATUS = 0
			BEGIN
				if @lastFlagStatus = -4 begin /* unconsume - shouldn't really ever happen, but hey, it's there */
					update kitallocation set itemconsumed = 0 where cartId = @cartId and itemNumber = @subItemNumber;
				end else begin
					update kitallocation set itemconsumed = 1 where cartId = @cartId and itemNumber = @subItemNumber;
				end
				FETCH NEXT FROM consume
				INTO @subItemNumber, @subQty, @reorderPoint
			END;
			CLOSE consume;
			DEALLOCATE consume;
			/* end of checks for consume (or unconsume) inventory */	

			/* END inventory checks */
		END
		
		/* __INVENTORY FILLING CHECKS__ */
		/* only check po fulfillment if this order belongs to an AP account */
		IF EXISTS(
			select 0 from cart with (nolock)
			inner join users with (nolock) on users.userid = cart.userid where users.accounttype = 1 and cartId = @cartId
		)
		BEGIN
			/*  
				check if this is a purchase order that has passed thru a step marked as finishedPurchaseOrderFlag 
				when a PO (an order placed by an AP account) goes through the finishedPurchaseOrderFlag step
				it is added to the vendorItems table as inventory
				and locked up
			*/
			if exists(
				select 0 from flagTypes with (nolock) where flagTypeId = @lastFlagStatus and 
				(
					finishedPurchaseOrderFlag = 1 or
					closesOrder = 1
				)
			)
			begin
				select @itemNumber = cart.itemnumber, @cartPrice = cart.price, @cartQty = cart.qty,
				@orderDate = orders.orderDate, @deliverBy = orders.deliverBy, @desc = case when items.shortDescription is null then '' else items.shortDescription end,
				@approvedBy = orders.approvedBy, @orderNumber = orders.orderNumber, @userId = orders.userId, @orderId = orders.orderId
				from cart with (nolock)
				inner join orders with (nolock) on cart.orderid = orders.orderid
				inner join items with (nolock) on cart.itemnumber = items.itemnumber
				where cart.cartId = @cartId
				/* check to make sure this PO was not already entered into inventory from a
				repeated flag or a change in the flag configuration */
				if not exists(select 0 from vendorItems where cartId = @cartId and orderId = @orderId) begin
					/* insert PO into active inventory pool */
					update cart set fulfillmentDate = @now where orderId = @orderId;
					insert into vendorItems (vendorItemId, vendorID, itemnumber, price, description, qtyOnHand, qtyReceived,
					qtyOrdered, orderedOn, recievedOn, estimatedRecieveDate, addedBy, addedOn, depletionOrder, poNumber, orderId, cartId, VerCol)
					values
					(
						newId(),/*vendorItemId*/
						@userId,/*userId*/
						@itemNumber,
						@cartPrice,
						@desc,
						@cartQty,/*qtyOnHand*/
						@cartQty,/*qtyReceived*/
						@cartQty,/*qtyOrdered*/
						@orderDate,/*orderedOn*/
						getDate(),/*recievedOn*/
						@deliverBy,/*estimatedRecieveDate*/
						@approvedBy,/*addedBy*/
						getDate(),
						0,
						@orderNumber,
						@orderId,
						@cartId,
						null
					)
				end
			end	
			/* END OF check if this is a purchase order that has passed thru a step flagged as finishedPurchaseOrderFlag */
		END
	
	
		/* __VALIDATE STATUS CHANGES__ */
		/* check for illegal status changes */
		/*
			Must have passed thru
			and Must Not have passed thru
			Loop thru the object's flag history and see if it has already passed through the requesit flags to have this new one added now
		*/
		select @cannotOccurAfterFlagId = cannotOccurAfterFlagId, @cannotOccurBeforeFlagId = cannotOccurBeforeFlagId from flagTypes with (nolock) where flagTypeId = @lastFlagStatus
	
		/* cannot occur before (if the record is NOT there ERROR)*/
		if not @cannotOccurBeforeFlagId = 0 begin
			if not exists(select serialId from objectFlags with (nolock) inner join FlagTypes with (nolock) on flagTypeID = flagType
					where 
					(
						objectflags.serialId = @serialId or 
						objectflags.orderId = (select orderId from cart with (nolock) where cartId = @cartId) or
						objectflags.shipmentId = (select shipmentId from cart with (nolock) where cartId = @cartId)
					)
					and (flagTypeID = @cannotOccurBeforeFlagId)
				)
			begin
				/* cannot occur before @cannotOccurBeforeFlagId has occured */
				SET @errorId = 3
			end
		end
	
		/* cannot occur after (if the record IS there ERROR)*/
		if not @cannotOccurAfterFlagId = 0 begin
			if exists(select serialId from objectflags with (nolock) inner join FlagTypes  with (nolock) on flagTypeID = flagType
					where 
					(
						objectflags.serialId = @serialId or 
						objectflags.orderId = (select orderId from cart with (nolock) where cartId = @cartId) or
						objectflags.shipmentId = (select shipmentId from cart with (nolock) where cartId = @cartId)
					)
					and (flagTypeID = @cannotOccurAfterFlagId)
				)
			begin
				/* cannot occur after @cannotOccurAfterFlagId has occured */
				SET @errorId = 4
			end
		end
	
		if exists(select 0 from deleted where deleted.cartId = @cartId and @lastFlagStatus = deleted.lastFlagStatus and not @lastFlagStatus = 0) begin
			/* cannot set to a status that it is already in (unless that state is 'comment')*/
			SET @errorId = 5
		end
		/* orders are not allowed to change from @orders_closed_on_flagId! */
		if exists(select 0 from deleted where lastFlagStatus = @orders_closed_on_flagId and cartid = @cartId) begin
			SET @errorId = 2
		end
		/* orders are not allowed to change once they are canceled */
		if exists(select 0 from deleted where lastFlagStatus in (select flagTypeId from flagTypes with (nolock) where cancelsOrder = 1) and cartid = @cartId) begin
			SET @errorId = 6
		end
		/* orders are not allowed to change once they are closed */
		if exists(select 0 from deleted where lastFlagStatus in (select flagTypeId from flagTypes with (nolock) where closesOrder = 1) and cartid = @cartId) begin
			SET @errorId = 7
		end
		/* end of illegal status change checks */
	
	
		FETCH NEXT FROM updated
		INTO @serialId, @lastFlagStatus, @cartId
	END;
	CLOSE updated;
	DEALLOCATE updated;
	
	/* (-11,-3,-2,-4,-12) procedural update - a caller asked to execute a inventory function, undo any flag changes so aging isn't changed */
	if @lastFlagStatus in (-11,-3,-2,-4,-5,-12) begin
		update serial_line set lastFlagId = deleted.lastFlagId, lastFlagStatus = deleted.lastFlagStatus, lastErrorID = @errorId
		from deleted where serial_line.serialId = deleted.serialId
	end

	/* if there was an out of stock error then roll back to the savepoint and undo the users update */
	if @errorId = 0 begin
		/* show that no error occured */
		update serial_line set lastErrorID = @errorId
		from deleted where serial_line.serialId = deleted.serialId
	
		DECLARE updateItemCache CURSOR FOR
		select kitAllocation.itemNumber
		from cart
		inner join deleted on deleted.serialId = cart.serialId
		inner join kitAllocation on kitAllocation.cartId = cart.cartId
		group by kitAllocation.itemNumber
		OPEN updateItemCache;
		FETCH NEXT FROM updateItemCache
		INTO @itemNumber
		WHILE @@FETCH_STATUS = 0
		BEGIN
			exec dbo.refreshItemOnHandTemp @now, @itemNumber
			FETCH NEXT FROM updateItemCache
			INTO @itemNumber
		END;
		CLOSE updateItemCache;
		DEALLOCATE updateItemCache;
	end else begin
		/* roll back any inventory deductions done */
		ROLLBACK TRANSACTION deplete_inventory
		/* put the values back to the way they were prior updating the row */
		update serial_line set lastFlagId = deleted.lastFlagId, lastFlagStatus = deleted.lastFlagStatus, lastErrorID = @errorId
		from deleted where serial_line.serialId = deleted.serialId
	end
GO
/****** Object:  View [dbo].[public_orderCart]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[public_orderCart] as
select
cart.cartID,
d.CartDetailID,
cart.itemnumber,
cart.valueCostTotal+cart.noTaxValueCostTotal+cart.price as price,
cart.qty,
cart.addressID,
cart.sessionid,
d.value,
d.inputName,
dbo.getCartSubTotal(cart.sessionId) as subTotal,
dbo.getAddressTaxTotal(cart.addressID,cart.sessionId) as taxTotal
from cart with (nolock)
inner join CartDetail d on d.cartID = cart.cartid
GO
/****** Object:  View [dbo].[public_cart]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[public_cart]
as
	select
	c.cartID,
	case when d.CartDetailID is null then '00000000-0000-0000-0000-000000000000' else d.CartDetailID end as cartDetailId,
	c.itemnumber,
	c.valueCostTotal+c.noTaxValueCostTotal+c.price as price,
	c.qty,
	c.addressID,
	c.sessionid,
	case when d.value is null then  '' else d.value end as value ,
	case when d.inputName is null then  '' else d.inputName end as inputName ,
	dbo.getCartSubTotal(c.sessionId) as subTotal,
	dbo.getContactTaxTotal(c.addressID,c.sessionId) as taxTotal,
	c.addTime,
	c.parentCartId
	from dbo.cart c with (nolock)
	left join dbo.cartDetail d on d.cartId = c.cartid and d.sessionId = c.sessionId
GO
/****** Object:  View [dbo].[orderdates]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[orderdates] as
select a.orderid,a.ordernumber,cast(b.value as datetime) as orderdate
from cart a inner join cartdetail b on a.sessionid = b.cartid where b.InputName = 'OrderDate'
group by a.orderid,a.ordernumber,cast(b.value as datetime)
GO
/****** Object:  View [dbo].[outputlist]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[outputlist]
AS
SELECT     cd.cartID, cd.CartDetailID, 'TemplateNamePlaceHolder' AS Expr1, RTRIM(cd.[value]) AS inputvalue, RIGHT(RTRIM(cd.inputName), 
                      LEN(RTRIM(cd.inputName)) - 38) AS inputname, RTRIM(c.serialnumber) + '.' + RTRIM(c.shipmentnumber) + '.' + RTRIM(CAST(c.linenumber AS char(4))) 
                      + '.' + CAST(cm.maxlinenumber AS char(4)) AS Serialnumber, RTRIM(c.ordernumber) AS ordernumber, RTRIM(c.shipmentnumber) AS shipmentnumber, 
                      RTRIM(c.serialnumber) AS itemserialnumber, c.linenumber AS linenumber, cm.maxlinenumber AS OrderItemCount, c.qty, c.Itemnumber, 
                      '' as scannedimage
FROM         dbo.CartDetail cd INNER JOIN
                      dbo.Cart c ON cd.cartID = c.cartID INNER JOIN
                          (SELECT     orderid, MAX(cart.linenumber) AS maxlinenumber
                            FROM          cart
                            GROUP BY orderid) cm ON c.orderID = cm.orderid
GO
/****** Object:  StoredProcedure [dbo].[logon]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[logon](
	@email as varchar(255),
	@password as varchar(255),
	@sessionId as uniqueidentifier,
	@createaccount as bit,
	@unique_siteId as uniqueidentifier,
	@userId as int,
	@refrenceSessionId as uniqueidentifier
	) as
	begin
		/* logon version 2 */
		print 'start logon procedure'
		SET NOCOUNT ON
		DECLARE @new_userId as int = -1
		DECLARE @default_new_user_allow_preorder as bit
		DECLARE @default_logon_redirect as varchar(255)
		DECLARE @defaultRateId as int
		DECLARE @newContactId as uniqueidentifier
		IF (@createaccount = 1)
		BEGIN
			/* get new account defaults */
			select
			@default_new_user_allow_preorder = default_new_user_allow_preorder,
			@default_logon_redirect = logon_redirect,
			@defaultRateId = default_rateId
			from site_configuration with (nolock) where unique_siteId = @unique_siteId
			/* do the insert */
			if(not exists(select userId from Users with (nolock) where (userId = @userId or email = @email)))
			begin
				print 'create account'
				declare @resultTable table (
					userId int
				)
				insert into @resultTable exec dbo.createAccount @email,@password,@sessionId,@default_new_user_allow_preorder,@defaultRateId,@unique_siteId,null;
				SET @new_userId = (select userId from @resultTable)
			end
		END
		ELSE
		BEGIN
			print 'start try impersonate a user'
			/*					impersonate a user
			TODO: this should use the user rights assignment table and not just 'admin' setting.
			right now it just requires an account with admin rights */
			if @refrenceSessionId = '00000000-0000-0000-0000-000000000000' or ((exists (select users.userId
			from visitors with (nolock)
			inner join users with (nolock) on visitors.userId = users.userId and administrator = 1
			where visitors.SessionId = @refrenceSessionId)) and not @refrenceSessionId = @sessionId) begin
				set @new_userId = (select top 1 userId from users with (nolock) where (userId = @userId and len(cast(@userId as varchar(50))) > 0) or (email = @email and len(@email) > 0 ))
				print 'impersonate user '+convert(varchar(50),@new_userId)
			end else begin
				print 'impersonate fail. Must logon as yourself!'
				set @new_userId = (select userId from users with (nolock) where (userId = @userId or email = @email) and password = @password)
			end
		END
	
		IF (not @new_userId is null) BEGIN
			print 'start logon success'
			update visitors set userId = @new_userId where sessionId = @sessionId
			update contacts set userId = @new_userId where sessionId = @sessionId
			update sessionHash set userId = @new_userId where sessionId = @sessionId /* attach all current session properties to this user */
			update sessionHash set sessionId = @sessionId where userId = @new_userId /* find all previous user session properties and add it to this session */
			/* add contact refrences to all the items in the cart and update existing refrence to attach to the user's Id*/
			IF not exists(select contactId from contacts with (nolock)
				inner join cart with (nolock) on contacts.contactId = cart.addressId
				where contacts.userId = @new_userId and cart.sessionId = @sessionId) BEGIN
				DECLARE @addressId uniqueidentifier
				DECLARE @newaddressId uniqueidentifier
				set @newaddressId = newId()
				set @addressId = (select top 1 addressId from (
									select top 1 addressId, 1 as pri from cart with (nolock)
										inner join Contacts with (nolock) on ContactId = addressId
										where cart.sessionId = @sessionId and not contacts.userId = -1
									union all
									select top 1 contactId as addressId, 2 as pri from contacts with (nolock) where userId = @new_userId
									union all
									select top 1 contactId as addressId, 3 as pri from contacts with (nolock) where sessionId = @sessionId
									union all
									select @newaddressId as addressId, 4 as pri
									) a order by  pri asc)
				IF (@addressId = @newaddressId)
				BEGIN
					/* create a new blank address */
					DECLARE @ncCountry varchar(255)
					DECLARE @ncRate int
					SELECT @ncRate = default_rateId, @ncCountry = local_country from site_configuration with (nolock) where unique_siteId = @unique_siteId 
					print @sessionId
					exec dbo.createContact @newaddressId,@sessionId,@new_userId,@ncRate,@ncCountry
				END
				update cart set addressId = @addressId, userId = @new_userId where sessionId = @sessionId
			END
		END
		ELSE BEGIN
			set @new_userId = -1
		END
		SELECT @new_userId as userId
	end
GO
/****** Object:  StoredProcedure [dbo].[kitStock]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[kitStock](@itemnumber varchar(50))
as
begin
set nocount on
declare @m table(qty int, itemnumber varchar(50))
insert into @m exec dbo.itemStock @itemnumber,1
select MIN(qty) from @m
end
GO
/****** Object:  StoredProcedure [dbo].[insertCartDetail]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[insertCartDetail](
	@cartDetailId uniqueidentifier,@cartId uniqueidentifier,
	@inputName varchar(255),@value varchar(8000),@sessionId  uniqueidentifier
) as
begin
	insert into cartdetail (cartdetailid,cartid,inputname,value,sessionid)
	values (@cartDetailId,@cartId,@inputName,@value,@sessionId)
end
GO
/****** Object:  View [dbo].[item_categories]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[item_categories] as
select itemnumber, dbo.ConcatCategoryName(itemnumber) as categories, bomonly from items
GO
/****** Object:  StoredProcedure [dbo].[itemInventoryPlot]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[itemInventoryPlot](@itemnumbers varchar(8000), @from datetime, @to datetime)
as begin
		/* itemInventoryPlot version 0.1.0 */
	set nocount on
	DECLARE @dataset table(itemnumber varchar(50), ats int, wip int, volume int, prebook int, consumed int, days datetime)
	DECLARE @itemnumber varchar(50)
	DECLARE @itemlist table(itemnumber varchar(50))
	--add comma to end of list
	SET @itemnumbers = @itemnumbers + ','
	--loop through list
	DECLARE @pos int
	WHILE CHARINDEX(',', @itemnumbers) > 0
	BEGIN
	  --get next comma position
	  SET @pos = CHARINDEX(',', @itemnumbers)
	  --insert next value into table
	  INSERT @itemlist VALUES (LTRIM(RTRIM(LEFT(@itemnumbers, @pos - 1))))
	  --delete inserted value from list
	  SET @itemnumbers = STUFF(@itemnumbers, 1, @pos, '')
	END
	DECLARE item_cursor CURSOR FORWARD_ONLY STATIC FOR
	SELECT itemnumber
	FROM @itemlist
	OPEN item_cursor;
	FETCH NEXT FROM item_cursor
	INTO @itemnumber
	WHILE @@FETCH_STATUS = 0
	BEGIN 
		insert into @dataset execute itemInventoryManager  @itemnumber, @from, @to, 0
		select days,ats as [Avaliable To Sell],
		wip as [Work In Progress],
		volume as [Allocated],
		prebook as [Prebook],
		consumed as [Consumed]
		from @dataset order by days asc;
		delete from @dataset;
		FETCH NEXT FROM item_cursor
		INTO @itemnumber
	END
	CLOSE item_cursor;
	DEALLOCATE item_cursor;
end
GO
/****** Object:  StoredProcedure [dbo].[insertCategoryItem]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[insertCategoryItem]
@valuesToAdd varchar(max),
@categoryId uniqueidentifier
as
declare @items table(columnIndex int identity,value varchar(50));
declare @cat table(cRefId uniqueidentifier, lvl int)
insert into @cat exec dbo.categoryItemList @categoryId
insert into @items select * from dbo.SPLIT(@valuesToAdd,',',1,1);
insert into categoryDetail
select NEWID() as categoryDetailId, @categoryId as categoryId, 
case when items.itemNumber is null then '' else items.itemNumber end as itemNumber,
0 as listOrder,
case when categories.categoryId is null then '00000000-0000-0000-0000-000000000000' else categories.categoryId end as childCategoryId,
null as VerCol
from @items
left join items on items.itemNumber = value
left join categories on replace(replace(cast(categories.categoryId as varchar(50)),'}',''),'{','') = replace(replace(value,'}',''),'{','')
where not value in 
(
select replace(replace(cast(categoryDetail.childCategoryId as varchar(50)),'}',''),'{','') from categoryDetail where categoryId = @categoryId
union all 
select itemNumber from categoryDetail where categoryId = @categoryId
union all
select replace(replace(cast(g.cRefId as varchar(50)),'}',''),'{','') from @cat g
)
GO
/****** Object:  StoredProcedure [dbo].[getSession]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[getSession](@sessionId uniqueidentifier,@url varchar(255),
@querystring varchar(max),@responder varchar(50),@adminResponder varchar(50),@adminDirectory varchar(50)) as
begin
	/* getSession version 1.0 */
	select 
	userid, 
	public_user.zip, 
	public_user.rate, 
	Context, 
	RecordsPerPage,
	orderby,
	listmode,
	wholesaler, 
	userlevel,
	user_email,
	allowPreorders,
	admin_script,
	logon_redirect,
	UI_JSON
	from public_user
	where sessionid = @sessionId

	select property, value from sessionHash where sessionid = @sessionId
	/* drop the tildie, they are not real, they are invaders from another language */
	set @responder = REPLACE(@responder,'~','');
	set @adminResponder = REPLACE(@adminResponder,'~','');
	set @adminDirectory = REPLACE(@adminDirectory,'~','');
	print @responder;
	print @adminResponder;
	print @adminDirectory;
	print @url
	print CHARINDEX(@adminResponder,@url);
	print CHARINDEX(@responder,@url);
	print CHARINDEX(@adminDirectory,@url);
	/* track visit history, but not when it's a @responder or @adminResponder url */
	if CHARINDEX(@adminResponder,@url) = 0 and CHARINDEX(@responder,@url) = 0 and CHARINDEX(@adminDirectory,@url) = 0 begin
		insert into visitorDetail select NEWID(),@sessionId,@url,GETDATE(),@querystring,null
	end
end
GO
/****** Object:  StoredProcedure [dbo].[getItems]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[getItems](@unique_siteId uniqueidentifier) as
begin
	/* DO NOT CHANGE THE ORDER OF ANTYHING IN HERE! - the item list loading relies on this order */
	select
	rtrim(itemNumber) as itemNumber,
	displayPrice, 
	price,
	salePrice,
	wholeSalePrice,
	isOnSale,
	description,
	shortCopy,
	packingSlipImage,
	auxillaryImage,
	cartImage,
	rtrim(formName) as formName,
	ProductCopy, 
	HTML,
	detailImage,
	fullSizeImage,
	listingImage,
	listing2Image,
	reorderPoint, 
	BOMOnly,
	HomeCategory, 
	HomeAltCategory, 
	Weight,
	quantifier,
	shortDescription,
	freeShipping,
	keywords, 
	searchPriority, 
	workCreditValue, 
	notax, 
	deleted, 
	removeafterpurchase, 
	parentItemnumber, 
	swatchId, 
	allowPreorders, 
	inventoryOperator,
	inventoryDepletesOnFlagId,
	inventoryRestockOnFlagId,
	itemIsConsumedOnFlagId,
	revenueaccount,
	sizeId,
	ratio,
	divisionId
	from item_list
	where unique_siteId = @unique_siteId or unique_siteId = '00000000-0000-0000-0000-000000000000'/* for items that have no site specific images (well, no images at all)*/
end
GO
/****** Object:  StoredProcedure [dbo].[addToCart]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[addToCart](
		@itemnumber varchar(50),
		@qty int,
		@sessionid uniqueidentifier,
		@userid int,
		@wholesale bit,
		@allow_Preorders bit,
		@unique_siteId uniqueidentifier,
		@new_price money,
		@override_Price bit,
		@overrideAddressId uniqueidentifier,
		@override_allow_preorder bit
	)
	as
	begin
		/* add to cart version 0.1.3 */
		set nocount on
		declare @error_number int
		declare @error_desc varchar(255)
		declare @price money
		declare @newid uniqueidentifier
		declare @addressid uniqueidentifier
		declare @newaddressid uniqueidentifier
		declare @stock table(qty int, itemnumber varchar(50))
		declare @stock_qty int
		declare @item_qty_total int
		declare @execStr nvarchar(100)
		declare @itempreorder bit
		declare @site_allow_preorder bit
		DECLARE @ncCountry varchar(255)
		DECLARE @ncRate int
		DECLARE @returnstring varchar(500)
		declare @ucv table(errors varchar(max))
		declare @invErrors varchar(max);
		SELECT @ncRate = default_rateid, @ncCountry = local_country, @site_allow_preorder = site_allow_preorder 
			from site_configuration with (nolock) where unique_siteID = @unique_siteId
		if (@override_allow_preorder = 1) begin
			set @site_allow_preorder = 1
		end
		set @error_number = 0
		set @error_desc = ''
		SET @execStr = 'dbo.itemStock '''+replace(@itemnumber,'''','''''')+''' '
		SET @newaddressid = (select newID())
		if (@overrideAddressId = '{00000000-0000-0000-0000-000000000000}') begin
			set @addressid = (select top 1 addressid from (
								select top 1 addressId, 1 as pri from cart with (nolock) where  sessionid = @sessionid and not addressId = @sessionid
								union all
								select top 1 contactId as addressid, 2 as pri from Contacts with (nolock) where userid = @userid and not contactId = @sessionid and not userId = -1
								union all
								select top 1 contactId as addressid, 3 as pri from contacts with (nolock) where sessionid = @sessionid and not contactId = @sessionid
								union all
								select @newaddressid as addressid,4 as pri
								) a order by  pri asc)
			IF (@addressid = @newaddressid)
			BEGIN
				/* create a new blank address */
				exec dbo.createContact @newaddressid,@sessionid,@userid,@ncRate,@ncCountry
			END
		end else begin
			set @addressid = @overrideAddressId
		end
	
		set @newid = '{00000000-0000-0000-0000-000000000000}'
		set @itempreorder = (select allowPreorders from Items with (nolock) where Itemnumber = @itemnumber)
	
		set @price = (
			select case when @override_Price = 0 then
				(select case 
						when not p.price is null then p.price 
						when not s.price is null then s.price 
						when @wholesale = 1 then i.wholesalePrice
						when i.isonsale = 1 then i.salePrice
						else i.price
						end as user_price
					from items i with (nolock)
					left join userPriceList p with (nolock) on p.itemnumber = i.itemnumber and userID = @userid and getDate() between fromDate and toDate
					left join site_prices s with (nolock) on s.itemnumber = i.itemnumber and s.unique_siteID = @unique_siteID
					where i.deleted = 0 and i.itemnumber = @itemnumber
				)
			else
				@new_price
			end
		)
		if @error_number = 0 begin
			/* check stock levels to make sure the cart does not contain more items than there are in stock */
			insert into @stock EXEC sp_executesql @execStr
			set @stock_qty = (select top 1 qty from @stock)
			set @item_qty_total = (select SUM(qty) from Cart with (nolock) where itemnumber = @itemnumber and SessionID = @sessionid)
			if @item_qty_total is null
			begin
				set @item_qty_total = 0
			end
			if (@stock_qty < (@item_qty_total+@qty)) and (@allow_Preorders = 0 or @itempreorder = 0) and @site_allow_preorder = 0
			begin
				if @stock_qty > 0
				begin
					set @error_number = 1
					set @error_desc = 'You are trying to add more '+@itemnumber+'s to the cart than there are '+@itemnumber+'s in stock. There are '+@stock_qty+' remaining in stock.'
				end
				else
				begin
					set @error_number = 2
					set @error_desc = 'Item '+@itemnumber+' is out of stock.'
				end
			end
			else
			begin
				if isnumeric(@price) = 1
				begin
					set @newid = newid();
				
					if exists(select 0
						from cart
						inner join items on items.itemNumber = cart.itemNumber and items.formName = 'NO FORM'
						where cart.itemnumber = @itemNumber and cart.sessionid = @sessionid
						) begin
						/* items with no forms only get one line item with an ever increasing quantity */
						update cart set qty = qty + @qty where itemnumber = @itemNumber and sessionid = @sessionid		
					end else begin
						insert into cart (
						cartid,sessionid,qty,itemnumber,price,addtime,
						valueCostTotal,noTaxValueCostTotal,addressId,
						estimatedFulfillmentDate,fulfillmentDate,
						backorderedQty,canceledQty,returnToStock,
						customerLineNumber,termId,epsmmcsAIFilename,
						epsmmcsOutput,
						serialId,shipmentId,orderId,
						serialNumber,shipmentNumber,orderNumber,userId,
						lineNumber,parentCartId
						)
						values
						(
						@newid,
						@sessionid,
						@qty,
						@itemnumber,
						@price,
						getdate(),
						0,
						0,
						@addressid,
						'1/1/1900 00:00:00.000',
						'1/1/1900 00:00:00.000',
						0,
						0,
						0,
						'',
						0,
						'',
						'',
						-1,
						-1,
						-1,
						'',
						'',
						'',
						@userid,
						-1,
						'{00000000-0000-0000-0000-000000000000}'
						)
					end
				end
				else
				begin
					set @error_number = 4
					set @error_desc = 'Item '+@itemnumber+' does not exist or the price is missing.'
				end
			end
			/* build dynamic kit pricing */
			insert into @ucv exec dbo.updateCartValues @sessionId, @wholesale, @userId
			set @invErrors = (select errors from @ucv);
			if LEN(RTRIM(@invErrors)) > 0 begin
				set @error_number = 5
				set @error_desc = @invErrors
			end
		end
	
		if @error_number <> 0
		begin
			insert into errors (script,description,number,source,sessionID,reference,logtime) values
			('dbo.addToCart',@error_desc,@error_number,'dbo.addToCart',@sessionid,@returnstring,GETDATE())
			print @returnstring
		end
	
		select @sessionid as sessionId,
		@newid as cartId, 
		@error_number as errorNumber, 
		@error_desc as errorDesc,
		@itemnumber as itemnumber,
		@qty as qty,
		@addressid as addressid,
		@price as money
		set nocount off
	end
GO
/****** Object:  StoredProcedure [dbo].[getShipPrices]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[getShipPrices](
	@sessionID uniqueidentifier
)
AS
BEGIN

SELECT c.weight,disc_wgt,sessionid,zip,wholesaledealer,selectedRateId,rateId,name,Enabled,International,discountable,ZoneCarrierID,
ZoneServiceClass,cmrAreaSurch,resAreaSurchg,groundFuelSurchgPct,airFuelSurchgPct,showsUpInOrderEntry,showsUpInWholesaleCart,
showsUpInRetailCart,shipzone,shippingCost as zoneTablePrice,carrier,sourceZip,service,fromzip,tozip,addressID,
dbo.getShippingSurcharge(rateId,zip,shippingCost,zoneServiceClass,airFuelSurchgPct,groundFuelSurchgPct,wholesaledealer,cmrAreaSurch,resAreaSurchg) as price,
case when selectedRateId = rateId then CAST(1 as bit) else CAST(0 as bit) end as selected
from 
(
	select
	dbo.getContactWeight(addressID,cart.sessionID) as weight,
	dbo.getDiscountedContactWeight(addressID,cart.sessionID) as disc_wgt,
	cart.sessionid,
	cast(substring(contacts.zip,0,5) as int) as zip,
	wholesaledealer,
	rate as selectedRateId,
	addressID
	from cart
	inner join contacts on Contacts.ContactID = addressID
	left join users on contacts.userid = users.userid
	group by addressID,cart.sessionID,cast(substring(contacts.zip,0,5) as int),wholesaledealer,rate
) c
inner join shipping_services on 
shipping_services.weight = c.weight
and c.zip between shipping_services.fromzip and shipping_services.tozip
where
c.SessionID = @sessionID


END
GO
/****** Object:  UserDefinedFunction [dbo].[getAddressShipPrice]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[getAddressShipPrice](
	@addressID uniqueidentifier,
	@sessionID uniqueidentifier
)
RETURNS money
AS
BEGIN
declare @shipprice money
declare @wholesale bit
declare @zip varchar(15)
declare @rateID int
declare @weight float
declare @disc_wgt float

SELECT @zip = zip, @wholesale = wholesale, @rateID = rate, @weight = weight, @disc_wgt = disc_wgt from (
	select case when addresses.zip is null then (select top 1 default_zip from site_configuration with (nolock)) else addresses.zip end as zip, 
		case when wholesaledealer is null then 0 else wholesaledealer end as wholesale,
		case when rate is null then (select top 1 default_RateID from site_configuration with (nolock)) else rate end as rate,
		dbo.getContactWeight(@addressID,@sessionID) as weight,
		dbo.getDiscountedContactWeight(@addressID,@sessionID) as disc_wgt
	from addresses with (nolock)
	left join orders with (nolock) on orders.sessionid = @sessionID
	left join users with (nolock) on orders.userid = users.userid
	where addressID = @addressID
) a

if (isnumeric(substring(@zip,1,5))=1)
	begin
		set @shipprice =	(SELECT 
								case 
									when exists(select count(*) from areaSurcharge with (nolock) where carrier = @rateID and deliveryArea = SUBSTRING(@zip,1,5))
								then (shipzone.cost+(case 
														when @wholesale = 1 
														then shippingtype.cmrAreaSurch 
														else shippingtype.resAreaSurchg 
													end))*(1+(case 
															when zoneServiceClass > 1
															then airFuelSurchgPct
															else groundFuelSurchgPct 
														end))
								else
								shipzone.cost*(1+(case 
												when zoneServiceClass > 1
												then airFuelSurchgPct
												else groundFuelSurchgPct
											end ))
								end
								as cost
							FROM shipzone  with (nolock)
								inner join shippingtype with (nolock) on shipzone.rate = shippingtype.rate
							WHERE 
								shippingtype.zoneserviceclass in (SELECT [service] from ziptozone with (nolock) WHERE SUBSTRING(@zip,1,5) between fromzip and tozip)
								and shipzone.shipzone in (select shipzone from ziptozone with (nolock) where SUBSTRING(@zip,1,5) between fromzip and tozip)
								and shipzone.weight = (@weight) /*removed -@discWeight to disable free shipping calculation */
								and	shippingtype.enabled = 1 
								and shippingtype.rate not in (select rate from zoneexclusions with (nolock) where shipzone.shipzone = zoneexclusions.shipzone)
								and shippingtype.rate = @rateID
						)
		end 

if (@shipprice is null)
	begin
		set @shipprice = 0
	end

RETURN(@shipprice)
END
GO
/****** Object:  StoredProcedure [dbo].[getCartContacts]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[getCartContacts] @sessionId uniqueidentifier
AS
BEGIN
	declare @address table (
		contactId uniqueidentifier,
		userId int,
		firstName varchar(100),
		lastName varchar(100),
		address1 varchar(100),
		address2 varchar(100),
		city varchar(100),
		state varchar(100),
		zip varchar(100),
		country varchar(100),
		homePhone varchar(100),
		workPhone varchar(100),
		email varchar(100),
		specialInstructions varchar(max),
		comments varchar(max),
		sessionId uniqueidentifier,
		sendShipmentUpdates bit,
		emailAds bit,
		rate int,
		dateCreated datetime,
		company varchar(100),
		weight float,
		disc_wgt float,
		selectedZip int,
		wholesaledealer bit,
		addressId uniqueidentifier
	)
	insert into @address
	select
	contactID, userId, firstName, lastName, address1, address2, city, state, zip,
	country, HomePhone, WorkPhone, Email, SpecialInstructions, Comments, c.sessionID, sendshipmentupdates,
	emailads, contacts.rate as contactSelectedRate, dateCreated, company, c.weight, disc_wgt, selectedZip,
	wholesaledealer, addressId
	from 
	(
		select
		dbo.getContactWeight(addressID,ic.sessionID) as weight,
		dbo.getDiscountedContactWeight(addressID,ic.sessionID) as disc_wgt,
		ic.sessionid,
		case when isNumeric(substring(ic.zip,1,5)) = 1 then cast( substring(ic.zip,1,5) as int) else 0 end as selectedZip,
		wholesaledealer,
		rate as selectedRateId,
		addressID
		from (
			select addressId,cart.sessionId,contacts.zip as zip,wholesaledealer,rate
			from cart with (nolock)
			inner join contacts with (nolock) on contacts.contactId = addressId
			left join users with (nolock) on contacts.userId = users.userId
			where cart.sessionid = @sessionId
			group by addressID,cart.sessionID,contacts.zip,wholesaledealer,rate
		) ic
	) c
	inner join contacts with (nolock) on (contactId = c.addressId or contactId = @sessionId)
	where c.sessionid = @sessionId

	select
	contactId, userId, firstName, lastName, address1, address2, city, state, zip,
	country, homePhone, workPhone, email, specialInstructions, comments, sessionId, sendShipmentUpdates,
	emailAds, a.rate as contactSelectedRate, dateCreated, company, rate as rate, case when a.rate = rate then cast(1 as bit) else cast(0 as bit) end as selected,
	name, selectedZip, shipzone as shipZone, 
	dbo.getShippingSurcharge(rateId,selectedZip,shippingCost,zoneServiceClass,airFuelSurchgPct,groundFuelSurchgPct,wholesaledealer,cmrAreaSurch,resAreaSurchg)+addCharge as estShipCost,
	a.weight,disc_wgt,@sessionId,selectedZip,wholesaledealer,rate,rateId,name,Enabled,International,discountable,ZoneCarrierID,
	ZoneServiceClass,cmrAreaSurch,resAreaSurchg,groundFuelSurchgPct,airFuelSurchgPct,showsUpInOrderEntry,showsUpInWholesaleCart,
	showsUpInRetailCart,shipzone,shippingCost as zoneTablePrice,carrier,sourceZip,service,fromzip,tozip,addressID,
	case when a.rate = rateId then CAST(1 as bit) else CAST(0 as bit) end as selected
	from @address a 
	inner join shipping_services with (nolock) on (
		(shipping_services.weight = a.weight or shipping_services.weight = -1 ) and 
		case when isnumeric(substring(zip,1,5)) = 1 then cast(substring(zip,1,5) as int) else 0 end
		between shipping_services.fromzip and shipping_services.tozip
	)
	order by contactId

END
GO
/****** Object:  StoredProcedure [dbo].[getOrderAddresses]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[getOrderAddresses]
@orderSessionId uniqueidentifier,
@cartSessionId uniqueidentifier
AS
BEGIN
	declare @wholesaledealer bit;
	declare @userId int;
	(select @wholesaledealer = wholeSaleDealer,@userId = userId from users where userId = (select top 1 userId from orders where sessionId = @orderSessionId))
	
	select
	addresses.addressId, 0 as defaultContact, @userId as userID, FirstName, LastName, Address1, Address2, City, State, addresses.ZIP,
	Country, HomePhone, WorkPhone, Email, SpecialInstructions, Comments, @orderSessionId as sessionid, sendshipmentupdates,
	emailads, addresses.rate as addresseselectedRate, dateCreated, Company, rate as rate, case when addresses.rate = rate then cast(1 as bit) else cast(0 as bit) end as selected,
	name, c.zip as selectedZip, shipzone as shipZone, 
	dbo.getShippingSurcharge(rateId,c.zip,shippingCost,zoneServiceClass,airFuelSurchgPct,groundFuelSurchgPct,@wholesaledealer,cmrAreaSurch,resAreaSurchg) as estShipCost,
	c.weight,disc_wgt,@orderSessionId as sessionid,c.zip,@wholesaledealer,selectedRateId,rateId,name,Enabled,International,discountable,ZoneCarrierID,
	ZoneServiceClass,cmrAreaSurch,resAreaSurchg,groundFuelSurchgPct,airFuelSurchgPct,showsUpInOrderEntry,showsUpInWholesaleCart,
	showsUpInRetailCart,shipzone,shippingCost as zoneTablePrice,carrier,sourceZip,service,fromzip,tozip,c.addressID,
	case when selectedRateId = rateId then CAST(1 as bit) else CAST(0 as bit) end as selected
	from 
	(
		select
		dbo.getContactWeight(cart.addressID,@cartSessionId)+dbo.getContactWeight(cart.addressID,@orderSessionId) as weight,
		dbo.getDiscountedContactWeight(cart.addressID,@cartSessionId)+dbo.getDiscountedContactWeight(cart.addressID,@orderSessionId) as disc_wgt,
		cast(substring(addresses.zip,0,5) as int) as zip,
		@wholesaledealer as wholesaledealer,
		rate as selectedRateId,
		cart.addressID
		from cart with (nolock)
		inner join addresses with (nolock) on addresses.addressId = cart.addressID
		where cart.sessionid = @orderSessionId or cart.sessionId = @cartSessionId
		group by cart.addressID,cast(substring(addresses.zip,0,5) as int),rate
	) c
	inner join shipping_services with (nolock) on shipping_services.weight = c.weight
		and c.zip between shipping_services.fromzip and shipping_services.tozip
	inner join addresses with (nolock) on (addresses.addressId = c.addressID)
	order by addresses.addressId
	option (recompile)
END
GO
/****** Object:  View [dbo].[public_shipment]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[public_shipment]
as 
select 
addressid as addressID,
sessionid as sessionid,
dbo.getContactTaxTotal(sessionid,addressID) as addressTaxTotal,
dbo.getContactSubtotal(addressid,sessionid) as addressSubTotal,
dbo.getContactShipPrice(addressid,sessionid) as shipPrice,
dbo.getContactWeight(addressid,sessionid) as weight
from cart with (nolock)
group by addressid,sessionid
GO
/****** Object:  StoredProcedure [dbo].[getOrderCart]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[getOrderCart](@sessionId uniqueidentifier) as
begin
declare @cd table(
	cartDetailId uniqueidentifier,
	cartId uniqueidentifier,
	itemNumber varchar(50),
	price money,
	qty int,
	addressId uniqueidentifier,
	value varchar(max),
	inputName varchar(50),
	estShipPrice money,
	subTotal money,
	taxTotal money
)
declare @sp table(
	addressId uniqueidentifier,
	estShipPrice money
)
insert into @cd select cartDetailId,cartId,itemnumber,price,qty,addressId,value,
inputName,0 as estShipPrice,subTotal,taxTotal from public_orderCart
where sessionid = @sessionId order by cartId;
insert into @sp select addressId,dbo.getAddressShipPrice(addressId,@sessionId) from @cd group by addressId


select cartDetailId,cartId,itemnumber,price,qty,i.addressId,value,inputName,o.estShipPrice,subTotal,taxTotal
from @cd i inner join @sp o on i.addressId = o.addressId

end
GO
/****** Object:  StoredProcedure [dbo].[getCart]    Script Date: 03/11/2011 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[getCart](@sessionId uniqueidentifier) as
begin
declare @cd table(
	cartDetailId uniqueidentifier,
	cartId uniqueidentifier,
	itemNumber varchar(50),
	price money,
	qty int,
	addressId uniqueidentifier,
	value varchar(max),
	inputName varchar(50),
	estShipPrice money,
	subTotal money,
	taxTotal money,
	addTime datetime,
	parentCartId uniqueidentifier
)
declare @sp table(
	addressId uniqueidentifier,
	estShipPrice money
)

/*update the values total cost before selecting the cart data */
declare @wholesale bit, @userId int
select @wholesale = wholesale, @userId = userId from (
	select v.userId,
	case when u.wholeSaleDealer is null then 0 else u.wholeSaleDealer end as wholesale
	from visitors v
	left join users u on u.userId = v.userId
	where v.sessionId = @sessionId
) f
/* build dynamic kit pricing */
declare @ucv table(errors varchar(max))
insert into @ucv exec dbo.updateCartValues @sessionId, @wholesale, @userId

insert into @cd select cartDetailId,cartId,itemnumber,price,qty,addressId,value,
inputName,0 as estShipPrice,subTotal,taxTotal,addtime,parentCartId from public_cart with (nolock)
where sessionid = @sessionId;

insert into @sp select addressId,dbo.getContactShipPrice(addressId,@sessionId) from @cd group by addressId

select cartDetailId,cartId,itemnumber,price,qty,i.addressId,value,inputName,o.estShipPrice,subTotal,taxTotal,addtime,parentCartId
from @cd i inner join @sp o on i.addressId = o.addressId order by addTime desc,cartId

end
GO
/****** Object:  Default [DF_Users_email]    Script Date: 03/11/2011 19:45:19 ******/
ALTER TABLE [dbo].[users] ADD  CONSTRAINT [DF_Users_email]  DEFAULT ((0)) FOR [email]
GO
/****** Object:  Default [DF_Users_terms]    Script Date: 03/11/2011 19:45:19 ******/
ALTER TABLE [dbo].[users] ADD  CONSTRAINT [DF_Users_terms]  DEFAULT ((0)) FOR [termId]
GO
/****** Object:  Default [DF_ShippingType_Enabled]    Script Date: 03/11/2011 19:45:24 ******/
ALTER TABLE [dbo].[shippingType] ADD  CONSTRAINT [DF_ShippingType_Enabled]  DEFAULT ((1)) FOR [enabled]
GO
/****** Object:  Default [DF_adCategoryDetail_adOrder]    Script Date: 03/11/2011 19:45:25 ******/
ALTER TABLE [dbo].[adCategoryDetail] ADD  CONSTRAINT [DF_adCategoryDetail_adOrder]  DEFAULT ((0)) FOR [adOrder]
GO
/****** Object:  Default [DF_adCategoryDetail_impressions]    Script Date: 03/11/2011 19:45:25 ******/
ALTER TABLE [dbo].[adCategoryDetail] ADD  CONSTRAINT [DF_adCategoryDetail_impressions]  DEFAULT ((0)) FOR [impressions]
GO
/****** Object:  Default [DF_adCategoryDetail_clicks]    Script Date: 03/11/2011 19:45:25 ******/
ALTER TABLE [dbo].[adCategoryDetail] ADD  CONSTRAINT [DF_adCategoryDetail_clicks]  DEFAULT ((0)) FOR [clicks]
GO
/****** Object:  Default [DF_AddressUpdate_AddressUpdateID]    Script Date: 03/11/2011 19:45:25 ******/
ALTER TABLE [dbo].[addressUpdate] ADD  CONSTRAINT [DF_AddressUpdate_AddressUpdateID]  DEFAULT (newid()) FOR [addressUpdateId]
GO
/****** Object:  Default [DF_AddressUpdate_addDate]    Script Date: 03/11/2011 19:45:25 ******/
ALTER TABLE [dbo].[addressUpdate] ADD  CONSTRAINT [DF_AddressUpdate_addDate]  DEFAULT (getdate()) FOR [addDate]
GO
/****** Object:  Default [DF_ads_impressions]    Script Date: 03/11/2011 19:45:25 ******/
ALTER TABLE [dbo].[ads] ADD  CONSTRAINT [DF_ads_impressions]  DEFAULT ((0)) FOR [impressions]
GO
/****** Object:  Default [DF_ads_clicks]    Script Date: 03/11/2011 19:45:25 ******/
ALTER TABLE [dbo].[ads] ADD  CONSTRAINT [DF_ads_clicks]  DEFAULT ((0)) FOR [clicks]
GO
/****** Object:  ForeignKey [FK_serial_order]    Script Date: 03/11/2011 19:45:24 ******/
ALTER TABLE [dbo].[serial_shipment]  WITH CHECK ADD  CONSTRAINT [FK_serial_order] FOREIGN KEY([orderId])
REFERENCES [dbo].[serial_order] ([orderId])
GO
ALTER TABLE [dbo].[serial_shipment] CHECK CONSTRAINT [FK_serial_order]
GO
/****** Object:  ForeignKey [FK_serial_line_order]    Script Date: 03/11/2011 19:45:24 ******/
ALTER TABLE [dbo].[serial_line]  WITH CHECK ADD  CONSTRAINT [FK_serial_line_order] FOREIGN KEY([orderId])
REFERENCES [dbo].[serial_order] ([orderId])
GO
ALTER TABLE [dbo].[serial_line] CHECK CONSTRAINT [FK_serial_line_order]
GO
/****** Object:  ForeignKey [FK_serial_shipment]    Script Date: 03/11/2011 19:45:24 ******/
ALTER TABLE [dbo].[serial_line]  WITH CHECK ADD  CONSTRAINT [FK_serial_shipment] FOREIGN KEY([shipmentId])
REFERENCES [dbo].[serial_shipment] ([shipmentid])
GO
ALTER TABLE [dbo].[serial_line] CHECK CONSTRAINT [FK_serial_shipment]
GO
/****** Object:  UserDefinedTableType [dbo].[intTable]    Script Date: 03/11/2011 19:45:25 ******/
CREATE TYPE [dbo].[intTable] AS TABLE(
	[value] [int] NULL
)
GO
/****** Object:  UserDefinedTableType [dbo].[jsonTable]    Script Date: 03/11/2011 19:45:25 ******/
CREATE TYPE [dbo].[jsonTable] AS TABLE(
	[json] [varchar](max) NULL,
	[row_number] [int] NULL,
	[pk] [sql_variant] NULL,
	[pk_dataType] [varchar](50) NULL,
	[pk_dataLength] [int] NULL
)
GO

/* addtional indexes */
create nonclustered index idx_cart_addr on dbo.cart (addressId)
create nonclustered index idx_areaSurcharge on areaSurcharge (deliveryArea)

create index idx_visitorsCover on dbo.visitors ([addDate]) include (sessionId, http_user_agent, remote_addr)
create index idx_visitorDetailCover on dbo.visitorDetail ([time]) include (sessionId, url, queryString)
create index idx_orders_terms_and_orderDate on dbo.orders (termId, orderDate)
create index idx_cart_stats on dbo.cart (addTime) include (qty,itemNumber,userId)


/* default page redirector */
insert into redirector
(redirectorId, urlMatchPattern, urlToRedirectToMatch, errorMatch, contentType, type, listOrder, enabled)
values ('00000000-0000-0000-0000-000000000000','~/$','~/default.aspx','200','text/html','Rewriter',0,1)