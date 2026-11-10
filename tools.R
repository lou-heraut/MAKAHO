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



## 1. LANGUAGE _______________________________________________________
word = function (id, lg) {
    w = dico[[lg]][dico$id == id]
    return (w)
}

## 2. VARIABLE _______________________________________________________
get_Variable = function (CARD_path, check_varSub, lg) {

    if (verbose) print("get_Variable")
    
    CARD_filepath = list.files(CARD_path,
                               full.names=TRUE,
                               recursive=TRUE)
    CARD_filepath = CARD_filepath[!grepl("default", CARD_filepath)]
    nVariable = length(CARD_filepath)
    Variable = dplyr::tibble()

    # metaEX_all = EXstat.CARD::CARD_list_all()
    
    for (CARD in CARD_filepath) {
        Process_default = sourceProcess(
            file.path(CARD_path, "__default__.R"))
        
        Process = sourceProcess(
            file.path(CARD),
            default=Process_default)

        principal = Process$P
        principal_names = names(principal)
        for (pp in 1:length(principal)) {
            assign(principal_names[pp], principal[[pp]])
        }


        variable_CARD = gsub("^[[:digit:]]+[_]", "",
                             gsub("[.]R", "", basename(CARD)))
        # metaEX = dplyr::filter(metaEX_all, variable_en==variable_CARD)
        # for (i in 1:length(names(metaEX))) {
            # assign(names(metaEX)[i], metaEX[[i]])
        # }
        
        variable = get(paste0("variable_", lg))

        topic = unlist(strsplit(get(paste0("topic_", lg)),
                                ", "))
        name = get(paste0("name_", lg))
        
        if (any(sapply(check_varSub, grepl, variable_CARD))) {
            id = which(sapply(check_varSub, grepl, variable_CARD))
            
            if (grepl("(month)|(season)", variable_CARD)) {
                to_rm = gsub("(month)|(season)", "",
                             variable_CARD)
                sub = gsub(to_rm, "", variable)
                pattern = paste0("(",
                                 paste0(sub, collapse=")|("),
                                 ")")
                variable = gsub(pattern, "", variable[1])

                if (grepl("month", variable_CARD)) {
                    variable = paste0(variable, word("var.month", lg))
                } else if (grepl("season", variable_CARD)) {
                    variable = paste0(variable, word("var.season", lg))
                }
                
                variableHTML = variable
                if (grepl('[_]', variable)) {
                    variableHTML = paste0("<span>",
                                          gsub('_', '<sub>', variable),
                                          "</sub>", "</span>")
                }

                Variable = bind_rows(
                    Variable,
                    dplyr::tibble(type=topic[1],
                                  event=topic[2],
                                  variable_CARD=variable_CARD,
                                  variable=variable,
                                  variableHTML=variableHTML,
                                  name=list(name),
                                  sub=list(sub),
                                  preferred_sampling_period=
                                      preferred_sampling_period,
                                  palette=str_split(palette,
                                                    " ")))
                
            } else {
                sub = paste0(stringr::str_extract(variable,
                                                  "[[:digit:]]+"),
                             "%")
                variable = gsub("[[:digit:]]+", "p", variable)
                variable_regexp = paste0("^", variable, "$")

                ok1 = grepl(variable_regexp, Variable$variable)
                ok2 = Variable$event == topic[2]
                if (identical(ok2, logical(0))) {
                    ok2 = FALSE
                }

                # print(paste0("sub : ", paste0(sub, collapse=" ")))

                variableHTML = variable
                if (grepl('[_]', variable)) {
                    variableHTML = paste0("<span>",
                                          gsub('_', '<sub>', variable),
                                          "</sub>", "</span>")
                }
                
                if (!any(ok1 & ok2)) {
                    Variable = bind_rows(
                        Variable,
                        dplyr::tibble(type=topic[1],
                                      event=topic[2],
                                      variable_CARD=variable,
                                      variable=variable,
                                      variableHTML=variableHTML,
                                      name=list(name),
                                      sub=list(sub),
                                      preferred_sampling_period=
                                  preferred_sampling_period,
                                      palette=str_split(palette,
                                                        " ")))
                } else {
                    id2 = which(ok1 & ok2)
                    Variable$name[[id2]] = c(Variable$name[[id2]],
                                             name)
                    Variable$sub[[id2]] = c(Variable$sub[[id2]], sub)
                }
            }
            
        } else {
            variableHTML = variable
            if (grepl('[_]', variable)) {
                variableHTML = paste0("<span>",
                                      gsub('_', '<sub>', variable),
                                      "</sub>", "</span>")
            }

            Variable = bind_rows(
                Variable,
                dplyr::tibble(type=topic[1],
                              event=topic[2],
                              variable_CARD=variable_CARD,
                              variable=variable,
                              variableHTML=variableHTML,
                              name=list(name),
                              sub=NA,
                              preferred_sampling_period=
                                  preferred_sampling_period,
                              palette=str_split(palette,
                                                " ")))
        }
        # print(paste0("variable : ", variable))
        # cat("\n")
    }
    return (Variable)
}

# Variable = get_Variable(CARD_path, check_varSub, lg=lg)
# stop()


## 3. MAP ____________________________________________________________
get_urlTile = function (theme, provider, theme_file, resources_path, token=NULL) {
    
    theme_path = file.path(resources_path, theme_file)
    urlTiles = as.character(read.table(file=theme_path,
                                       header=FALSE,
                                       quote='"')[[1]])
        
    OkProvider = grepl(provider, urlTiles, fixed=TRUE)
    urlTiles_provider = urlTiles[OkProvider]
    
    if (provider == "jawg") {
        if (theme == 'light') {
            themeUrl = 'light'
        } else if (theme == 'terrain') {
            themeUrl = 'terrain'
        } else if (theme == 'dark') {
            themeUrl = 'dark'
        }
    } else if (provider == "stadia") {
        if (theme == 'light') {
            themeUrl = "alidade_smooth/"
        } else if (theme == 'terrain') {
            themeUrl ="outdoors"
        } else if (theme == 'dark') {
            themeUrl = "alidade_smooth_dark/"
        }
    }

    OkTheme = grepl(themeUrl, urlTiles_provider, fixed=TRUE)
    urlTile = urlTiles_provider[OkTheme]
    
    if (provider == "jawg") {
        urlTile = sub("[{]accessToken[}]", token, urlTile)
    }
    return (urlTile)
}
# get_urlTile('light', 'stadia',
#             'theme.txt',
#             resources_path,
#             token=jawg_token)


## 4. ICON ___________________________________________________________
create_iconLib = function (icon_dir, resources_path) {
    iconLib = icon_set(file.path(resources_path, icon_dir))#, icon_file))
    return (iconLib)
}




## 5. BUTTON _________________________________________________________
### 5.1. Button ______________________________________________________
Button = function (inputId, label=NULL, icon_name=NULL,
                   width=NULL, tooltip=NULL, ...){

    if (is.null(tooltip)) {
        actionButton(inputId=inputId,
                     label=div(icon_name,
                               label,
                               style="float:right;
                                      padding-left:0.2rem;
                                      padding-right: 0.2rem;"),
                     icon=NULL,
                     width=width,
                     # img=img(icon_name, align="right",
                         # style="text-align: center;
                                # display: flex; align-items: center;"),
                     ...)
    } else {
        div(class="Tooltip bunch",
            HTML(paste0(
                actionButton(inputId=inputId,
                             label=div(icon_name,
                                       label,
                                       style="float:right;
                                          padding-left:0.2rem;
                                          padding-right: 0.2rem;"),
                             icon=NULL,
                             width=width,
                             # img=img(icon_name, align="right",
                                 # style="text-align: center;
                                        # display: flex; align-items: center;"),
                             ...),
                '<span class="Tooltiptext">', tooltip, '</span>')))
    }
}

### 5.2. Select button _______________________________________________
selectButton = function (inputId, label=NULL, icon_name=NULL,
                         class='', selected=FALSE, tooltip=NULL, ...){

    if (is.null(tooltip)) {
        div(class="Tooltip bunch",
            HTML(paste0(
                checkboxGroupButtons(
                    status=class,
                    inputId=inputId,
                    label=NULL,
                    choiceNames=
                        paste0(img(icon_name,
                                   align="right",
                                   style="text-align: center;
                                          display: flex; align-items: center;"),
                               label),
                    choiceValues=TRUE,
                    selected=selected,
                    ...),
                '<span class="Tooltiptext">', tooltip, '</span>')))
    } else {
        checkboxGroupButtons(
            status=class,
            inputId=inputId,
            label=NULL,
            choiceNames=
                paste0(img(icon_name,
                           align="right",
                           style="text-align: center;
                                  display: flex; align-items: center;"),
                       label),
            choiceValues=TRUE,
            selected=selected,
            ...)
    }
}

### 5.3. Update select button ________________________________________
updateSelectButton = function (session, inputId, label=NULL,
                               icon_name=NULL, class='',
                               selected=FALSE, ...){

    if (is.null(icon_name) & is.null(label)) {
        choiceNames = NULL
        choiceValues = NULL
    } else {
        choiceNames = paste0(img(icon_name,
                                 align="right",
                                 style="text-align: center;
                                        display: flex; align-items: center;"),
                             label)
        choiceValues = TRUE
    }
    
    updateCheckboxGroupButtons(
        session=session,
        status=class,
        inputId=inputId,
        label=NULL,
        choiceNames=choiceNames,
        choiceValues=choiceValues,
        selected=selected,
        ...)
}

### 5.4. Radio button ________________________________________________
radioButton = function (class='',
                        choiceIcons=NULL, choiceNames=NULL,
                        choiceValues=NULL, choiceTooltips=NULL, ...) {

    if (!is.null(choiceNames)) {
        choiceItems = choiceNames

        if (is.null(choiceValues)) {
            choiceValues = choiceNames
        }
        
    } else {
        choiceItems = replicate(max(length(choiceTooltips),
                                    length(choiceIcons)),
                                "", simplify=FALSE)
    }
    if (!is.null(choiceIcons)) {
        inter = lapply(choiceIcons, img, align="right",
                       style="text-align: center;
                              display: flex; align-items: center;")
        choiceItems = mapply(paste0, inter, choiceItems)
    }
    if (!is.null(choiceTooltips)) {
        choiceItems = lapply(paste0(choiceItems,
                                    '<span class="Tooltiptext">',
                                    choiceTooltips,
                                    '</span>'), HTML)
        choiceItems = lapply(choiceItems,
                             div, class="Tooltip bunch")
    }

    radioGroupButtons(
        status=class,
        label=NULL,
        choiceNames=choiceItems,
        choiceValues=choiceValues,
        ...)
}

### 5.5. Update radio button _________________________________________
updateRadioButton = function (session, class='', choiceIcons=NULL,
                              choiceNames=NULL, choiceValues=NULL,
                              choices=NULL,
                              choiceTooltips=NULL, ...) {

    if (!is.null(choiceNames)) {
        choiceItems = choiceNames

        if (is.null(choiceValues)) {
            choiceValues = choiceNames
        }
        
    } else {
        choiceItems = replicate(max(length(choiceTooltips),
                                    length(choiceIcons)),
                                "", simplify=FALSE)
    }
    
    if (!is.null(choiceIcons)) {
        inter = lapply(choiceIcons, img, align="right",
                       style="text-align: center;
                              display: flex; align-items: center;")
        choiceItems = mapply(paste0, inter, choiceItems)
    }
    if (!is.null(choiceTooltips)) {
        choiceItems = lapply(paste0(choiceItems,
                                    '<span class="Tooltiptext">',
                                    choiceTooltips,
                                    '</span>'), HTML)
        choiceItems = lapply(choiceItems,
                             div, class="Tooltip bunch")
    }

    if (!is.null(choices)) {
        updateRadioGroupButtons(
            session=session,
            status=class,
            label=NULL,
            choices=choices,
            ...)
    } else {
        updateRadioGroupButtons(
            session=session,
            status=class,
            label=NULL,
            choiceNames=choiceItems,
            choiceValues=choiceValues,
            ...) 
    }
}


## 6. SLIDER _________________________________________________________
Slider = function (class, modeText=FALSE, ...) {
    if (modeText) {
        div(class=class,
            sliderTextInput(...))
    } else {
        div(class=class,
            sliderInput(...))
    }
}
updateSlider = function (class, modeText=FALSE, ...) {
    if (modeText) {
        div(class=class,
            updateSliderTextInput(...))
    } else {
        div(class=class,
            updateSliderInput(...))
    }
}


## 7. HELP ___________________________________________________________
### 7.1. Circle ______________________________________________________
page_circle = function (n, leftBase, widthHelp,
                        bottom, dh, tooltip=NULL) {
    hidden(
        fixedPanel(id=paste0("c", n,"_panelButton"),
                   left=paste0("calc(", leftBase,
                               " - ", 0.5*widthHelp, "px",
                               " + ", dh*(n-1), "px)"),
                   bottom=bottom,
                   width="auto", height="auto",

                   hidden(
                       div(id=paste0("c", n,"U_panelButton"),
                           Button(class="Button-icon-hover",
                                  inputId=paste0("c", n, "U_button"),
                                  label=NULL,
                                  icon_name=iconLib$circle_unchecked_white,
                                  tooltip=tooltip))
                   ),
                   hidden(
                       div(id=paste0("c", n,"C_panelButton"),
                           Button(class="Button-icon-hover",
                                  inputId=paste0("c", n, "C_button"),
                                  label=NULL,
                                  icon_name=iconLib$circle_checked_white,
                                  tooltip=tooltip))
                   )
                   )
    )
}


### 7.2. Page ________________________________________________________
show_page = function (n, N) {
    
    for (i in 1:N) {
        if (i == n) {
            showElement(id=paste0('help', i, '_panel'))
        } else {
            hide(id=paste0('help', i, '_panel'))
        }

        showElement(id=paste0('c', i, '_panelButton'))
        if (i <= n) {
            hide(id=paste0('c', i, 'U_panelButton'))
            showElement(id=paste0('c', i, 'C_panelButton'))
        } else {
            showElement(id=paste0('c', i, 'U_panelButton'))
            hide(id=paste0('c', i, 'C_panelButton'))
        }
    }
}

hide_page = function (N) {
    for (i in 1:N) {
        hide(id=paste0('help', i, '_panel'))
        hide(id=paste0('c', i, 'U_panelButton'))
        hide(id=paste0('c', i, 'C_panelButton'))
    }
}

observePage = function (input, rv, n, N) {
    observeEvent(input[[paste0("c", n ,"U_button")]], {
        rv$helpPage = n
        show_page(n=n, N=N)
    })    
    observeEvent(input[[paste0("c", n ,"C_button")]], {
        rv$helpPage = n
        show_page(n=n, N=N)
    })
}




## 8. MASK / HIDE / SHOW _____________________________________________
### 8.1. Mask ________________________________________________________
IdList_mask = c("maskZoom_panelButton",
                "maskAna_panelButton",
                # "maskActualise_panelButton",
                "maskInfo_panelButton",
                "maskPhoto_panelButton",
                "opacPhoto_panelButton",
                "maskDownload_data_panelButton",
                "maskDownload_sheet_panelButton")

maskAll = function (except=NULL, None=FALSE,
                    IdList=IdList_mask) {
    for (Id in IdList) {
        if (!(Id %in% except)) {
            showElement(id=Id)
        }
    }
}

demaskAll = function (except=NULL, None=FALSE,
                      IdList=IdList_mask) {
    for (Id in IdList) {
        if (!(Id %in% except)) {
            hide(id=Id)
        }
    }
}

maskOnly = function (id, IdList=IdList_mask) {
    for (Id in IdList) {
        if (Id %in% id) {
            hide(id=Id)
        } else {
            showElement(id=Id)
        }
    }
}

### 8.2. Hide / Show panel ___________________________________________
IdList_panel = c('ana_panel',
                 'theme_panel',
                 'info_panel',
                 'photo_bar',
                 'download_sheet_bar',
                 'click_bar',
                 'dlClick_bar',
                 'poly_bar')

hideAll = function (except=NULL, IdList=IdList_panel) {
    for (Id in IdList) {
        if (!(Id %in% except)) {
            hide(id=Id)
        }
    }
}

showOnly = function (id, IdList=IdList_panel) {
    for (Id in IdList) {
        if (Id %in% id) {
            showElement(id=Id)
        } else {
            hide(id=Id)
        }
    }
}

toggleOnly = function (id, IdList=IdList_panel) {
    for (Id in IdList) {
        if (Id %in% id) {
            toggle(id=Id)
        } else {
            hide(id=Id)
        }
    }
}

### 8.3. Hide / Show mode ____________________________________________
deselect_mode = function (session, rv) {
    updateSelectButton(
        session=session,
        class="selectButton",
        inputId="click_select",
        selected=FALSE)
    rv$clickMode = FALSE

    updateSelectButton(
        session=session,
        class="selectButton",
        inputId="poly_select",
        selected=FALSE)
    map = leafletProxy("map")
    map = clearShapes(map)
    rv$polyMode = 'false'
    rv$polyCoord = NULL

    updateSelectButton(
        session=session,
        class="selectButton",
        inputId="dlClick_select",
        selected=FALSE)
    rv$dlClickMode = FALSE
}


## 9. PLOTTING _______________________________________________________
# get_trendExtremesMOD = function (rv,
#                                  data, df_trend, unit,
#                                  minXprob=0, maxXprob=1,
#                                  CodeSample=NULL) {
    
#     if (unit == 'hm^{3}' | unit == 'm^{3}.s^{-1}') {
#         df_mean =
#             summarise(group_by(data, code),
#                       mean=mean(get(rv$variable), na.rm=TRUE))

#         df_join = full_join(df_trend, df_mean, by="code")
#         value = df_join$a / df_join$mean
#         Code = df_join$code
#     } else {
#         value = df_trend$a
#         Code = df_trend$code
#     }

#     if (!is.null(CodeSample)) {
#         valueSample = value[Code %in% CodeSample]
#     } else {
#         valueSample = value
#     }
    
#     minX = quantile(valueSample, minXprob, na.rm=TRUE)
#     maxX = quantile(valueSample, maxXprob, na.rm=TRUE)
    
#     df_value = tibble(code=Code, value=value)   
#     if (all(CodeSample %in% Code)) {
#         df_valueSample = tibble(code=CodeSample, value=valueSample)
#     } else {
#         df_valueSample = tibble(code=Code, value=valueSample)
#     }
#     res = list(df_value=df_value, df_valueSample=df_valueSample,
#                min=minX, max=maxX)
#     return (res)
# }

get_trendLabel = function (rv, Code, lg, space=FALSE) {

    trendEX_code = rv$trendEX[rv$trendEX$code == Code,]
    if (nrow(trendEX_code) == 0) {
        return (NA)
    }
    if (is.na(trendEX_code$a)) {
        return (NA)
    }

    if (space) {
        space = "    "
    } else {
        space = "&emsp;"
    }
    unitHTML = rv$unit
    unitHTML = gsub('[/^][/{]', '<sup>', unitHTML)
    unitHTML = gsub('[/}]', '</sup>', unitHTML)

    power = get_power(trendEX_code$a)

    a_normaliseC =
        as.character(format(round(trendEX_code$a_normalise, 2),
                            nsmall=2))
    if (-1 <= power & power <= 1) {
        aC = as.character(signif(trendEX_code$a, 3))

        if (rv$type == word("ana.type.Q", lg)) {
            if (rv$to_normalise) {
                label = paste0(
                    "<b>", aC, "</b>",
                    " [", unitHTML, ".",
                    word("unit.year", lg), "<sup>-1</sup>]",
                    space,
                    "<b>", a_normaliseC,
                    "</b> [%.", word("unit.year", lg), "<sup>-1</sup>]")
                
            } else {
                label = paste0(
                    "<b>", aC, "</b>",
                    " [", unitHTML, ".",
                    word("unit.year", lg), "<sup>-1</sup>]")
            }
            
        } else if (rv$type == word("ana.type.T", lg)) {
            label = paste0(
                "<b>", aC, "</b>",
                " [", unitHTML, ".",
                word("unit.year", lg), "<sup>-1</sup>]")

        } else if (rv$type == word("ana.type.P", lg)) {
            label = paste0(
                "<b>", aC, "</b>",
                " [", unitHTML, ".",
                word("unit.year", lg), "<sup>-1</sup>]")
        }

        
    } else {
        brk = 10^power
        aC = as.character(format(round(trendEX_code$a / brk, 2),
                                 nsmall=2))

        if (rv$type == word("ana.type.Q", lg)) {
            if (rv$to_normalise) {
                label = paste0(
                    "<b>", aC, " x ",
                    "10<sup>", power, "</sup></b>",
                    " [", unitHTML, ".",
                    word("unit.year", lg), "<sup>-1</sup>]",
                    space,
                    "<b>", a_normaliseC,
                    "</b> [%.", word("unit.year", lg), "<sup>-1</sup>]")
            
            } else {
                label = paste0(
                    "<b>", aC, " x ",
                    "10<sup>", power, "</sup></b>",
                    " [", unitHTML, ".",
                    word("unit.year", lg), "<sup>-1</sup>]")
            }
            
        } else if (rv$type == word("ana.type.T", lg)) {
            label = paste0(
                "<b>", aC, " x ",
                "10<sup>", power, "</sup></b>",
                " [", unitHTML, ".",
                word("unit.year", lg), "<sup>-1</sup>]")

        } else if (rv$type == word("ana.type.P", lg)) {
            label = paste0(
                "<b>", aC, " x ",
                "10<sup>", power, "</sup></b>",
                " [", unitHTML, ".",
                word("unit.year", lg), "<sup>-1</sup>]")
        }
    }

    return (label)
}


## 10. OTHER _________________________________________________________
count_decimal = function(x) {
    if ((x %% 1) != 0) {
        nchar(strsplit(sub('0+$', '',
                           as.character(x)), ".",
                       fixed=TRUE)[[1]][[2]])
    } else {
        return(0)
    }
}
