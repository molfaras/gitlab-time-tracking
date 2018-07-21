module AuthenticationHelper
  def authenticate(params)
    client = gitlab_api(params['private_token'])
    response = client.user

    if response
      User.new(response.to_hash.merge(
        'private_token' => params['private_token']
      ))
    end
  end

  def gitlab_api(private_token)
    Api::Gitlab.new(private_token: private_token)
  end
end
