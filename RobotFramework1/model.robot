*** Keywords ***
for loop
    [Arguments]    ${times}
    :FOR    ${i}    IN RANGE    ${times}
    \    log    ${i}
