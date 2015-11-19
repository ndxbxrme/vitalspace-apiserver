bodyParser = Npm.require 'body-parser'
Picker.middleware bodyParser.json()
Picker.middleware bodyParser.urlencoded(extended:false)
Picker.route '/', (params, req, res, next) ->
  res.end 'hello'
Picker.route '/search', (params, req, res, next) ->
  res.setHeader "Access-Control-Allow-Origin", "*"
  res.setHeader "Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept"
  if req.method is 'POST'
    Props = if propSwitch is 1 then Properties1 else Properties
    where = {}
    if req.body.MinimumPrice or req.body.MaximumPrice
      where['Price.PriceValue'] = {}
    if req.body.MinimumPrice
      where['Price.PriceValue']['$gte'] = req.body.MinimumPrice
    if req.body.MaximumPrice
      where['Price.PriceValue']['$lte'] = req.body.MaximumPrice
    if req.body.MinimumBedrooms or req.body.MaximumBedrooms
      where['RoomCountsDescription.Bedrooms'] = {}
    if req.body.MinimumBedrooms
      where['RoomCountsDescription.Bedrooms']['$gte'] = req.body.MinimumBedrooms
    if req.body.MaximumBedrooms
      where['RoomCountsDescription.Bedrooms']['$lte'] = req.body.MaximumBedrooms
    if req.body.MinimumRooms or req.body.MaximumRooms
      where['NoRooms'] = {}
    if req.body.MinimumRooms
      where['NoRooms']['$gte'] = req.body.MinimumRooms
    if req.body.MaximumRooms
      where['NoRooms']['$lte'] = req.body.MaximumRooms
    if not req.body.IncludeStc
      where['stc'] = false
    if req.body.RoleType
      where['RoleType.SystemName'] = req.body.RoleType
    limit = 10
    skip = 0
    if req.body.PageSize
      limit = parseInt req.body.PageSize
    if req.body.PageNumber
      skip = (req.body.PageNumber - 1) * limit
    total = Props.find where
    .fetch().length
    paging =
      limit: limit
      skip: skip
    properties = Props.find where, paging
    .fetch()
    response = 
      TotalCount: total
      CurrentCount: properties.length
      PageSize: limit
      PageNumber: Math.floor(skip / limit) + 1
      Collection: properties
    res.end JSON.stringify response
  else if req.method is 'OPTIONS'
    res.end()
Picker.route '/property', (params, req, res, next) ->
  res.setHeader "Access-Control-Allow-Origin", "*"
  res.setHeader "Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept"
  if req.method is 'POST'
    Props = if propSwitch is 1 then Properties1 else Properties
    id = undefined
    if req.body.id
      id = req.body.id
    if req.body.RoleId
      id = req.body.RoleId
    property = Props.findOne
      RoleId: id
    if property && property.NoRooms
      where = 
        NoRooms: property.NoRooms
        'Price.PriceValue':
          '$gte': property.Price.PriceValue * 0.85
          '$lte': property.Price.PriceValue * 1.15
      similar = Props.find where,
        limit: 4
      .fetch()
      if similar
        property.similar = similar
    res.end JSON.stringify property
  else if req.method is 'OPTIONS'
    res.end()