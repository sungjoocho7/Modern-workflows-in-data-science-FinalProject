# Libaray
library(broom)
library(shiny)
library(tidyverse)
library(ggplot2)
library(plotly)
library(shinydashboard)


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

par(mfrow=c(2,2))
FemalePlot(evs, child_suffer)
MalePlot(evs, child_suffer)


# function for the regression model

# 1. Regression model table
RegTable <- function(data, y_var, age_poly = 1, sex = FALSE, edu = FALSE) {
  
  data <- data %>%
    na.omit()
  
  # regression formula
  reg_formula <- paste0(deparse(substitute(y_var)), " ~ poly(age, ", age_poly, ", raw =TRUE)")
  
  if (sex) {
    reg_formula <- paste0(reg_formula, " + sex")
  }
  
  if (edu) {
    reg_formula <- paste0(reg_formula, " + edu")
  }
  
  # regression model
  print(reg_formula)
  reg_model <- lm(reg_formula, data = data)
  tidy(reg_model)
}

# Example usage
RegTable(data = evs, y_var = child_suffer, age_poly = 5, sex = TRUE, edu = TRUE)





# Shiny --------------------------------------------------------

cntrys <- evs$cntry %>% unique()
intro_text <- list(This is an app)


# Shiny --------------------------------------------------------

ui <- dashboardPage(
  
  ## Header ##
  dashboardHeader(title = "European Value Study (EVS)"),
  
  ## Sidebar ##
  dashboardSidebar(
    
    selectInput("country", 
                "Country:", 
                choices = cntrys),
    
    radioButtons("outcome", 
                 "Outcome variable:",
                 choiceNames = c("child_suffer", "job_national"),
                 choiceValues = c("child_suffer", "job_national")),
    
    checkboxGroupInput("controls", 
                       "Countrols:",
                       choiceNames = c("sex", "education"),
                       choiceValues = c("sex", "educ")),
    
    sliderInput("polynomial",
                "Age polynomial:",
                value = 1, min = 1, max = 5)
    ),
  
  ## Dashboard Body ##
  dashboardBody(
    
    tabItems(
      
      # First tab (Overview)
      tabItem(
        tabName = "Overview",
        h2("Overview of the Application"),
        h3("Introduction"),
        h4("This is the application"),
        h3("Section Information"),
        h4("The application is structured around three main tabs.")
      ),
      
      
      # Second tab (Exploration)
      tabItem(
        tabName = "Exploration",
        h1("Exploration")
      ),
      
      
      # Third tab (Regression)
      tabItem(
        tabName = "Regression",
        h1("Regression")
      )
    )
  )
  )


server <- function(input, output, session) {
  
}

shinyApp(ui, server) 


  














