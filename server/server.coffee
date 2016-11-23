@propSwitch = 0
@apiurl = undefined
@apikey = undefined
@refreshMinutes = Meteor.settings.REFRESH_MINUTES
Meteor.startup ->
  Props = undefined
  apiurl = Meteor.settings.API_URL
  apikey = Meteor.settings.API_KEY
  fetchStcProperties = (pageNo) ->
    if propSwitch is 1 then Props = Properties
    else Props = Properties1
    if not pageNo then pageNo = 1
    HTTP.call 'post', apiurl + 'search?APIKey=' + apikey, 
      data: {
        MarketingFlags: 'ApprovedForMarketingWebsite'
        MinimumPrice: 0
        MaximumPrice: 9999999
        MinimumBedrooms: 0
        SortBy: 0
        PageSize: 2000
        IncludeStc: true
        BranchIdList: []
        PageNumber: pageNo
      }
      headers: {'Rezi-Api-Version': '1.0'}
    , Meteor.bindEnvironment (err, data) ->
      console.log 'call done ', data.data.PageNumber, data.data.PageSize, data.data.CurrentCount, data.data.TotalCount
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
        fetchNonStcProperties 1
  fetchNonStcProperties = (pageNo) ->
    HTTP.call 'post', apiurl + 'search?APIKey=' + apikey, 
      data: {
        MarketingFlags: 'ApprovedForMarketingWebsite'
        MinimumPrice: 0
        MaximumPrice: 9999999
        MinimumBedrooms: 0
        SortBy: 0
        PageSize: 2000
        IncludeStc: false
        BranchIdList: []
        PageNumber: pageNo
      }
      headers: {'Rezi-Api-Version': '1.0'}
    , Meteor.bindEnvironment (err, data) ->
      console.log 'non stc done'
      if data.data.Collection
        for property in data.data.Collection
          Props.update
            RoleId: property.RoleId
          , '$set':
            stc: false
      if propSwitch is 1
        @propSwitch = 0 
      else 
        @propSwitch = 1


  setInterval Meteor.bindEnvironment(fetchStcProperties), refreshMinutes * 60 * 1000
  Props = Properties
  fetchStcProperties 1