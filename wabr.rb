require 'rest_client'
require 'rexml/document'
require 'base64'

class WAUtils

	def WAUtils.nodeValue(nodeParent, name, default)
		sout = default
		node = REXML::XPath.first(nodeParent, name)
		if node != nil then
			if node.text != nil then
				sout = node.text
			end
		end
		return sout
	end

	def WAUtils.signature(image)
		if (image == nil || image == "") then
			return ""
		end
		sout = ' [' + image[0, [image.length, 80].min] +  '] '
        return  sout
	end
   

	def WAUtils.decodeBase64(base64)
        ret = nil
		if (base64 == "") then
			return ret
		end
        begin
			ret = Base64.decode64(base64)
        rescue
			i = 3
		end
		return ret
	end


	def WAUtils.nodeValueXml(nodeParent, name)
		node = REXML::XPath.first(nodeParent, name)
		if node != nil then
			sout = node.elements.map(&:to_s).to_s
			doc = REXML::Document.new(sout)
			return doc
		end
		return nil
	end


	def WAUtils.decodeBase64(base64)
		if (base64 == "") then
			return nil
		end
        begin
			return Base64.decode64(base64)
        rescue
			i = 3
		end
		return nil
	end

	def WAUtils.nodeValueInt(nodeParent, name, default)
		nout = default
		sout = WAUtils.nodeValue(nodeParent, name, "")
		if sout != "" then
			nout = Integer(sout)
		end
		return nout
	end

	def WAUtils.isBase64(value) 
		v = value
		# replace formating characters
		v = v.gsub("\r\n", "")
		v = v.gsub("\r", "")
		# remove reference file name, if  present
		arr = v.split(":::")
		v = arr[0]
		if v == nil or v.length == 0 or (v.length % 4) != 0 then
			return false
		end
		index = v.length - 1
		if v[index] == '=' then
			index -= 1
		end
		if v[index] == '=' then
			index -= 1
		end
		v.each_byte do |c|
			if WAUtils.IsInvalidBase64char(c) then
				return false
			end
		end
		return true
	end

	def WAUtils.IsInvalidBase64char(intValue)
		if intValue >= 48 and intValue <= 57 then
			return false
		end
		if intValue >= 65 and intValue <= 90 then
			return false
		end
		if intValue >= 97 and intValue <= 122 then
			return false
		end
		return ((intValue != 43) and (intValue != 47))
	end
end

class WAHttpRequest

	def WAHttpRequest.ExecRequest(serverUrl, authorization, files, queries, retries)

		$env_auth = 'WABR_AUTH'
		if (authorization == nil) 
			authorization = ""
		end

		if (authorization == "" and ENV.include?($env_auth))
			authorization = ENV[$env_auth]		
        end


        payload_hash = {
		  :multipart => true,
		}


		body = 
		queries.each { |key, value|
			payload_hash[key] = value   # DO NOT CGI.escpe in multi-part
		}

		files.each_with_index { |file, index|
		  file_key = ("file"+index.to_s).to_sym
		  payload_hash[file_key] = File.new(file, "rb")
		}
     	request1 = RestClient::Request.new(
			:method => :post,
			:url =>  serverUrl,
			# :user => @sid,
			# :password => @token,
			:headers => {:Authorization => authorization}, 
			:payload => payload_hash)
		response = request1.execute() do |response, request, result, &block|
				if ([301, 302, 307].include? response.code and retries < 2) then
					if ($bShowDiag) then
						puts '    ===== REDIRECTED TO: ' + response.headers[:location].to_s;
					end
					url = response.headers[:location]
					if url !~ /^http/
						url = URI.parse(response.args[:url]).merge(url).to_s
					end
					url = URI.parse(response.headers[:location].to_s).to_s
                    return WAHttpRequest.ExecRequest(url, authorization, files, queries, retries + 1)
				elsif response.code == 200
					return response.body.force_encoding("UTF-8")
				else 
                    err = "HttpError:" + result.code.to_s + ". "  + result.message 
					if (!response.body.start_with?("<!DOCTYPE"))
						err  = err + ". " + response.body
					end
					raise err
				end
			end
		end
	end
		



class WABarcode
	def initialize()
		@Values = Hash.new
		@Dat = Array.new
		@Text = ""
		@Type = ""
		@Length=0
		@Page=0
		@Top=0
		@Left=0
		@Bottom=0
		@Right=0
		@File=""
		@Meta=""
	end
	
	def Text
		return @Text
	end
	
	def set_Text(value)
		@Text = value
	end
	
	
	def Data
		return @Data
	end
	
	def set_Data(value)
		@Data = value
	end
	
	def Type
		return @Type
	end
	
	def set_Type(value)
		@Type=value
	end
	
	def Length
		return @Length
	end
	
	def set_Length(value)
		@Length=value
	end
	
	def Page
		return @Page
	end
	
	def set_Page(value)
		@Page=value
	end
	
	def Rotation
		return @Rotation
	end
	
	def set_Rotation(value)
		@Rotation=value
	end
	
	def Left
		rturn @Left
	end
	
	def set_Left(value)
		@Left=value
	end
	
	def Top
		return @Top
	end
	
	def set_Top(value)
		@Top=value
	end
	
	def Right
		return @Right
	end
	
	def set_Right(value)
		@Right=value
	end
	
	def Bottom
		return @Bottom
	end
	
	def set_Bottom(value)
		@Bottom = value
	end
	
	def File
		return @File
	end
	
	def set_File(value)
		@File = value
	end
	
	def Meta
		return @Meta
	end
	
	def set_Meta(value)
		@Meta = value
	end
	
	def Values
		return @Values
	end
	
	def set_Values(value)
		@Values = value
	end
	
	def	addValue (name,	value)
		@Values[name]=value
	end
end

class WABarcodeReader
	def initialize(serverUrl, authorization)
		@_serverUrl = "wabr.inliteresearch.com"
		@_authorization = ""
		@types = ""
		@validtypes = "1d,Code39,Code128,Code93,Codabar,Ucc128,Interleaved2of5," + "Ean13,Ean8,Upca,Upce," + "2d,Pdf417,DataMatrix,QR," + "DrvLic," + "postal,imb,bpo,aust,sing,postnet," + "Code39basic,Patch"
		@directions = ""
		@tbr_code = 0
		@throwException = true
		@_serverUrl = serverUrl
		@_authorization = authorization
		@bShowDiag = true
	end
	
	# <summary>
	# Read barcodes
	# </summary>
	# <param name="image">
	# One or more of the following items. Multiple items should be separated by |
	# - URL     Web location of an image file, accessible by server
	# URL  should starts with: http:\\ https:\\ ftp:\\ file:\\
	# - FILE    Path to a client-side local or network image file
	# FILE should exist on client and be readable
	# - IMAGE    Base64-encoded image file content
	# </param>
	# <returns>
	# Array of found barcodes
	# </returns>
	def Read(image)
		return self.ReadOpt(image, @types, @directions, @tbr_code)
	end
	
	# <summary>
	# Read barcodes
	# </summary>
	# <param name="image">
	# One or more of the following items. Multiple items should be separated by |
	# - URL     Web location of an image file, accessible by server
	# URL  should starts with: http:\\ https:\\ ftp:\\ file:\\
	# - FILE    Path to a client-side local or network image file
	# FILE should exist on client and be readable
	# - IMAGE    Base64-encoded image file content
	# </param>
	# <returns>
	# Array of found barcodes
	# </returns>
	def ReadOpt(image, types, directions, tbr_code)
		if ($bShowDiag)  then
			puts ("\n================= PROCESSING: " + WAUtils.signature(image))
		end
		
		names = image.split('|')
		urls = Array.new()
		files = Array.new()
		images = Array.new()
		names.each do |name1| 
			name = name1.strip
			s = name.downcase
			if s.start_with?("http://", "https://", "ftp://", "file://") then
				urls.push(name)
			elsif File.file?(name) then
				files.push(name)
			elsif name.start_with?("data:") or WAUtils.isBase64(name) then
				images.push(name)
			else
				raise Exception.new("Invalid image source: " + WAUtils::signature(name))
			end
		end
		return self.ReadLocal(urls, files, images, types, directions, tbr_code)
	end
	
	
	
	def WABarcodeReader.ParseResponse(txtResponse)
		barcodes = Array.new
		
        txtResponse = txtResponse.strip() 
		
		if txtResponse.start_with?("<") then
			doc = REXML::Document.new(txtResponse)
			REXML::XPath.each(doc,  "//Barcode") do |nodeBarcode|
				barcode = WABarcode.new()
				barcode.set_Text(WAUtils.nodeValue(nodeBarcode, "Text", ""))
				barcode.set_Left(WAUtils.nodeValueInt(nodeBarcode, "Left", 0))
				barcode.set_Right(WAUtils.nodeValueInt(nodeBarcode, "Right", 0))
				barcode.set_Top(WAUtils.nodeValueInt(nodeBarcode, "Top", 0))
				barcode.set_Bottom(WAUtils.nodeValueInt(nodeBarcode, "Bottom", 0))
				barcode.set_Length(WAUtils.nodeValueInt(nodeBarcode, "Length", 0))
				barcode.set_Data(WAUtils.decodeBase64(WAUtils.nodeValue(nodeBarcode, "Data", "")))
				barcode.set_Page(WAUtils.nodeValueInt(nodeBarcode, "Page", 0))
				barcode.set_File(WAUtils.nodeValue(nodeBarcode, "File", ""))
				meta = WAUtils.nodeValueXml(nodeBarcode, "Meta")
				if (meta != nil) then
                    barcode.set_Meta(meta.elements.map(&:to_s).to_s)
				end
				barcode.set_Type(WAUtils.nodeValue(nodeBarcode, "Type", ""))
				barcode.set_Rotation(WAUtils.nodeValue(nodeBarcode, "Rotation", ""))
				docValues = WAUtils.nodeValueXml(nodeBarcode, "Values")
				if docValues != nil then
					REXML::XPath.each(docValues.root, ".//*") do |node|
						barcode.addValue(node.name, node.text)
					end
				end
				barcodes.push(barcode)
			end
		end
		return barcodes
	end
	
	def ReadLocal(urls, files, images, types_, dirs_, tbr_)
		server = @_serverUrl
		if server == "" then
			server = "https://wabr.inliteresearch.com"
		end # default server
		queries = {} # Hash.new # Dictionary[System::String, System::String].new()
		url = ""
		urls.each do |s|
			if url != "" then
				url += "|"
			end
			url += s
		end
		if "url" != "" then
			queries["url"] = url
		end
		image = ""
		images.each do |s|
			if image != "" then
				image += "|"
			end
			image += s
		end
		if "image" != "" then
			queries["image"] = image
		end
		queries["format"] = "xml"
		queries["fields"] = "meta"
		if types_ != "" then
			queries["types"] = types_
		end
		if dirs_ != "" then
			queries["options"] = dirs_
		end
		if tbr_ != 0 then
			queries["tbr"] = tbr_.to_s
		end
		serverUrl = server + "/barcodes"
		barcodes = nil
		txtResponse = ""
		
		begin
			txtResponse = WAHttpRequest.ExecRequest(serverUrl, @_authorization, files, queries, 0)
			barcodes = WABarcodeReader.ParseResponse(txtResponse)
		rescue Exception => ex2
			raise ex2
		end
		return barcodes
	end
end
