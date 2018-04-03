require 'test_helper'
require 'webmock/minitest'
require 'sensu-handler'

class TestHandleAPIRequest < MiniTest::Test
  include SensuPluginTestHelper

  Sensu::Handler.disable_autorun

  def test_http_request
    stub_request(:get, 'http://127.0.0.1:4567/foo').to_return(status: 200, body: '', headers: {})

    handler = Sensu::Handler.new([])
    response = handler.api_request(:get, '/foo')

    assert_equal(response.code, '200')
  end

  def test_https_request
    stub_request(:get, 'https://127.0.0.1:4567/foo').to_return(status: 200, body: '', headers: {})

    handler = Sensu::Handler.new([])
    handler.api_settings = handler.api_settings.merge('ssl' => {})

    response = handler.api_request(:get, '/foo')

    assert_equal(response.code, '200')
  end
end
