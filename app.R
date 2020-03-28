library(shiny)
library(rvest)
library(DT)

webpage <- read_html("https://virihealth.com/full-details/")

# Table 2. Cases in Canada
Table2 <- webpage %>%
  html_nodes("table") %>%
  .[[2]] %>%
  html_table(fill = TRUE)

#Fix Date field
Table2$Date2 <- as.Date(paste0(Table2$Date,"-","2020"),"%d-%b-%Y")

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
      
      width = 3),
    # Main panel for displaying outputs ----
    mainPanel(
      
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
    rows <- (Table2$Date2 >= input$dateRange[1] & Table2$Date2 <= input$dateRange[2])
    Table2[rows,,drop = FALSE] 
    
  })
    
  observe({
    output$table <- renderDataTable(filtered()
      ,options = list(pageLength = 10,columnDefs = list(list(
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
}

# Create Shiny object
shinyApp(ui = ui, server = server)