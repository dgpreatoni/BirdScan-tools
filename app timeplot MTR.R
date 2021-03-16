#### header ####################################################################
# shiny app to make MTR time plots from BirdScanM1 radar data
#
# see run_app_timeplot_MTR.R for a standalone R CLI script.
# 

#### version history ###########################################################
# version 0.2
# created: prea 20210304
# updated: prea 20210218
# version history:
#  0.2 - cleaned up code, added support for persistent symbols (colors, shapes, sizes), added blind time display
#  0.1 - derived from app timeplot.R

library(shiny)
library(dplyr)
library(lubridate)
library(suncalc)
library(ggplot2)
library(scales)
library(sp)


#### data preprocessing --------------------------------------------------------
# preprocessing assumes that data has already been extracted from a BirdScanMR1 database and live in a dataframe: this is done by running:
# source("MSSQL get data.R")

#@TODO actually, thou shalt instead connect to the live MSSQL server and pull out stuff from a view (e.g. v_mtr)

# load already preprocessed data (for now)
#readRDS('./data/db_2019_BollediMagadino-col.data-20200220_123911.RData')
#readRDS('./data/db_20201013_BollediMagadino-col.data-20201013_143607.RData')
mtr.data <- readRDS('../data/db_2019_BollediMagadino-mtr.data-20210219_124837.RData')


#### size up dashboard parameters, condition data --------------------------

## location name (and dd coords), time zone
#@TODO loc name coords and tz should be sucked from the DB
posMagadino <- list(lat=46.1602147, lon=8.9338966) # "exact" from Nicola authorization request
spMagadino <- SpatialPoints(matrix(c(posMagadino$lat, posMagadino$lon), nrow=1), proj4string=CRS("+init=epsg:4326"))
timeZone <- Sys.timezone()

## date slider
minDate <- min(mtr.data$time_stamp)
maxDate <- max(mtr.data$time_stamp)

## elevation slider
minElevation <- min(mtr.data$from_altitude)
maxElevation <- max(mtr.data$to_altitude)

## dot sizes, shapes, colours, other eye candy
maxDotSize <- 20                      # maximum dot size on plot
breaksDotSize <- c(0,10,100,500,1000) # classes breaks for MTR values
# colours and shapes, order is:
#              Insect     Bird        Passerine Wader      L. s. bird Flock
colourDot <- c('#FDC086', '#386CB0', '#F0027F', '#BEAED4', '#386CB0', '#7FC97F') # light orange, navy, purple, lilac, navy, green @ TODO find R colour names as per http://www.stat.columbia.edu/~tzheng/files/Rcolor.pdf?utm_source=twitterfeed&utm_medium=twitter 
shapeDot <- c(20, 20, 20, 15, 18, 17) # bullet, bullet, bullet, square, diamond, triangle

nightColor <- 'cadetblue4' # used to display night time on plot
nightAlpha <- 0.15

blindColor <- '#5F0202' # used to add "blind stripes" on plot top
blindAlpha <- 0.4

## object classes
# See "MSSQL get data.R" on how to pull out classes stuff from the BirdScan DB.
# Detail of classes, as per the 'classification' table, are compacted into a fewer classes, in the 'monitor classes' table
# as of February 2021 monitor_classes are as follows:
# id  name                   fill      shape 
#  0  "Insect"             #FDC086 orange      20 bullet
#  1  "Bird"               #386CB0 navy        20 bullet         
#  4  "Passerine"          #F0027F green       20 bullet
#  5  "Wader"              #BEAED4 lilac       22 square*
#  6  "Large Single Bird"  #386CB0 navy        21 circle* 
# 10  "Flock"              #7FC97F green       21 circle*
# *shapes 21 to 24 have both colour (border) and fill (inside)
# there's a more extensive classification schema for all the 'classification' classes, see 'MSSQL get data.R'

mclasses.style <- data.frame(id=c(0,1,4,5,6,10),
                             name=c('Insect', 'Bird', 'Passerine', 'Wader', 'Large single bird', 'Flock'),
                             fill=colourDot,
                             shape=shapeDot,
                             stringsAsFactors=FALSE)
mclasses.style$class <- factor(mclasses.style$id, levels=mclasses.style$id, labels=mclasses.style$name)
row.names(mclasses.style) <- mclasses.style$id


#### define user scales --------------------------------------------------------
# colour by class
mColors <- mclasses.style$fill
names(mColors) <- mclasses.style$name
colorScale <- scale_colour_manual(name="class", values=mColors) 
# shape by class
mShapes <- mclasses.style$shape
names(mShapes) <- mclasses.style$name
shapeScale <- scale_shape_manual(name="class", values=mShapes) 

# ensure factoring
mtr.data$class <- factor(mtr.data$monitor_class, levels=c(0,1,4,5,6,10), labels=c('Insect', 'Bird', 'Passerine', 'Wader', 'Large single bird', 'Flock'))




#### UI definition -------------------------------------------------------------
ui <- fluidPage(
  titlePanel("MTR time plot dashboard"),
  # top controls (date, class & elevation selectors)
  wellPanel(# width=12
    fluidRow( # two rows here
      #column(3,
      #dateRangeInput("dates", label="Date range", min=date(minDate), max=date(maxDate), start=date(minDate), end=date(maxDate))
      #),
      column(11, sliderInput("date", label="Date", min=date(minDate), max=date(maxDate), value=date(minDate),  animate=animationOptions(interval=1000, loop=TRUE)))
    ), # row 1
    #fluidRow(
    #  checkboxGroupInput("classes", label="Object classes", inline=TRUE, choices=mclasses.style$class, selected=c("Bird", "Passerine", "Wader", "Large single bird", "Flock"))
    #),
    #fluidRow(
    #  sliderInput("elevation", label="Elevation", min=minElevation, max=maxElevation, step=50, value=c(minElevation, maxElevation))
    #)
    fluidRow( # row 2
      column(3, checkboxGroupInput("classes", label="Object classes", inline=TRUE, choices=mclasses.style$class, selected=c("Bird", "Passerine", "Wader", "Large single bird", "Flock"))),
      column(8, sliderInput("elevation", label="Elevation", min=minElevation, max=maxElevation, step=50, value=c(minElevation, maxElevation)))
    ) # row 2
  ), # well Panel
  #### 
  fluidRow( # this is only for UI debugging
    #column(12, verbatimTextOutput("dates"),
    #column(12, verbatimTextOutput("minDate")), #, verbatimTextOutput("rows")),
    #column(12, verbatimTextOutput("classes"))
    #column(12, verbatimTextOutput("elevation"))
  ),
  fluidRow(
    plotOutput("timeplot")
  )
)


#### server definition ---------------------------------------------------------
server <- function(input, output) {
  ## these are for debugging
  #output$dates <- renderPrint({input$dates})
  #output$minDate <- renderPrint({minDate})
  #output$classes <- renderPrint({input$classes})
  #output$elevation <- renderPrint({input$elevation})
  #plotData <- reactive({ # filter out data here
  #  col.data[date(col.data$time_stamp)==as.POSIXct(input$date),]
  #  #return(col.data[col.data$time_stamp==input$date,] %>% group_by(year, month, day, hour, mean_altitude, classification_name) %>% summarise(n=n()))
  #  #plotData$time <- make_datetime(plotData$year, plotData$month, plotData$day, plotData$hour)
  #})
  #plotData <- col.data %>% group_by(year, month, day, hour, mean_altitude, classification_name) %>% summarise(n=n())
  #output$rows <- renderPrint({nrow(plotData)})
  
  # this is a "reactive" plot
  output$timeplot <- renderPlot({
    # get limits to subset data based on user selection
    ## Not Run:
    # minTimeStamp <- as.POSIXct("2020-06-16 16:00:00")
    # maxTimeStamp <- as.POSIXct("2020-06-17 23:59:59")
    # a time slice with high blindness
    # minTimeStamp <- as.POSIXct("2019-10-15 16:00:00")
    # maxTimeStamp <- as.POSIXct("2019-10-15 23:59:59")
    minTimeStamp <- as.POSIXct(paste(input$date-1, "16:00:00"))
    maxTimeStamp <- as.POSIXct(paste(input$date, "23:59:59"))
    # calculate dawn and dusks
    timeDuskBefore <- getSunlightTimes(date=as.Date(minTimeStamp), lat=coordinates(siteLocation)[1], lon=coordinates(siteLocation)[2], tz=timeZone)$dusk
    timeDawn <- getSunlightTimes(date=as.Date(maxTimeStamp), lat=coordinates(siteLocation)[1], lon=coordinates(siteLocation)[2], tz=timeZone)$dawn
    timeDusk <- getSunlightTimes(date=as.Date(maxTimeStamp), lat=coordinates(siteLocation)[1], lon=coordinates(siteLocation)[2], tz=timeZone)$dusk
    #print(timeDawn)
    # subset: by time bracket
    plotData <- mtr.data[mtr.data$time_stamp >= minTimeStamp & mtr.data$time_stamp <= maxTimeStamp,]
    # subset: by object class
    plotData <- plotData[plotData$class %in% input$classes,]
    # mind that class levels must be kept constant! this forcing does not solve things, look at plotting commands instead, necause up to here we have all levels also with classes filtered out
    # plotData$class <- factor(plotData$monitor_class, levels=c(0,1,4,5,6,10), labels=c('Insect', 'Bird', 'Passerine', 'Wader', 'Large single bird', 'Flock'))
    # subset: by elevation
    plotData <- plotData[plotData$mean_altitude >= as.numeric(input$elevation[1]) & plotData$mean_altitude <= as.numeric(input$elevation[2]),]
    # calculate blindness
    plotData$is_blind <- ifelse(plotData$blind_percent >= 80, TRUE, NA)
    # look up fill and shape
    #@FIXME Not needed, define fill and shape by class name, add style after
    #plotData$fill <- mclasses.style[as.character(plotData$monitor_class),'fill']
    #plotData$shape <- mclasses.style[as.character(plotData$monitor_class),'shape']
    #plotData <- plotData %>% group_by(year, month, day, hour, minute, mean_altitude, classification_name) %>% summarise(n=n())
    #plotData <- as.data.frame(plotData)
    #plotData$timeofday <-  as.POSIXct(paste0(input$date, " ", plotData$hour, ":", plotData$minute, ":00"))
    #str(plotData)
    ## Not Run: test plot
    #ggplot(plotData, aes(x=time_stamp, y=mean_altitude, colour=class)) + geom_rect(aes(xmin=timeDuskBefore, xmax=timeDawn, ymin=0, ymax=+Inf), alpha=.5, fill='lightgray', inherit.aes=FALSE) + geom_rect(aes(xmin=timeDusk, xmax=maxTimeStamp, ymin=0, ymax=+Inf), alpha=.5, fill='lightgray', inherit.aes=FALSE) + geom_count() + scale_x_datetime(labels=date_format("%H:%M", tz=timeZone), date_breaks="1 hour") + theme(legend.position='top') + ylim(minElevation, maxElevation) + xlab('Time of day') + ylab("Elevation [m]") + scale_fill_manual(values=c('#FDC086', '#386CB0', '#F0027F', '#BEAED4', '#386CB0', '#7FC97F'))
    # better here
    # ggplot(plotData, aes(x=time_stamp, y=mean_altitude)) + geom_point(aes(colour=class, shape=class, size=mtr)) + scale_colour_manual(values=colourDot) + scale_shape_manual(values=shapeDot) + scale_alpha_continuous(plotData$mtr) + scale_size_area(breaks=breaksDotSize, max_size=maxDotSize) 
    ## here we plot
    plt <- ggplot(plotData, aes(x=time_stamp, y=mean_altitude))
    # first draw masks for day and night, add as annotations as per https://stackoverflow.com/questions/17521438/geom-rect-and-alpha-does-this-work-with-hard-coded-values
    plt <- plt + annotate("rect", xmin=timeDuskBefore, xmax=timeDawn, ymin=0, ymax=+Inf, alpha=nightAlpha, fill=nightColor, show.legend=FALSE) + annotate('rect', xmin=timeDusk, xmax=maxTimeStamp, ymin=0, ymax=+Inf, alpha=nightAlpha, fill=nightColor, show.legend=FALSE)
    # add blind time, color is #5F0202
    blindYmin <- input$elevation[2] - ((input$elevation[2] - input$elevation[1]) * 0.025) # 2.5% plot height
    # blindYmin <- max(plotData$to_altitude) - ((min(plotData$from_altitude) - max(plotData$to_altitude)) * 0.025)
    blindData <- plotData[plotData$is_blind==TRUE,]
    plt <- plt + geom_rect(data=blindData, aes(xmin=time_start, xmax=time_stop, ymin=blindYmin, ymax=Inf, fill=blindColor, alpha=blindAlpha)) + scale_fill_manual('Blind time', values=blindColor) 
    # add actual data
    #plt <- plt + geom_point(aes(colour=class, shape=class, size=mtr)) + scale_colour_manual(values=colourDot) + scale_shape_manual(values=shapeDot) + scale_alpha_continuous(plotData$mtr) + scale_size_area(breaks=breaksDotSize, max_size=maxDotSize) 
    plt <- plt + geom_point(aes(colour=class, shape=class, size=mtr)) + colorScale + shapeScale + scale_alpha_continuous(plotData$mtr) + scale_size_area(breaks=breaksDotSize, max_size=maxDotSize) 
    # finish up (legend, labels, etc.)
    plt <- plt + scale_x_datetime(labels=date_format("%H:%M", tz=timeZone), date_breaks="1 hour") + theme(legend.position='top') + ylim(input$elevation[1], input$elevation[2]) +  guides(colour=guide_legend(override.aes=list(size=5))) + xlab('Time of day') + ylab("Elevation [m]")
    plt
    #ggplot(plotData, aes(x=time_stamp, y=mean_altitude, colour=fill)) + geom_rect(aes(xmin=timeDuskBefore, xmax=timeDawn, ymin=0, ymax=+Inf), alpha=.5, fill='lightgray', inherit.aes=FALSE) + geom_rect(aes(xmin=timeDusk, xmax=maxTimeStamp, ymin=0, ymax=+Inf), alpha=.5, fill='lightgray', inherit.aes=FALSE) + geom_count() + scale_x_datetime(labels=date_format("%H:%M", tz=timeZone), date_breaks="1 hour") + theme(legend.position='top') + ylim(input$elevation[1], input$elevation[2]) + xlab('Time of day') + ylab("Elevation [m]")
  })
}


# run the app locally
shinyApp(ui=ui, server=server)

## Not Run:
# to run as to be seen from local (LAN) clients:
#runApp('scripts/app timeplot MTR.R', host="0.0.0.0", port=9999)
