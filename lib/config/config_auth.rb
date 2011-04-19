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
MIICkzCCAXugAwIBAgIBADANBgkqhkiG9w0BAQUFADANMQswCQYDVQQDDAJjYTAe
Fw03MDAxMDEwMDAwMDBaFw0zODAxMTkwMzE0MDdaMA0xCzAJBgNVBAMMAmNhMIIB
IjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzSNGNA/eiCAWgHvpv73VnR31
4UIk2KYayXMJqg7QFVBJF6VHHrlX2Ec5GtdQmCewbcxsdgGxRsg2YV+l9Yl0SCkK
swnly+HLwW8zuyeUuTRxVbOH6yxAyvqdk5e9Ic5X3Bmc+YCIcqZGo3uAYBs4mpaw
a+loKMLwS+HO7ZoPyGBOYOen1MjEbF40l07KuwiLtesDF5yQ40qWIjbwtJPznPs9
AjRIOQBN9NbLzJQAJRCxXG8ZhAsjyxtdW4/0G8uLHHAjVLVuLxESwIVm2ZaCA6pG
v6hzqjtUYoB21C0jJeZm60RWeh8h8AYBJMWEZTHqgcRfxanPKSe7srtw1BmzSwID
AQABMA0GCSqGSIb3DQEBBQUAA4IBAQBV7nbpFCQpgBP9angRhzCRpOkLeMkXOy7F
jlBPWJHdEheNuOyfV6Mfnfc0Tc/b7l6AafzYPUk7cl5EHPYVnRBWiVqI8xPbC5Hy
lfb6dojPfp6WTzSzcqnNlhXwSoelBXs3Qj46Xkaix8bWyL0rsbjmFI2k+hhPrZdj
DKhPjAFJIK5luzWrtpUToq4FdoMBuIErD9nwp4/+aWRRRQvp3H43hY4Nu4Pguiv4
4Otn1gz5A+7xkItNzj2I2YeFx05yuUpISLHPFaJ7NOAGECxymcP3IEqkP6+ggMWb
V58KB/erhTtQ0asXfeW9eyGNOeoLFMROP0iecbSzmbaCkSVK7Gyf
-----END CERTIFICATE-----
END_CA_CERT

DEFAULT_MY_CERT=<<END_MY_CERT
-----BEGIN CERTIFICATE-----
MIICmDCCAYCgAwIBAgIBADANBgkqhkiG9w0BAQUFADANMQswCQYDVQQDDAJjYTAe
Fw03MDAxMDEwMDAwMDBaFw0zODAxMTkwMzE0MDdaMBIxEDAOBgNVBAMMB2RlZmF1
bHQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC+9jTYOZ1vXFxzHSfX
NeeC6jAuYqGn9ZYUzBz759O9lRVIK4qXejo+E2QHTN5fhxd9YKMFBiGo6j+ONTg/
kJT9h0vUfwODlR8LF/qQAkRv25frMK5NYef1QSOCFiLZuPM6wwb8qL27v+XU6OsY
xk4c2CqNHDTjgxdMDaAshJTWj5cQYwlU3sEXZ5NDOQzNtkdXhbcOLGJ+RFqiSzb7
KWzVV3jXMNb8acndnvNyLUNRpTEANJsWCMefzGoMJMw55d5DU6/EQuAyMacFBM30
kCKzpcOM39DoISgjNiVcfuHG0dXzDwMQu0LjvOJZkKyL5qYtsU0twzFPcLQvn3+p
uNz5AgMBAAEwDQYJKoZIhvcNAQEFBQADggEBAGIj7CZ/St5F40jNmdIHG4xRnxP/
4Pz6BDSNHokRqQ97rQ/vl6f+jKf9IGOeBYpo2bxBz+oce290vLPuTkosj5Bgwa2e
jM4y89qdMoDJn8mcqU/LV4sspwddY2kuKvn4DTzmbm+XvezrkX6tQXdeKeIl3yJP
CZOnc78OdVArHjrK4IbFdW3jSsLIjtfGX3VCLVmWpGR5vVcKy5steFRtAUwwDpPj
+XdYcDJJV28ziN6918/baiP9kIR0nws9o0R+u90h0YWS46k/kHOrLwGoSy/S9xjD
weHGtHeoRPLKH8n3tcrXJ6ZBoow12au4QM0YIkhGgl6+t21Td49WRaMfEkY=
-----END CERTIFICATE-----
END_MY_CERT

DEFAULT_MY_KEY=<<END_MY_KEY
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAvvY02Dmdb1xccx0n1zXnguowLmKhp/WWFMwc++fTvZUVSCuK
l3o6PhNkB0zeX4cXfWCjBQYhqOo/jjU4P5CU/YdL1H8Dg5UfCxf6kAJEb9uX6zCu
TWHn9UEjghYi2bjzOsMG/Ki9u7/l1OjrGMZOHNgqjRw044MXTA2gLISU1o+XEGMJ
VN7BF2eTQzkMzbZHV4W3DixifkRaoks2+yls1Vd41zDW/GnJ3Z7zci1DUaUxADSb
FgjHn8xqDCTMOeXeQ1OvxELgMjGnBQTN9JAis6XDjN/Q6CEoIzYlXH7hxtHV8w8D
ELtC47ziWZCsi+amLbFNLcMxT3C0L59/qbjc+QIDAQABAoIBABfJy+Nzqe0JcGrW
ovPoPyLL0Zy1pLWrnjqRArtOsc3YGIKZCfa8vyykdb2DEeCMj5yKwUQK8357T9eD
QbKJbEX46LVb7TAjD27uWcQ+xA+7Jz2hHtV88MxYhPfbkhPVOleDnAc1bg1JZnQT
X9YCPhDRzNsvPFdrKSfMOrvQ+EmR+oINwzE6jWNsvr3kZsuT3LXzjuiAU1aLP3fX
dIJexw/xKdVaXCJYbJzgW6XmTiNSWVedgnfanORLcIh8o4+EemE1QSXMl9gxrUFW
huEjyYXLyw/skVfldHngafz+xQiG0KMkAOT8+qtSWA4IfqcAQgwp6Fc8PaVI3W6z
xB6380ECgYEA4fLn4Iexn9WBnC4qnqeUHd4aJQ5GgBAW9TvfYO7YeYHm1BodEttL
1wnbtA8yW4MxeTYF/WeJiv/2+AzSbE1cXpDWWZ4WY8WVAyQdkmX/iL/ovdmP4gJq
fkys/zjPpTesjYvBGPLN3hbsT03mFUf+21PVT3NbEfb4yIxbk340r10CgYEA2FwP
wNpKpiZczbvHKkrtGLxD6GsJwxvQpCSa3GNCu2zFAFkavlZoHA1t8IvvHTAlTd3I
9A8rLRr+j1mX/HQ/8Cdmj1/Q/zjDGfAWQve3Rn4Lg4OpMt15EPYdqSsPoKxgEoiF
2siTuRQm448ZMo/S8DcuAXSGUrk4fmcluyzEtk0CgYEA2fUKbtIWqxs3GuSB4me+
/ozIZaR+p3xd2RR3Z7cfBR8k/sdt8kmuv/HXiLr8FcDZUZamcoqU6Iv/vcoIlcaO
av6Gdw6DhJ0NIGmPSTCxLkYJilG7dQZlmg3293/i9fpdrnD4xUs7AZjVPa7kWvUH
SKV26Fxbplm6JSMYF5Av3FUCgYAeQOFDCkMd8IdRjUxQMaHtr4WfXjhDPAR0r1mo
L4kJRDBX2B3RN6vfIFGbLTYGUtEkjjqnRee3quqliNWjy22VWy0QJ0nGJl3Bpry2
KIVMKhvaC/MA1c8z+/YxzX+l6/STItv0t89QNe0qLLxNQacxR8X7FhwiPRwVML8p
6RyokQKBgQCg9M1u9w5XR+JQYri6hVt4vTaN3MvEn6IvgqoRmSF3nquhoNBr6D6g
m0xYiL0CYzrRPPcjixdQtRNMjmgHvIunjYdm8HcDUpSK26UAi3wBzVWpQnDbioX6
ho684wh+7fuOavKTpaBoddUjD6+4Msu6i+px8jhjXA7+fTazZ19mYQ==
-----END RSA PRIVATE KEY-----
END_MY_KEY



end

