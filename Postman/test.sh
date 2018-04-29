newman run demo.postman_collection.json -e test.postman_environment.json -r cli,junit --reporter-junit-export ./report/report.xml
sleep 3
newman run demo.postman_collection1.json -e test.postman_environment.json -r cli,junit --reporter-junit-export ./report/report1.xml
sleep 3
newman run demo.postman_collection2.json -e test.postman_environment.json -r cli,junit --reporter-junit-export ./report/report2.xml
