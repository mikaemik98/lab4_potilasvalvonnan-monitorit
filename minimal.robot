*** Settings ***
Library           CustomSerialLibrary.py    COM3    115200

*** Test Cases ***
Interact with Pro Sim 8
    [Teardown]    Close Serial
    ${ok}=    Initialize Serial
    Should Be True    ${ok}    Sarjayhteys ei aukea: tarkista COM-portti ja kaapeli
    ${response}=    Send Command    REMOTE
    Log    Response: ${response}
    Should Be Equal As Strings    ${response}    RMAIN
    ${response}=    Send Command    QMODE
    Log    Response: ${response}
    Should Be Equal As Strings    ${response}    RMAIN
    ${response}=    Send Command    LOCAL
    Log    Response: ${response}
    Should Be Equal As Strings    ${response}    LOCAL