bodyParser = Npm.require 'body-parser'
Picker.middleware bodyParser.json()
Picker.middleware bodyParser.urlencoded(extended:false)
Picker.route '/', (params, req, res, next) ->
  res.end 'hey'
Picker.route '/search', (params, req, res, next) ->
  res.setHeader "Access-Control-Allow-Origin", "*"
  res.setHeader "Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept"
  if req.method is 'POST'
    try
      Props = if propSwitch is 1 then Properties1 else Properties
      where = {}
      if req.body.MinimumPrice or req.body.MaximumPrice
        where['Price.PriceValue'] = {}
      if req.body.MinimumPrice
        where['Price.PriceValue']['$gte'] = parseInt req.body.MinimumPrice
      if req.body.MaximumPrice
        where['Price.PriceValue']['$lte'] = parseInt req.body.MaximumPrice
      if req.body.MinimumBedrooms or req.body.MaximumBedrooms
        where['RoomCountsDescription.Bedrooms'] = {}
      if req.body.MinimumBedrooms
        where['RoomCountsDescription.Bedrooms']['$gte'] = parseInt req.body.MinimumBedrooms
      if req.body.MaximumBedrooms
        where['RoomCountsDescription.Bedrooms']['$lte'] = parseInt req.body.MaximumBedrooms
      if req.body.MinimumRooms or req.body.MaximumRooms
        where['NoRooms'] = {}
      if req.body.MinimumRooms
        where['NoRooms']['$gte'] = parseInt req.body.MinimumRooms
      if req.body.MaximumRooms
        where['NoRooms']['$lte'] = parseInt req.body.MaximumRooms
      if not req.body.IncludeStc
        where['stc'] = false
      if req.body.RoleType
        where['RoleType.SystemName'] = req.body.RoleType
      if req.body.Search
        where['$or'] = [{
          'Address.Street':
            '$regex': '.*' + req.body.Search + '.*'
            '$options': 'i'
        }
        {
          'Address.Town':
            '$regex': '.*' + req.body.Search + '.*'
            '$options': 'i'
        }
        {
          'Address.Locality':
            '$regex': '.*' + req.body.Search + '.*'
            '$options': 'i'
        }
        {
          'Address.Postcode':
            '$regex': '.*' + req.body.Search + '.*'
            '$options': 'i'
        }
        {
          'Address.County':
            '$regex': '.*' + req.body.Search + '.*'
            '$options': 'i' 
        }]
      sortby = 'Price.PriceValue'
      sortdir = 1
      limit = 10
      skip = 0
      if req.body.SortBy
        sortby = req.body.SortBy
      if req.body.SortDir
        sortdir = req.body.SortDir
      if req.body.PageSize
        limit = parseInt req.body.PageSize
      if req.body.PageNumber
        skip = (req.body.PageNumber - 1) * limit
      total = Props.find where
      .fetch().length
      paging =
        limit: limit
        skip: skip
        sort: {}
      paging.sort[sortby] = sortdir
      properties = Props.find where, paging
      .fetch()
      response = 
        TotalCount: total
        CurrentCount: properties.length
        PageSize: limit
        PageNumber: Math.floor(skip / limit) + 1
        Collection: properties
      res.end JSON.stringify response
    catch e
      res.end JSON.stringify e
  else if req.method is 'OPTIONS'
    res.end()
Picker.route '/property/:id', (params, req, res, next) ->
  res.setHeader "Access-Control-Allow-Origin", "*"
  res.setHeader "Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept"
  if req.method is 'GET'
    Props = if propSwitch is 1 then Properties1 else Properties
    id = undefined
    if params.id
      id = params.id
    property = Props.findOne
      RoleId: parseInt id
    similar = []
    if property && property.RoomCountsDescription && property.RoomCountsDescription.Bedrooms
      where = 
        'RoomCountsDescription.Bedrooms': property.RoomCountsDescription.Bedrooms
        'Price.PriceValue':
          '$gte': property.Price.PriceValue * 0.85
          '$lte': property.Price.PriceValue * 1.15
      similar = Props.find where,
        limit: 4
      .fetch()
    HTTP.call 'get', Meteor.settings.API_URL + id + '?APIKey=' + Meteor.settings.API_KEY,
      headers: {'Rezi-Api-Version': '1.0'}
    , Meteor.bindEnvironment (err, data) ->
      if data and data.data
        if similar
          data.data.similar = similar
        res.end JSON.stringify data.data
  else if req.method is 'OPTIONS'
    res.end()