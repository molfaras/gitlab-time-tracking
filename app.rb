APP_ROOT = File.dirname(__FILE__)
SECRET = File.join(APP_ROOT, '.secret')

require 'pry' if ENV['RACK_ENV'] = 'development'
require 'rubygems'
require 'sinatra/base'
require "sinatra/reloader"
require 'haml'
require 'gitlab'
require 'encrypted_cookie'
require 'securerandom'

class GitLabTimeTracking < Sinatra::Base
  # Create .secret file for EncryptedCookie
  unless File.exists?(SECRET)
    File.open(SECRET, 'w') { |file| file.write(SecureRandom.hex(32)) }
  end

  use Rack::Session::EncryptedCookie,
    secret: File.read(File.join(APP_ROOT, '.secret')).strip

  configure :development do
    register Sinatra::Reloader
  end

  set :database_file, "#{APP_ROOT}/config/database.yml"

  require 'sinatra/activerecord'
  require './api/gitlab'
  require './lib/time_note'
  require './lib/time_parser'
  require './helpers/authentication_helper'
  require './helpers/render_partial'
  require './models/user'
  require './models/time_log'

  get '/' do
    authenticate_user!

    @day_to = if params[:day_to]
                params[:day_to].to_date
              else
                Date.today
              end

    @day_from = @day_to - 1.week
    @days = (@day_from..@day_to).to_a
    @time_logs = TimeLog.where(user_id: current_user.id)
                        .where('day >= ? AND day <= ?', @day_from, @day_to)

    haml :index
  end

  get '/project/:id' do
    authenticate_user!

    @day_to = if params[:day_to]
      params[:day_to].to_date
    else
      Date.today
    end

    @day_from = @day_to - 1.week
    @days = (@day_from..@day_to).to_a
    @project = current_user.api.project(params[:id])
    @time_logs = TimeLog.where(project_id: params[:id])
      .where('day >= ? AND day <= ?', @day_from, @day_to)

    haml :project
  end

  get '/profile' do
    authenticate_user!

    haml :profile
  end

  get '/login' do
    haml :login
  end

  get '/logout' do
    sign_out
    redirect '/'
  end

  post '/user_sessions' do
    begin
      user = User.authenticate(params[:user_session])
    rescue Gitlab::Error::Unauthorized
      @error = "Wrong login or password"
    rescue URI::InvalidURIError
      @error = "Wrong server url"
    end

    if user && sign_in(user)
      redirect '/'
    else
      haml :login
    end
  end

  get '/log_time' do
    authenticate_user!

    @projects = current_user.api.projects

    haml :log_time
  end

  post '/create_time_log' do
    authenticate_user!

    log_time_params = params['time_log'].slice(*Api::Gitlab::LOG_TIME_ATTRIBUTES).symbolize_keys
    time_log_params = params['time_log'].slice(*TimeLog::ATTRIBUTES)

    time_log_params['user_id'] = current_user.id
    time_log_params['time'] = TimeParser.new(time_log_params['time']).to_h

    time_log = TimeLog.new(time_log_params)

    if time_log.save
      begin
        current_user.api.log_time(**log_time_params) if params.dig('time_log', 'push_to_gitlab')
      rescue Gitlab::Error::BadRequest
        nil
      end

      redirect '/'
    else
      @projects = current_user.api.projects
      @errors = time_log.errors.full_messages

      haml :log_time
    end
  end

  helpers do
    def current_user
      @current_user ||= begin
                          if session[:current_user]
                            User.new(Marshal.load(session[:current_user]))
                          end
                        end
    end

    def sign_in(user)
      session[:current_user] = Marshal.dump user.to_hash
    end

    def sign_out
      session[:current_user] = nil
    end

    def authenticate_user!
      unless current_user
        redirect '/login'
        return
      end
    end

    def gravatar_icon(user_email = '', size = 40)
      gravatar_url ||= 'https://secure.gravatar.com/avatar/%{hash}?s=%{size}&d=mm'
      user_email.strip!
      sprintf gravatar_url, hash: Digest::MD5.hexdigest(user_email.downcase), size: size
    end

    def link_to(title, path, opts={})
      "<a href='#{path}' class='#{opts[:class]}'>#{title}</a>"
    end

    def issue_url(project, id)
      project.web_url + '/issues/' + id.to_s
    end
  end

  # start the server if ruby file executed directly
  run! if app_file == $0
end
