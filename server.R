# Copyright 2022-2024 Louis Héraut (louis.heraut@inrae.fr)*1,
#                     Éric Sauquet (eric.sauquet@inrae.fr)*1,
#                     Michel Lang (michel.lang@inrae.fr)*1,
#                     Jean-Philippe Vidal (jean-philippe.vidal@inrae.fr)*1,
#                     Benjamin Renard (benjamin.renard@inrae.fr)*1
#                     
# *1   INRAE, France
#
# This file is part of MAKAHO R shiny app.
#
# MAKAHO R shiny app is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# MAKAHO R shiny app is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with MAKAHO R shiny app.
# If not, see <https://www.gnu.org/licenses/>.


server = function (input, output, session) {
## 0. START __________________________________________________________
### 0.1. Dev check ___________________________________________________
    if (dir.exists(dev_lib_path)) {
        session$onSessionEnded(stopApp)
    }

### 0.2. Reactive value (common to all reactive or observer) _________
    rv = reactiveValues(startHelp=FALSE,
                        start=FALSE,
                        width=0,
                        height=0,
                        CodeSample=NULL,
                        CodeSample_save=NULL,
                        CodeSampleCheck=NULL,
                        CodeSearch=NULL,
                        markerListAll_save=NULL,
                        Search_save=NULL,
                        polyCoord=NULL,
                        theme_choice_save=NULL,
                        mapHTML=NULL,
                        polyMode='false',
                        clickMode=FALSE,
                        warningMode=TRUE,
                        dlClickMode=FALSE,
                        photoMode=FALSE,
                        invertSliderMode=FALSE,
                        sampleSliderMode=FALSE,
                        optimalMode=FALSE,
                        optimalMode_act=FALSE,
                        currentLimits=NULL,
                        map_bounds=NULL, 
                        mapPreview_bounds=NULL,
                        defaultBounds=NULL,
                        trend=NULL,
                        minX=NULL,
                        maxX=NULL,
                        helpPage=NULL,
                        helpPage_prev=NULL,
                        sizeList=NULL,
                        shapeList=NULL,
                        colorList=NULL,
                        fillList=NULL,
                        trendLabelAll=NULL,
                        codePlot=NULL,
                        missCode=c(),
                        invalidCode=c(),
                        badCode=c(),
                        actualise=FALSE,
                        need_actualise=FALSE,
                        idCode=NA,
                        idDate=NA,
                        idValue=NA,
                        idExCode=NA,
                        idExDate=NA,
                        idExValue=NA,
                        dataEX=NULL,
                        metaEX=NULL,
                        trendEX=NULL,
                        period=NULL,
                        sampling_period=NULL,
                        alpha=NULL,
                        type=NULL,
                        variable=NULL,
                        variable_en=FALSE,
                        event=FALSE,
                        unit=NULL,
                        unitHTML=NULL,
                        to_normalise=NULL,
                        proba=NULL,
                        Palette=NULL,
                        CodeSample_act=NULL,
                        CodeAdd=NULL,
                        actualiseForce=FALSE,
                        data_name="RRSE",
                        dataAll=NULL,
                        CodeAll=NULL,
                        data=NULL,
                        meta=NULL,
                        dataHTML_ana=""
                        )

### 0.3. Start observer ______________________________________________
    startOBS = observe({
        showElement(id="zoom_panelButton")
        showElement(id='ana_panelButton')
        showElement(id='theme_panelButton')
        showElement(id='photo_panelButton')
        showElement(id='download_data_panelButton')
        showElement(id='download_sheet_panelButton')
        showElement(id='help_panelButton')
        rv$startHelp = TRUE
        startOBS$destroy()
    })

    
    
## 1. MAP ____________________________________________________________
### 1.1. Background __________________________________________________
    theme = reactive({
        if (is.null(input$theme_choice)) {
            default_theme
        } else {
            input$theme_choice
        }
    })

    urlTile = reactive({
        get_urlTile(theme(),
                    provider,
                    theme_file,
                    resources_path,
                    token=jawg_token)
    })

    defaultLimits = reactive({
        if (is.null(rv$meta)) {
            Lon = meta()$lon_deg
            Lat = meta()$lat_edg
        } else {
            Lon = rv$meta$lon_deg
            Lat = rv$meta$lat_deg
        }
        list(north=max(Lat), east=max(Lon),
             south=min(Lat), west=min(Lon))
    })

### 1.2. Leaflet render ______________________________________________
    output$map = renderLeaflet({
        map = leaflet(options=leafletOptions(minZoom=minZoom,
                                             maxZoom=maxZoom,
                                             zoomControl=FALSE,
                                             attributionControl=FALSE))
        
        map = fitBounds(map,
                        lng1=defaultLimits()$east,
                        lat1=defaultLimits()$south,
                        lng2=defaultLimits()$west,
                        lat2=defaultLimits()$north,
                        options=list(padding=c(20, 20)))
        
        map = addTiles(map, urlTemplate=urlTile())
        rv$mapHTML = map
    })
    
    output$mapPreview = renderLeaflet({
        mapPreview = leaflet(options=leafletOptions(
                                 zoomControl=FALSE,
                                 attributionControl=FALSE))
        mapPreview = fitBounds(mapPreview,
                               lng1=defaultLimits()$east,
                               lat1=defaultLimits()$south,
                               lng2=defaultLimits()$west,
                               lat2=defaultLimits()$north,
                               options=list(padding=c(20, 20)))
    })


    observeEvent(input$map_click, {
        if (rv$polyMode == 'false' & !rv$clickMode & !rv$dlClickMode & !rv$photoMode) {
            hideAll()
        }
    })

## 2. ZOOM ___________________________________________________________
### 2.1. Default _____________________________________________________
    observeEvent({
        input$dimension
    }, {
        map = leafletProxy("map")
        map = fitBounds(map,
                        lng1=defaultLimits()$east,
                        lat1=defaultLimits()$south,
                        lng2=defaultLimits()$west,
                        lat2=defaultLimits()$north,
                        options=list(padding=c(20, 20)))
    })

### 2.2. Map preview _________________________________________________
#### 2.2.1. Definition _______________________________________________
    observeEvent({
        CodeSample()
        rv$meta
    }, {
        if (!is.null(CodeSample())) {
            Lon = rv$meta$lon_deg[rv$meta$code %in% CodeSample()]
            Lat = rv$meta$lat_deg[rv$meta$code %in% CodeSample()]
            rv$currentLimits = list(north=max(Lat), east=max(Lon),
                                    south=min(Lat), west=min(Lon))

            if (length(CodeSample()) > 1) {
                mapPreview = leafletProxy("mapPreview")
                mapPreview = fitBounds(mapPreview,
                                       lng1=rv$currentLimits$east,
                                       lat1=rv$currentLimits$south,
                                       lng2=rv$currentLimits$west,
                                       lat2=rv$currentLimits$north,
                                       options=list(padding=c(20, 20)))
            } else {
                rv$mapPreview_bounds = NULL
            }
        } else {
            rv$currentLimits = NULL
            rv$mapPreview_bounds = NULL
        }        
    })

#### 2.2.2. Auto zoom ________________________________________________
    observeEvent({
        input$mapPreview_bounds
    }, {
        rv$mapPreview_bounds = input$mapPreview_bounds
    })
    
    observeEvent(input$focusZoom_button, {
        map = leafletProxy("map")
        map = fitBounds(map,
                        lng1=rv$currentLimits$east,
                        lat1=rv$currentLimits$south,
                        lng2=rv$currentLimits$west,
                        lat2=rv$currentLimits$north,
                        options=list(padding=c(20, 20)))
    })

### 2.3. Map _________________________________________________________
    observeEvent(input$defaultZoom_button, {
        map = leafletProxy("map")
        map = fitBounds(map,
                        lng1=defaultLimits()$east,
                        lat1=defaultLimits()$south,
                        lng2=defaultLimits()$west,
                        lat2=defaultLimits()$north,
                        options=list(padding=c(20, 20)))
    })
    
    observeEvent({
        input$map_bounds
        rv$mapPreview_bounds
        theme()
    }, {
        windowChange = input$dimension[1] != rv$width | input$dimension[2] != rv$height

        if (!identical(windowChange, logical(0))) {
            if (windowChange) {
                rv$defaultBounds = input$map_bounds
                rv$width = input$dimension[1]
                rv$height = input$dimension[2]
            }

            error = 0.1
            isDefault = all(abs(unlist(input$map_bounds) - unlist(rv$defaultBounds)) <= error)
            isFocus = all(abs(unlist(input$map_bounds) - unlist(rv$mapPreview_bounds)) <= error)

            if (windowChange) {
                isDefault = TRUE
                isFocus = TRUE
            }

            if (isDefault & isFocus & is.null(rv$helpPage)) {
                hide(id='focusZoom_panelButton')
                hide(id='defaultZoom_panelButton')
                
            } else if (isDefault & !isFocus) {
                showElement(id='focusZoom_panelButton')
                hide(id='defaultZoom_panelButton')
                
            } else if (!isDefault & isFocus) {
                hide(id='focusZoom_panelButton')
                showElement(id='defaultZoom_panelButton')
                
            } else if (!isDefault & !isFocus) {
                showElement(id='focusZoom_panelButton')
                hide(id='defaultZoom_panelButton')
            }
        }
    })

## 3. MARKER _________________________________________________________
### 3.1. Get marker list _____________________________________________
    markerListAll = reactive({
        if (verbose) print("markerListAll")        
        
        if (theme() == 'terrain' | theme() == 'light') {
            none1Color = none1Color_light
        } else if (theme() == 'dark') {
            none1Color = none1Color_dark
        }
        
        if (theme() == 'terrain' | theme() == 'light') {
            none2Color = none2Color_light
        } else if (theme() == 'dark') {
            none2Color = none2Color_dark
        }

        if (!is.null(rv$dataEX) & !is.null(rv$trendEX) &
            all(rv$CodeSample %in% levels(factor(rv$dataEX$code)))) {
            
            trendCode = rv$trendEX$code

            sizeList = rep('small', length(rv$CodeAll))
            sizeList[match(rv$codePlot, rv$CodeAll)] = 'big'

            rv$sizeList = sizeList

            OkS = rv$trendEX$p <= alpha()
            CodeSU = trendCode[OkS & rv$trendEX$a >= 0]
            CodeSD = trendCode[OkS & rv$trendEX$a < 0]
            CodeNS = trendCode[!OkS]

            shapeList = rep('o', length(rv$CodeAll))
            shapeList[match(CodeSU, rv$CodeAll)] = '^'
            shapeList[match(CodeSD, rv$CodeAll)] = 'v'
            shapeList[match(CodeNS, rv$CodeAll)] = 'o'
            shapeList[match(missCode(), rv$CodeAll)] = 'o'

            rv$shapeList = shapeList

            colorList = rep(none1Color, length(rv$CodeAll))
            colorList[match(CodeSample(), rv$CodeAll)] = validSColor
            colorList[match(CodeSample()[CodeSample() %in% CodeNS],
                            rv$CodeAll)] = validNSColor
            invalidCodeSample = invalidCode()[invalidCode() %in% CodeSample()]
            colorList[match(invalidCodeSample, rv$CodeAll)] = invalidColor
            missCodeSample = missCode()[missCode() %in% CodeSample()]
            colorList[match(missCodeSample, rv$CodeAll)] = missColor

            rv$colorList = colorList

            rv$a_normalise= rv$trendEX$a_normalise
            rv$minX = rv$trendEX$a_normalise_min
            rv$maxX = rv$trendEX$a_normalise_max

            res = compute_colorBin(rv$minX,
                                   rv$maxX,
                                   colorStep=colorStep,
                                   center=0,
                                   include=FALSE)
            bin = res$bin
            upBin = res$upBin
            lowBin = res$lowBin            
            
            fill = get_colors(rv$a_normalise,
                              upBin=upBin,
                              lowBin=lowBin,
                              Palette=rv$Palette)
            
            fillList = rep(none2Color, length(rv$CodeAll))
            fillCode = rv$trendEX$code
            
            okCodeSample = fillCode %in% CodeSample()
            fillCodeSample = fillCode[okCodeSample]
            fillSample = fill[okCodeSample]

            fillList[match(fillCodeSample, rv$CodeAll)] = fillSample
            rv$fillList = fillList
            
        } else {
            sizeList = rep('small', nrow(rv$meta))
            shapeList = rep('o', nrow(rv$meta))
            colorList = rep(none1Color, nrow(rv$meta))
            fillList = rep(none2Color, nrow(rv$meta))
        }
        
        get_markerList(sizeList,
                       shapeList,
                       colorList,
                       fillList,
                       resources_path)
    })

### 3.2. Plot marker list ____________________________________________
    observeEvent({
        theme()
        alpha()
        rv$meta
        markerListAll()
    }, {

        if (verbose) print("observeEvent.marker")   
        map = leafletProxy("map")
        
        if (theme() != rv$theme_choice_save |
            is.null(unlist(rv$markerListAll_save$iconUrl))) {
            okCode = rep(TRUE, length(rv$CodeAll))
        } else {
            if (length(unlist(markerListAll()$iconUrl)) !=
                length(unlist(rv$markerListAll_save$iconUrl))) {
                okCode = rep(TRUE, length(rv$CodeAll))
            } else {
                okCode = unlist(markerListAll()$iconUrl) != unlist(rv$markerListAll_save$iconUrl)
            }
        }
        
        rv$theme_choice_save = theme()
        rv$markerListAll_save = markerListAll()
        
        markerList = markerListAll()
        markerList$iconUrl = markerListAll()$iconUrl[okCode]
        
        codeShapeList =
            as.numeric(str_extract(unlist(markerList$iconUrl),
                                   "[:digit:]+"))        

        LonAll = rv$meta$lon_deg
        LatAll = rv$meta$lat_deg
        NomAll = rv$meta$name
        SupAll = rv$meta$surface_km2
        AltAll = rv$meta$elevation_m
        trendColorAll = rv$fillList
        trendColorAll = sapply(trendColorAll, switch_color,
                               color_to_switch=color_to_switch)
        
        markerList$iconUrl = markerList$iconUrl
        Code = rv$CodeAll[okCode]
        Lon = LonAll[okCode]
        Lat = LatAll[okCode]
        Nom = NomAll[okCode]
        Sup = SupAll[okCode]
        Alt = AltAll[okCode]
        trendColor = trendColorAll[match(Code, rv$CodeAll)]

        map = removeMarker(map, layerId=Code)

        ok21 = codeShapeList == 21
        okN21 = !ok21

        iconAnchorX = list(iconAnchorX=markerList$iconAnchorX)
        iconAnchorY = list(iconAnchorY=markerList$iconAnchorY)

        if (any(okN21)) {
            iconUrlN21 = unlist(markerList$iconUrl,
                                use.names=FALSE)[okN21]
            iconUrlN21 = as.list(iconUrlN21)
            names(iconUrlN21) = rep("iconUrl", times=length(iconUrlN21))
            iconUrlN21 = list(iconUrl=iconUrlN21)
            markerListN21 = append(iconUrlN21, iconAnchorX)
            markerListN21 = append(markerListN21, iconAnchorY)
            
            map = addMarkers(map,
                             group="NS",
                             lng=Lon[okN21],
                             lat=Lat[okN21],
                             icon=markerListN21,
                             layerId=Code[okN21],
                             options=markerOptions(zIndexOffset=2000))
        }
        
        if (any(ok21)) {
            iconUrl21 = unlist(markerList$iconUrl, use.names=FALSE)[ok21]
            iconUrl21 = as.list(iconUrl21)
            names(iconUrl21) = rep("iconUrl", times=length(iconUrl21))
            iconUrl21 = list(iconUrl=iconUrl21)
            markerList21 = append(iconUrl21, iconAnchorX)
            markerList21 = append(markerList21, iconAnchorY)
            
            map = addMarkers(map,
                             group="S",
                             lng=Lon[ok21],
                             lat=Lat[ok21],
                             icon=markerList21,
                             layerId=Code[ok21],
                             options=markerOptions(zIndexOffset=1000))
        }

        if (!is.null(rv$dataEX) & !is.null(rv$trendEX)) {
            if (verbose) print("get_trendLabel")
            trendLabelAll = sapply(rv$CodeAll, get_trendLabel,
                                   rv=rv, lg=lg)
        } else {
            trendLabelAll = NA
        }

        trendLabelAll[is.na(trendLabelAll)] = ""

        if (length(rv$trendLabelAll) !=
            length(trendLabelAll)) {
            okCode = rep(TRUE, length(rv$CodeAll))
        } else {
            okCode = rv$trendLabelAll != trendLabelAll
        }
        
        Code = rv$CodeAll[okCode]
        Lon = LonAll[okCode]
        Lat = LatAll[okCode]
        Nom = NomAll[okCode]
        Sup = SupAll[okCode]
        Alt = AltAll[okCode]
        trendColor = trendColorAll[match(Code, rv$CodeAll)]
        trendLabel = trendLabelAll[okCode]
        
        Br = rep("<br>", times=length(Code))
        Br[trendLabel == ""] = ""
        
        rv$trendLabelAll = trendLabelAll

        markerListVoid = get_markerList(rep("void", length(Code)),
                                        resources_path=resources_path)
        n = 4
        label = paste0(
            '<b style="color:#00a3a6">', Code," </b>", ' - ',
            '<span style="color:#00a3a6">', Nom," </span>",
            '<br>',
            '<span style="color:',  trendColor,'">', trendLabel, "</span>",
            Br,

            '<table>',
            "<tr>",
            "<td>",
            '<b style="color:',  grey20COL,'">',
            word('m.hov.lat', lg), " : ", format(signif(Lat, n), nsmall=n), "</b>",
            "&emsp;", "</td>",
            "<td>",
            '<b style="color:',  grey20COL,'">',
            word('m.hov.sup', lg), " : ", round(Sup),
            " km<sup>2</sup></b>",
            "</td>",
            "</tr>",

            "<tr>",
            "<td>",
            '<b style="color:',  grey20COL,'">',
            word('m.hov.lon', lg), " : ", format(signif(Lon, n), nsmall=n), "</b>",
            "&emsp;", "</td>",
            "<td>",
            '<b style="color:',  grey20COL,'">',
            word('m.hov.alt', lg), " : ", round(Alt), " m</b>",
            "</td>",
            "</tr>",
            "</table>"
        )

        map = removeMarker(map, layerId=paste0("_", Code))
        map = addMarkers(map,
                         group="label",
                         lng=Lon,
                         lat=Lat,
                         icon=markerListVoid,
                         label=lapply(label, HTML),
                         layerId=paste0("_", Code),
                         options=markerOptions(zIndexOffset=3000))
    })
    

## 4. ANALYSE ________________________________________________________
### 4.0. Button ______________________________________________________
    observeEvent(input$ana_button, {
        toggleOnly(id="ana_panel")
        deselect_mode(session, rv)
    })

### 4.1. Dataset _____________________________________________________
    data_name = reactive({
        if (verbose) print("data_name")
        if (is.null(input$data_choice)) {
            hide(id="type_row")
            default_data
            
        } else {
            if (input$data_choice == "RRExplore2") {
                showElement(id="type_row")
            } else {
                hide(id="type_row")
            }
            input$data_choice
        }
    })

### 4.2. Metadata ____________________________________________________
    meta = reactive({
        if (verbose) print("meta") 
        metatmp =
            read_tibble(path=file.path(computer_data_path,
                                          'fst',
                                       paste0('meta_',
                                              data_name(),
                                              '.fst')))
        
        if (dev) {
            if (!is.null(nStation_dev)) {
                metatmp = metatmp[1:nStation_dev,]
            }
        }
        # crs_rgf93 = sf::st_crs(2154)
        # crs_wgs84 = sf::st_crs(4326)
        # sf_loca = sf::st_as_sf(metatmp[c("XL93_m", "YL93_m")],
        #                        coords=c("XL93_m", "YL93_m"))
        # sf::st_crs(sf_loca) = crs_rgf93
        # sf_loca = sf::st_transform(sf_loca, crs_wgs84)
        # sf_loca = sf::st_coordinates(sf_loca$geometry)
        # metatmp$lon = sf_loca[, 1]
        # metatmp$lat = sf_loca[, 2]
        metatmp = metatmp[order(metatmp$code),]

        if (is.null(rv$meta)) {
            rv$meta = metatmp
        }        
        metatmp
    })

### 4.3. Station selection ___________________________________________
#### 4.3.0. sample ___________________________________________________
    CodeAll = reactive({
        if (verbose) print("CodeAll")
        CodeAll = levels(factor(meta()$code))
        if (is.null(rv$CodeAll)) {
            rv$CodeAll = CodeAll
        }
        CodeAll
    })

    rv$CodeSample = isolate(CodeAll())
    rv$CodeSample_save = isolate(CodeAll())
    rv$theme_choice_save = isolate(theme())

    CodeSampleCheck = reactive({
        if (verbose) print("CodeSampleCheck")
        if (!rv$warningMode) {
            rv$CodeSample[!(rv$CodeSample %in% badCode())]
        } else {
            rv$CodeSample
        }
    })

    CodeSample = reactive({
        if (verbose) print("CodeSample")
        if (identical(CodeSampleCheck(), character(0))) {
            NULL
        } else {
            CodeSampleCheck()
        }
    })

#### 4.3.1. all/none _________________________________________________
    observeEvent(input$all_button, {
        rv$CodeSample = rv$CodeAll
    })

    observeEvent(input$none_button, {
        updateSelectizeInput(session, 'search_input',
                             selected="")
        rv$CodeSample = NULL
    })

#### 4.3.2. click on map _____________________________________________
    codeClick = reactive({
        if (is.null(input$map_marker_click)) {
            NULL
        } else {
            gsub("_", "", input$map_marker_click$id)
        }
    })

    observe({
        if (!is.null(input$click_select)) {
            hide(id='ana_panel')
            hide(id='theme_panel')
            hide(id='info_panel')
            hide(id='photo_bar')
            hide(id='download_sheet_bar')
            hide(id='poly_bar')
            hide(id='dlClick_bar')
            showElement(id='click_bar')
            rv$clickMode = TRUE
        } else {
            if (rv$clickMode) {
                deselect_mode(session, rv)
                hide(id='click_bar')
                showElement(id='ana_panel')
            }
        }
    })

    observeEvent(codeClick(), {
        if (rv$polyMode == 'false' & rv$clickMode & !rv$dlClickMode & !rv$photoMode) {
            CodeSample = rv$CodeSample
            if (codeClick() %in% CodeSample) {
                newCodeSample = CodeSample[CodeSample != codeClick()]
            } else {
                newCodeSample = c(CodeSample, codeClick())
            }
            rv$CodeSample = newCodeSample
        }
    })

    observeEvent(input$clickOk_button, {
        deselect_mode(session, rv)                
        hide(id='click_bar')
        hide(id='theme_panel')
        showElement(id='ana_panel')
    })

#### 4.3.3. polygone on map __________________________________________
    observe({
        if (!is.null(input$poly_select)) {
            if (rv$polyMode != 'Add' & rv$polyMode != 'Rm') {
                hide(id='ana_panel')
                hide(id='theme_panel')
                hide(id='info_panel')
                hide(id='photo_bar')
                hide(id='download_sheet_bar')
                hide(id='click_bar')
                hide(id='dlClick_bar')
                showElement(id='poly_bar')
                rv$polyMode = input$poly_choice
                rv$polyCoord = tibble()
            }
        } else {
            if (rv$polyMode == 'Add' | rv$polyMode == 'Rm') {
                deselect_mode(session, rv)
                hide(id='poly_bar')
                showElement(id='ana_panel')
            }
        }
    })

    observeEvent(input$poly_choice, {
        if (!is.null(input$poly_choice) & !is.null(rv$polyCoord)) {
            if (input$poly_choice == 'Add') {
                rv$polyMode = "Add"
                if (nrow(rv$polyCoord) != 0) {
                    map = leafletProxy("map")
                    map = clearShapes(map)
                    color = "#6d9192"
                    map = addPolygons(map,
                                      color=color,
                                      lng=rv$polyCoord$lng,
                                      lat=rv$polyCoord$lat)
                }
            } else if (input$poly_choice == 'Rm') {
                rv$polyMode = "Rm"
                if (nrow(rv$polyCoord) != 0) {
                    map = leafletProxy("map")
                    map = clearShapes(map)
                    color = "#b35457"
                    map = addPolygons(map,
                                      color=color,
                                      lng=rv$polyCoord$lng,
                                      lat=rv$polyCoord$lat)
                }
            }
        }
    })
    
    observeEvent(input$map_click, {
        if (rv$polyMode != 'false' & !rv$clickMode & !rv$dlClickMode & !rv$photoMode) {
            rv$polyCoord = bind_rows(rv$polyCoord,
                                     tibble(lng=input$map_click$lng,
                                            lat=input$map_click$lat))
            map = leafletProxy("map")
            map = clearShapes(map)
            if (rv$polyMode == "Add") {
                color = "#6d9192"
            } else if (rv$polyMode == "Rm") {
                color = "#b35457"
            }
            map = addPolygons(map,
                              color=color,
                              lng=rv$polyCoord$lng,
                              lat=rv$polyCoord$lat)
        }
    })
    
    observeEvent(input$polyOk_button, {
        if (nrow(rv$polyCoord) != 0) {
            
            station_coordinates = sp::SpatialPointsDataFrame(
                                          rv$meta[c('lon_deg',
                                                    'lat_deg')],
                                          rv$meta['code'])
            
            # Transform them to an sp Polygon
            drawn_polygon = sp::Polygon(as.matrix(rv$polyCoord))
            
            # Use over from the sp package to identify selected station
            selected_station = sp::over(station_coordinates, sp::SpatialPolygons(list(sp::Polygons(list(drawn_polygon), "drawn_polygon"))))

            selectCode = rv$meta$code[!is.na(selected_station)]

            if (rv$polyMode == "Add") {
                rv$CodeSample = c(rv$CodeSample, selectCode)
                rv$CodeSample = rv$CodeSample[!duplicated(rv$CodeSample)]
            } else if (rv$polyMode == "Rm") {
                rv$CodeSample = rv$CodeSample[!(rv$CodeSample %in% selectCode)]
            }

            map = leafletProxy("map")
            map = clearShapes(map)
        }
        deselect_mode(session, rv)
    })

    
### 4.4. Warning _____________________________________________________
    observe({        
        if (!is.null(input$warning_select)) {
            rv$warningMode = TRUE
        } else {
            rv$warningMode = FALSE
        }
    })

### 4.5. Search ______________________________________________________
    meta_location = reactive({
        gsub("((L'|La |Le )(.*?)aux )|((L'|La |Le )(.*?)au )|((L'|La |Le )(.*?)à )", "", rv$meta$name)
    })

    meta_river = reactive({
        gsub("(L'|La |Le )| à(.*)| au(.*)| aux(.*)", "", rv$meta$name)
    })

    meta_basin = reactive({
        df_basinName = tibble(letter=
                                  c('D', 'E',
                                    'A', 'B',
                                    'F', 'G', 'H', 'I',
                                    'J', 'K', 'L', 'M', 'N',
                                    'O', 'P', 'Q', 'R', 'S',
                                    'U', 'V', 'W', 'X', 'Y',
                                    'Z'),
                              basin=
                                  c(rep('Artois-Picardie', 2),
                                    rep('Rhin-Meuse', 2),
                                    rep('Seine-Normandie', 4),
                                    rep('Loire-Bretagne', 5),
                                    rep('Adour-Garonne', 5),
                                    rep('Rhône-Méditérannée & Corse', 5),
                                    rep('Îles', 1)
                                    ))
        fL = substr(rv$meta$code, 1, 1)
        df_basinName$basin[match(fL, df_basinName$letter)]
    })
    
    searchChoices = reactive({
        Values = c(
            paste0("code:", rv$meta$code),
            paste0("name:", rv$meta$name),
            paste0("region:", rv$meta$hydrological_region),
            # paste0("regime:", rv$meta$regime_hydro),
            paste0("location:", meta_location()),
            paste0("river:", meta_river()),
            paste0("basin:", meta_basin())
        )
        htmlValues = c(
            paste0(rv$meta$code,
                   '<i style="font-size: 9pt; color: ',
                   grey85COL, '">&emsp;', word("ana.search.code", lg),
                   '</i>'),
            paste0(rv$meta$name,
                   '<i style="font-size: 9pt; color: ',
                   grey85COL, '">&emsp;', word("ana.search.name", lg),
                   '</i>'),
            paste0(rv$meta$hydrological_region,
                   '<i style="font-size: 9pt; color: ',
                   grey85COL, '">&emsp;', word("ana.search.region", lg),
                   '</i>'),
            # paste0(rv$meta$regime_hydro,
            # '<i style="font-size: 9pt; color: ',
            # grey85COL, '">&emsp;', word("ana.search.regime", lg),
            # '</i>'),
            paste0(meta_location(),
                   '<i style="font-size: 9pt; color: ',
                   grey85COL, '">&emsp;', word("ana.search.location", lg),
                   '</i>'),
            paste0(meta_river(),
                   '<i style="font-size: 9pt; color: ',
                   grey85COL, '">&emsp;', word("ana.search.river", lg),
                   '</i>'),
            paste0(meta_basin(),
                   '<i style="font-size: 9pt; color: ',
                   grey85COL, '">&emsp;', word("ana.search.basin", lg),
                   '</i>')
        )
        
        tibble(value=Values, label=htmlValues, 
               html=htmlValues, stringsAsFactors=FALSE)
    })

    observe({
        updateSelectizeInput(session, 'search_input',
                             choices=searchChoices(),
                             server=TRUE,
                             options=list(
                                 create=FALSE,
                                 placeholder=word("ana.search", lg),
                                 render=I('{
                 item: function(item, escape) {
                    return "<div>" + item.html + "</div>";
                 },
                  option: function(item, escape) {
                    return "<div>" + item.html + "</div>";
                 }
                                 }'),
                 onDropdownOpen=
                     I('function($dropdown) {if (!this.lastQuery.length) {this.close(); this.settings.openOnFocus = false;}}'),
                 onType=
                     I('function (str) {if (str === \"\") {this.close();}}'),
                 onItemAdd=
                     I('function() {this.close();}')))
    })
    
    observeEvent(input$search_input, {
        htmlSearch = input$search_input
        Search = gsub("(.*?):", "", htmlSearch)
        searchType = gsub(":(.*)", "", htmlSearch)

        Code = rv$meta$code[rv$meta$code %in% Search[searchType == "code"]]
        CodeNom = rv$meta$code[rv$meta$name %in% Search[searchType == "name"]]
        CodeRegion = rv$meta$code[rv$meta$hydrological_region %in% Search[searchType == "region"]]
        # CodeRegime = rv$meta$code[rv$meta$regime_hydro %in% Search[searchType == "regime"]]
        CodeLocation = rv$meta$code[meta_location() %in% Search[searchType == "location"]]
        CodeRiver = rv$meta$code[meta_river() %in% Search[searchType == "river"]]
        CodeBasin = rv$meta$code[meta_basin() %in% Search[searchType == "basin"]]

        selectCode = levels(factor(c(Code,
                                     CodeNom,
                                     CodeRegion,
                                     # CodeRegime,
                                     CodeLocation,
                                     CodeRiver,
                                     CodeBasin)))

        if (all(rv$CodeAll %in% rv$CodeSample)) {
            rv$CodeSample = selectCode
        } else {
            codeRm = rv$CodeSearch[!(rv$CodeSearch %in% selectCode)]        
            rv$CodeSample = rv$CodeSample[!(rv$CodeSample %in% codeRm)]
            rv$CodeSample = c(rv$CodeSample, selectCode)
            rv$CodeSample = rv$CodeSample[!duplicated(rv$CodeSample)] 
        }
        rv$CodeSearch = selectCode
    })
    
    observe({
        if (verbose) print("search")
        if (is.null(input$search_input) & !is.null(rv$Search_save)) {
            rv$CodeSample = rv$CodeSample_save
        }
        if (is.null(input$search_input) & is.null(rv$Search_save)) {
            rv$CodeSample_save = rv$CodeSample
        }
        rv$Search_save = input$search_input
    })


### 4.5. Variable ____________________________________________________
#### 4.5.0. all variables ____________________________________________
    Variable_ALL = reactive({
        get_Variable(CARD_path, check_varSub, lg=lg)
    })

#### 4.5.1. type _____________________________________________________
    type = reactive({
        if (verbose) print("type")
        if (data_name() == "RRSE") {
            word("ana.type.Q", lg)
        } else {
            input$type_choice   
        }
    })

#### 4.5.2. variables selection ______________________________________
    Variable = reactive({
        if (verbose) print("Variable")
        Variable_tmp = Variable_ALL()[Variable_ALL()$type == type(),]
        if (type() == word("ana.type.T", lg)) {
            selected = unique(Variable_tmp$event)[1]
        } else if (type() == word("ana.type.Q", lg)) {
            selected = unique(Variable_tmp$event)[2]
        } else if (type() == word("ana.type.P", lg)) {
            selected = unique(Variable_tmp$event)[2]
        }
        updateRadioButton(session,
                          class="radioButton",
                          inputId="event_choice",
                          choices=unique(Variable_tmp$event),
                          selected=selected,
                          choiceTooltips=
                              paste(word("tt.ana.regime", lg),
                                    tolower(unique(Variable_tmp$event))))
        Variable_tmp
    })

#### 4.5.3. event ____________________________________________________
    observeEvent(input$event_choice, {
        if (verbose) print("observeEvent.variable_choice")
        if (is.null(Variable())) {
            Variable = Variable_ALL()
        } else {
            Variable = Variable()
        }

        if (input$event_choice == "FALSE") {
            if (type() == word("ana.type.T", lg)) {
                event = unique(Variable$event)[1]
            } else if (type() == word("ana.type.Q", lg)) {
                event = unique(Variable$event)[2]
            } else if (type() == word("ana.type.P", lg)) {
                event = unique(Variable$event)[2]
            }
        } else {
            event = input$event_choice
        }
        
        variable_event = Variable$variable[Variable$event == event]
        variableHTML_event = Variable$variableHTML[Variable$event ==
                                                   event]
        name_event = Variable$name[Variable$event == event]
        name_event = sapply(name_event, '[[', 1)

        updateRadioButton(session,
                          class="radioButton",
                          inputId="variable_choice",
                          choiceValues=variable_event,
                          choiceNames=variableHTML_event,
                          choiceTooltips=name_event,
                          selected=variable_event[1])
    })

    event = reactive({
        if (verbose) print("event")
        if (is.null(input$event_choice)) {
            default_event
        } else {
            event = input$event_choice
        }
    })

#### 4.5.4. variable _________________________________________________
    variable = reactive({
        if (verbose) print("variable")
        if (is.null(input$variable_choice)) {
            default_variable
        } else {
            input$variable_choice
        }
    })

#### 4.5.5. alpha risk level _________________________________________
    alpha = reactive({
        if (verbose) print("alpha")
        if (is.null(input$alpha_choice)) {
            default_alpha
        } else {
            input$alpha_choice
        }
    })

#### 4.5.6. proba / month / season ___________________________________ 
    proba_choices = reactive({
        if (verbose) print("proba_choices")
        id = which(Variable()$variable == variable() &
                             Variable()$event == event())
        if (!identical(id, integer(0))) {
            Variable()$sub[[id]]
        } else {
            NULL
        }
    })

    proba = reactive({
        if (!is.null(proba_choices())) {
            input$proba_choice
        } else {
            NULL
        }
    })

#### 4.5.7. preferred ________________________________________________
    preferred_sampling_period = reactive({
        if (verbose) print("preferred_sampling_period")
        id = which(Variable()$variable == variable() &
                             Variable()$event == event())
        if (!identical(id, integer(0)) & !identical(id, NA)) {        
            Variable()$preferred_sampling_period[id]
        } else {
            NA
        }
    })

#### 4.5.8. palette __________________________________________________
    Palette = reactive({
        if (verbose) print("palette")
        id = which(Variable()$variable == variable() &
                             Variable()$event == event())
        if (!identical(id, integer(0))) {
            unlist(Variable()$palette[id])
        } else {
            unlist(Variable_ALL()$palette[Variable_ALL()$variable == default_variable])
        }
    })

#### 4.5.9. html output ______________________________________________
    output$regimeRow = renderText({
        if (verbose) print("regimeRow")
        if (type() == word("ana.type.T", lg)) {
            word("ana.temperature", lg)
        } else if (type() == word("ana.type.Q", lg)) {
            word("ana.regime", lg)
        } else if (type() == word("ana.type.P", lg)) {
            word("ana.pluviometrie", lg)
        }
    })
    
    output$variableHTML = renderUI({
        if (verbose) print("variableHTML")
        if (is.null(rv$proba)) {
            HTML(paste0(
                "<b>",
                Variable_ALL()$variableHTML[Variable_ALL()$variable == rv$variable],
                "</b>"
            ))
        } else {
            variable = Variable_ALL()$variableHTML[Variable_ALL()$variable == rv$variable &
                                                                 Variable_ALL()$event == rv$event]
            if (grepl(SeasonMonth_pattern, variable)) {
                variable = gsub(SeasonMonth_pattern, rv$proba, variable)
            } else {
                variable = gsub("p", gsub("[%]", "", rv$proba), variable)
            }
            HTML(paste0("<b>", variable, "</b>"))
        }
    })

    output$nameHTML = renderUI({
        if (verbose) print("nameHTML")
        name = unlist(Variable_ALL()$name[Variable_ALL()$variable == rv$variable])
        if (length(name) > 1) {
            sub = unlist(Variable_ALL()$sub[Variable_ALL()$variable == rv$variable])
            name = name[sub == rv$proba]
        }
        nbNewline = 0
        nbLim = 24
        nbChar = nchar(name)
        while (nbChar > nbLim) {
            nbNewline = nbNewline + 1
            posSpace = which(strsplit(name, "")[[1]] == " ")
            idNewline = which.min(abs(posSpace - nbLim * nbNewline))
            posNewline = posSpace[idNewline]
            name = paste(substring(name,
                                   c(1, posNewline + 1),
                                   c(posNewline,
                                     nchar(name))),
                         collapse="<br>")
            Newline = substr(name,
                             posNewline + 2,
                             nchar(name))
            nbChar = nchar(Newline)
        }
        HTML(name)
    })

    output$dataHTML_ana = renderUI({
        if (verbose) print("dataHTML_ana")
        id = which(Variable()$variable == variable() &
                             Variable()$event == event())
        
        if (identical(id, integer(0))) {
            rv$dataHTML_ana
        } else {
            
            if (is.null(proba())) {
                data = paste0(Variable()$variableHTML[id], ' : ',
                              Variable()$name[[id]])
            } else {
                name = unlist(Variable()$name[id])
                sub = unlist(Variable()$sub[id])
                name = name[sub == proba()]
                variable = Variable()$variableHTML[id]
                
                if (grepl(SeasonMonth_pattern, variable)) {
                    variable = gsub(SeasonMonth_pattern, proba(), variable)
                } else {
                    variable = gsub("p", gsub("[%]", "", proba()), variable)
                }
                data = paste0(variable, ' : ', name)
            }
            rv$dataHTML_ana = data
            HTML(data)
        }
    })

    output$probaRow = renderText({
        if (verbose) print("probaRow")
        if (grepl(word("var.month", lg), variable())) {
            word("ana.month", lg)
        } else if (grepl(word("var.season", lg), variable())) {
            word("ana.season", lg)
        } else {
            word("ana.proba", lg)
        }
    })

    output$significativite = renderText({
        paste0(word("out.sig", lg), " ",
               as.numeric(alpha())*100, '%')
    })
    
#### 4.5.10. update proba row ________________________________________
    observe({
        if (verbose) print("observe.proba_choice")
        if (!is.null(proba_choices())) {
            showElement(id="proba_row")
            choices = proba_choices()
        } else {
            hide(id="proba_row")
            choices = FALSE
        }

        if (grepl("month", variable())) {
            tt = word("tt.ana.month", lg)
        } else if (grepl("season", variable())) {
            tt = word("tt.ana.season", lg)
        } else {
            tt = word("tt.ana.proba", lg)
        }
        
        updateRadioButton(session,
                          class="radioButton",
                          inputId="proba_choice",
                          choices=choices,
                          choiceTooltips=
                              paste0(tt, " ", choices))
    })


### 4.6. Sampling periode ____________________________________________
#### 4.6.0. show / hide ______________________________________________
    observe({
        if (!is.null(input$optimalSlider_select)) {
            rv$optimalMode = TRUE
            hide(id="sampleSlider")
        } else {
            rv$optimalMode = FALSE
            showElement(id="sampleSlider")
        }
    })
    
    observe({
        if (!is.null(input$sampleSlider_select)) {
            rv$sampleSliderMode = TRUE
            showElement(id="invertSlider")
        } else {
            rv$sampleSliderMode = FALSE
            hide(id="invertSlider")
        }
    })

    observe({
        if (!is.null(input$invertSlider_select)) {
            rv$invertSliderMode = TRUE
        } else {
            rv$invertSliderMode = FALSE
        }
    })

#### 4.6.1. update render ui _________________________________________
    observeEvent({
        rv$sampleSliderMode
        rv$invertSliderMode
        rv$optimalMode
        preferred_sampling_period()
    }, {
        if (verbose) print("sampling_period_slider")
        if (!is.na(preferred_sampling_period())) {
            hydroMonths = as.numeric(gsub("[-].*", "", preferred_sampling_period()))
        } else {
            hydroMonths = match(input$sampling_period_slider, Months)
        }

        if (rv$optimalMode | grepl(SeasonMonth_pattern, variable())) {
            class = "size1Slider noneSlider"
            selected = Months[hydroMonths[1]]

        } else if (rv$sampleSliderMode) {
            if (rv$invertSliderMode) {
                class = "size1Slider invertSlider"
                if (length(hydroMonths) == 1) {
                    selected = Months[c(1, hydroMonths)]
                } else {
                    selected = Months[hydroMonths]
                }
                
            } else {
                class = "size1Slider"
                if (length(input$sampling_period_slider) == 1) {
                    selected = Months[c(hydroMonths, 12)]
                } else {
                    selected = Months[hydroMonths]
                }
            }           
        } else {
            class = "size1Slider soloSlider"
            selected = Months[hydroMonths[1]]            
        }
        
        output$sampling_period_slider = renderUI({
            Slider(class=class,
                   inputId="sampling_period_slider",
                   modeText=TRUE,
                   label=NULL,
                   grid=TRUE,
                   force_edges=FALSE,
                   choices=Months,
                   selected=selected)
        })
    })

#### 4.6.2. get ______________________________________________________
    sampling_periodB = reactive({
        if (verbose) print("sampling_period")
        if (!is.null(input$sampling_period_slider)) {
            if (rv$sampleSliderMode & length(input$sampling_period_slider) == 2) {
                if (rv$invertSliderMode) {
                    nameMonthStart = input$sampling_period_slider[2]
                    idMonthStart = which(Months == nameMonthStart)
                    monthStart = formatC(idMonthStart, width=2, flag=0)

                    nameMonthEnd = input$sampling_period_slider[1]
                    idMonthEnd = which(Months == nameMonthEnd)
                    monthEnd = formatC(idMonthEnd, width=2, flag=0)            
                    dateEnd = as.Date(paste0("1972-", monthEnd, "-01"))
                    
                    sampling_periodStart = paste0(monthStart, "-01")
                    sampling_periodEnd = substr(dateEnd - 1, 6, 10)
                    
                } else {
                    nameMonthStart = input$sampling_period_slider[1]
                    idMonthStart = which(Months == nameMonthStart)
                    monthStart = formatC(idMonthStart, width=2, flag=0)

                    nameMonthEnd = input$sampling_period_slider[2]
                    idMonthEnd = which(Months == nameMonthEnd)
                    monthEnd = formatC(idMonthEnd, width=2, flag=0)
                    dateEnd = as.Date(paste0("1972-", monthEnd, "-01"))

                    sampling_periodStart = paste0(monthStart, "-01")
                    sampling_periodEnd = substr(dateEnd + months(1) - 1, 6, 10)
                }
                c(sampling_periodStart, sampling_periodEnd)

            } else if (rv$optimalMode) {
                rv$sampling_period
            } else {
                nameMonthStart = input$sampling_period_slider[1]
                idMonthStart = which(Months == nameMonthStart)
                monthStart = formatC(idMonthStart, width=2, flag=0)
                sampling_periodStart = paste0(monthStart, "-01")
                sampling_periodStart
            }
        } else {
            default_sampling_period
        }
    })
    sampling_period = debounce(sampling_periodB, 100)

#### 4.6.3. html output ______________________________________________
    output$sampling_periodHTML = renderUI({
        if (rv$optimalMode_act) {
            HTML(word("out.optimal", lg))
        } else {
            hydroStart = format(rv$period[1], "%d %b")
            hydroEnd = format(rv$period[2], "%d %b")
            HTML(paste0(word("out.hp", lg), "<br>",
                        word("out.from", lg), " ",
                        hydroStart, " ",
                        word("out.to", lg), " ",
                        hydroEnd))
        }
    })


### 4.7. Analyse periode _____________________________________________
#### 4.7.0. render ui ________________________________________________
    output$dateYear_slider = renderUI({
        Slider(class="size2Slider",
               inputId="dateYear_slider",
               label=NULL,
               step=1,
               sep='',
               min=slider_minYear,
               max=slider_maxYear,
               value=c(slider_midYear, slider_maxYear))
    })

#### 4.7.1. get period _______________________________________________
    periodB = reactive({
        if (verbose) print("period")
        if (!is.null(input$dateYear_slider)) {
            startYear = input$dateYear_slider[1]
            endYear = input$dateYear_slider[2]
        } else {
            startYear = slider_midYear
            endYear = slider_maxYear
        }
        
        inter = endYear - startYear
        if (inter < 30) {
            if (startYear + 30 > slider_maxYear &
                endYear - 30 >= slider_minYear) {
                startYear = endYear - 30
            } else {
                endYear = startYear + 30
            }
            updateSlider(session=session,
                         class="size2Slider",
                         inputId="dateYear_slider",
                         value=c(startYear, endYear))
        }

        if (rv$sampleSliderMode & length(sampling_period()) == 2) {
            Start = as.Date(paste0(startYear,
                                   "-",
                                   sampling_period()[1]))
            End = as.Date(paste0(endYear,
                                 "-",
                                 sampling_period()[2]))
            periodB = c(Start, End)

        } else {
            Start = as.Date(paste0(startYear,
                                   "-",
                                   sampling_period()[1]))
            Endtmp = as.Date(paste0(endYear,
                                    "-",
                                    sampling_period()[1])) - 1
            End = as.Date(paste0(endYear,
                                 "-",
                                 substr(Endtmp, 6, 10)))
            periodB = c(Start, End)
        }
        periodB
    })
    period = debounce(periodB, 100)

#### 4.7.2. html output ______________________________________________
    output$period_ana = renderText({        
        start = format(periodB()[1], word("out.date_format", lg))
        end = format(periodB()[2], word("out.date_format", lg))
        paste0(word("out.From", lg), " ", start, " ",
               word("out.to", lg), " ", end)
    })

    output$period = renderText({
        start = format(rv$period[1], "%Y")
        end = format(rv$period[2], "%Y")
        paste0(word("out.period", lg), " ", start, ' - ', end)
    })


## 5. DATA ___________________________________________________________
### 5.1. All data ____________________________________________________
    dataAll = reactive({
        if (verbose) print("dataAll")
        test = file.path(computer_data_path,
                         'fst',
                         paste0('data_',
                                data_name(),
                                '.fst'))
        if (file.exists(test)) {
            dataAll =
                read_tibble(path=file.path(computer_data_path,
                                           'fst',
                                           paste0('data_',
                                                  data_name(),
                                                  '.fst')))
            if (dev) {
                if (!is.null(nStation_dev)) {
                    dataAll =
                        dplyr::filter(
                                   dataAll,
                                   code %in%
                                   levels(factor(dataAll$code))[1:nStation_dev])
                }
            }
            dataAll
            
        } else {
            NULL
        }
    })

### 5.2. Sub data ____________________________________________________
    data = reactive({
        if (verbose) print("data")
        if (!is.null(dataAll()) & !is.null(CodeSample())) {
            if (all(rv$CodeSample %in%
                    levels(factor(dataAll()$code)))) {
                data = dataAll()[dataAll()$code %in% CodeSample(),]
            } else {
                data = dataAll()
                rv$CodeSample = CodeAll()
                rv$CodeSample_save = CodeAll()
            }
            
            rv$idValue = c()
            for (id in 1:ncol(data)) {
                x = data[[id]]
                if (is.character(x)) {
                    rv$idCode = id
                } else if (lubridate::is.Date(x)) {
                    rv$idDate = id
                } else if (is.numeric(x)) {
                    rv$idValue = c(rv$idValue, id)
                }
            }
            data
        } else {
            NULL
        }
    })

    
## 6. ACTUALISE ______________________________________________________
### 6.1. Test ________________________________________________________
    observeEvent({
        CodeSample()
        variable()
        period()
        proba()
        sampling_period()
        rv$photoMode
        rv$optimalMode
        data_name()
        # rv$helpPage
    }, {
        if (verbose) print("observeEvent.check_actualise")
        if (!is.null(CodeSample()) & !is.null(rv$CodeSample_act)) {
            if (!all(CodeSample() %in% rv$CodeSample_act) &
                identical(data_name(), rv$data_name)) {
                rv$CodeAdd = CodeSample()[!(CodeSample() %in%
                                            rv$CodeSample_act)]
                rv$actualiseForce = !rv$actualiseForce
            }
        }

        if (identical(variable(), rv$variable) &
            all(identical(period(), rv$period)) &
            identical(proba(), rv$proba) &
            all(identical(sampling_period(), rv$sampling_period)) &
            # is.null(rv$helpPage) &
            identical(rv$optimalMode, rv$optimalMode_act) &
            identical(data_name(), rv$data_name)) {
            hide(id="actualise_panelButton")
            rv$need_actualise = FALSE
        } else {
            # if ((rv$variable != FALSE | !is.null(rv$period) | !is.null(rv$proba) | !is.null(rv$sampling_period)) & !rv$photoMode) {
            #     showElement(id="actualise_panelButton")
            # }
            if ((!is.null(rv$variable) | !is.null(rv$period) | !is.null(rv$proba) | !is.null(rv$sampling_period)) & !rv$photoMode) {
                showElement(id="actualise_panelButton")
                rv$need_actualise = TRUE
            }
        }
    })

### 6.2. Do __________________________________________________________
#### 6.2.0. check ____________________________________________________
    observeEvent({
        input$actualise_button
        rv$actualiseForce
        rv$start
    }, {
        if (verbose) print("observeEvent.press_actualise")
        if (!is.null(data()) & !is.null(meta()) & variable() != FALSE & !is.null(period())) {
            rv$actualise = TRUE
            showElement(id="loading_panel")
        }
    })
    
    observeEvent(rv$actualise, {
        if (verbose) print("actualise")
        if (rv$actualise & rv$start) {


#### 6.2.1. actualise reactive value _________________________________
            if (!is.null(rv$codePlot)) {
                map = leafletProxy("map")
                map = fitBounds(map,
                                lng1=defaultLimits()$east,
                                lat1=defaultLimits()$south,
                                lng2=defaultLimits()$west,
                                lat2=defaultLimits()$north,
                                options=list(padding=c(20, 20)))
                
                rv$codePlot = NULL
                hide(id='plot_panel')
            }
            
            if (rv$data_name != data_name()) {
                map = leafletProxy("map")
                map = clearMarkers(map)

                map = fitBounds(map,
                                lng1=defaultLimits()$east,
                                lat1=defaultLimits()$south,
                                lng2=defaultLimits()$west,
                                lat2=defaultLimits()$north,
                                options=list(padding=c(20, 20)))
                
                rv$codePlot = NULL
                hide(id='plot_panel')
            }
            
            rv$data_name = data_name()
            rv$dataAll = dataAll()
            rv$CodeAll = CodeAll()
            rv$data = data()
            rv$meta = meta()
            
            rv$CodeSample_act = c(CodeSample(), rv$CodeAdd)
            rv$CodeSample_act = sort(rv$CodeSample_act)
            rv$optimalMode_act = rv$optimalMode
            rv$type = type()
            rv$variable = variable()
            rv$event = event()
            rv$period = period()
            rv$proba = proba()
            rv$sampling_period = sampling_period()
            rv$alpha = alpha()
            rv$Palette = Palette()


#### 6.2.2. get extraction parameters ________________________________
            if (!is.null(rv$CodeAdd)) {
                data = rv$data[rv$data$code %in% rv$CodeAdd,]
            } else {
                data = rv$data
            }
            
            hide(id="actualise_panelButton")

            if (!(rv$event %in% Variable()$event)) {
                Ok = Variable()$variable == rv$variable
            } else {
                Ok = Variable()$event == rv$event &
                              Variable()$variable == rv$variable
            }

            variable_CARD = Variable()$variable_CARD[Ok]

            if (grepl("(QpA)|(fQpA)", rv$variable)) {
                if (rv$proba != FALSE & !is.null(proba_choices())) {
                    CARD_name = paste0(gsub("p",
                                            gsub("%", "", rv$proba),
                                            variable_CARD))
                } else {
                    CARD_name = NULL
                }
            } else {
                CARD_name = variable_CARD
            }

            if (!is.null(CARD_name)) {
                if (rv$optimalMode_act) {
                    sampling_period_overwrite = NULL
                } else {
                    sampling_period_overwrite = rv$sampling_period
                }

                data = dplyr::relocate(data, code, .before=date)

#### 6.2.3. variable extraction ______________________________________
                if (verbose) print("CARD_extraction")
                res = CARD_extraction(
                    data,
                    CARD_path=CARD_path,
                    # CARD_dir=CARD_dir,
                    CARD_name=CARD_name,
                    period_default=rv$period,
                    cancel_lim=FALSE,
                    simplify=TRUE,
                    sampling_period_overwrite=sampling_period_overwrite,
                    verbose=verbose)
                
                metaEX = res$metaEX
                dataEX = res$dataEX

                if (!is.null(rv$proba)) {
                    if (grepl(SeasonMonth_pattern, rv$variable)) {
                        variable_tmp = gsub(SeasonMonth_pattern,
                                            rv$proba, rv$variable)
                        rv$variable_en =
                            metaEX$variable_en[metaEX[paste0("variable_",
                                                             lg)] == variable_tmp]
                        dataEX =
                            dplyr::select(dataEX,
                                          c("code",
                                            "date",
                                            tidyr::all_of(rv$variable_en)))
                        metaEX = metaEX[metaEX$variable_en == rv$variable_en,]
                        
                    } else {
                        rv$variable_en = metaEX$variable_en
                    }

                } else {
                    rv$variable_en = metaEX$variable_en
                }

                dataEX = dplyr::filter(dataEX,
                                       !all(is.na(get(rv$variable_en))),
                                       .by="code")

#### 6.2.4. process trend analyse ____________________________________
                if (verbose) print("process_trend")
                trendEX = process_trend(
                    dataEX,
                    metaEX=metaEX,
                    extreme_take_not_signif_into_account=TRUE,
                    MK_level=as.numeric(alpha()),
                    time_dependency_option="AR1",
                    period_trend=rv$period,
                    extreme_prob=extreme_prob,
                    show_advance_stat=TRUE,
                    verbose=verbose)

                if (verbose) print("trendEX")
                rv$unit = metaEX[paste0("unit_", lg)][1]
                rv$to_normalise = metaEX$to_normalise[1]
                trendEX = trendEX[!is.na(trendEX$a),]

                if (!is.null(rv$CodeAdd)) {
                    dataEX = bind_rows(rv$dataEX, dataEX)
                    dataEX = dataEX[order(dataEX$code),]
                    trendEX = bind_rows(rv$trendEX, trendEX)
                    trendEX = trendEX[order(trendEX$code),]
                    rv$CodeAdd = NULL
                }

                dataEX = dataEX[dataEX$code %in% CodeSample(),]
                trendEX = trendEX[trendEX$code %in% CodeSample(),]

                rv$idExValue = c()
                for (id in 1:ncol(data)) {
                    x = data[[id]]
                    if (is.character(x)) {
                        rv$idExCode = id
                    } else if (lubridate::is.Date(x)) {
                        rv$idExDate = id
                    } else if (is.numeric(x)) {
                        rv$idExValue = c(rv$idExValue, id)
                    }
                }

                if (verbose) print("end actualise")
                
                rv$dataEX = dataEX
                rv$metaEX = metaEX
                rv$trendEX = trendEX

            } else {
                rv$dataEX = NULL
                rv$metaEX = NULL
                rv$trendEX = NULL
            }
        }
        rv$actualise = FALSE
        hide(id="loading_panel")
    })

#### 6.2.5 html output ______________________________________________
    output$stat_totalHTML = renderUI({
        hydroStart = format(rv$period[1], "%d %b")
        hydroEnd = format(rv$period[2], "%d %b")
        nStation = nrow(rv$trendEX)
        nStation_up = nrow(dplyr::filter(rv$trendEX, H & a>0))
        nStation_down = nrow(dplyr::filter(rv$trendEX, H & a<0))
        
        HTML(paste0("<b>", nStation, "</b> ",
                    word("out.stat.tot", lg), "<br>",
                    "&#8710; <b>", nStation_up, "</b> ",
                    word("out.stat.up", lg), "<br>",
                    "&#8711; <b>", nStation_down, "</b> ",
                    word("out.stat.down", lg)
                    ))
    })
    
    
## 7. CODE CHECK _____________________________________________________
### 7.1. Miss code ___________________________________________________
    missCode = reactive({
        if (verbose) print("missCode")
        if (!is.null(rv$dataAll)) {
            Start = rv$period[1]
            End = rv$period[2]
            dataNoNA = rv$dataAll[!is.na(rv$dataAll$Q),]
            
            df_Start = summarise(group_by(dataNoNA, code),
                                 Start=min(date, na.rm=TRUE))
            StartData = df_Start$Start
            df_End = summarise(group_by(dataNoNA, code),
                               End=max(date, na.rm=TRUE))            
            EndData = df_End$End
            CodeData = df_Start$code

            CodeData[EndData <= Start | End <= StartData]
            
        } else {
            c()
        }
    })

### 7.2. Invalid code ________________________________________________
    invalidCode = reactive({
        if (verbose) print("invalidCode")
        if (!is.null(rv$dataAll) & !is.null(rv$period)) {
            Start = rv$period[1]
            End = rv$period[2]
            dataNoNA = rv$dataAll[!is.na(rv$dataAll$Q),]
            dataNoNA = dataNoNA[Start <= dataNoNA$date
                                & dataNoNA$date <= End,]
            
            df_Period = summarise(group_by(dataNoNA, code),
                                  Period=length(Q))
            PeriodData = df_Period$Period/365.25
            CodeData = df_Period$code

            CodeData[PeriodData < analyseMinYear]
            
        } else {
            c()
        }
    })

### 7.3. Bad code ____________________________________________________
    badCode = reactive({
        if (verbose) print("badCode")
        badCode = c(missCode(), invalidCode())
        badCode[!duplicated(badCode)]
    })


## 8. TREND PLOT _____________________________________________________
### 8.1. Code click __________________________________________________
    observeEvent(codeClick(), {
        if (verbose) print("codeClick")
        if (rv$polyMode == 'false' & !rv$clickMode & !rv$dlClickMode) {
            
            if (!is.null(codeClick()) & !is.null(rv$codePlot)) {
                if (codeClick() == rv$codePlot) {

                    map = leafletProxy("map")
                    map = fitBounds(map,
                                    lng1=defaultLimits()$east,
                                    lat1=defaultLimits()$south,
                                    lng2=defaultLimits()$west,
                                    lat2=defaultLimits()$north,
                                    options=list(padding=c(20, 20)))
                    
                    rv$codePlot = NULL
                    hide(id='plot_panel')
                    
                } else {
                    rv$codePlot = codeClick()
                }
            } else {
                rv$codePlot = codeClick()
            }
        }
    })

### 8.2. Zoom ________________________________________________________
    observeEvent(rv$codePlot, {
        if (verbose) print("fitBounds")
        Lon = rv$meta$lon_deg[rv$meta$code == rv$codePlot]
        Lat = rv$meta$lat_deg[rv$meta$code == rv$codePlot]
        names(Lon) = NULL
        names(Lat) = NULL
        
        map = leafletProxy("map")
        map = fitBounds(map,
                        lng1=Lon+1,
                        lat1=Lat+1,
                        lng2=Lon-1,
                        lat2=Lat-2,
                        options=list(padding=c(20, 20)))
    })

### 8.3. Plot ________________________________________________________
    observeEvent({
        rv$codePlot
        rv$period
        rv$variable
        rv$width
    }, {
        if (verbose) print("plot_trend")

        if (rv$polyMode == 'false' & !rv$clickMode & !rv$dlClickMode & !is.null(rv$codePlot)) {
            
            showOnly(id='plot_panel', c(IdList_panel, 'plot_panel'))
            
            name = rv$meta$name[rv$meta$code == rv$codePlot]

            data_code = rv$data[rv$data$code == rv$codePlot,]
            maxQ_win = max(data_code$Q, na.rm=TRUE)*1.1            
            dataEX_code = rv$dataEX[rv$dataEX$code == rv$codePlot,]
            trendEX_code = rv$trendEX[rv$trendEX$code == rv$codePlot,]
            color = rv$fillList[rv$CodeAll == rv$codePlot]
            switchColor = switch_color(color, color_to_switch)
            
            output$trend_plot = plotly::renderPlotly({
                
                shiny::validate(need(!is.null(rv$codePlot),
                                     message=FALSE))


                if (rv$data_name == "RRExplore2") {
                    maxP_win = max(data_code$P, na.rm=TRUE)*1.1 
                    fig0 = plotly::plot_ly()

                    x = data_code$date
                    event = Variable_ALL()$event[Variable_ALL()$variable == rv$variable]
                    y = data_code$P
                    varLabel = "P"
                    unitLabel = " [mm]"
                    
                    fig0 = plotly::add_trace(
                                       fig0,
                                       type="scatter",
                                       mode="lines",
                                       x=x,
                                       y=y,
                                       line=list(color=grey20COL, width=0.85),
                                       xhoverformat=
                                           word("out.date_format", lg),
                                       hovertemplate = paste0(
                                           word("plot.day", lg),
                                           " ", "%{x}<br>",
                                           "<b>", varLabel, "</b> %{y}",
                                           unitLabel,
                                           "<extra></extra>"),
                                       hoverlabel=list(bgcolor=color,
                                                       font=list(size=12,
                                                                 family="Helvetica"),
                                                       bordercolor="white"))


                    data_codeLIM = data_code
                    minDate = min(data_code$date)
                    maxDate = max(data_code$date)
                    
                    if (minDate > rv$period[1]) {
                        NAadd = seq.Date(rv$period[1],
                                         minDate-1,
                                         "day")
                        nNAadd = length(NAadd)
                        data_codeLIM =
                            bind_rows(tibble(date=NAadd,
                                             P=rep(NA, nNAadd),
                                             code=rep(rv$codePlot, nNAadd)),
                                      data_codeLIM)
                    }
                    
                    if (maxDate < rv$period[2]) {
                        NAadd = seq.Date(maxDate+1,
                                         rv$period[2],
                                         "day")
                        nNAadd = length(NAadd)
                        data_codeLIM =
                            bind_rows(data_codeLIM,
                                      tibble(date=NAadd,
                                             P=rep(NA, nNAadd),
                                             code=rep(rv$codePlot, nNAadd)))
                    }
                    
                    # Extract NA data
                    NAdate = data_codeLIM$date[is.na(data_codeLIM$P)]
                    # Get the difference between each point of date data
                    # without NA
                    dNAdate = diff(NAdate)
                    # If difference of day is not 1 then
                    # it is TRUE for the beginning of each missing data period 
                    NAdate_Down = NAdate[append(Inf, dNAdate) != 1]
                    # If difference of day is not 1 then
                    # it is TRUE for the ending of each missing data period 
                    NAdate_Up = NAdate[append(dNAdate, Inf) != 1]
                    
                    nMiss = length(NAdate_Up)
                    Ymin = rep(0, nMiss)
                    Ymax = rep(maxP_win, nMiss)

                    lenMiss = NAdate_Up - NAdate_Down + 1
                    
                    for (i in 1:nMiss) {
                        fig0 = plotly::add_trace(
                                           fig0,
                                           type="scatter",
                                           mode="lines",
                                           x=c(NAdate_Down[i], NAdate_Down[i],
                                               NAdate_Up[i], NAdate_Up[i],
                                               NAdate_Down[i]),
                                           y=c(Ymin[i], Ymax[i],
                                               Ymax[i], Ymin[i],
                                               Ymin[i]),
                                           fill="toself",
                                           opacity=0.4,
                                           fillcolor=lightCyanCOL,
                                           line=list(width=0),
                                           text=paste0(
                                               "<b>",
                                               lenMiss[i],
                                               "</b>", " ",
                                               word("plot.miss", lg)),
                                           hoverinfo="text",
                                           hoveron="fills",
                                           hoverlabel=
                                               list(bgcolor=lightCyanCOL,
                                                    font=list(color="white",
                                                              family="Helvetica",
                                                              size=12),
                                                    bordercolor="white"))
                    }
                    
                    # Gets the p value
                    pVal = trendEX_code$p

                    if (pVal <= alpha()) {
                        colorLine = color
                        colorLabel = color
                    } else {
                        colorLine = 'grey85'
                        colorLabel = 'grey85'
                    }

                    trendLabel = get_trendLabel(rv,
                                                Code=rv$codePlot,
                                                lg=lg,
                                                space=TRUE)

                    fig0 = plotly::add_annotations(
                                       fig0,
                                       x=0.01,
                                       y=1.06,
                                       xref="paper",
                                       yref="paper",
                                       text=trendLabel,
                                       showarrow=FALSE,
                                       xanchor='left',
                                       yanchor='bottom',
                                       font=list(color=switchColor,
                                                 family="Helvetica",
                                                 size=12))

                    fig0 = plotly::add_annotations(
                                       fig0,
                                       x=0.01,
                                       y=1.30,
                                       xref="paper",
                                       yref="paper",
                                       text=paste0("<b>",
                                                   rv$codePlot,
                                                   "</b> - ",
                                                   name),
                                       showarrow=FALSE,
                                       xanchor='left',
                                       yanchor='bottom',
                                       font=list(color=INRAECyanCOL,
                                                 family="Helvetica",
                                                 size=12))
                    
                    fig0 = plotly::layout(
                                       fig0,
                                       separators='. ',

                                       yaxis=list(
                                           range=c(0, maxP_win),
                                           title=list(
                                               text=paste0(
                                                   "<b>", varLabel, "</b>",
                                                   unitLabel),
                                               font=list(color=grey20COL,
                                                         family="Helvetica")),
                                           gridcolor=grey85COL,
                                           gridwidth=0.6,
                                           ticks="outside",
                                           tickcolor=grey75COL,
                                           tickfont=list(color=grey40COL,
                                                         family="Helvetica"),
                                           showline=TRUE,
                                           linewidth=2,
                                           linecolor=grey85COL,
                                           zerolinecolor=grey85COL,
                                           zerolinewidth=0.6,
                                           mirror=TRUE,
                                           fixedrange=TRUE),

                                       autosize=FALSE,
                                       plot_bgcolor=grey97COL,
                                       paper_bgcolor='transparent',
                                       showlegend=FALSE)

                    fig0 = plotly::config(
                                       fig0,
                                       locale=word("plotly.language", lg),
                                       displaylogo=FALSE,
                                       toImageButtonOptions =
                                           list(format="svg"),
                                       modeBarButtonsToRemove =
                                           list("lasso2d",
                                                "select2d",
                                                "drawline",
                                                "zoom2d",
                                                "drawrect",
                                                "autoScale2d",
                                                "hoverCompareCartesian",
                                                "hoverClosestCartesian")
                                   )
                }


                fig1 = plotly::plot_ly()

                x = data_code$date
                if (rv$event == "Basses Eaux") {
                    maxQ_win = sqrt(maxQ_win)
                    y = sqrt(data_code$Q)
                    varLabel = "&#8730;Q"
                    unitLabel = " [m<sup>3/2</sup>.s<sup>-1/2</sup>]"
                } else {
                    y = data_code$Q
                    varLabel = "Q"
                    unitLabel = " [m<sup>3</sup>.s<sup>-1</sup>]"
                }

                fig1 = plotly::add_trace(
                                   fig1,
                                   type="scatter",
                                   mode="lines",
                                   x=x,
                                   y=y,
                                   line=list(color=grey20COL, width=0.85),
                                   xhoverformat=
                                       word("out.date_format", lg),
                                   hovertemplate = paste0(
                                       word("plot.day", lg),
                                       " ", "%{x}<br>",
                                       "<b>", varLabel, "</b> %{y}",
                                       unitLabel,
                                       "<extra></extra>"),
                                   hoverlabel=list(bgcolor=color,
                                                   font=list(size=12,
                                                             family="Helvetica"),
                                                   bordercolor="white"))


                data_codeLIM = data_code
                minDate = min(data_code$date)
                maxDate = max(data_code$date)
                
                if (minDate > rv$period[1]) {
                    NAadd = seq.Date(rv$period[1],
                                     minDate-1,
                                     "day")
                    nNAadd = length(NAadd)
                    data_codeLIM =
                        bind_rows(tibble(date=NAadd,
                                         Q=rep(NA, nNAadd),
                                         code=rep(rv$codePlot, nNAadd)),
                                  data_codeLIM)
                }
                
                if (maxDate < rv$period[2]) {
                    NAadd = seq.Date(maxDate+1,
                                     rv$period[2],
                                     "day")
                    nNAadd = length(NAadd)
                    data_codeLIM =
                        bind_rows(data_codeLIM,
                                  tibble(date=NAadd,
                                         Q=rep(NA, nNAadd),
                                         code=rep(rv$codePlot, nNAadd)))
                }
                
                # Extract NA data
                NAdate = data_codeLIM$date[is.na(data_codeLIM$Q)]
                # Get the difference between each point of date data
                # without NA
                dNAdate = diff(NAdate)
                # If difference of day is not 1 then
                # it is TRUE for the beginning of each missing data period 
                NAdate_Down = NAdate[append(Inf, dNAdate) != 1]
                # If difference of day is not 1 then
                # it is TRUE for the ending of each missing data period 
                NAdate_Up = NAdate[append(dNAdate, Inf) != 1]
                
                nMiss = length(NAdate_Up)
                Ymin = rep(0, nMiss)
                Ymax = rep(maxQ_win, nMiss)

                lenMiss = NAdate_Up - NAdate_Down + 1
                
                for (i in 1:nMiss) {
                    fig1 = plotly::add_trace(
                                       fig1,
                                       type="scatter",
                                       mode="lines",
                                       x=c(NAdate_Down[i], NAdate_Down[i],
                                           NAdate_Up[i], NAdate_Up[i],
                                           NAdate_Down[i]),
                                       y=c(Ymin[i], Ymax[i],
                                           Ymax[i], Ymin[i],
                                           Ymin[i]),
                                       fill="toself",
                                       opacity=0.4,
                                       fillcolor=lightCyanCOL,
                                       line=list(width=0),
                                       text=paste0(
                                           "<b>",
                                           lenMiss[i],
                                           "</b>", " ",
                                           word("plot.miss", lg)),
                                       hoverinfo="text",
                                       hoveron="fills",
                                       hoverlabel=
                                           list(bgcolor=lightCyanCOL,
                                                font=list(color="white",
                                                          family="Helvetica",
                                                          size=12),
                                                bordercolor="white"))
                }


                if (rv$data_name != "RRExplore2") {
                    # Gets the p value
                    pVal = trendEX_code$p

                    if (pVal <= alpha()) {
                        colorLine = color
                        colorLabel = color
                    } else {
                        colorLine = 'grey85'
                        colorLabel = 'grey85'
                    }

                    trendLabel = get_trendLabel(rv,
                                                Code=rv$codePlot,
                                                lg=lg,
                                                space=TRUE)

                    fig1 = plotly::add_annotations(
                                       fig1,
                                       x=0.01,
                                       y=1.01,
                                       xref="paper",
                                       yref="paper",
                                       text=trendLabel,
                                       showarrow=FALSE,
                                       xanchor='left',
                                       yanchor='bottom',
                                       font=list(color=switchColor,
                                                 family="Helvetica",
                                                 size=12))

                    fig1 = plotly::add_annotations(
                                       fig1,
                                       x=0.01,
                                       y=1.25,
                                       xref="paper",
                                       yref="paper",
                                       text=paste0("<b>",
                                                   rv$codePlot,
                                                   "</b> - ",
                                                   name),
                                       showarrow=FALSE,
                                       xanchor='left',
                                       yanchor='bottom',
                                       font=list(color=INRAECyanCOL,
                                                 family="Helvetica",
                                                 size=12))

                }
                
                fig1 = plotly::layout(
                                   fig1,
                                   separators='. ',
                                   
                                   yaxis=list(
                                       range=c(0, maxQ_win),
                                       title=list(
                                           text=paste0("<b>",
                                                       varLabel,
                                                       "</b>",
                                                       unitLabel),
                                           font=list(color=grey20COL,
                                                     family="Helvetica")),
                                       gridcolor=grey85COL,
                                       gridwidth=0.6,
                                       ticks="outside",
                                       tickcolor=grey75COL,
                                       tickfont=list(color=grey40COL,
                                                     family="Helvetica"),
                                       showline=TRUE,
                                       linewidth=2,
                                       linecolor=grey85COL,
                                       zerolinecolor=grey85COL,
                                       zerolinewidth=0.6,
                                       mirror=TRUE,
                                       fixedrange=TRUE),

                                   autosize=FALSE,
                                   plot_bgcolor=grey97COL,
                                   paper_bgcolor='transparent',
                                   showlegend=FALSE)

                # if (rv$data_name == "RRExplore2") {
                #     fig1 = plotly::layout(
                #                        fig1,
                #                        xaxis=list(range=rv$period,
                #                                   showgrid=FALSE,
                #                                   ticks="outside",
                #                                   tickcolor=grey75COL,
                #                                   showline=TRUE,
                #                                   linewidth=2,
                #                                   linecolor=grey85COL,
                #                                   showticklabels=FALSE,
                #                                   mirror="all"))
                # }

                fig1 = plotly::config(
                                   fig1,
                                   locale=word("plotly.language", lg),
                                   displaylogo=FALSE,
                                   toImageButtonOptions =
                                       list(format="svg"),
                                   modeBarButtonsToRemove =
                                       list("lasso2d",
                                            "select2d",
                                            "drawline",
                                            "zoom2d",
                                            "drawrect",
                                            "autoScale2d",
                                            "hoverCompareCartesian",
                                            "hoverClosestCartesian")
                               )     
                

                DateNoNA =
                    dataEX_code$date[!is.na(dataEX_code[[rv$variable_en]])]
                abs = c(min(DateNoNA), max(DateNoNA))
                # Convert the number of day to the unit of the period
                abs_num = as.numeric(abs) / 365.25
                # Compute the y of the trend
                if (rv$metaEX$unit_en == "yearday") {
                    ord = as.Date(abs_num * trendEX_code$a +
                                  trendEX_code$b, origin="1970-01-01")
                } else {
                    ord = abs_num * trendEX_code$a +
                        trendEX_code$b
                }

                x = dataEX_code$date

                if (rv$metaEX$unit_en == "yearday") {
                    y = as.Date(dataEX_code[[rv$variable_en]],
                                origin="1970-01-01")
                    yhoverformat = "%d %b"
                    unitLabel = ""
                } else {
                    y = dataEX_code[[rv$variable_en]]
                    yhoverformat = '.3r'
                    unitLabel = rv$unit
                    unitLabel = gsub('[/^][/{]', '<sup>',
                                     unitLabel)
                    unitLabel = gsub('[/}]', '</sup>', unitLabel)
                    unitLabel = paste0(" [", unitLabel, "]<br>")
                }

                id = which(Variable_ALL()$event == rv$event &
                                         Variable_ALL()$variable == rv$variable)
                varLabel = Variable_ALL()$variableHTML[id]
                if (!is.null(rv$proba)) {
                    if (grepl(SeasonMonth_pattern, rv$variable)) {
                        varLabel = gsub(SeasonMonth_pattern, rv$proba,
                                        varLabel)
                    } else {
                        varLabel = gsub('p', gsub("%", "", rv$proba),
                                        varLabel)
                    }
                }

                fig2 = plotly::plot_ly()
                
                fig2 = plotly::add_trace(
                                   fig2,
                                   type="scatter",
                                   mode="markers",
                                   x=x,
                                   y=y,
                                   marker=list(color=grey50COL),
                                   xhoverformat="%Y",
                                   yhoverformat=yhoverformat,
                                   hovertemplate = paste0(
                                       "année %{x}<br>",
                                       "<b>", varLabel, "</b> %{y}",
                                       unitLabel,
                                       "<extra></extra>"),
                                   hoverlabel=list(bgcolor=color,
                                                   font=list(size=12,
                                                             family="Helvetica"),
                                                   bordercolor="white"))

                fig2 = plotly::add_trace(
                                   fig2,
                                   type="scatter",
                                   mode="markers+lines",
                                   x=abs,
                                   y=ord,
                                   marker=list(color='white', size=6),
                                   line=list(color='white', width=6),
                                   hoverinfo="none")
                
                fig2 = plotly::add_trace(
                                   fig2,
                                   type="scatter",
                                   mode="markers+lines",
                                   x=abs,
                                   y=ord,
                                   marker=list(color=color, size=3),
                                   line=list(color=color, width=3),
                                   hoverinfo="none")
                
                unitLabel = rv$unit
                unitLabel = gsub('[/^][/{]', '<sup>', unitLabel)
                unitLabel = gsub('[/}]', '</sup>', unitLabel)
                unitLabel = paste0("[", unitLabel, "]<br>")
                title = paste0("<b> ", varLabel, "</b>",
                               " ", unitLabel)

                fig2 = plotly::layout(
                                   fig2,
                                   separators='. ',
                                   
                                   yaxis=list(
                                       title=list(
                                           text=title,
                                           font=list(color=grey20COL,
                                                     family="Helvetica")),
                                       showgrid=FALSE,
                                       ticks="outside",
                                       tickcolor=grey75COL,
                                       tickfont=list(color=grey40COL,
                                                     family="Helvetica"),
                                       showline=TRUE,
                                       linewidth=2,
                                       linecolor=grey85COL,
                                       zerolinecolor="transparent",
                                       mirror=TRUE,
                                       fixedrange=TRUE),
                                   
                                   autosize=FALSE,
                                   plot_bgcolor=grey97COL,
                                   paper_bgcolor='transparent',
                                   showlegend=FALSE)

                if (rv$metaEX$unit_en == "yearday") {
                    fig2 = plotly::layout(
                                       fig2,
                                       yaxis=
                                           list(tickformat="%b"))
                }

                fig2 = plotly::config(
                                   fig2,
                                   locale=word("plotly.language", lg),
                                   displaylogo=FALSE,
                                   toImageButtonOptions =
                                       list(format="svg"),
                                   modeBarButtonsToRemove =
                                       list("lasso2d",
                                            "select2d",
                                            "drawline",
                                            "zoom2d",
                                            "drawrect",
                                            "autoScale2d",
                                            "hoverCompareCartesian",
                                            "hoverClosestCartesian")
                               )


                if (rv$data_name == "RRExplore2") {
                    fig = plotly::subplot(fig0, fig1, fig2,
                                          nrows=3,
                                          heights=c(3/12,
                                                    3/12,
                                                    6/12),
                                          titleY=TRUE,
                                          shareX=TRUE,
                                          margin=0.025)
                    plotHeight = as.integer(rv$height/2)
                    
                } else {
                    fig = plotly::subplot(fig1, fig2,
                                          nrows=2,
                                          heights=c(1/3,
                                                    2/3),
                                          titleY=TRUE,
                                          shareX=TRUE,
                                          margin=0.025)

                    plotHeight = as.integer(rv$height/2.7)
                }

                
                if (rv$width > 1920) {
                    plotWidth = as.integer(rv$width/3)
                } else if (rv$width > 1080 & rv$width <= 1920) {
                    plotWidth = as.integer(rv$width/2.5)
                } else if (rv$width > 720 & rv$width <= 1080) {
                    plotWidth = as.integer(rv$width/2)
                } else if (rv$width <= 720) {
                    plotWidth = rv$width - 40
                }
                
                margin_top = as.integer(plotHeight/7.6)

                fig = plotly::layout(fig,
                                     autosize=FALSE,
                                     width=plotWidth,
                                     height=plotHeight,
                                     
                                     xaxis=list(range=rv$period,
                                                showgrid=FALSE,
                                                ticks="outside",
                                                tickcolor=grey75COL,
                                                tickfont=
                                                    list(color=grey40COL,
                                                         family="Helvetica"),
                                                showline=TRUE,
                                                linewidth=2,
                                                linecolor=grey85COL,
                                                showticklabels=TRUE,
                                                mirror="all"),
                                     
                                     margin=list(l=0,
                                                 r=12,
                                                 b=0,
                                                 t=margin_top, #32
                                                 pad=0))
                
                fig = plotly::config(
                                  fig,
                                  locale=word("plotly.language", lg),
                                  displaylogo=FALSE,
                                  toImageButtonOptions =
                                      list(format="svg"),
                                  modeBarButtonsToRemove =
                                      list("lasso2d",
                                           "select2d",
                                           "drawline",
                                           "zoom2d",
                                           "drawrect",
                                           "autoScale2d",
                                           "hoverCompareCartesian",
                                           "hoverClosestCartesian")
                              )
                fig
            })
        }
    })

### 8.4. Close _______________________________________________________
    observeEvent(input$closePlot_button, {
        if (verbose) print("closePlot_button")
        map = leafletProxy("map")
        map = fitBounds(map,
                        lng1=defaultLimits()$east,
                        lat1=defaultLimits()$south,
                        lng2=defaultLimits()$west,
                        lat2=defaultLimits()$north,
                        options=list(padding=c(20, 20)))
        
        rv$codePlot = NULL
        hide(id='plot_panel')
    })

    
## 9. COLORBAR PLOT __________________________________________________
    observeEvent({
        colorbar_choice()
        rv$minX
        rv$maxX
        rv$a_normalise
    }, {
        if (verbose) print("plot_colorbar")
        
        if (colorbar_choice() == 'show' & !is.null(rv$trendEX)) {
            output$colorbar_plot = plotly::renderPlotly({
                
                res = compute_colorBin(rv$minX,
                                       rv$maxX,
                                       colorStep=colorStep,
                                       center=0,
                                       include=FALSE)
                bin = res$bin
                binNoINF = bin[is.finite(bin)]
                
                upBin = res$upBin
                Y1 = upBin / max(upBin[is.finite(upBin)])
                dY = mean(diff(Y1[is.finite(Y1)]))
                Y1[Y1 == Inf] = 1 + dY
                
                lowBin = res$lowBin
                Y0 = lowBin / max(lowBin[is.finite(lowBin)])
                Y0[Y0 == -Inf] = -1 - dY

                X0 = rep(0, colorStep)
                X1 = rep(1, colorStep)
                
                # Computes the histogram of values
                res = hist(rv$a_normalise,
                           # breaks=c(-Inf, bin, Inf),
                           breaks=bin,
                           plot=FALSE)
                # Extracts the number of counts per cells
                counts = res$counts

                plotWidth = 67
                plotHeight = 260# as.integer(rv$height/2.8) 
                
                fig = plotly::plotly_empty(width=plotWidth,
                                           height=plotHeight)
                
                for (i in 2:(colorStep-1)) {
                    fig = plotly::add_trace(
                                      fig,
                                      type="scatter",
                                      mode="lines",
                                      x=c(X0[i], X0[i],
                                          X1[i], X1[i], X0[i]),
                                      y=c(Y0[i], Y1[i],
                                          Y1[i], Y0[i], Y0[i]),
                                      fill="toself",
                                      fillcolor=rv$Palette[i],
                                      line=list(width=0),
                                      text=paste0("<b>",
                                                  counts[i],
                                                  "</b>",
                                                  "<br>stations"),
                                      hoverinfo="text",
                                      hoveron="fills",
                                      hoverlabel=list(bgcolor=counts[i],
                                                      font=list(color="white",
                                                                size=12),
                                                      bordercolor="white"))
                }
                
                fig = plotly::layout(
                                  fig,
                                  autosize=FALSE,
                                  xaxis=list(range=c(-1.51, 3.4),
                                             showticklabels=FALSE,
                                             fixedrange=TRUE),
                                  yaxis=list(range=c(-1-dY*2/3, 1+dY*2/3),
                                             showticklabels=FALSE,
                                             fixedrange=TRUE),
                                  plot_bgcolor='transparent',
                                  paper_bgcolor='transparent',
                                  showlegend=FALSE)
                
                fig = plotly::add_trace(
                                  fig,
                                  type="scatter",
                                  mode="lines",
                                  x=c(0, 1, 0.5, 0),
                                  y=c(1, 1, 1+dY*2/3, 1),
                                  fill="toself",
                                  fillcolor=rv$Palette[colorStep],
                                  line=list(width=0),
                                  text=paste0("<b>",
                                              counts[colorStep],
                                              "</b>",
                                              "<br>stations"),
                                  hoverinfo="text",
                                  hoveron="fills",
                                  hoverlabel=list(bgcolor=counts[colorStep],
                                                  font=list(size=12,
                                                            family="Helvetica"),
                                                  bordercolor="white"))
                
                fig = plotly::add_trace(
                                  fig,
                                  type="scatter",
                                  mode="lines",
                                  x=c(0, 1, 0.5, 0),
                                  y=c(-1, -1, -1-dY*2/3, -1),
                                  fill="toself",
                                  fillcolor=rv$Palette[1],
                                  line=list(width=0),
                                  text=paste0("<b>",
                                              counts[1],
                                              "</b>",
                                              "<br>stations"),
                                  hoverinfo="text",
                                  hoveron="fills",
                                  hoverlabel=list(bgcolor=counts[1],
                                                  font=list(size=12,
                                                            family="Helvetica"),
                                                  bordercolor="white"))

                Xlab = rep(1.2, colorStep)
                Ylab = binNoINF / max(binNoINF)

                ncharLim = 4
                # if (rv$to_normalise) {                    
                # labelRaw = binNoINF*100
                # } else {
                labelRaw = binNoINF
                # }
                
                if (get_power(max(labelRaw)) < 0) {
                    power = get_power(min(labelRaw))
                    labelRaw = labelRaw * 10^(-power)
                    powerLabel = paste0("x<b>10<sup>",
                                        power,
                                        "</sup></b>")
                    fig = plotly::add_annotations(
                                      fig,
                                      x=0.95,
                                      y=-1-dY*2/3,
                                      text=powerLabel,
                                      showarrow=FALSE,
                                      xanchor='left',
                                      font=list(color=grey60COL,
                                                family="Helvetica",
                                                size=12.5))

                    fig = plotly::layout(
                                      fig,
                                      margin=list(l=0,
                                                  r=5,
                                                  b=6,
                                                  t=0,
                                                  pad=0))
                } else {
                    fig = plotly::layout(
                                      fig,
                                      margin=list(l=0,
                                                  r=5,
                                                  b=3,
                                                  t=3,
                                                  pad=0))
                }
                
                label = round_label(labelRaw, ncharLim=ncharLim)
                label = paste0("<b>", label, "</b>")
                
                fig = plotly::add_annotations(
                                  fig,
                                  x=Xlab,
                                  y=Ylab,
                                  text=label,
                                  showarrow=FALSE,
                                  xanchor='left',
                                  font=list(color=grey40COL,
                                            family="Helvetica",
                                            size=12))

                # unit = rv$unit

                if (rv$type == word("ana.type.Q", lg)) {
                    if (rv$to_normalise) {
                        unit = paste0("%", " ",
                                      word("unit.by", lg), " ",
                                      word("unit.year", lg))
                    } else {
                        unit = paste0(word("unit.day", lg), " ",
                                      word("unit.by", lg), " ",
                                      word("unit.year", lg))
                    }
                    
                } else if (rv$type == word("ana.type.T", lg)) {
                    unit = paste0("C", " ", word("unit.by", lg), " ",
                                  word("unit.year", lg))

                } else if (rv$type == word("ana.type.P", lg)) {
                    unit = paste0("mm", " ", word("unit.by", lg), " ",
                                  word("unit.year", lg))
                }

                title = paste0("<b>", word("cb.title", lg), "</b>",
                               " ", unit)
                
                fig = plotly::add_annotations(
                                  fig,
                                  x=-0.1,
                                  y=0,
                                  text=title,
                                  textangle=-90,
                                  showarrow=FALSE,
                                  xanchor='right',
                                  yanchor='center',
                                  font=list(color=grey50COL,
                                            family="Helvetica",
                                            size=13.5))
                
                fig = plotly::config(
                                  fig,
                                  displaylogo=FALSE,
                                  displayModeBar=FALSE,
                                  doubleClick=FALSE)                
                fig  
            })
        }
    })
    

## 10. CUSTOMIZATION _________________________________________________
### 10.0. Show / hide ________________________________________________
    observeEvent(input$theme_button, {
        toggleOnly(id="theme_panel")
        deselect_mode(session, rv)
    })

    observeEvent(input$closeSettings_button, {
        hide(id='theme_panel')
        showElement(id='ana_panel')
    })
    
### 10.1. Palette ____________________________________________________
    colorbar_choice = reactive({
        if (is.null(input$colorbar_choice)) {
            default_colorbar_choice 
        } else {
            input$colorbar_choice
        }
    })
    
    observeEvent({
        colorbar_choice()
        rv$trendEX
    }, {
        if (verbose) print("colorbar_choice")
        if (colorbar_choice() == 'show' & !is.null(rv$trendEX)) {
            showElement(id="colorbar_panel")
        } else if (colorbar_choice() == 'none' | is.null(rv$trendEX)) {
            hide(id="colorbar_panel")
        }
    })

### 10.2. Resume _____________________________________________________
    resume_choice = reactive({
        if (is.null(input$resume_choice)) {
            default_resume_choice 
        } else {
            input$resume_choice
        }
    })

    observeEvent({
        resume_choice()
        rv$trendEX
    }, {
        if (verbose) print("resume_choice")
        if (resume_choice() == 'show' & !is.null(rv$trendEX)) {
            showElement(id="resume_panel")
        } else if (resume_choice() == 'none') {
            hide(id="resume_panel")
        }
    })

### 10.3. Stat _______________________________________________________
    stat_choice = reactive({
        if (is.null(input$stat_choice)) {
            default_stat_choice 
        } else {
            input$stat_choice
        }
    })

    observeEvent({
        stat_choice()
        rv$trendEX
    }, {
        if (verbose) print("stat_choice")
        if (stat_choice() == 'show' & !is.null(rv$trendEX)) {
            showElement(id="stat_panel")
        } else if (stat_choice() == 'none') {
            hide(id="stat_panel")
        }
    })
    
    
## 11. INFO __________________________________________________________
    observeEvent(input$info_button, {
        if (verbose) print("info_panel")
        toggleOnly(id="info_panel")
        deselect_mode(session, rv)
    })

    
## 12. SCREENSHOT ____________________________________________________
    observeEvent(input$photo_button, {
        if (verbose) print("photo")
        hide(id="zoom_panelButton")
        hide(id="ana_panelButton")
        hide(id="theme_panelButton")
        hide(id="photo_panelButton")
        hide(id="download_data_panelButton")
        hide(id="download_sheet_panelButton")
        hide(id="help_panelButton")
        hide(id="actualise_panelButton")
        
        hideAll()
        
        deselect_mode(session, rv)
        rv$photoMode = TRUE
    })

    observeEvent(input$map_click, {
        if (verbose) print("map click")
        if (rv$polyMode == 'false' & !rv$clickMode & !rv$dlClickMode & rv$photoMode) {
            showElement(id="zoom_panelButton")
            showElement(id="ana_panelButton")
            showElement(id="theme_panelButton")
            showElement(id="photo_panelButton")
            showElement(id="download_data_panelButton")
            showElement(id="download_sheet_panelButton")
            showElement(id="help_panelButton")
            # showElement(id="actualise_panelButton")
            rv$photoMode = FALSE
        }
    })
    

## 13. DOWNLOAD ______________________________________________________
### 13.1. Data _______________________________________________________
    observeEvent(input$download_data_button, {
        if (verbose) print("downloadData_button")
        outdir = file.path(computer_data_path, "tmp")
        if (file.exists(outdir)) {
            unlink(outdir, recursive=TRUE)
        }
        dir.create(outdir)
        
        files = c("meta.csv", "metaEX.csv",
                  "dataEX.csv", "trendEX.csv")
        ASHE::write_tibble(rv$meta,
                           path=file.path(outdir, "meta.csv"))
        ASHE::write_tibble(rv$metaEX,
                           path=file.path(outdir, "metaEX.csv"))
        ASHE::write_tibble(rv$dataEX,
                           path=file.path(outdir, "dataEX.csv"))
        tmp = rv$trendEX
        tmp$period_trend = sapply(tmp$period_trend, paste0, collapse=" ")
        ASHE::write_tibble(tmp,
                           path=file.path(outdir, "trendEX.csv"))

        readme = readLines(readme_path)
        sep = " : "
        param = NULL
        param = c(param,
                   paste0(word("ana.data", lg), sep, rv$data_name))
        param = c(param,
                   paste0(word("ana.type", lg), sep, rv$type))

        if (rv$type == word("ana.type.T", lg)) {
            event_name = word("ana.temperature", lg)
        } else if (rv$type == word("ana.type.Q", lg)) {
            event_name = word("ana.regime", lg)
        } else if (rv$type == word("ana.type.P", lg)) {
            event_name = word("ana.pluviometrie", lg)
        }
        param = c(param,
                   paste0(event_name, sep, rv$event))
        param = c(param,
                   paste0(word('ana.var', lg), sep, rv$variable))

        if (grepl(word("var.month", lg), rv$variable)) {
            proba_name = word("ana.month", lg)
        } else if (grepl(word("var.season", lg), rv$variable)) {
            proba_name = word("ana.season", lg)
        } else {
            proba_name = word("ana.proba", lg)
        }
        param = c(param,
                   paste0(proba_name, sep, rv$proba))

        if (rv$optimalMode_act) {
            sampling_period_overwrite = word("ana.optimal.slider", lg)
        } else {
            sampling_period_overwrite = paste0(rv$sampling_period,
                                               collapse=" ")
        }
        
        param = c(param,
                   paste0(word('ana.dm', lg), sep,
                               sampling_period_overwrite))
        param = c(param,
                   paste0(word('ana.dy', lg), sep,
                          paste0(rv$period, collapse=" ")))
        param = c(param,
                   paste0(word('ana.sig', lg), sep, rv$alpha))

        id = which(grepl("[[]PARAM[]]", readme))
        readme = c(readme[1:(id-1)],
                   param,
                   readme[(id+1):length(readme)])
        readme = gsub("[[]DATE[]]",
                      format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
                      readme)
        
        writeLines(readme, readme_tmp_path)
        
        outfile = "MAKAHO_analyse.zip"
        outpath = file.path(outdir, outfile)
        paths = file.path(outdir, files)
        paths = c(paths, licence_path, readme_tmp_path)
        zip(zipfile=outpath, files=paths, flags ='-r9Xj')
        
        output$downloadData = downloadHandler(
            filename = function () {
                outfile
            },
            content = function (file) {
                from = outpath
                file.copy(from, file)
            }
        )
        jsinject = "setTimeout(function()
                        {window.open($('#downloadData')
                        .attr('href'))}, 100);"
        session$sendCustomMessage(type='jsCode',
                                  list(value=jsinject))
    })

### 13.2. Sheet ______________________________________________________
#### 13.2.0. show/ hide ______________________________________________
    observeEvent(input$download_sheet_button, {
        toggleOnly(id="download_sheet_bar")
        deselect_mode(session, rv)
    })

    observe({
        if (!is.null(input$dlClick_select)) {
            hide(id='ana_panel')
            hide(id='theme_panel')
            hide(id='info_panel')
            hide(id='photo_bar')
            hide(id='download_sheet_bar')
            hide(id='click_bar')
            hide(id='poly_bar')
            showElement(id='dlClick_bar')
            rv$dlClickMode = TRUE
        } else {
            if (rv$dlClickMode) {
                deselect_mode(session, rv)
                hide(id='dlClick_bar')
                showElement(id='download_sheet_bar')
            }
        }
    })

    observeEvent(input$dlClickOk_button, {
        deselect_mode(session, rv)
        hide(id='dlClick_bar')
        showElement(id='download_sheet_bar')
    })

#### 13.2.1. click ___________________________________________________
    observeEvent(codeClick(), {
        if (rv$polyMode == 'false' & !rv$clickMode & rv$dlClickMode & !rv$photoMode) {
            code = rv$meta$code_hydro2[rv$meta$code == codeClick()]
            output$downloadData = downloadHandler(
                filename = function () {
                    paste0(code, ".pdf")
                },
                content = function (file) {
                    name = paste0(code, ".pdf")
                    from = file.path(computer_data_path, 'pdf', name)
                    file.copy(from, file)
                }
            )
            jsinject = "setTimeout(function()
                        {window.open($('#downloadData')
                        .attr('href'))}, 100);"
            session$sendCustomMessage(type='jsCode',
                                      list(value=jsinject))    
        }
    })

#### 13.2.2. selection _______________________________________________
    observeEvent(input$dlSelec_button, {
        
        outdir = file.path(computer_data_path, "tmp")
        if (file.exists(outdir)) {
            unlink(outdir, recursive=TRUE)
        }
        dir.create(outdir)

        outfile = "fiches_stations.zip"
        outpath = file.path(outdir, outfile)
        
        files = file.path(computer_data_path, "pdf",
                          paste0(CodeSample(), ".pdf"))
        zip(zipfile=outpath, files=files, flags = '-r9Xj')

        output$downloadData = downloadHandler(
            filename = function () {
                outfile
            },
            content = function (file) {
                from = outpath
                file.copy(from, file)
            }
        )
        jsinject = "setTimeout(function()
                        {window.open($('#downloadData')
                        .attr('href'))}, 100);"
        session$sendCustomMessage(type='jsCode',
                                  list(value=jsinject))  
    })

#### 13.2.3. all _____________________________________________________
    observeEvent(input$dlAll_button, {
        outdir = file.path(computer_data_path, "zip")        
        if (!(file.exists(outdir))) {
            dir.create(outdir)
        }
        outfile = "fiches_stations_ALL.zip"
        outpath = file.path(outdir, outfile)

        if (!(file.exists(outpath))) {
            files = dir(file.path(computer_data_path, "pdf") ,
                        full.names=TRUE)            
            zip(zipfile=outpath, files=files, flags = '-r9Xj')
        }

        output$downloadData = downloadHandler(
            filename = function () {
                outfile
            },
            content = function (file) {
                from = outpath
                file.copy(from, file)
            }
        )
        jsinject = "setTimeout(function()
                        {window.open($('#downloadData')
                        .attr('href'))}, 100);"
        session$sendCustomMessage(type='jsCode',
                                  list(value=jsinject))
    })


## 14. HELP __________________________________________________________
### 14.0. Show / hide ________________________________________________
    observeEvent({
        input$help_button
        rv$startHelp
    }, {
        if (verbose) print("help start")
        rv$start = TRUE
        rv$CodeSample = rv$CodeAll
        
        rv$helpPage = 1
        rv$helpPage_save = 0

        hideAll()
        rv$codePlot = NULL
        hide(id='plot_panel')
        
        deselect_mode(session, rv)
        maskAll()
        
        showElement(id='blur_panel')
        hide(id='help_panelButton')
        
        showElement(id='focusZoom_panelButton')
        # showElement(id='actualise_panelButton')
        
        showElement(id='before_panelButton')
        show_page(n=1, N=N_helpPage)
        showElement(id='next_panelButton')
        showElement(id='closeHelp_panelButton')

        showElement(id='dlHelp_panelButton')
        
    })

### 14.1. Navigation _________________________________________________
    observeEvent(input$before_button, {
        if (verbose) print("before_button")
        if (rv$helpPage > 1) {
            show_page(n=rv$helpPage - 1, N=N_helpPage)
            rv$helpPage = rv$helpPage - 1
        }
    })

    observeEvent(input$next_button, {
        if (verbose) print("help next")
        if (rv$helpPage < N_helpPage) {
            show_page(n=rv$helpPage + 1, N=N_helpPage)
            rv$helpPage = rv$helpPage + 1
        }
    })

### 14.2. Make page __________________________________________________
    observePage(input, rv, n=1, N=N_helpPage)
    observePage(input, rv, n=2, N=N_helpPage)
    observePage(input, rv, n=3, N=N_helpPage)
    observePage(input, rv, n=4, N=N_helpPage)
    observePage(input, rv, n=5, N=N_helpPage)
    observePage(input, rv, n=6, N=N_helpPage)
    observePage(input, rv, n=7, N=N_helpPage)
    observePage(input, rv, n=8, N=N_helpPage)
    observePage(input, rv, n=9, N=N_helpPage)
    observePage(input, rv, n=10, N=N_helpPage)
    observePage(input, rv, n=11, N=N_helpPage)
    observePage(input, rv, n=12, N=N_helpPage)
    observePage(input, rv, n=13, N=N_helpPage)
    observePage(input, rv, n=14, N=N_helpPage)
    observePage(input, rv, n=15, N=N_helpPage)
    observePage(input, rv, n=16, N=N_helpPage)

### 14.3. Update page ________________________________________________
    observeEvent({
        rv$helpPage
        rv$width
        # rv$need_actualise
    }, {
        if (verbose) print("help")
        if (!is.null(rv$helpPage)) {

            if (rv$helpPage == 1 |
                rv$helpPage == 2 |
                rv$helpPage == 3) {
                # hide(id="actualise_panelButton")
                hideAll()
                maskAll()
                # hide(id="maskActualise_panelButton")
            }

            width_lim = 1260
            if (rv$width <= width_lim) {
                hideAll()
            }
            
            if (rv$helpPage == 4) {
                hideAll()
                maskOnly(id="maskZoom_panelButton")
                rv$CodeSample = rv$CodeAll[substr(rv$CodeAll,
                                                  1, 1) == "O"]
            } else {
                rv$CodeSample = rv$CodeAll
            }

            if (rv$helpPage == 5) {
                if (rv$width > width_lim) {
                    showOnly(id=c("ana_panel", "poly_bar"))
                }
                showElement(id="maskAna_panelButton")
            }
            
            if (rv$helpPage == 6 | rv$helpPage == 7 |
                rv$helpPage == 8) {
                if (rv$width > width_lim) {
                    showOnly(id="ana_panel")
                }
                maskOnly(id="maskAna_panelButton")
            }

            if (rv$helpPage == 10) {
                if (rv$width > width_lim) {
                    showOnly(id="ana_panel")
                }
                maskOnly(id="maskAna_panelButton")
                showElement(id="actualise_panelButton")
            } else {
                if (!rv$need_actualise) {
                    hide(id="actualise_panelButton")
                }
            }

            if (rv$helpPage == 11) {
                if (rv$width > width_lim) {
                    showOnly(id="theme_panel")
                }
                maskOnly(id="")
            }

            if (rv$helpPage == 12) {
                if (rv$width > width_lim) {
                    showOnly(id="theme_panel")
                }
                maskOnly(id="")
            }

            if (rv$helpPage == 13) {
                if (rv$width > width_lim) {
                    showOnly(id="photo_bar")
                }
                maskOnly(id="maskPhoto_panelButton")
            }

            if (rv$helpPage == 14) {
                if (rv$width > width_lim) {
                    showOnly(id="download_sheet_bar")
                }
                maskOnly(id="maskDownload_sheet_panelButton")
            }

            if (rv$helpPage == 15) {
                hideAll()
                maskOnly(id="maskDownload_data_panelButton")
            }

            if (rv$helpPage == 16) {
                if (rv$width > width_lim) {
                    showOnly(id="info_panel")
                }
                maskOnly(id="maskInfo_panelButton")
            }

            if (rv$need_actualise & rv$helpPage != 10) {
                showElement(id="maskActualise_panelButton")
            } else {
                hide(id="maskActualise_panelButton")
            }
        }
    })

### 14.4. Download help ______________________________________________
    observeEvent(input$dlHelp_button, {
        outdir = file.path(resources_path)
        outfile = "makaho.pdf"
        outpath = file.path(outdir, outfile)
        
        output$downloadData = downloadHandler(
            filename = function () {
                outfile
            },
            content = function (file) {
                from = outpath
                file.copy(from, file)
            }
        )
        jsinject = "setTimeout(function()
                        {window.open($('#downloadData')
                        .attr('href'))}, 100);"
        session$sendCustomMessage(type='jsCode',
                                  list(value=jsinject))
    })
    
### 14.5. Close ______________________________________________________
    observeEvent(input$closeHelp_button, {
        if (verbose) print("help close")
        if (rv$helpPage == 4) {
            rv$CodeSample = rv$CodeAll
        }
        rv$helpPage = NULL
        rv$helpPage_save = NULL

        hideAll()
        hide(id='focusZoom_panelButton')
        # hide(id='actualise_panelButton')
        hide(id="maskActualise_panelButton")
        demaskAll()

        hide(id='blur_panel')
        showElement(id='help_panelButton')

        hide(id='before_panelButton')
        hide_page(N=N_helpPage)
        hide(id='next_panelButton')
        hide(id='closeHelp_panelButton')

        hide(id='dlHelp_panelButton')        
    })
}
