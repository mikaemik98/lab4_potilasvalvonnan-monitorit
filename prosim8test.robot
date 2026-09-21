*** Settings ***
Library  CustomSerialLibrary.py  COM10  115200

*** Test Cases ***
Interact with Pro Sim 8
    initialize_serial
    ${response}=  send_command  REMOTE
    Log    Response from Pro Sim 8 Simulator: ${response}
    Should Be Equal As Strings      ${response}   RMAIN

    ${NSRA}=  send_command  NSRA=100
    Log    Response from Pro Sim 8 Simulator: ${NSRA}
    Should Be Equal As Strings      ${NSRA}   *

    ${NSRA}=  send_command  TEMP=41.0
    Log    Response from Pro Sim 8 Simulator: ${NSRA}
    Should Be Equal As Strings      ${NSRA}   *

    close_serial


