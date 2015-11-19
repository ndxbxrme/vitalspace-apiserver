@propSwitch = 0
Meteor.startup ->
  Props = undefined
  apiurl = Meteor.settings.API_URL
  apikey = Meteor.settings.API_KEY
  fetchStcProperties = (pageNo) ->
    if propSwitch is 1 then Props = Properties
    else Props = Properties1
    if not pageNo then pageNo = 1
    HTTP.call 'post', apiurl + apikey, 
      data: {
        MarketingFlags: 'ApprovedForMarketingWebsite'
        MinimumPrice: 0
        MaximumPrice: 9999999
        MinimumBedrooms: 0
        SortBy: 0
        PageSize: 100
        IncludeStc: true
        BranchIdList: []
        PageNumber: pageNo
      }
      headers: {'Rezi-Api-Version': '1.0'}
    , Meteor.bindEnvironment (err, data) ->
      console.log 'call done ' + new Date()
      if data.data.Collection
        if pageNo is 1
          Props.remove {}
        for property in data.data.Collection
          property.stc = true
          property.NoRooms = 0
          if property.RoomCountsDescription
            if property.RoomCountsDescription.Bedrooms then property.NoRooms += property.RoomCountsDescription.Bedrooms
            if property.RoomCountsDescription.Bathrooms then property.NoRooms += property.RoomCountsDescription.Bathrooms
            if property.RoomCountsDescription.Receptions then property.NoRooms += property.RoomCountsDescription.Receptions
            if property.RoomCountsDescription.Others then property.NoRooms += property.RoomCountsDescription.Others
          Props.insert property
        if ((data.data.PageNumber - 1) * data.data.PageSize) + data.data.CurrentCount < data.data.TotalCount
          fetchStcProperties ++pageNo
        else
          fetchNonStcProperties 1
  fetchNonStcProperties = (pageNo) ->
    HTTP.call 'post', apiurl + apikey,
      data: {
        MarketingFlags: 'ApprovedForMarketingWebsite'
        MinimumPrice: 0
        MaximumPrice: 9999999
        MinimumBedrooms: 0
        SortBy: 0
        PageSize: 100
        IncludeStc: false
        BranchIdList: []
        PageNumber: pageNo
      }
      headers: {'Rezi-Api-Version': '1.0'}
    , Meteor.bindEnvironment (err, data) ->
      if data.data.Collection
        for property in data.data.Collection
          Props.update
            RoleId: property.RoleId
          , '$set':
            stc: false
      if ((data.data.PageNumber - 1) * data.data.PageSize) + data.data.CurrentCount < data.data.TotalCount
        fetchNonStcProperties ++pageNo
      else
        if propSwitch is 1
          @propSwitch = 0 
        else 
          @propSwitch = 1


  setInterval Meteor.bindEnvironment(fetchStcProperties), 1 * 60 * 1000
  Props = Properties
  fetchStcProperties 1