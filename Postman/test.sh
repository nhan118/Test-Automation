newman run ./postman/demo.postman_collection.json -e ./postman/test.postman_environment.json -r cli,html --reporter-html-export ./report/report.html
sleep 3
newman run ./postman/demo.postman_collection1.json -e ./postman/test.postman_environment.json -r cli,html --reporter-html-export ./report/report1.html
sleep 3
newman run ./postman/demo.postman_collection2.json -e ./postman/test.postman_environment.json -r cli,html --reporter-html-export ./report/report2.html
