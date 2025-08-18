let
    Source = Sql.Databases("m3data.kemin.com"),
    PRD_Staging = Source{[Name="PRD_Staging"]}[Data],
    m3_V_CustomerOrderLines = PRD_Staging{[Schema="m3",Item="V_CustomerOrderLines"]}[Data],
    #"Removed Other Columns" = Table.SelectColumns(m3_V_CustomerOrderLines,{"Allocated quantity - basic U/M", "Customer number", "Customer order number", "Departure date (ISO format)", "Entry date (ISO format)", "Facility", "Highest status - customer order", "Item name", "Item number", "Ordered quantity - basic U/M", "Remaining quantity - basic U/M", "Warehouse"}),
    #"Filtered Rows1" = Table.SelectRows(#"Removed Other Columns", each [#"Highest status - customer order"] < 66),
    Custom1 = #"Filtered Rows1",
    #"Filtered Rows" = Table.SelectRows(Custom1, each [Facility] = "NAA" or [Facility] = "NOA" or [Facility] = "NAI"),
    #"Filtered Rows2" = Table.SelectRows(#"Filtered Rows", each true),
    #"Reordered Columns" = Table.ReorderColumns(#"Filtered Rows2",{"Customer order number", "Customer number", "Highest status - customer order", "Facility", "Warehouse", "Item number", "Item name", "Ordered quantity - basic U/M", "Allocated quantity - basic U/M", "Remaining quantity - basic U/M", "Departure date (ISO format)", "Entry date (ISO format)"}),
    #"Renamed Columns" = Table.RenameColumns(#"Reordered Columns",{{"Customer order number", "Order number"}, {"Departure date (ISO format)", "Departure date"}, {"Entry date (ISO format)", "Entry date"}, {"Remaining quantity - basic U/M", "Remaining quantity"}, {"Allocated quantity - basic U/M", "Allocated quantity"}, {"Ordered quantity - basic U/M", "Ordered quantity"}, {"Highest status - customer order", "Order STS"}}),
    #"Merged Queries" = Table.NestedJoin(#"Renamed Columns", {"Customer number"}, #"m3 V_CustomerMaster", {"Customer number"}, "m3 V_CustomerMaster", JoinKind.LeftOuter),
    #"Expanded m3 V_CustomerMaster" = Table.ExpandTableColumn(#"Merged Queries", "m3 V_CustomerMaster", {"Customer name"}, {"m3 V_CustomerMaster.Customer name"}),
    #"Reordered Columns1" = Table.ReorderColumns(#"Expanded m3 V_CustomerMaster",{"Order number", "Customer number", "m3 V_CustomerMaster.Customer name", "Order STS", "Facility", "Warehouse", "Item number", "Item name", "Ordered quantity", "Allocated quantity", "Remaining quantity", "Departure date", "Entry date"}),
    #"Renamed Columns1" = Table.RenameColumns(#"Reordered Columns1",{{"Ordered quantity", "Order qty"}, {"Allocated quantity", "Allocated qty"}, {"m3 V_CustomerMaster.Customer name", "Customer"}}),
    #"Filtered Rows3" = Table.SelectRows(#"Renamed Columns1", each not Text.StartsWith([Item number], "S")),
    #"Filtered Rows4" = Table.SelectRows(#"Filtered Rows3", each ([Warehouse] <> "260"))
in
    #"Filtered Rows4"