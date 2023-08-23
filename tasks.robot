*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.FileSystem


*** Variables ***
${GLOBAL_RETRY_AMOUNT}      3x
${GLOBAL_RETRY_INTERVAL}    1s


*** Tasks ***
Orders robots from RobotSpareBin Industries Inc
    Open the robot order website
    Close the annoying modal
    Download CSV from HTTP server and Get Orders As Table


*** Keywords ***
Open the robot order website
    [Documentation]    Open the website to order robot
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Close the annoying modal
    Click Button    OK

Download CSV from HTTP server and Get Orders as Table
    Download
    ...    https://robotsparebinindustries.com/orders.csv
    ...    overwrite=True
    ...    target_file=${OUTPUT_DIR}${/}orders.csv
    ${orders}=    Get Orders    ${OUTPUT_DIR}${/}orders.csv
    FOR    ${order}    IN    @{orders}
        Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}    Create Order    ${order}
    END
    Create a ZIP file of receipt PDF files

Create a ZIP file of receipt PDF files
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${OUTPUT_DIR}${/}PDFs.zip
    Remove Directory    ${OUTPUT_DIR}${/}receipts    ${True}
    Remove Directory    ${OUTPUT_DIR}${/}images    ${True}

Get Orders
    [Documentation]    Read the data from CSV and return it as Table
    [Arguments]    ${file}
    ${orders_table}=    Read table from CSV    ${file}
    RETURN    ${orders_table}

Create Order
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath=//input[@type='number']    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Button    preview
    Click Button    order
    Assert Page Contains Element    order-another
    ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
    ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
    Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
    Click Button    order-another
    Close the annoying modal

Assert Page Contains Element
    [Arguments]    ${locator}
    Wait Until Page Contains Element    ${locator}

Store the receipt as a PDF file
    [Arguments]    ${file_name}
    ${order_receipt_html}=    Get Element Attribute    receipt    outerHTML
    Html To Pdf    ${order_receipt_html}    ${OUTPUT_DIR}${/}receipts${/}${file_name}.pdf
    RETURN    ${OUTPUT_DIR}${/}receipts${/}${file_name}.pdf

Take a screenshot of the robot
    [Arguments]    ${file_name}
    Screenshot    robot-preview-image    ${OUTPUT_DIR}${/}images${/}${file_name}.png
    RETURN    ${OUTPUT_DIR}${/}images${/}${file_name}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${opened_pdf}=    Open Pdf    ${pdf}
    ${image}=    Create List    ${pdf}    ${screenshot}
    Add Files To Pdf    ${image}    ${pdf}
    Close Pdf    ${opened_pdf}
