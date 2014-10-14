require 'json'
require 'net/https'

class JiraHttpClient

  def initialize(args = {})
    jira_config = SettingsLocalHelper.config
    @options = {username: jira_config['jira_username'],
                password: jira_config['jira_password']}.merge(args)
  end

  def getJson(path)
    JSON.parse(request('GET', path).body)
  end

  def request(http_method, path)
    request = Net::HTTP.const_get(http_method.to_s.capitalize).new(path, {})
    request.basic_auth(@options[:username], @options[:password])
    response = http_conn.request(request)
    raise "non-200 response: #{response}" unless response.class == Net::HTTPOK
    response
  end

  def http_conn
    conn = Net::HTTP.new("jira.corp.squareup.com", 443)
    conn.use_ssl = true
    conn.verify_mode = false
    conn
  end
end