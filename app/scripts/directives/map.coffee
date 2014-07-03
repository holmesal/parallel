'use strict'

angular.module('parallelApp')
  .directive('map', ->
    template: '<div id="map"></div>'
    restrict: 'E'
    link: (scope, element, attrs) ->

        # scope.$watch 'location', reload

        # how often shall we load data whilst dragging yonder map?
        dragTimeout = 2000

        # set up the firebase reference
        firebaseRef = new Firebase 'https://publicdata-parking.firebaseio.com/san_francisco'
        streetsRef = firebaseRef.child 'streets'
        geoFireRef = streetsRef.child '_geofire'

        geoFire = new GeoFire geoFireRef


        scope.init = ->
            scope.location = [37.77199069765, -122.38829801735]

            scope.spots = {}
      
            # create ze map
            scope.map = L.mapbox.map('map', 'examples.map-i86nkdio').setView scope.location, 17

            # load more data on move
            # Too choppy right now! Optimize with a bounding box?
            # scope.map.on 'move', ->
            #     console.log 'move!'
            #     clearTimeout scope.loadTimeout if scope.loadTimeout
            #     scope.loadTimeout = setTimeout loadData, dragTimeout

            scope.map.on 'moveend', loadData

            # load data, the first time
            loadData()


        loadData = ->

            if not scope.throttle or Date.now() - scope.throttle > dragTimeout

                console.log 'loading data!'
                # Set the throttle
                scope.throttle = Date.now()

                # Clear the previous query
                scope.query.cancel() if scope.query
            
                # Get the current map center
                center = scope.map.getCenter()
                scope.location = [center.lat, center.lng]

                console.log "loading data for #{scope.location}"

                scope.query = geoFire.query 
                    center: scope.location
                    radius: 5

                scope.query.on 'ready', (data) =>
                    console.log 'data ready!'
                    console.log data

                scope.query.on 'key_entered', (key, location, distance) =>

                    # Unless it's already been loaded locally, start tracking this spot
                    unless scope.spots[key]
                        # Make a new spot and store that shit
                        scope.spots[key] = new Spot key, location, distance






        # Dat spots class though.
        class Spot

            constructor: (@key, @location, @distance) ->

                # grab some more dater
                @ref = streetsRef.child @key
                # just extend this instance
                @ref.once 'value', (snap) =>
                    for k, v of snap.val()
                        @[k] = v

                    # parse the rates into a more workable format
                    @parseRates()

                    # update, or just... date?
                    @update()

                @styles = 

                    active: 
                        color: 'green'
                        weight: 10

                    warning:
                        color: 'yellow'
                        weight: 10

                    dontdoit:
                        color: 'red'
                        weight: 10

            update: ->
                # wat time is it and wat does that mean?
                @classify()

                # draw all the lines
                @draw() if @style

            draw: ->
                # remove the line if it exists
                scope.map.removeLayer @line if @line

                # make start and end points
                start = L.latLng @points[0], @points[1]
                end = L.latLng @points[2], @points[3]

                # draw the line with the current style
                @line = L.polyline [start, end], @style

                @line.addTo scope.map
                

            range: ->
                # Update the distance to this marker
                @distance = GeoFire.distance scope.location, @location

            parseRates: ->

                # parsing into minutes because i've been spoiled by unix timestamps

                for rate, idx in @rates
                    @rates[idx].span =
                        start: @getMins rate.BEG
                        end: @getMins rate.END
                    

            getMins: (human) ->
                # track minutes
                minutes = 0

                isPM = if human.indexOf('PM') isnt -1 then true else false

                # hours to minutes
                colon = human.indexOf ':'
                hours = parseInt human.substring(0,colon)
                unless hours is 12 and not isPM
                    minutes += hours * 60

                # real minutes
                space = human.indexOf ' '
                minutes += parseInt human.substring(colon+1, space)

                if isPM
                    minutes += 12 * 60 # minutes in 12 hours

                return minutes


            classify: ->
                # get the current time
                d = new Date()
                mins = d.getHours() * 60 + d.getMinutes()

                found = false

                # where do we fall in @rates?
                for rate in @rates

                    if mins >= rate.span.start and mins < rate.span.end

                        found = true

                        if rate.RQ is 'Str sweep'
                            @style = @styles.dontdoit

                        else if rate.RQ is 'No charge'
                            @style = @styles.active

                        else
                            console.log rate.RQ
                            @style = @styles.warning

                        break

                # catch incomplete datasets
                if found is false
                    @style = null

                


        scope.init()







  )
