library(shiny)
library(rvest)
library(DT)
library(leaflet)
library(geojsonio)
library(tigris)
library(ggplot2)
library(plotly)

webpage <- read_html("https://virihealth.com/full-details/")

# Table 2. Cases in Canada
Table2 <- webpage %>%
  html_nodes("table") %>%
  .[[2]] %>%
  html_table(fill = TRUE)

#Fix Date field
Table2$Date2 <- as.Date(paste0(Table2$Date,"-","2020"),"%d-%b-%Y")

# Read in Provinces data
provinces <- geojsonio::geojson_read("canada.geojson", what = "sp")

# Define UI for app that creates a dashboard ----
ui <- fluidPage(
  
  # App title ----
  titlePanel("Covid Cases in Canada"),
  HTML("<h5>Created by <a href=\'https://shafquatarefeen.com/\'>Shafquat Arefeen</a></h5><br>"),
  
  
  # Sidebar layout with input and output definitions ----
  sidebarLayout(
    
    # Sidebar panel for inputs ----
    sidebarPanel(
      
      
      # Input: Select a Date Range ----
      dateRangeInput("dateRange", 
                     "Select date range:",
                     start = as.Date('2020-01-25'),
                     #end = as.Date('2020-01-30')
                     ),
      # Input: Select Province ----
      selectInput(inputId = "s_prov", "Select Province", choices=c("All", sort(unique(as.character(Table2$Prov))))),
      
      width = 3),
    # Main panel for displaying outputs ----
    mainPanel(
      # Canadian Provinces
      leafletOutput("mymap", height=400),
      plotlyOutput("bar",height = 600),
      
      # Let user know of mapping restriction ----
      h5("Data from Virihealth"),     
      # Output: Table of Work Done ----
      dataTableOutput('table')
      
      
    )
  )
)


# Define server logic required to have an interactive dashboard ----
server <- function(input, output, session) {
  
  filtered <- reactive({
    rows <- (Table2$Date2 >= input$dateRange[1] & Table2$Date2 <= input$dateRange[2]) &
      (input$s_prov == "All" | Table2$Prov==input$s_prov)
    Table2[rows,,drop = FALSE] 
    
    
  })
    
  observe({
    
    outputtable1 <- filtered()[,c("Prov#","Date2","Prov","Health Region","Sex","Age","Source","Details")]
    colnames(outputtable1) <- c("ID#","Date","Province","Health Region","Sex","Age","Source","Details")
    
    
    output$table <- renderDataTable(filtered()
      ,options = list(pageLength = 5,columnDefs = list(list(
        targets = 8, 
        render = JS(
          "function(data, type, row, meta) {",
          "return type === 'display' && data.length > 20 ?",
          "'<span title=\"' + data + '\">' + data.substr(0, 20) + '...</span>' : data;",
          "}")
      ))), callback = JS('table.page(3).draw(false);')
      #options = list(pageLength = 5, width="100%", scrollX = TRUE)
      , rownames= FALSE
    )
  })

  observe({
    output$bar <- renderPlotly({
      H_R <- data.frame(table(filtered()$`Health Region`))
      
      ggplot(H_R, aes(Var1,Freq))+
        geom_bar(stat="identity", color="blue", fill="white") +
        labs(x = "Health Region", y = "Number of Cases") +
        theme(axis.text.x = element_text(angle=90)
        )
    })
    #   renderPlot({
    #   # Groupby("HR").count()
    #   H_R <- data.frame(table(filtered()$`Health Region`))
    # 
    #   barplot(H_R$Freq, main="Number of Cases by Health Region",
    #           xlab="Health Region")
    # })
  })
    
  observe({
    pal <- colorNumeric("viridis", NULL,reverse=TRUE)
    # Groupby("Prov").count()
    prov_count <- data.frame(table(filtered()$Prov))
    #merge shapefile and dataframe
    m <- geo_join(provinces,prov_count,by_sp='abbr',by_df='Var1',how="left")
    
    output$mymap <- renderLeaflet({
      leaflet(m) %>%
        addTiles() %>%
        addPolygons(stroke = FALSE, smoothFactor = 0.3, fillOpacity = 1
                   ,fillColor = ~pal(Freq)
                     ,label = ~paste0(abbr, ": ", formatC(Freq, big.mark = ","))) %>%
                    addLegend(pal = pal, values = ~Freq, opacity = 0.8,
                   labFormat = labelFormat(transform = function(x) sort(x)))
    })
  })
}

# Create Shiny object
shinyApp(ui = ui, server = server)