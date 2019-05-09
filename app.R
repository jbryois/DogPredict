# Load library
library(shiny)
library(miniUI)
library(reticulate)
library(ggplot2)

# Restrict image size to 10 MB per file
options(shiny.maxRequestSize=10*1024^2)

# Create python environment with necessary packages
# Run two first lines then comment them (to avoid creating the environment each time)
# Make sure that the path is linked to python3

#reticulate::virtualenv_create(envname = "DogPredict", python= "/anaconda3/bin/python")
#reticulate::virtualenv_install("DogPredict", packages = c('torchvision','fastai'))
reticulate::use_virtualenv("DogPredict", required = TRUE)

#Load python prediction module (resnet50 fine tuned model)
source_python("Code/predict.py")

###########################################################
##############        User interface         ############## 
###########################################################

ui <- miniPage(
  gadgetTitleBar(
    left = NULL, 
    right = NULL,
    "Dog Breed Prediction"
  ),
  
  miniTabstripPanel(
    
    # Information tab
    miniTabPanel(
      "Information", icon = icon("info"),
      miniContentPanel(
        htmlOutput("info")
      )
    ),
    
    # Take picture tab (with some css code to display the input image)
    miniTabPanel(
      "Take Picture", icon = icon("camera"),
      tags$head(tags$style(
        type="text/css",
        "#inputImage img {max-width: 50%; width: 50%; height: auto}"
      )),
      miniContentPanel(
        fileInput('file1', 'Choose an image (max 10MB)'),
        imageOutput("inputImage")
      )
    ),
    
    # Prediction tab
    miniTabPanel(
      "Prediction", icon = icon("chart-line"),
      miniContentPanel(
        plotOutput("barplot")
      )
    )
    
  )
)

###########################################################
##############            Server             ############## 
###########################################################

server <- function(input, output, session) {
  
  #Reactive function processing image
  ProcessImage <- reactive({
    
    progress <- Progress$new(session, min=1, max=15)
    on.exit(progress$close())
    
    progress$set(
      message = 'in progress', 
      detail = 'This may take a few seconds...'
    )
    
    inFile = input$file1
    req(inFile)
    imgfile = inFile$datapath
    DogBreedPred(imgfile)
  })
  
  
  ###########################################################
  ##############        Display elements       ############## 
  ###########################################################
  
  #Intro
  output$info <- renderUI({
    list(
      h4("This app predicts the breed of a dog based on a picture."),
      h4("A total of 120 different breeds can be predicted."),
      h4(strong("Take a picture on the next tab to predict your dog breed!",align="center")), 
      img(SRC="all_species.jpg", height = 340),
      h5("Code on ",  tags$a(href="https://github.com/jbryois/DogBreeds", "GitHub", target="_blank")),
      h5("By Julien Bryois")
    )
  })
  
  
  #Display image if there is an input image
  output$inputImage <- renderImage({
    req(input$file1)
    list(src = input$file1$datapath)
  },
  deleteFile = FALSE
  )
  
  #Display the prediction of the top 5 breeds as a barplot
  output$barplot <- renderPlot({
    req(ProcessImage())
    d <- ProcessImage()
    ggplot(d,aes(reorder(Breed,Prob),Prob, fill=Breed)) + geom_bar(stat='identity') + coord_flip() +
      xlab('') + ylab('Probability') + 
      theme_light() + theme(legend.position = 'none') + theme(text=element_text(size=24))
  })
}

#Shiny app call
shinyApp(ui, server)