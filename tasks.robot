*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.Excel.Files
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             Collections
Library             RPA.Dialogs
#Library    RPA.Robocloud.Secrets
Library             OperatingSystem
Library             RPA.RobotLogListener


*** Variables ***
${url}              https://robotsparebinindustries.com/#/robot-order
${img_folder}       ${CURDIR}${/}image_files
${pdf_folder}       ${CURDIR}${/}pdf_files
${output_folder}    ${CURDIR}${/}output
${orders_file}      ${CURDIR}${/}orders.csv
${zip_file}         ${output_folder}${/}pdf_archive.zip
${csv_url}          https://robotsparebinindustries.com/orders.csv


*** Tasks ***
Order robots from RobotSpareBin Industries Inc.
    Open the robot orders application
#    Login to robot orders application
    Download orders file
    Fill the form using orders data from csv file
    Read order details from csv file
    Close the annoying modal
    Directory Cleanup
    Log out from app and close the browser
    Create a Zip File of the Receipts



*** Keywords ***
Directory Cleanup
    Log To console    Cleaning up content from previous test runs
    # The archive command will not create this automatically so we need to ensure that the directory is there
    # Create Directory will not give us an error if the directory already exists.
    Create Directory    ${output_folder}
    Create Directory    ${img_folder}
    Create Directory    ${pdf_folder}
#    Empty Directory    ${output_folder}
    Empty Directory    ${img_folder}
#    Empty Directory    ${pdf_folder}

Open the robot orders application
    Close Browser
    Open Available Browser    ${url}
    Maximize Browser Window
#    Wait Until Page Contains Element    id:username

#Login to robot orders application
#    Input Text    username    maria
#    Input Password    password    thoushallnotpass
#    Submit Form
#    Wait Until Page Contains Element    id:sales-form

Download orders file
    Download    url=${csv_url}    target_file=${orders_file}    overwrite=True

Read order details from csv file
    ${sales_orders_table}=    Read table from CSV    path=${orders_file}
    Log    ${sales_orders_table}
    RETURN    ${sales_orders_table}

Fill the form using orders data from csv file
    ${sales_orders}=    Read order details from csv file
    FOR    ${sales_order}    IN    @{sales_orders}
        Close the annoying modal
        Create robot order    ${sales_order}
        Wait Until Keyword Succeeds    10x    2s    Preview the robot
        Wait Until Keyword Succeeds    10x    2s    Submit The Order
        ${orderid}    ${img_filename}=    Take a screenshot of the robot
        ${pdf_filename}=    Store the receipt as a PDF file    ORDER_NUMBER=${order_id}
        Embed the robot screenshot to the receipt PDF file    IMG_FILE=${img_filename}    PDF_FILE=${pdf_filename}
        Create order for order another robot
    END

Close the annoying modal
    # Define local variables for the UI elements
    Set Local Variable
    ...    ${btn_yep}
    ...    //div[@class='modal-dialog']//div[@class='alert-buttons']//button[@class='btn btn-warning'][text()='Yep']
    Wait And Click Button    ${btn_yep}

Create robot order
    [Arguments]    ${sales_order}
    #Define local variables for to store the order details
    Set Local Variable    ${order_no}    ${sales_order}[Order number]
    Set Local Variable    ${head}    ${sales_order}[Head]
    Set Local Variable    ${body}    ${sales_order}[Body]
    Set Local Variable    ${legs}    ${sales_order}[Legs]
    Set Local Variable    ${address}    ${sales_order}[Address]

    #Define local variables for the UI elements(XPath)
    Set Local Variable    ${input_head}    //*[@id="head"]
    Set Local Variable    ${input_body}    body
    Set Local Variable
    ...    ${input_legs}
    ...    xpath://input[@class='form-control'][@placeholder='Enter the part number for the legs']
    Set Local Variable    ${input_address}    //*[@id="address"]
    Set Local Variable    ${btn_preview}    //*[@id="preview"]
    Set Local Variable    ${btn_order}    //*[@id="order"]
    Set Local Variable    ${img_preview}    //*[@id="robot-preview-image"]

    #fill the order details
    Wait Until Element Is Visible    ${input_head}
    Wait Until Element Is Enabled    ${input_head}
    Select From List By Value    ${input_head}    ${head}
    Wait Until Element Is Enabled    ${input_body}
    Select Radio Button    ${input_body}    ${body}
    Wait Until Element Is Enabled    ${input_legs}
    Input Text    ${input_legs}    ${legs}
    Wait Until Element Is Enabled    ${input_address}
    Input Text    ${input_address}    ${address}

Preview the robot
    # Define local variables for the UI elements
    Set Local Variable    ${btn_preview}    //*[@id="preview"]
    Set Local Variable    ${img_preview}    //*[@id="robot-preview-image"]
    Click Button    ${btn_preview}
    Wait Until Element Is Visible    ${img_preview}

Submit the order
    # Define local variables for the UI elements
    Set Local Variable    ${btn_order}    //*[@id="order"]
    Set Local Variable    ${lbl_receipt}    //*[@id="receipt"]
    #Do not generate screenshots if the test fails
    Mute Run On Failure    Page Should Contain Element
    # Submit the order. If we have a receipt, then all is well
    Click button    ${btn_order}
    Page Should Contain Element    ${lbl_receipt}

Take a screenshot of the robot
    # Define local variables for the UI elements
    Set Local Variable    ${lbl_orderid}    xpath://div[@id='receipt']/p[@class='badge badge-success']
    Set Local Variable    ${img_robot}    //*[@id="robot-preview-image"]
    Wait Until Element Is Visible    ${img_robot}
    Wait Until Element Is Visible    ${lbl_orderid}
    #get the order ID
    ${orderid}=    Get Text    ${lbl_orderid}
    # Create the File Name
    Set Local Variable    ${order_success_img_filename}    ${img_folder}${/}${orderid}.png
    Sleep    1sec
    Log To Console    Capturing Screenshot to ${order_success_img_filename}
    Capture Element Screenshot    ${img_robot}    ${order_success_img_filename}
    RETURN    ${orderid}    ${order_success_img_filename}

Store the receipt as a PDF file
    [Arguments]    ${ORDER_NUMBER}
    Set Local Variable    ${order_receipt}    //*[@id="receipt"]
    Wait Until Element Is Visible    ${order_receipt}
    Log To Console    Printing ${ORDER_NUMBER}
    ${order_receipt_html}=    Get Element Attribute    ${order_receipt}    outerHTML
    Set Local Variable    ${order_success_pdf_filename}    ${pdf_folder}${/}${ORDER_NUMBER}.pdf
    Html To Pdf    content=${order_receipt_html}    output_path=${order_success_pdf_filename}
    RETURN    ${order_success_pdf_filename}

Create order for order another robot
    # Define local variables for the UI elements
    Set Local Variable    ${btn_order_another_robot}    //*[@id="order-another"]
    Click Button    ${btn_order_another_robot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${IMG_FILE}    ${PDF_FILE}
    Log To Console    Printing Embedding image ${IMG_FILE} in pdf file ${PDF_FILE}
    Open Pdf    ${PDF_FILE}
    @{myfiles}=    Create List    ${IMG_FILE}:x=0,y=0
    Add Files To PDF    ${myfiles}    ${PDF_FILE}    ${True}
#    Save Pdf    ${PDF_FILE}    PyPDF2
    Sleep    5s
#    Close Pdf ${PDF_FILE}

Log out from app and close the browser
#    Click Button    Log out
    Close Browser

Create a Zip File of the Receipts
    Archive Folder With ZIP    ${pdf_folder}    ${zip_file}    recursive=True    include=*.pdf
