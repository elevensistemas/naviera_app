@echo off
set "CHROME=C:\Program Files\Google\Chrome\Application\chrome.exe"
if exist "%CHROME%" (
    start "" "%CHROME%" --disable-web-security --ignore-certificate-errors --user-data-dir="C:\tmp\chrome_dev_cors" "http://127.0.0.1:8085" "https://127.0.0.1:2223"
) else (
    start "" "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" --disable-web-security --ignore-certificate-errors --user-data-dir="C:\tmp\edge_dev_cors" "http://127.0.0.1:8085" "https://127.0.0.1:2223"
)
