module Api
  class Gitlab
    # Change this to restrict login with one instance
    SERVER_URL = ENV['GITLAB_SERVER']
    API_VERSION = '/api/v4'
    DEFAULT_PER_PAGE = 100

    delegate :user, :project, :issue, :search_projects, to: :client

    attr_reader :private_token

    def initialize(private_token:)
      @private_token = private_token
      intercept_errors
    end

    def projects(options = {})
      client.projects(options.reverse_merge(per_page: DEFAULT_PER_PAGE, starred: true))
    end

    def log_time(project_id:, issue_iid:, time:, day:, comment:)
      note = TimeNote.new(time: time, day: day, comment: comment).call
      client.create_issue_note(project_id, issue_iid, note)
    end

    private

    def client
      @client = ::Gitlab.client(endpoint: endpoint, private_token: private_token)
    end

    def endpoint
      @endpoint ||= SERVER_URL + API_VERSION
    end

    def intercept_errors
      return if endpoint =~ URI::regexp
      raise URI::InvalidURIError
    end
  end
end
