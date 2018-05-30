*** Settings ***
Library           ../../Python27/Lib/site-packages/robot/libraries/Screenshot.py

*** Test Cases ***
test_case
    log    hello robot framework

test_case2
    log    this is second test case

Variable
    ${a}    Set Variable    hello world
    log     ${a}

List
    ${abc}    Create List    a    b    c
    log     ${abc}

Catenate
    ${hi}    Catenate    hello    world
    log    ${hi}

time
    ${t}    get time
    log     ${t}
    sleep    5
    ${t}    get time
    log     ${t}

if
    ${a}    Set variable    90
    run keyword if    ${a}>=90    log     优秀
    ...    ELSE IF    ${a}>=70    log    良好
    ...    ELSE IF    ${a}>=60    log    及格
    ...    ELSE    log    不及格

for
    :FOR    ${i}    IN RANGE     10
    \    log    ${i}

evaluate
    ${i}    Evaluate    random.randint(1000,9999)    random
    log    ${i}

time_py
    ${t}    Evaluate    time.ctime()    time
    log    ${t}
