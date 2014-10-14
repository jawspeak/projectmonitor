class SettingsLocalHelper
  def self.config
    # ConfigHelper didn't load settings.local.yml, oh well. Low QPS makes this ok.
    jira_config = YAML.load_file(
        File.join(Rails.root, 'config', 'settings.local.yml'))[Rails.env]
    jira_config
  end
end