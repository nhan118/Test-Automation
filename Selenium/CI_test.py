# !/usr/bin/env python3
# -*- coding: utf-8 -*-
from selenium import webdriver
import time

base_url = "http://192.168.1.13:8088/jenkins"
driver = webdriver.Chrome()
driver.get(base_url)
time.sleep(2)
driver.maximize_window()
newman = driver.find_element_by_link_text("Newman")
time.sleep(3)
newman.click()
time.sleep(3)
# build = driver.find_element_by_xpath(".//*[@id='job_Newman_Test']/td[7]/a/img")
# print(build)
# build.click()
time.sleep(3)
driver.quit()
