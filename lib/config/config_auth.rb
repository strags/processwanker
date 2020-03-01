############################################################################
#
# config_auth.rb
#
# auth block parser:
#
# auth {
# 	ca_cert				"ca_cert_path"
# 	my_cert				"my_cert_path"
# 	my_key				"my_key_path"
#   accept_peers	"blah","hello"
# 	reject_peers	"fred"
#   accept_ip 		10.1.99.0/24
#   reject_ip 		10.1.99.0/24
# }
#
############################################################################

require 'ipaddr'
require 'openssl'
require 'config'

module ProcessWanker
	
	############################################################################
	#
	#
	#
	############################################################################

	class IPFilter
		
		attr_accessor					:ips
		
		def initialize()
			@ips=[]
		end
		
		def contains(ip)
			ips.each do |x|
				return(true) if(x.include?(ip))
			end
			false
		end
		
	end

	############################################################################
	#
	#
	#
	############################################################################

	class ConfigAuth < ConfigNode
		
		attr_accessor					:ca_cert
		attr_accessor					:my_cert
		attr_accessor					:my_key
		attr_accessor					:accept_peers
		attr_accessor					:reject_peers
		attr_accessor					:is_default
		attr_accessor					:accept_ip
		attr_accessor					:reject_ip
		
		def initialize()
			init_default()
		end
		
		def init_default()
			@is_default=true
			@ca_cert=OpenSSL::X509::Certificate.new(DEFAULT_CA_CERT)
			@my_cert=OpenSSL::X509::Certificate.new(DEFAULT_MY_CERT)
			@my_key=OpenSSL::PKey::RSA.new(DEFAULT_MY_KEY)
		end
		
		def allow_ip(ip)
			return(false) if(accept_ip && !accept_ip.contains(ip))
			return(false) if(reject_ip && reject_ip.contains(ip))
			true
		end
		
	end

	############################################################################
	#
	#
	#
	############################################################################

	class ConfigAuthBuilder < Builder
				
		def ca_cert(v)
			@config.ca_cert=OpenSSL::X509::Certificate.new(File.read(v))
			@config.is_default=false
		end
	
		def my_cert(v)
			@config.my_cert=OpenSSL::X509::Certificate.new(File.read(v))
		end
	
		def my_key(v)
			@config.my_key=OpenSSL::PKey::RSA.new(File.read(v))
		end
	
		def accept_peers(*v)
			@config.accept_peers ||= {}
			v.each do |vv|
				@config.accept_peers[vv]=true
			end
		end
		
		def reject_peers(*v)
			@config.reject_peers ||= {}
			v.each do |vv|
				@config.reject_peers[vv]=true
			end
		end
		
		def accept_ip(v)
			@config.accept_ip ||= IPFilter.new
			@config.accept_ip.ips << IPAddr.new(v)
		end

		def reject_ip(v)
			@config.reject_ip ||= IPFilter.new
			@config.reject_ip.ips << IPAddr.new(v)
		end
	
	end

	############################################################################
	#
	#
	#
	############################################################################

DEFAULT_CA_CERT=<<END_CA_CERT
-----BEGIN CERTIFICATE-----
MIICkzCCAXugAwIBAgIBADANBgkqhkiG9w0BAQsFADANMQswCQYDVQQDDAJjYTAe
Fw03MDAxMDEwMDAwMDBaFw0zODAxMTkwMzE0MDdaMA0xCzAJBgNVBAMMAmNhMIIB
IjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuUUHbStQnmJysiR5B0mwIP7b
SrA8iNNwwmnFfeMpi58ykSyXFzK6YTaK5ntJS8B2EYxNVYnwhhj3FZYxnjMNc/c2
Jr8ff/HQ9px1leu/oXuVdcgpf7YfWi5MaMye48r6Qgdd50/00mKU1IULuWXDlfY+
lAGT64qTa/An0LbhBWIBesCRCgQtpr/4toZH8cyb46ycN8ahcHl1kFA81dKumPM+
RACqI6ov+tyMfI3qq752VFsDM+M2wz/ZlteryQZ9a8PE4w04CUWxekQdWeZJCMQv
sFnpZJLfVLrdPwMUEmg/X4PZV57pKsw3cNkNX96HE9DJjK76o9pHX9rZ4SGZSQID
AQABMA0GCSqGSIb3DQEBCwUAA4IBAQA13/YESqE3IJREJC2SG2pDtOuZmnEoI3xD
Z1m4FbQEnPtTPIGR6wd8JY/WrqgVY9+kFCnv/kPjFPwFzfn0WmydeHKGqwtGSYGF
NJX8rUw5WUsKQk+5nKEyLYnjRvc88QgChJtxL43ORq09pvAogGFZdKh0lNahZXdg
Ou5PX9WuNgixqJ82T6VYzUu3OBeNHUsiJ8vzGHzovrXpcrDIHiNxk6R80Tie6NA6
a4HZaZ3C6NbFQTwa3LjVOOR4i28EIYknVKSdqiS066aMhGgSGNzGyAcnc17zwcGg
Ql7bQ6InqCw3jv+WuN0SMaTpCVDoy4wFZ9Uz0CY7mCh4w/N0mIuI
-----END CERTIFICATE-----
END_CA_CERT

DEFAULT_MY_CERT=<<END_MY_CERT
-----BEGIN CERTIFICATE-----
MIIClTCCAX2gAwIBAgIBADANBgkqhkiG9w0BAQsFADANMQswCQYDVQQDDAJjYTAe
Fw03MDAxMDEwMDAwMDBaFw0zODAxMTkwMzE0MDdaMA8xDTALBgNVBAMMBHVzZXIw
ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDKKOIFDzkFJb7TkOy8Ucg/
rmRUq7A9K3AQ6lsUkebEid8TiWXv11h5O1xCCyWnqGPIK/kJOPiUb0qdpQWQZy8h
dYonbAFZaJUS8SdaZKZbIuHeGPL02Fh7WxQIiG7UfEslGTrTMKI7M2Ol/XRZmkHm
EryTG1FdDSKdemy+FAb8ishiuCvb+9USjU5Rg/P1asVoRJePCpVaCbNI87a+qqYl
LnMyE7V59GO+B6DFVnn93tIbDReKKnPW+g9ZrxBopUt9d6v5qcJWzzUvneeETsfl
maKLSfN8xa1bhLP5SgT91Y8EMVaq9C6HgFQ22qJP/hfTb6teNXRMH0CDUF+CTKbx
AgMBAAEwDQYJKoZIhvcNAQELBQADggEBAFYibRRmihzP9zHw4uhG9oS5/C+AuFjo
c8Q+2aQGcbuarWXXiSLwGHR5Ji06GVHpNJroNgTod0uDnLFrfDVX9PIgN+NGjDMf
DlMFr6gBd7huAD8c1C1/S4aLcrlf7AmJQsVQRiU3oeFYJLidsxKpZW1zNcbkR/hi
BCmNvLsKwG/BVsO4Kg2wgSh6hzhD+rKNTROvaqlf60LLOhsQJHjrv8iflDJvppFY
dWF8LqQvwUPgEKWIppSG1LeYyJh/VvMI4dVBYAV8JQUlQjV+wsUeCKDCaGj6lopn
ZrJSy5TXo9y9QPUOvJmqAOq4IjbjGSRi8hzA5zUHF3sKdMAc7yJOnT8=
-----END CERTIFICATE-----
END_MY_CERT

DEFAULT_MY_KEY=<<END_MY_KEY
-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEAyijiBQ85BSW+05DsvFHIP65kVKuwPStwEOpbFJHmxInfE4ll
79dYeTtcQgslp6hjyCv5CTj4lG9KnaUFkGcvIXWKJ2wBWWiVEvEnWmSmWyLh3hjy
9NhYe1sUCIhu1HxLJRk60zCiOzNjpf10WZpB5hK8kxtRXQ0inXpsvhQG/IrIYrgr
2/vVEo1OUYPz9WrFaESXjwqVWgmzSPO2vqqmJS5zMhO1efRjvgegxVZ5/d7SGw0X
iipz1voPWa8QaKVLfXer+anCVs81L53nhE7H5Zmii0nzfMWtW4Sz+UoE/dWPBDFW
qvQuh4BUNtqiT/4X02+rXjV0TB9Ag1Bfgkym8QIDAQABAoIBAFphdMs2RxPaEDqe
LHj1R0XRPeHs8FootW2amSXVJQrxaN5fK0fTSybINzL/sNIIIrQ3lJte8SPLrdxV
DuvEdfnLhvyg+Ol0LFHPpvxuy0Erkzesh9KXdtePnKFD/ejZuO7ZHMeWkrFNBFwN
uJrmsFegQNaz++hSGwu01DEW2xjEV7+rjRszWpfJXR4Nj5VenoRayJfgzZkrbDH9
o7vmmQBMQh3NMDsvx66ssAek+PAgePbTLyUkmy+XfgcZtcSvlzS8C36ADBgRYo52
lBwUdZDpzxwKoyc/79S94w9H8om19v4p9NvKNzoDxt6hzoV2cC4BsoS/ppBa/5tI
bGZ9nlECgYEA7YA2MuOTBkJ8IRBBMwZJQzIJSR5uRpimQKlX+IHigAEiIlvKTSVm
0pGnZtzmT+93mMzN+HPqyrDrKr5nbGajCKjceXUKGfImlm/F0uf7Q+6fMoULfBzq
T783/w3SQjdVtgp5I+ZyStcdj5u7JIysrfTnEzY0CUbP3phcGQCaBycCgYEA2ef3
QQLADzIrNKtOlkVdhEhkyEh6JlZdxix4kc3VfdZGqMAQvN5ATh6+HCnjdI65EH3Y
dab5TlCjKqgA5Y0F93Ftlk9CxrFbvqiysqA8S4ue+fN/BhbAf4FE6jTedaD+tKCp
Y3iSW+A9S46j7+mCOQHHz+nHGDEoPXswCmd38CcCgYEAhWdbCkKiNwXpS3kh5lNF
m6TjalrZfnYIDJISg9gRLe11Cu+cNrEnjGecLD8wbv4Ho6CGoWQbIjc2IRBKb61H
LnoLPX3sap6F5kJqUAlWLdY/PdVVmiVzx8+U2IMe82q5jkNbwDqVQEyMojnLaMBL
znqdwUDVAdDwugvCz5hy7EkCgYEAmW3UUakfFFQNyfMIzZQfyaGznLYzk8TiGER9
zKPyu7zhWbaK0oFnI9pPn8L6zbokonEJtaWRCsyKZuGOaBMI7XanY9uBOCfvYmqk
EFP0wHiZwoLpoJ7qgZzCqmn5bTejwAkT298sppZYclgIJEf1kjAnwcRolCcgn1Ga
vOinsacCgYEA0WaUoD8ZdFH3PvTJqXysjsRrbklPrEHidz1waQ7vWyXEBxI+/H4A
/eDBMD+eRtAG3LXCrUNacu5wtIeTh2ASiCUn5aadWvHmGWVSVmFRRwzi/MWPV0B0
dIHosQUNb7TDknRCZRvEbsE0DlK3cI36VC64TciZzETeb1MVVY/tLkI=
-----END RSA PRIVATE KEY-----
END_MY_KEY



end

