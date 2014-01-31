case node['platform']
  when 'ubuntu'
    chef-gem 'open-uri'
    require 'open-uri'
    chef-gem 'json'
    require 'json'
    chef-gem 'net-ldap'
    require 'net-ldap'
end

# This stuff goes in a library
LDAPHOST = "ipamasterdev4.chimpy.internal"
LDAPADMIN = "uid=admin,cn=users,cn=accounts,dc=chimpy,dc=internal"
HOSTNAME = "vagrant"
IPADDRESS = "10.0.2.15"
SECRETPATH = "~/.chef/adminsecret"

# Parse a response from the API and return a user object.
def parse_ldap(response)
  user = nil

  # Check for a successful request
  # Parse the response body, which is in JSON format.
  parsed = JSON.parse(response)
  #puts parsed
  #puts "Facet #{parsed["facet_name"]}"
end

def modify_ldap(user_json, ip, hostname)
# Pass the information to LDAP
  admin_secret = Chef::EncryptedDataBagItem.load_secret("#{SECRETPATH}")
  admin_creds = Chef::EncryptedDataBagItem.load("admins", "admin", admin_secret)
  ldap = Net::LDAP.new :host => LDAPHOST,
      :port => 389,
      :auth => {
          :method => :simple,
          :username => LDAPADMIN,
          :password => admin_creds["password"]
      }
  dn = "fqdn=#{hostname}.chimpy.internal,cn=computers,cn=accounts,dc=chimpy,dc=internal"
  ops = [
    [:add, :description, "#{user_json['node_name']} #{ip} #{hostname}"],
    [:add, :l, "#{user_json['organization']}"],
  ]
  puts "dn = #{dn}"
  puts "ops = #{ops}"
  ldap.modify :dn => dn, :operations => ops
end

#baseurl = "http://169.254.169.254"
#hostname = open("#{baseurl}/latest/meta-data/hostname")
#hostname.each do |hostline|
#  @hostname = hostline
#end
@hostname = HOSTNAME

#aws_response = open("#{baseurl}/latest/meta-data/public-ipv4")
#aws_response.each do |aws|
#  @public_ip = aws
#end
@public_ip = IPADDRESS

# Get the Amazon tags
#response = open("#{baseurl}/latest/user-data/")
#concat = ""
#response.each do |token|
#  #print token
#  concat = concat + token
#end
#print concat
#user_data = parse_ldap(concat)
user_data = {
  "chef_server" => "https://api.opscode.com/organizations/srp5-infochimps",
  "node_name" => "p1_hdp-jt-0",
  "organization" => "srp5-infochimps",
  "cluster_name" => "p1_hdp",
  "facet_name" => "jt",
  "facet_index" => 0
}

modify_ldap(user_data, @public_ip, @hostname)
