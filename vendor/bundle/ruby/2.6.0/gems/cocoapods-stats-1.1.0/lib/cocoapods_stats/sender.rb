require 'rest'

module CocoaPodsStats
  class Sender
    API_URL = 'https://stats.cocoapods.org/api/v1/install'.freeze

    def send(targets, pod_try: false)
      body = {
        :targets => targets,
        :cocoapods_version => Pod::VERSION,
        :pod_try => pod_try,
      }
      headers = {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
      }
      curl(API_URL, body, headers)
    end

    private

    def curl(url, json, headers)
      headers = headers.map { |k, v| ['-H', "#{k}: #{v}"] }.flatten
      command = ['curl', *headers, '-X', 'POST', '-d', json.to_json, '-m', '30', url]
      dev_null = '/dev/null'
      Process.spawn(*command, :out => dev_null, :err => dev_null)
    end
  end
end
