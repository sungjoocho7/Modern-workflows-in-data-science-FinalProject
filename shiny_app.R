# Libaray
library(broom)
library(shiny)
library(tidyverse)
library(ggplot2)
library(plotly)
library(shinydashboard)
library(haven)
library(DT) 
library(knitr)


# import data
evs <- readRDS("data/evs.rds")

# Functions --------------------------------------------------------


# function for graph (country, 3 graphs, input: outcome variable)

# 1. Plot for Female
FemalePlot <- function(data, y_var){
  
  # filter female data
  data_female <- data %>%
    filter(sex == "Female") %>%
    na.omit()
  
  # plot
  plot <- data_female %>%
    ggplot(aes(x = age, y = {{y_var}}, color = edu)) +
    stat_summary(geom = "line", fun = "mean") +
    labs(title = "Average disagreement of job_national by age (Female)",
         x = "Age",
         y = "Average Disagreement") 
    
  return(plot)
}

FemalePlot(evs, child_suffer)


# 2. Plot for Male
MalePlot <- function(data, y_var){
  
  # filter female data
  data_female <- data %>%
    filter(sex == "Male") %>%
    na.omit()
  
  # plot
  plot <- data_female %>%
    ggplot(aes(x = age, y = {{y_var}}, color = edu)) +
    stat_summary(geom = "line", fun = "mean") +
    labs(title = "Average disagreement of job_national by age (Female)",
         x = "Age",
         y = "Average Disagreement") 
  
  return(plot)
}



# 3. Plot
ExplorationPlot <- function(data, y_var){
  
  # filter data
  data <- data %>%
    na.omit()
  
  # plot
  plot <- data %>%
    ggplot(aes(x = age, y = !!as.name(y_var), color = interaction(edu, sex))) +  
    stat_summary(geom = "line", fun = "mean") +
    labs(title = "Average disagreement of job_national by age",
         x = "Age",
         y = "Average Disagreement") 
  
  return(plot)
}


ExplorationPlot(evs, "child_suffer")



# function for the regression model

# 1. Regression model table
RegTable <- function(data, y_var, age_poly = 1, sex = FALSE, edu = FALSE) {
  
  data <- data %>%
    na.omit()
  
  # regression formula
  reg_formula <- paste0(y_var, " ~ poly(age, ", age_poly, ", raw =TRUE)")
  
  if (sex) {
    reg_formula <- paste0(reg_formula, " + sex")
  }
  
  if (edu) {
    reg_formula <- paste0(reg_formula, " + edu")
  }
  
  # regression model
  reg_model <- lm(reg_formula, data = data)
  as.data.frame((tidy(reg_model)))
}

RegTable(evs, "child_suffer", age_poly = 2, sex=TRUE, edu=FALSE)



# 2. Regression model scatter plot
RegScatterPlot <- function(data, y_var, age_poly = 1, sex = FALSE, edu = FALSE) {
  
  data <- data %>%
    na.omit()
  
  # regression formula
  reg_formula <- paste0(y_var, " ~ poly(age, ", age_poly, ", raw =TRUE)")
  
  if (sex) {
    reg_formula <- paste0(reg_formula, " + sex")
  }
  
  if (edu) {
    reg_formula <- paste0(reg_formula, " + edu")
  }
  
  # regression model
  reg_model <- lm(reg_formula, data = data)
  
  # Obtain the residuals and predicted values
  residuals <- residuals(reg_model)
  predicted <- fitted(reg_model)
  
  # Create a data frame with predicted and residuals
  plot_data <- data.frame(Predicted = predicted, Residuals = residuals)
  
  # Create a scatter plot using ggplot
  ggplot(plot_data, aes(x = Predicted, y = Residuals)) +
    geom_point() +
    labs(x = "Predicted Values", y = "Residuals",
         title = "Scatter Plot of Predicted vs. Residuals")
}

RegScatterPlot(evs, "job_national", age_poly = 1, sex=TRUE, edu=TRUE)


mod <- lm(child_suffer ~ age + age^2 + sex, data = evs)
summary(mod)
res <- resid(mod)
plot(fitted(mod), res)









# Shiny --------------------------------------------------------

cntrys <- evs$cntry %>% unique()


# Shiny --------------------------------------------------------

ui <- dashboardPage(
  
  ## Header ##
  dashboardHeader(title = "European Value Study (EVS)"),
  
  ## Sidebar ##
  dashboardSidebar(
    
    # input
    selectInput("country", 
                "Country:", 
                choices = c("overall", cntrys),
                selected = "overall"),
    
    radioButtons("outcome", 
                 "Outcome variable:",
                 choiceNames = c("child_suffer", "job_national"),
                 choiceValues = c("child_suffer", "job_national")),
    
    checkboxGroupInput("controls", 
                       "Choose the predictor(s):",
                       choiceNames = c("sex", "edu"),
                       choiceValues = c("sex", "edu")),
    
    sliderInput("polynomial",
                "Age polynomial:",
                value = 1, min = 1, max = 5),
    
    # sidebar menu
    sidebarMenu(
      menuItem("Overview", tabName = "Overview", icon = icon("dashboard")),
      menuItem("Exploration", tabName = "Exploration", icon = icon("chart-simple")),
      menuItem("Regression", tabName = "Regression", icon = icon("database"))
      ),
    
    
    # download
    downloadButton("report", "Generate report")
    ),
  
  
  
  ## Dashboard Body ##
  dashboardBody(
    
    tabItems(
      
      # First tab (Overview)
      tabItem(
        tabName = "Overview",
        h2("Overview of the Application"),
        h3("Introduction"),
        h4("This application is designed to analyze data sourced from the European Value Study (EVS). Users can explore attitudes towards gender roles and immigration. Analysis of the overall data with the entire sample, as well as on a country-by-country basis, is available by using the country drop-down menu located in the sidebar"),
        
        h3("Section Information"),
        h4("The application is structured around four main tabs: Overview, Exploration, and Regression. These tabs are easily accessible through the sidebar menu. Users can choose the outcome variable in the sidebar menu under the 'Outcome variable' section."),
        tags$ul(
          style = "font-size: 18px; list-style-type: disc",
          tags$li("The 'Exploration' section provides a graph describing the selected outcome variable with three predictors age, education, and sex."),
          tags$li("The 'Regression' section provides a table showing the regression coefficients and a scatter plot illustrating the predicted versus the residuals from the regression model. By default, age is the main predictor. Users can choose additional predictors (sex and education), and also adjust the polynomial value of age from 1 to 5 in the sidebar menu.")
          )
      ),
      
      
      # Second tab (Exploration)
      tabItem(
        tabName = "Exploration",
        h1("Exploration"),
        h3(uiOutput("selected_country_exploration")),
        
        fluidPage(
          h4(textOutput("exploration_description")),
          plotlyOutput("exploration_plot")
        )
      ),
      
      
      # Third tab (Regression)
      tabItem(
        tabName = "Regression",
        h1("The regression model"),
        h3(uiOutput("selected_country_regression")),
        
        fluidPage(
          h4(textOutput("regression_tab_description")),
          dataTableOutput("reg_table"),
          h4(textOutput("regression_plot_description")),
          plotlyOutput("reg_plot")
        )
      )
    )
  )
  )


server <- function(input, output, session) {
  
  # make a country data
  data <- reactive({
    if (input$country == "overall") {
      return(evs)
    } else {
      return(evs[evs$cntry == input$country, ])
    }
  })
  
  # selected country
  output$selected_country_exploration <- renderText({input$country})
  output$selected_country_regression <- renderText({input$country})
  
  # exploration description
  output$exploration_description <- renderText({
    paste("The graph for", input$outcome, "and the three controls: age, education, and sex:")})
  
  # regression table description
  output$regression_tab_description <- renderText({
    paste0("The regression model for ", input$outcome, ":")
  })
  
  # regression scatter plot description
  output$regression_plot_description <- renderText({
    paste0("The scatter plot showing the predicted versus the residuals from the regression model for ", input$outcome, ":")
  })

  
  # ExplorationPlot (Second section)
  output$exploration_plot <- renderPlotly({
    req(data())
    ExplorationPlot(data(), input$outcome)
  })
  
  
  # RegTable (Third section)
  output$reg_table  <- renderDataTable({
    req(data())
    if ("sex" %in% input$controls) {
      s <- TRUE
    } else {
      s <- FALSE
    }
    
    if ("edu" %in% input$controls) {
      e <- TRUE
    } else {
      e <- FALSE
    }
    RegTable(data(), input$outcome, input$polynomial, s, e)
  })
  
  
  
  # RegScatterPlot (Third section)
  output$reg_plot <- renderPlotly({
    req(data())
    req(data())
    if ("sex" %in% input$controls) {
      s <- TRUE
    } else {
      s <- FALSE
    }
    
    if ("edu" %in% input$controls) {
      e <- TRUE
    } else {
      e <- FALSE
    }
    RegScatterPlot(data(), input$outcome, input$polynomial, s, e)
  })
  
  
  
  # download
  output$report <- downloadHandler(
    filename = ("evs_report.html"),
    
    content = function(file) {
      tempReport <- file.path("report.Rmd")
      file.copy(tempReport, file, overwrite = TRUE)
      
      # set up parameters to pass to Rmd document
      params <- list(
        country = input$country,
        outcome = input$outcome,
        controls = input$controls,
        polynomial = input$polynomial
      )
      
      # knit the document, passing in the 'params' list
      rmarkdown::render(tempReport, output_file = file,
                        params = params,
                        envir = new.env(parent = globalenv()))
    }
  )
}

shinyApp(ui, server) 

