#!/usr/local/bin/ruby -w
$LOAD_PATH.unshift File.dirname(__FILE__)  # enable 'require' use modules in script folder

require 'wabr'
require 'sample_code'


# Configure server
auth = ''
serverUrl = ''
reader = WABarcodeReader.new(serverUrl, auth)

#Configure Test
$bShowDiag = true	# testing only

 """  To disable specific test set to false. Default: all tests are  enabled
$bTestDropBox = false
$bTestBase64 = false
$bTestSamplesLocal = false
$bTestSamplesWeb = false
$bTestUtf8 = false
$bTestUtf8Names = false
"""

# Run Test
Test.Run(reader)

