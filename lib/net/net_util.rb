############################################################################
#
# net_util.rb
#
# handles the physical TCP/SSL connection between client(s) and daemon(s)
#
############################################################################

require 'openssl'
require 'fileutils'

module ProcessWanker
	
  ############################################################################
  #
  #
  #
  ############################################################################

	module NetUtil
	
		DEFAULT_PORT			=			45231

	  ############################################################################
	  #
	  #
	  #
	  ############################################################################

		def make_filename(prefix,type)
			ext={ :key => "key", :cert => "crt" }[type]
			"#{prefix}.#{ext}"
		end
		module_function				:make_filename
	
	  ############################################################################
	  #
	  # generate_ca
	 	#
	 	# create a new CA certificate and private key
	  #
	  ############################################################################

		def generate_ca(prefix,passphrase=nil)

			outdir=File.expand_path(File.dirname("#{prefix}a.b"))
			FileUtils.mkdir_p(outdir)

			#
			# write key file
			#
			
			puts "generating CA key..."
			key = OpenSSL::PKey::RSA.new(2048)
			cipher = OpenSSL::Cipher::Cipher.new('AES-128-CBC')
			exp = passphrase ? key.export(cipher,passphrase) : key.export
			puts "saving CA key..."
			File.open(make_filename(prefix,:key),"w") do |f|
				f.write(exp)
			end
			
			#
			# generate certificate
			#
			
			puts "generating CA cert..."
			ca_name = OpenSSL::X509::Name.parse('CN=ca')
			ca_cert = OpenSSL::X509::Certificate.new
			ca_cert.serial = 0
			ca_cert.version = 2
			ca_cert.not_before = Time.at(0)
			ca_cert.not_after = Time.at(0x7fffffff)
			ca_cert.public_key = key.public_key
			ca_cert.subject = ca_name
			ca_cert.issuer = ca_name

			extension_factory = OpenSSL::X509::ExtensionFactory.new
			extension_factory.subject_certificate = ca_cert
			extension_factory.issuer_certificate = ca_cert

			extension_factory.create_extension 'subjectKeyIdentifier', 'hash'
			extension_factory.create_extension 'basicConstraints', 'CA:TRUE', true
			extension_factory.create_extension 'keyUsage', 'cRLSign,keyCertSign', true

			puts "signing CA cert..."
			ca_cert.sign(key, OpenSSL::Digest::SHA1.new)

			puts "saving CA cert..."
			File.open(make_filename(prefix,:cert),"w") do |f|
				f.write(ca_cert.to_pem)
			end			
			
			puts "wrote #{make_filename(prefix,:key)} and #{make_filename(prefix,:cert)}"
			
		end

		module_function			:generate_ca

	  ############################################################################
	  #
	  #
	  #
	  ############################################################################
	
		def generate_cert(ca_prefix,cert_prefix,name,passphrase=nil)
			
			outdir=File.expand_path(File.dirname("#{cert_prefix}a.b"))
			FileUtils.mkdir_p(outdir)
			
			#
			# load ca key and cert
			#
			
			puts "loading CA key and cert..."
			ca_key=OpenSSL::PKey::RSA.new( File.read(make_filename(ca_prefix,:key)) )
			ca_cert=OpenSSL::X509::Certificate.new( File.read(make_filename(ca_prefix,:cert)) )
			
			#
			# write key file
			#
			
			puts "generating key for #{name}..."
			key = OpenSSL::PKey::RSA.new(2048)
			cipher = OpenSSL::Cipher::Cipher.new('AES-128-CBC')
			exp = passphrase ? key.export(cipher,passphrase) : key.export
			puts "saving key for #{name}..."
			File.open(make_filename(cert_prefix,:key),"w") do |f|
				f.write(exp)
			end
			
			#
			# generate CSR
			#
			
			puts "generating CSR for #{name}..."
			csr = OpenSSL::X509::Request.new
			csr.version = 0
			csr.subject = OpenSSL::X509::Name.parse("CN=#{name}")
			csr.public_key = key.public_key
			csr.sign(key,OpenSSL::Digest::SHA1.new)
			
			#
			# create certificate
			#
			
			puts "creating cert for #{name}..."
			csr_cert = OpenSSL::X509::Certificate.new
			csr_cert.serial = 0
			csr_cert.version = 2
			csr_cert.not_before = Time.at(0)
			csr_cert.not_after = Time.at(0x7fffffff)

			csr_cert.subject = csr.subject
			csr_cert.public_key = csr.public_key
			csr_cert.issuer = ca_cert.subject

			extension_factory = OpenSSL::X509::ExtensionFactory.new
			extension_factory.subject_certificate = csr_cert
			extension_factory.issuer_certificate = ca_cert

			extension_factory.create_extension 'basicConstraints', 'CA:FALSE'
			extension_factory.create_extension 'keyUsage','keyEncipherment,dataEncipherment,digitalSignature'
			extension_factory.create_extension 'subjectKeyIdentifier', 'hash'

			puts "signing cert for #{name}..."
			csr_cert.sign(ca_key,OpenSSL::Digest::SHA1.new)
			
			#
			# save it
			#
			
			puts "saving cert for #{name}..."
			File.open(make_filename(cert_prefix,:cert),"w") do |f|
				f.write(csr_cert.to_pem)
			end			
			
			puts "wrote #{make_filename(cert_prefix,:key)} and #{make_filename(cert_prefix,:cert)}"
			
		end
		module_function			:generate_cert
	
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################
	
		def post_fork()

			if(NetServer.instance())
				NetServer.instance().post_fork()
			end		
		
		end
		module_function			:post_fork	
	
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################
	
	end

end
