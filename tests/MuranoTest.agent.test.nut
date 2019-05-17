// MIT License
//
// Copyright 2019 Exosite
//
// SPDX-License-Identifier: MIT
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED &quot;AS IS&quot;, WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

//*****************************************************************
//   TO RUN THIS TEST
//*****************************************************************
// 1.) Change PRODUCT_ID to the product id of the testing area in Murano
// 2.) Ensure the current device being tested is not provisioned
// 3.) From the repository root run `impt test run` (see tests/README.md for more detail)

class MuranoTestCase extends ImpTestCase {
    const PRODUCT_ID = "c449gfcd11ky00000";
    _exositeAgent = null;

    function setUp() {
        clear_token();
        _exositeAgent = Exosite(PRODUCT_ID, null);

        //Enable debugMode that was defaulted to false
        _exositeAgent.debugMode = true;
        //Change number of seconds between config_io refreshes that was defaulted to 60 seconds
        _exositeAgent.configIORefreshTime = 5;
    }

    function clear_token(){
        server.log("Clearing token from server table");
        local persist = server.load(); 
        if (persist.rawin("exosite_token")) {
            persist.rawdelete("exosite_token"); 
        }
        local result = server.save(persist);
        server.log("Result of save: " + result);
    }

    function test01_createDevice() {
        this.assertTrue(!_exositeAgent.tokenValid());
        return provision_test();
    }

    function test02_autoDeviceID() {
        local inputString = "https://agent.electricimp.com/fyofyVhlsf7C";
        local expectedString =  "fyofyVhlsf7C";

        local actualString = _exositeAgent.getDeviceFromURL(inputString);
        this.assertEqual(expectedString, actualString);
    }

    function test03_writeData(){
        return writeDataTest();
    }

    function provision_test() {
        return Promise(function(resolve, reject) {
            _exositeAgent.provision_w_cb(function(response){
                    if (response.statuscode == 200 || response.statuscode == 204) {
                        _exositeAgent.setToken(response);
                        resolve(response.statuscode);
                    } else {
                        reject(response.statuscode);
                    }
            }.bindenv(this));
        }.bindenv(this));
    }

    function writeDataTest(){
        return Promise(function(resolve, reject) {
            this.info("in promise");
            local test_data = {};
            test_data.temp <- 1;
            test_data.press <- 2;
            this.info("CreatedTestData");
            //Write the data
            _exositeAgent.writeData_w_cb(test_data, function(response){
                //Read the data back
                readAttribute("data_in", function(response){
                    //Check it's the same
                    local expected_result = "data_in=%7b+%22press%22%3a+2%2c+%22temp%22%3a+1+%7d"
                    if (response.statuscode != 200) {
                        reject(response.statuscode);
                    } else if (response.body != expected_result) {
                        reject(response.body);
                    } else {
                        resolve(response.body);
                    }
                }.bindenv(this));
            }.bindenv(this));
        }.bindenv(this));
    }
}
