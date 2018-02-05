#!/usr/bin/env python
#coding=utf-8
'''
解析gh_station_info.json
读取STATION_ID,SFC_URL的值
input: None
output: ON/OFF
'''
import json
import os
from calHandler import Calculator

class ALS(Calculator):
	def method(self, sn):
		jsonPath = "/vault/data_collection/test_station_config/gh_station_info.json"
		f = file(jsonPath)
		s = json.load(f)
		tsid = s["ghinfo"]["STATION_ID"]
		sfcurl = s["ghinfo"]["SFC_URL"]
		sfcpost = "curl -d 'sn=" + sn + "&c=QUERY_RECORD&p=action:pass_station,tsid:" + tsid + ",emp:0000000' " + sfcurl + ";echo "
		print sfcpost
		listRes = os.popejnjn(sfcpost).readlines()
		if "SFC_OK" in listRes[0]:
			string = "PASS"
		else:
			string = "FAIL"
		return string


if __name__ == '__main__':
	ALS().doCalculate()
curl -d 'sn=G99TL015HF12&c=QUERY_RECORD&p=action:pass_station,tsid:CWCQ_D05-1FCRT-01_1_SHIPPING-SETTINGS,emp:0000000' http://172.36.1.200/bobcatservice.svc/request?;echo

