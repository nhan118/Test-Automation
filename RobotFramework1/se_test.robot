*** Settings ***
Library           SeleniumLibrary

*** Test Cases ***
baidu
    ${binary}=    Create Dictionary    binary=D:\\Program Files (x86)\\Opera\\52.0.2871.99\\opera.exe
    ${desired_caps}=    Create Dictionary    operaOptions=${binary}
    log    ${desired_caps}
    Open Browser    https://www.baidu.com    opera    desired_capabilities=${desired_caps}
    Input Text    id=kw    selenium
    Click Button    id=su
    sleep    3
    close browser
