class MilestonesController < ApplicationController
  layout 'jaw'

  # memorized filter such as the following:
  # summary ~ "▲ Milestone" AND project = PAY AND (resolved = EMPTY OR resolved > -14d) ORDER BY due ASC
  MILESTONE_FILTER_PATH = '/rest/api/2/filter/18720'

  # memorized filter such as:
  # type = epic AND project = PAY AND (resolved = EMPTY OR resolved > -14d) ORDER BY resolved DESC
  #
  # Note: this is a bit incorrect. jira agile wall displays epics based on if they are hidden or not.
  # When they are hidden the following gets set from value = "To Do" (or others):
  # To this:
  #  "customfield_11082": {
  #     "self": "https://jira.corp.squareup.com/rest/api/2/customFieldOption/10862",
  #     "value": "Done",
  #     "id": "10862"
  #  },
  #
  # You need to manually verify that all epics are not resolved if they are on the card wall as an active "project".
  EPIC_FILTER_PATH = '/rest/api/2/filter/18721'

  # this custom field is on a per-jira installation (i think) for grasshopper.
  # the story link back to the epic key.
  CUSTOM_EPICS_LINK_FIELD = 'customfield_11080'
  # the epic field with the name of the epic, (fields.summary is not displayed in agile board),
  # this field is.
  CUSTOM_EPIC_NAME_FIELD = 'customfield_11081'

  MISSING_EPICS = "<< Missing Epic >>".to_sym

  def index
    # Find all the milestones for our team.
    search_url = client.getJson(MILESTONE_FILTER_PATH)['searchUrl']
    found_milestones = client.getJson(search_url)
    Rails.logger.info("Retrieved milestones")
    found_milestones = found_milestones['issues'].map do |m|
      f = m['fields']
      {name: f['summary'].gsub(/milestone[:]? /i, '').gsub(/▲[ ]*/, '').gsub(/ [ ]+/, ' '), #cleaner, shorter name
       key: m['key'],
       url_link: "#{SettingsLocalHelper.config['base_jira_url']}browse/#{m['key']}",
       assignee: f['assignee'].nil? ? 'unassigned' : f['assignee']['name'],
       url_assignee_avitar: f['assignee'].nil? ? nil : f['assignee']['avatarUrls']['32x32'],
       created_at: parse_datetime_local(f['created']),
       due_at: f['duedate'].nil? ? 1.day.ago : parse_datetime_local(f['duedate']), #make due in past and warn!
       warning: f['duedate'].nil? ? "Warning: No due date! " : nil,
       resolved_at: f['resolutiondate'].nil? ? nil : parse_datetime_local(f['resolutiondate']),
       epic_key: f[CUSTOM_EPICS_LINK_FIELD].nil? ? MISSING_EPICS : f[CUSTOM_EPICS_LINK_FIELD]}
    end
    epics_in_milestones = found_milestones.map{|m| m[:epic_key].to_sym}.uniq

    # Find all the epics.
    search_url = client.getJson(EPIC_FILTER_PATH)['searchUrl']
    found_epics = client.getJson(search_url)
    Rails.logger.info("Retrieved epics")
    found_epics = found_epics['issues'].reduce({MISSING_EPICS => MISSING_EPICS}) do |total,e|
      # epic_key => epic name
      total[e['key'].to_sym] = e['fields'][CUSTOM_EPIC_NAME_FIELD]
      total
    end

    # Munge a list of epics with their milestones.
    @epics = []
    epics_in_milestones.each do |epic_key|
      milestones = found_milestones.select{|m| m[:epic_key].to_sym == epic_key}.sort_by{|m| m[:due_at]}.map do |m|
        m.merge(state: pick_state(m))
      end
      @epics << { epic_name: found_epics[epic_key], milestones: milestones }
    end
    @epics.sort_by!{|e| e[:epic_name].to_s}
  end

  private

  def pick_state(milestone)
    return 'success' if milestone[:resolved_at].present?
    milestone_due_at = milestone[:due_at]
    end_of_sprint = Time.now.end_of_week
    if milestone_due_at < Time.now
      'danger' # overdue
    elsif milestone_due_at > Time.now.beginning_of_day && milestone_due_at < Time.now.end_of_day
      'warning' # due today
    elsif milestone_due_at < end_of_sprint
      'primary' # due this sprint
    else
      'default' # due in a future sprint
    end
  end

  def parse_datetime_local(value)
    # assumes this is local time.
    ActiveSupport::TimeZone['America/Los_Angeles'].parse(value)
  end

  def client
    @client ||= JiraHttpClient.new
  end
end
